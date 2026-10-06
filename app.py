#!/usr/bin/env python3
"""A local Gemini tool agent with a browser UI for Termux."""

from __future__ import annotations

import argparse
import json
import os
import re
import secrets
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs, quote, urlencode, urlparse
from urllib.request import Request, urlopen


APP_DIR = Path(__file__).resolve().parent
WEB_DIR = APP_DIR / "web"
CONFIG_DIR = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "terminux"
CONFIG_FILE = CONFIG_DIR / "config.json"
SYSTEM_PROMPT = (
    "You are a practical terminal agent running inside the user's Termux environment on their Android device. "
    "The user speaks Persian; reply in Persian unless they ask otherwise. Use run_shell for commands that must "
    "be executed. Never claim a command succeeded until its actual output confirms it. Explain risky or "
    "irreversible commands before requesting them. Work in the user's home directory by default."
)
MAX_COMMAND_STEPS = 8
MAX_OUTPUT_CHARS = 16000

LOCK = threading.RLock()
HISTORY: list[dict] = []
EVENTS: list[dict] = []
NEXT_EVENT_ID = 1
RUNNING = False
AUTO_APPROVE = False
PENDING_APPROVAL: dict | None = None
APPROVAL_EVENT: threading.Event | None = None
APPROVAL_DECISION: bool | None = None
CONFIG = {"api_key": os.environ.get("GEMINI_API_KEY", ""), "model": os.environ.get("GEMINI_MODEL", "gemini-2.5-flash")}


def load_config() -> None:
    global CONFIG
    if CONFIG_FILE.is_file():
        try:
            saved = json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
            CONFIG = {
                "api_key": os.environ.get("GEMINI_API_KEY") or saved.get("api_key", ""),
                "model": os.environ.get("GEMINI_MODEL") or saved.get("model", "gemini-2.5-flash"),
            }
        except (OSError, ValueError):
            pass


def save_config(api_key: str, model: str) -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    CONFIG_FILE.write_text(json.dumps({"api_key": api_key, "model": model}, indent=2), encoding="utf-8")
    try:
        CONFIG_FILE.chmod(0o600)
    except OSError:
        pass


def add_event(kind: str, **fields: object) -> dict:
    global NEXT_EVENT_ID
    with LOCK:
        event = {"id": NEXT_EVENT_ID, "type": kind, "time": int(time.time()), **fields}
        NEXT_EVENT_ID += 1
        EVENTS.append(event)
        del EVENTS[:-300]
        return event


def build_gemini_payload(contents: list[dict]) -> dict:
    return {
        "systemInstruction": {"parts": [{"text": SYSTEM_PROMPT}]},
        "contents": contents,
        "tools": [{
            "functionDeclarations": [{
                "name": "run_shell",
                "description": "Run a shell command in the user's Termux home directory and return its exit code, stdout and stderr.",
                "parameters": {
                    "type": "OBJECT",
                    "properties": {"command": {"type": "STRING", "description": "The exact shell command to run."}},
                    "required": ["command"],
                },
            }]
        }],
        "generationConfig": {"temperature": 0.2},
    }


def call_gemini(contents: list[dict]) -> dict:
    api_key = CONFIG.get("api_key", "")
    if not api_key:
        raise RuntimeError("کلید Gemini تنظیم نشده است. از دکمهٔ تنظیمات، API key را وارد کن.")
    model = CONFIG.get("model") or "gemini-2.5-flash"
    endpoint = f"https://generativelanguage.googleapis.com/v1beta/models/{quote(model, safe='')}:generateContent?{urlencode({'key': api_key})}"
    body = json.dumps(build_gemini_payload(contents)).encode("utf-8")
    request = Request(endpoint, data=body, headers={"Content-Type": "application/json"}, method="POST")
    try:
        with urlopen(request, timeout=90) as response:
            return json.loads(response.read().decode("utf-8"))
    except HTTPError as error:
        try:
            detail = json.loads(error.read().decode("utf-8")).get("error", {}).get("message", "")
        except (ValueError, OSError):
            detail = ""
        raise RuntimeError(f"Gemini API پاسخ {error.code} داد. {detail}".strip()) from error
    except URLError as error:
        raise RuntimeError(f"اتصال به Gemini برقرار نشد: {error.reason}") from error


def execute_command(command: str, timeout: int = 120) -> dict:
    if not isinstance(command, str) or not command.strip():
        return {"exit_code": 2, "output": "فرمان خالی بود."}
    shell = os.environ.get("SHELL")
    try:
        result = subprocess.run(
            command,
            shell=True,
            executable=shell if shell and Path(shell).exists() else None,
            cwd=Path.home(),
            capture_output=True,
            text=True,
            errors="replace",
            timeout=timeout,
        )
        output = "".join((result.stdout or "", result.stderr or ""))
        if not output:
            output = "(بدون خروجی)"
        if len(output) > MAX_OUTPUT_CHARS:
            output = output[:MAX_OUTPUT_CHARS] + "\n… خروجی برای نمایش کوتاه شد."
        return {"exit_code": result.returncode, "output": output}
    except subprocess.TimeoutExpired as error:
        output = (error.stdout or b"")
        if isinstance(output, bytes):
            output = output.decode("utf-8", errors="replace")
        return {"exit_code": 124, "output": f"مهلت {timeout} ثانیه‌ای تمام شد.\n{output}"}
    except OSError as error:
        return {"exit_code": 127, "output": str(error)}


def request_approval(command: str) -> bool:
    global PENDING_APPROVAL, APPROVAL_EVENT, APPROVAL_DECISION
    with LOCK:
        if AUTO_APPROVE:
            return True
        approval_id = secrets.token_urlsafe(9)
        event = threading.Event()
        APPROVAL_EVENT = event
        APPROVAL_DECISION = None
        PENDING_APPROVAL = {"id": approval_id, "command": command}
    add_event("command_pending", command=command, approval_id=approval_id)
    completed = event.wait(300)
    with LOCK:
        approved = completed and APPROVAL_DECISION is True
        PENDING_APPROVAL = None
        APPROVAL_EVENT = None
        APPROVAL_DECISION = None
    if not completed:
        add_event("notice", text="درخواست فرمان پس از ۵ دقیقه بدون تأیید رد شد.")
    return approved


def run_agent(message: str) -> None:
    global RUNNING
    try:
        with LOCK:
            HISTORY.append({"role": "user", "parts": [{"text": message}]})
        for _ in range(MAX_COMMAND_STEPS + 1):
            response = call_gemini(HISTORY)
            candidates = response.get("candidates", [])
            if not candidates or not candidates[0].get("content"):
                raise RuntimeError("Gemini پاسخی برنگرداند. وضعیت مدل یا API key را بررسی کن.")
            model_content = candidates[0]["content"]
            model_content.setdefault("role", "model")
            HISTORY.append(model_content)
            parts = model_content.get("parts", [])
            for part in parts:
                if part.get("text"):
                    add_event("assistant", text=part["text"])
            calls = [part["functionCall"] for part in parts if part.get("functionCall")]
            if not calls:
                break
            if len(HISTORY) > 100:
                del HISTORY[:20]
            for call in calls:
                name = call.get("name")
                args = call.get("args", {})
                if name != "run_shell":
                    output = {"exit_code": 2, "output": f"ابزار ناشناخته: {name}"}
                else:
                    command = args.get("command", "") if isinstance(args, dict) else ""
                    if not isinstance(command, str) or not command.strip():
                        output = {"exit_code": 2, "output": "مدل فرمان معتبری نفرستاد."}
                    elif not request_approval(command):
                        output = {"exit_code": 125, "output": "کاربر اجرای این فرمان را تأیید نکرد."}
                        add_event("command_result", command=command, **output)
                    else:
                        add_event("command_running", command=command)
                        output = execute_command(command)
                        add_event("command_result", command=command, **output)
                HISTORY.append({
                    "role": "user",
                    "parts": [{"functionResponse": {"name": name, "response": output}}],
                })
        else:
            add_event("notice", text="برای جلوگیری از حلقهٔ بی‌پایان، این نوبت پس از چند فرمان متوقف شد.")
    except Exception as error:
        add_event("error", text=str(error))
    finally:
        with LOCK:
            RUNNING = False
        add_event("status", running=False)


class LocalServer(ThreadingHTTPServer):
    daemon_threads = True
    allow_reuse_address = True


class Handler(BaseHTTPRequestHandler):
    server_version = "Terminux/0.1"

    def log_message(self, _format: str, *_args: object) -> None:
        return

    def _send(self, status: int, body: bytes, content_type: str) -> None:
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.end_headers()
        self.wfile.write(body)

    def _json(self, status: int, value: dict) -> None:
        self._send(status, json.dumps(value, ensure_ascii=False).encode("utf-8"), "application/json; charset=utf-8")

    def _local_request(self) -> bool:
        host = self.headers.get("Host", "").split(":", 1)[0].lower()
        if host not in {"127.0.0.1", "localhost"}:
            return False
        origin = self.headers.get("Origin")
        if origin:
            parsed = urlparse(origin)
            if parsed.hostname not in {"127.0.0.1", "localhost"}:
                return False
        return True

    def do_GET(self) -> None:
        if not self._local_request():
            self._json(403, {"error": "فقط اتصال محلی مجاز است."})
            return
        path = urlparse(self.path).path
        if path in {"/", "/index.html"}:
            try:
                self._send(200, (WEB_DIR / "index.html").read_bytes(), "text/html; charset=utf-8")
            except OSError:
                self._json(500, {"error": "فایل رابط وب پیدا نشد."})
        elif path == "/api/state":
            query = parse_qs(urlparse(self.path).query)
            try:
                after = int(query.get("after", ["0"])[0])
            except ValueError:
                after = 0
            with LOCK:
                state = {
                    "events": [item for item in EVENTS if item["id"] > after],
                    "running": RUNNING,
                    "autoApprove": AUTO_APPROVE,
                    "pending": PENDING_APPROVAL,
                    "configured": bool(CONFIG.get("api_key")),
                    "model": CONFIG.get("model"),
                }
            self._json(200, state)
        elif path == "/api/config":
            self._json(200, {"configured": bool(CONFIG.get("api_key")), "model": CONFIG.get("model")})
        elif path == "/healthz":
            self._json(200, {"ok": True})
        else:
            self._json(404, {"error": "پیدا نشد."})

    def do_POST(self) -> None:
        global RUNNING, AUTO_APPROVE, APPROVAL_DECISION
        if not self._local_request():
            self._json(403, {"error": "فقط اتصال محلی مجاز است."})
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if length > 65536:
                self._json(413, {"error": "درخواست بیش از حد بزرگ است."})
                return
            data = json.loads(self.rfile.read(length) or b"{}")
        except (ValueError, json.JSONDecodeError):
            self._json(400, {"error": "JSON نامعتبر است."})
            return
        path = urlparse(self.path).path
        if path == "/api/chat":
            message = data.get("message", "")
            if not isinstance(message, str) or not message.strip() or len(message) > 8000:
                self._json(400, {"error": "متن پیام خالی یا بیش از حد طولانی است."})
                return
            with LOCK:
                if RUNNING:
                    self._json(409, {"error": "یک درخواست دیگر هنوز در حال اجراست."})
                    return
                RUNNING = True
            add_event("user", text=message.strip())
            add_event("status", running=True)
            threading.Thread(target=run_agent, args=(message.strip(),), daemon=True).start()
            self._json(202, {"ok": True})
        elif path == "/api/config":
            model = data.get("model", CONFIG.get("model", "gemini-2.5-flash"))
            api_key = data.get("apiKey", "")
            if not isinstance(model, str) or not re.fullmatch(r"[A-Za-z0-9._-]{1,100}", model):
                self._json(400, {"error": "نام مدل معتبر نیست."})
                return
            if not isinstance(api_key, str):
                self._json(400, {"error": "API key معتبر نیست."})
                return
            if api_key.strip():
                CONFIG["api_key"] = api_key.strip()
            CONFIG["model"] = model
            try:
                save_config(CONFIG["api_key"], model)
            except OSError as error:
                self._json(500, {"error": f"تنظیمات ذخیره نشد: {error}"})
                return
            self._json(200, {"ok": True, "configured": bool(CONFIG["api_key"]), "model": model})
        elif path == "/api/approval":
            approved = data.get("approved") is True
            with LOCK:
                if not PENDING_APPROVAL or data.get("id") != PENDING_APPROVAL.get("id") or not APPROVAL_EVENT:
                    self._json(409, {"error": "درخواست تأییدی برای این شناسه وجود ندارد."})
                    return
                APPROVAL_DECISION = approved
                APPROVAL_EVENT.set()
            self._json(200, {"ok": True})
        elif path == "/api/auto-approve":
            if not isinstance(data.get("enabled"), bool):
                self._json(400, {"error": "مقدار enabled باید true یا false باشد."})
                return
            with LOCK:
                AUTO_APPROVE = data["enabled"]
            add_event("notice", text="اجرای خودکار روشن شد." if AUTO_APPROVE else "تأیید دستی فرمان‌ها روشن شد.")
            self._json(200, {"ok": True, "enabled": AUTO_APPROVE})
        elif path == "/api/clear":
            with LOCK:
                if RUNNING:
                    self._json(409, {"error": "هنگام اجرای درخواست نمی‌توان گفتگو را پاک کرد."})
                    return
                HISTORY.clear()
                EVENTS.clear()
            self._json(200, {"ok": True})
        else:
            self._json(404, {"error": "پیدا نشد."})


def main() -> None:
    parser = argparse.ArgumentParser(description="Terminux: local Gemini terminal agent for Termux")
    parser.add_argument("--host", default="127.0.0.1", help="Bind address (keep this on localhost)")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--open-browser", action="store_true", help="Open the local chat page with Termux")
    args = parser.parse_args()
    if args.host not in {"127.0.0.1", "localhost"}:
        parser.error("The server intentionally only supports localhost binding.")
    load_config()
    server = LocalServer((args.host, args.port), Handler)
    url = f"http://127.0.0.1:{args.port}/"
    print(f"Terminux is ready at {url}", flush=True)
    if args.open_browser:
        try:
            subprocess.Popen(["termux-open-url", url], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except OSError:
            print("Could not open a browser automatically. Open the URL above.", flush=True)
    try:
        server.serve_forever(poll_interval=0.5)
    except KeyboardInterrupt:
        print("\nStopping local agent...", flush=True)
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
