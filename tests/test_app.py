import unittest
from unittest.mock import patch

import app


class AgentCoreTests(unittest.TestCase):
    def test_payload_declares_shell_tool(self):
        payload = app.build_gemini_payload([{"role": "user", "parts": [{"text": "hello"}]}])
        declaration = payload["tools"][0]["functionDeclarations"][0]
        self.assertEqual(declaration["name"], "run_shell")
        self.assertEqual(declaration["parameters"]["required"], ["command"])

    def test_command_returns_exit_status_and_output(self):
        result = app.execute_command("printf agent-test")
        self.assertEqual(result["exit_code"], 0)
        self.assertEqual(result["output"], "agent-test")

    def test_command_output_is_capped(self):
        with patch.object(app, "MAX_OUTPUT_CHARS", 5):
            result = app.execute_command("printf 123456789")
        self.assertTrue(result["output"].startswith("12345"))
        self.assertIn("کوتاه شد", result["output"])

    def test_empty_command_is_rejected(self):
        result = app.execute_command("  ")
        self.assertNotEqual(result["exit_code"], 0)


if __name__ == "__main__":
    unittest.main()
