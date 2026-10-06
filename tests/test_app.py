import json
import os
import tempfile
import threading
import unittest
from pathlib import Path
from unittest.mock import patch
from urllib.request import Request, urlopen

import app


class AgentCoreTests(unittest.TestCase):
    def test_payload_declares_shell_tool(self):
        payload = app.build_gemini_payload([{"role": "user", "parts": [{"text": "hello"}]}])
        declarations = payload["tools"][0]["functionDeclarations"]
        names = {item["name"] for item in declarations}
        self.assertTrue({"run_shell", "write_file", "github_api", "github_create_repo", "github_publish_workspace", "cloudflare_api"} <= names)

    def test_command_returns_exit_status_and_output(self):
        with patch.object(app, "WORKSPACE_DIR", Path.cwd()):
            result = app.execute_command("printf agent-test")
        self.assertEqual(result["exit_code"], 0)
        self.assertEqual(result["output"], "agent-test")

    def test_command_output_is_capped(self):
        with patch.object(app, "WORKSPACE_DIR", Path.cwd()), patch.object(app, "MAX_OUTPUT_CHARS", 5):
            result = app.execute_command("printf 123456789")
        self.assertTrue(result["output"].startswith("12345"))
        self.assertIn("کوتاه شد", result["output"])

    def test_empty_command_is_rejected(self):
        result = app.execute_command("  ")
        self.assertNotEqual(result["exit_code"], 0)

    def test_provider_tokens_are_removed_from_shell_environment(self):
        with patch.object(app, "WORKSPACE_DIR", Path.cwd()), patch.dict(os.environ, {"GITHUB_TOKEN": "hidden-test-token", "CLOUDFLARE_API_TOKEN": "hidden-cf-token"}):
            result = app.execute_command("printf '%s:%s' \"${GITHUB_TOKEN-unset}\" \"${CLOUDFLARE_API_TOKEN-unset}\"")
        self.assertEqual(result["output"], "unset:unset")

    def test_workspace_read_write_and_escape_guard(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            with patch.object(app, "WORKSPACE_DIR", root):
                result = app.write_workspace_file("src/main.py", "print('hello')")
                self.assertTrue(result["ok"])
                self.assertEqual(app.read_workspace_file("src/main.py")["content"], "print('hello')")
                with self.assertRaises(ValueError):
                    app.workspace_path("../outside.txt")

    def test_credentials_and_history_are_saved_with_private_permissions(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            with patch.object(app, "CONFIG_DIR", root), patch.object(app, "CONFIG_FILE", root / "config.json"), patch.object(app, "HISTORY_FILE", root / "history.json"), patch.object(app, "HISTORY", [{"role": "user", "parts": [{"text": "continue"}]}]):
                with patch.dict(app.CONFIG, {"api_key": "gemini-test", "github_token": "github-test", "cloudflare_token": "cloudflare-test", "model": "gemini-test-model"}):
                    app.save_config()
                app.save_history()
                settings = json.loads((root / "config.json").read_text(encoding="utf-8"))
                self.assertEqual(settings["github_token"], "github-test")
                self.assertEqual(settings["cloudflare_token"], "cloudflare-test")
                if os.name == "posix":
                    self.assertEqual((root / "config.json").stat().st_mode & 0o777, 0o600)
                    self.assertEqual(root.stat().st_mode & 0o777, 0o700)

    def test_persisted_history_reloads_for_the_next_run(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            with patch.object(app, "CONFIG_DIR", root), patch.object(app, "HISTORY_FILE", root / "history.json"), patch.object(app, "HISTORY", [{"role": "user", "parts": [{"text": "resume project"}]}]) as history:
                app.save_history()
                history.clear()
                app.load_history()
                self.assertEqual(history[0]["parts"][0]["text"], "resume project")

    def test_settings_api_saves_tokens_but_never_returns_them(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            server = app.LocalServer(("127.0.0.1", 0), app.Handler)
            thread = threading.Thread(target=server.serve_forever, daemon=True)
            thread.start()
            url = f"http://127.0.0.1:{server.server_address[1]}"
            try:
                with patch.object(app, "CONFIG_DIR", root), patch.object(app, "CONFIG_FILE", root / "config.json"), patch.dict(app.CONFIG, {}, clear=True):
                    body = json.dumps({"apiKey":"gemini-secret","githubToken":"github-secret","cloudflareToken":"cloudflare-secret","model":"gemini-test"}).encode()
                    request = Request(url + "/api/config", data=body, headers={"Content-Type":"application/json"}, method="POST")
                    saved = json.load(urlopen(request))
                    visible = json.load(urlopen(url + "/api/config"))
                self.assertTrue(saved["githubConfigured"] and saved["cloudflareConfigured"])
                self.assertNotIn("github-secret", json.dumps(visible))
                self.assertNotIn("cloudflare-secret", json.dumps(visible))
            finally:
                server.shutdown()
                server.server_close()

    def test_provider_token_stays_in_header_not_tool_result(self):
        class FakeResponse:
            status = 200

            def __enter__(self):
                return self

            def __exit__(self, *_args):
                return False

            def read(self, _size):
                return b'{"login":"agent"}'

        with patch.dict(app.CONFIG, {"github_token": "test-token-secret"}), patch.object(app, "urlopen", return_value=FakeResponse()) as mocked:
            result = app.provider_api("github", "GET", "/user")
        request = mocked.call_args.args[0]
        self.assertEqual(request.full_url, "https://api.github.com/user")
        self.assertEqual(request.get_header("Authorization"), "Bearer test-token-secret")
        self.assertNotIn("test-token-secret", json.dumps(result))

    def test_provider_rejects_absolute_or_traversal_paths(self):
        with patch.dict(app.CONFIG, {"github_token": "test-token"}):
            self.assertIn("error", app.provider_api("github", "GET", "https://example.com/user"))
            self.assertIn("error", app.provider_api("github", "GET", "/repos/a/../b"))

    def test_publish_workspace_builds_single_commit_and_skips_env(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "README.md").write_text("# Demo", encoding="utf-8")
            (root / ".env").write_text("SECRET=hidden", encoding="utf-8")
            (root / ".env.production").write_text("SECRET=also-hidden", encoding="utf-8")
            (root / "icon.png").write_bytes(b"\x89PNG\r\n\x1a\n")
            calls = []

            def fake_api(_provider, method, path, body=None):
                calls.append((method, path, body))
                if method == "GET" and path == "/repos/alice/demo":
                    return {"success": True, "data": {"default_branch": "main"}}
                if method == "GET" and path.endswith("/git/ref/heads/main"):
                    return {"success": False, "status": 404, "data": {}}
                if method == "POST" and path.endswith("/git/blobs"):
                    return {"success": True, "data": {"sha": "binary-blob-sha"}}
                if method == "POST" and path.endswith("/git/trees"):
                    return {"success": True, "data": {"sha": "tree-sha"}}
                if method == "POST" and path.endswith("/git/commits"):
                    return {"success": True, "data": {"sha": "commit-sha", "html_url": "https://github.com/alice/demo/commit/commit-sha"}}
                if method == "POST" and path.endswith("/git/refs"):
                    return {"success": True, "data": {}}
                self.fail(f"Unexpected API request: {method} {path}")

            with patch.object(app, "WORKSPACE_DIR", root), patch.object(app, "provider_api", side_effect=fake_api):
                result = app.github_publish_workspace({"owner": "alice", "repo": "demo", "message": "Initial commit"})

            self.assertTrue(result["success"])
            self.assertEqual(result["files_committed"], 2)
            tree_request = next(body for method, path, body in calls if method == "POST" and path.endswith("/git/trees"))
            self.assertEqual({entry["path"] for entry in tree_request["tree"]}, {"README.md", "icon.png"})
            self.assertEqual(next(entry["sha"] for entry in tree_request["tree"] if entry["path"] == "icon.png"), "binary-blob-sha")
            self.assertNotIn("SECRET=hidden", json.dumps(tree_request))
            self.assertNotIn("SECRET=also-hidden", json.dumps(tree_request))

    def test_publish_updates_existing_branch_without_force_push(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "main.py").write_text("print('updated')", encoding="utf-8")
            calls = []

            def fake_api(_provider, method, path, body=None):
                calls.append((method, path, body))
                if method == "GET" and path == "/repos/alice/demo":
                    return {"success": True, "data": {"default_branch": "main"}}
                if method == "GET" and path.endswith("/git/ref/heads/main"):
                    return {"success": True, "data": {"object": {"sha": "old-commit"}}}
                if method == "GET" and path.endswith("/git/commits/old-commit"):
                    return {"success": True, "data": {"tree": {"sha": "old-tree"}}}
                if method == "POST" and path.endswith("/git/trees"):
                    return {"success": True, "data": {"sha": "new-tree"}}
                if method == "POST" and path.endswith("/git/commits"):
                    return {"success": True, "data": {"sha": "new-commit", "html_url": "https://github.com/alice/demo/commit/new-commit"}}
                if method == "PATCH" and path.endswith("/git/refs/heads/main"):
                    return {"success": True, "data": {}}
                self.fail(f"Unexpected API request: {method} {path}")

            with patch.object(app, "WORKSPACE_DIR", root), patch.object(app, "provider_api", side_effect=fake_api):
                result = app.github_publish_workspace({"owner": "alice", "repo": "demo", "message": "Update"})

            self.assertTrue(result["success"])
            update = next(call for call in calls if call[0] == "PATCH")
            self.assertFalse(update[2]["force"])
            self.assertEqual(update[2]["sha"], "new-commit")


if __name__ == "__main__":
    unittest.main()
