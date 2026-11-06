import express, { type Request, type Response } from "express";
import cors from "cors";
import { spawn, type ChildProcess } from "node:child_process";
import { createHash } from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const APP_DIR = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const WEB_DIR = path.join(APP_DIR, "web");
const CONFIG_DIR = process.env.TERMINUX_CONFIG_DIR || path.join(os.homedir(), ".config", "terminux");
const CONFIG_FILE = path.join(CONFIG_DIR, "config.json");
const UPLOAD_DIR = path.join(CONFIG_DIR, "uploads");
const WORKSPACE = path.resolve(process.env.TERMINUX_WORKSPACE || path.join(APP_DIR, "workspace"));
const HOST = process.env.TERMINUX_HOST || "127.0.0.1";
const PORT = Number(process.env.PORT || 3000);

const PROVIDERS = [
  { id: "gemini", label: "Gemini", env: ["GEMINI_API_KEY"], models: ["gemini-3.8-flash", "gemini-2.5-flash", "gemini-2.5-pro"] },
  { id: "mistral", label: "Mistral", env: ["MISTRAL_API_KEY"], models: ["mistral-large-latest", "mistral-small-latest"] },
  { id: "deepseek", label: "DeepSeek", env: ["DEEPSEEK_API_KEY"], models: ["deepseek-chat", "deepseek-reasoner"] },
  { id: "openrouter", label: "OpenRouter", env: ["OPENROUTER_API_KEY"], models: ["anthropic/claude-sonnet-4", "openai/gpt-4o-mini", "google/gemini-2.5-flash"] },
] as const;

type ProviderId = (typeof PROVIDERS)[number]["id"];

interface McpServer { url?: string; command?: string; args?: string[]; token?: string }

interface Config {
  provider: ProviderId;
  model: string;
  apiKey: string;
  mistralApiKey: string;
  deepseekApiKey: string;
  openrouterApiKey: string;
  geminiOauthTokens: string;
  githubToken: string;
  cloudflareToken: string;
  linearApiKey: string;
  hfToken: string;
  gmailAddress: string;
  gmailAppPassword: string;
  driveClientId: string;
  driveClientSecret: string;
  driveRefreshToken: string;
  mcpServers: Record<string, McpServer>;
  passTokensToShell: boolean;
}

const DEFAULT_CONFIG: Config = {
  provider: "gemini",
  model: process.env.GEMINI_MODEL || "gemini-3.8-flash",
  apiKey: "", mistralApiKey: "", deepseekApiKey: "", openrouterApiKey: "", geminiOauthTokens: "",
  githubToken: "", cloudflareToken: "", linearApiKey: "", hfToken: "",
  gmailAddress: "", gmailAppPassword: "", driveClientId: "", driveClientSecret: "", driveRefreshToken: "",
  mcpServers: {}, passTokensToShell: false,
};

const SECRET_FIELDS: (keyof Config)[] = [
  "apiKey", "mistralApiKey", "deepseekApiKey", "openrouterApiKey", "geminiOauthTokens", "githubToken",
  "cloudflareToken", "linearApiKey", "hfToken", "gmailAppPassword", "driveClientSecret", "driveRefreshToken",
];

function loadConfig(): Config {
  try {
    const raw = JSON.parse(fs.readFileSync(CONFIG_FILE, "utf8")) as Partial<Config>;
    return { ...DEFAULT_CONFIG, ...raw, mcpServers: raw.mcpServers || {} };
  } catch {
    return { ...DEFAULT_CONFIG };
  }
}

const config: Config = loadConfig();

function saveConfig(): void {
  fs.mkdirSync(CONFIG_DIR, { recursive: true, mode: 0o700 });
  fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2), { mode: 0o600 });
}

function providerKey(): string {
  const p = PROVIDERS.find((x) => x.id === config.provider);
  if (!p) return "";
  if (p.id === "gemini") return config.apiKey || process.env.GEMINI_API_KEY || firstOauthToken();
  if (p.id === "mistral") return config.mistralApiKey || process.env.MISTRAL_API_KEY || "";
  if (p.id === "deepseek") return config.deepseekApiKey || process.env.DEEPSEEK_API_KEY || "";
  return config.openrouterApiKey || process.env.OPENROUTER_API_KEY || "";
}

function firstOauthToken(): string {
  const fromConfig = config.geminiOauthTokens.split(/\s+/).filter(Boolean);
  return fromConfig[0] || (process.env.GEMINI_OAUTH_TOKENS || "").split(/\s+/).filter(Boolean)[0] || "";
}

function providerConfigured(): boolean {
  return Boolean(providerKey());
}

// ── events (polling log) ──
interface AgentEvent { id: number; type: string; text?: string; [key: string]: unknown }

const events: AgentEvent[] = [];
let nextEventId = 1;
const MAX_EVENTS = 500;

function pushEvent(event: Omit<AgentEvent, "id">): AgentEvent {
  const full = { ...event, id: nextEventId++ } as AgentEvent;
  events.push(full);
  if (events.length > MAX_EVENTS) events.splice(0, events.length - MAX_EVENTS);
  return full;
}

// ── agent state ──
interface PendingApproval { approval_id: number; command: string; resolve: (value: { approved: boolean; reason?: string }) => void }

let running = false;
let autoApprove = false;
let pending: PendingApproval | null = null;
let currentAbort: AbortController | null = null;
let currentChild: ChildProcess | null = null;
let nextApprovalId = 1;

const history: { role: "user" | "model"; text: string }[] = [];

// ── path safety ──
function insideRoot(root: string, candidate: string): string | null {
  const resolved = path.resolve(root, candidate);
  const rel = path.relative(root, resolved);
  if (rel && (rel.startsWith("..") || path.isAbsolute(rel))) return null;
  return resolved;
}

function workspacePath(input: string): string | null {
  return insideRoot(WORKSPACE, input || ".");
}

function readJson(req: Request): Record<string, unknown> {
  const body = req.body as unknown;
  return body && typeof body === "object" ? (body as Record<string, unknown>) : {};
}

function str(value: unknown): string {
  return typeof value === "string" ? value : "";
}

// ── shell tool ──
function runShell(command: string, timeoutMs = 120_000): Promise<{ exitCode: number; output: string }> {
  return new Promise((resolve) => {
    const shell = process.platform === "win32" ? "cmd.exe" : "bash";
    const args = process.platform === "win32" ? ["/d", "/s", "/c", command] : ["-lc", command];
    let child: ChildProcess;
    try {
      child = spawn(shell, args, { cwd: WORKSPACE, detached: process.platform !== "win32", env: shellEnv() });
    } catch (error) {
      resolve({ exitCode: 1, output: `spawn failed: ${String(error)}` });
      return;
    }
    currentChild = child;
    const chunks: string[] = [];
    let size = 0;
    const keep = (text: string) => {
      chunks.push(text);
      size += text.length;
      while (size > 200_000 && chunks.length > 1) size -= chunks.shift()!.length;
    };
    child.stdout?.on("data", (data: Buffer) => {
      const text = data.toString();
      keep(text);
      pushEvent({ type: "command_chunk", chunk: text });
    });
    child.stderr?.on("data", (data: Buffer) => {
      const text = data.toString();
      keep(text);
      pushEvent({ type: "command_chunk", chunk: text });
    });
    let timedOut = false;
    const timer = setTimeout(() => {
      timedOut = true;
      killTree(child);
    }, timeoutMs);
    child.on("error", (error) => {
      clearTimeout(timer);
      currentChild = null;
      resolve({ exitCode: 1, output: chunks.join("") + `\n${String(error)}` });
    });
    child.on("close", (code) => {
      clearTimeout(timer);
      currentChild = null;
      const suffix = timedOut ? `\n[killed after ${timeoutMs}ms timeout]` : "";
      resolve({ exitCode: timedOut ? 124 : (code ?? 1), output: chunks.join("").slice(-200_000) + suffix });
    });
  });
}

function killTree(child: ChildProcess): void {
  try {
    if (process.platform !== "win32" && child.pid) process.kill(-child.pid, "SIGKILL");
    else child.kill("SIGKILL");
  } catch {
    try { child.kill("SIGKILL"); } catch { /* already gone */ }
  }
}

function shellEnv(): NodeJS.ProcessEnv {
  const env: NodeJS.ProcessEnv = { ...process.env, TERMINUX_WORKSPACE: WORKSPACE };
  if (config.passTokensToShell) {
    env.GEMINI_API_KEY = config.apiKey || env.GEMINI_API_KEY;
    env.GITHUB_TOKEN = config.githubToken || env.GITHUB_TOKEN;
    env.CLOUDFLARE_API_TOKEN = config.cloudflareToken || env.CLOUDFLARE_API_TOKEN;
  }
  return env;
}

// ── conversation persistence ──
function historyLimit(): number {
  return 30;
}

function pushHistory(entry: { role: "user" | "model"; text: string }): void {
  history.push(entry);
  if (history.length > 200) history.splice(0, history.length - 100);
}

// ── system prompt ──
function systemPrompt(): string {
  return [
    "You are Terminux, a terminal agent running on the user's machine (usually Termux on Android).",
    `Workspace: ${WORKSPACE}. Platform: ${process.platform} ${process.arch}.`,
    "To run a command, output EXACTLY one fenced block tagged run:",
    "```run",
    "ls -la",
    "```",
    "Only run commands that are safe and relevant. Never fabricate command output or success.",
    "Answer in the user's language (Persian by default). Keep answers short and practical.",
  ].join("\n");
}

// ── provider request ──
interface ToolResult { exitCode: number; output: string }

async function callGemini(messages: { role: "user" | "model"; text: string }[], token: string, signal: AbortSignal): Promise<string> {
  const body = {
    systemInstruction: { parts: [{ text: systemPrompt() }] },
    contents: messages.map((m) => ({ role: m.role, parts: [{ text: m.text }] })),
    generationConfig: { temperature: 0.4, maxOutputTokens: 4096 },
  };
  const doFetch = async (bearer: string) => fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(config.model)}:generateContent?key=${encodeURIComponent(bearer)}`,
    { method: "POST", signal, headers: { "Content-Type": "application/json" }, body: JSON.stringify(body) },
  );
  let response = await doFetch(token);
  if (response.status === 401 || response.status === 403) {
    const retry = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(config.model)}:generateContent`,
      { method: "POST", signal, headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` }, body: JSON.stringify(body) },
    );
    if (retry.ok) response = retry;
  }
  if (!response.ok) throw new Error(`Gemini ${response.status}: ${(await response.text()).slice(0, 400)}`);
  const data = await response.json() as { candidates?: { content?: { parts?: { text?: string }[] } }[] };
  return (data.candidates?.[0]?.content?.parts || []).map((p) => p.text || "").join("").trim();
}

async function callOpenAICompatible(messages: { role: "user" | "model"; text: string }[], token: string, signal: AbortSignal): Promise<string> {
  const endpoints: Record<string, string> = {
    mistral: "https://api.mistral.ai/v1/chat/completions",
    deepseek: "https://api.deepseek.com/chat/completions",
    openrouter: "https://openrouter.ai/api/v1/chat/completions",
  };
  const url = endpoints[config.provider] || endpoints.deepseek;
  const response = await fetch(url, {
    method: "POST",
    signal,
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${token}` },
    body: JSON.stringify({
      model: config.model,
      messages: [{ role: "system", content: systemPrompt() }, ...messages.map((m) => ({ role: m.role === "model" ? "assistant" : "user", content: m.text }))],
      temperature: 0.4,
      max_tokens: 4096,
    }),
  });
  if (!response.ok) throw new Error(`${config.provider} ${response.status}: ${(await response.text()).slice(0, 400)}`);
  const data = await response.json() as { choices?: { message?: { content?: string } }[] };
  return (data.choices?.[0]?.message?.content || "").trim();
}

async function callModel(messages: { role: "user" | "model"; text: string }[], signal: AbortSignal): Promise<string> {
  const token = providerKey();
  if (!token) throw new Error("هیچ کلید API تنظیم نشده است. در تنظیمات کلید را وارد کنید.");
  return config.provider === "gemini" ? callGemini(messages, token, signal) : callOpenAICompatible(messages, token, signal);
}

// ── command extraction ──
function extractCommand(reply: string): { text: string; command: string | null } {
  const match = reply.match(/```run\r?\n([\s\S]*?)```/);
  if (!match) return { text: reply.trim(), command: null };
  const command = match[1].trim();
  const text = reply.replace(match[0], "").trim();
  return { text, command: command || null };
}

function requestApproval(command: string): Promise<{ approved: boolean; reason?: string }> {
  if (autoApprove) return Promise.resolve({ approved: true });
  return new Promise((resolve) => {
    const approval_id = nextApprovalId++;
    pending = { approval_id, command, resolve };
    pushEvent({ type: "command_pending", command, approval_id });
  });
}

// ── agent loop ──
async function runAgent(userText: string, attachments: { name: string; path: string; mimeType?: string }[]): Promise<void> {
  if (running) return;
  running = true;
  pushEvent({ type: "user", text: userText, attachments });
  pushEvent({ type: "status", running: true });
  const abort = new AbortController();
  currentAbort = abort;
  const note = attachments.length ? `\n\nپیوست‌ها: ${attachments.map((a) => a.path).join(", ")}` : "";
  pushHistory({ role: "user", text: userText + note });
  try {
    for (let step = 0; step < 6 && !abort.signal.aborted; step++) {
      pushEvent({ type: "thinking", step: step + 1, text: step === 0 ? "در حال تحلیل درخواست…" : "در حال بررسی نتیجه و ادامه…" });
      const reply = await callModel(history.slice(-historyLimit()), abort.signal);
      if (!reply) { pushEvent({ type: "error", text: "مدل پاسخ خالی داد." }); break; }
      const { text, command } = extractCommand(reply);
      if (text) {
        pushHistory({ role: "model", text });
        pushEvent({ type: "assistant", text });
      }
      if (!command) break;
      if (autoApprove) pushEvent({ type: "tool_call", tool: "shell", command, cwd: WORKSPACE });
      const decision = await requestApproval(command);
      if (!decision.approved) {
        pushEvent({ type: "notice", text: `فرمان اجرا نشد: ${decision.reason || "رد شد"}` });
        pushHistory({ role: "user", text: `Command was rejected by the user: ${command}. Ask what to do instead.` });
        break;
      }
      pending = null;
      pushEvent({ type: "command_running", command });
      const result = await runShell(command);
      pushEvent({ type: "tool_result", tool: "shell", command, exitCode: result.exitCode, output: result.output.slice(-8000) });
      if (abort.signal.aborted) break;
      pushHistory({ role: "user", text: `Command: ${command}\nExit code: ${result.exitCode}\nOutput:\n${result.output.slice(-8000)}\n\nContinue.` });
    }
  } catch (error) {
    if (!abort.signal.aborted) pushEvent({ type: "error", text: error instanceof Error ? error.message : String(error) });
    else pushEvent({ type: "notice", text: "اجرا متوقف شد." });
  } finally {
    pending?.resolve({ approved: false, reason: "cancelled" });
    pending = null;
    running = false;
    currentAbort = null;
    pushEvent({ type: "status", running: false });
  }
}

function stopAgent(): void {
  if (pending) pending.resolve({ approved: false, reason: "stopped" });
  pending = null;
  currentAbort?.abort();
  if (currentChild) killTree(currentChild);
}

// ── GitHub helpers ──
async function github(pathname: string, init: RequestInit = {}): Promise<unknown> {
  const token = config.githubToken || process.env.GITHUB_TOKEN || "";
  if (!token) throw new Error("توکن GitHub تنظیم نشده است.");
  const response = await fetch(`https://api.github.com${pathname}`, {
    ...init,
    headers: { Accept: "application/vnd.github+json", Authorization: `Bearer ${token}`, "User-Agent": "terminux", ...(init.headers || {}) },
  });
  if (!response.ok) throw new Error((await response.text()).slice(0, 300) || `GitHub ${response.status}`);
  return response.json();
}

// ── app ──
const app = express();
app.use((req, res, next) => {
  const host = (req.headers.host || "").split(":")[0];
  if (host !== "127.0.0.1" && host !== "localhost" && host !== HOST) {
    res.status(403).json({ error: "host not allowed" });
    return;
  }
  next();
});
app.use(cors({ origin: [`http://127.0.0.1:${PORT}`, `http://localhost:${PORT}`] }));
app.use(express.json({ limit: "25mb" }));
app.use(express.static(WEB_DIR, { index: "index.html" }));

app.get("/api/state", (req, res) => {
  const after = Number(req.query.after || 0);
  res.json({
    events: events.filter((event) => event.id > after),
    running,
    autoApprove,
    pending: pending ? { id: pending.approval_id, command: pending.command } : null,
    workspace: WORKSPACE,
    model: config.model,
    providerConfigured: providerConfigured(),
    githubConfigured: Boolean(config.githubToken || process.env.GITHUB_TOKEN),
    cloudflareConfigured: Boolean(config.cloudflareToken || process.env.CLOUDFLARE_API_TOKEN),
    ttsAvailable: process.platform !== "win32",
  });
});

app.post("/api/chat", (req, res) => {
  const body = readJson(req);
  const message = str(body.message).trim();
  const attachments = Array.isArray(body.attachments) ? body.attachments as { name: string; path: string; mimeType?: string }[] : [];
  if (!message && !attachments.length) { res.status(400).json({ error: "پیام خالی است." }); return; }
  if (running) { res.status(409).json({ error: "ایجنت در حال اجراست." }); return; }
  void runAgent(message, attachments);
  res.json({ ok: true });
});

app.post("/api/approval", (req, res) => {
  const body = readJson(req);
  const id = Number(body.id);
  if (!pending || pending.approval_id !== id) { res.status(409).json({ error: "درخواست تأیید منقضی شده است." }); return; }
  const approved = Boolean(body.approved);
  const resolve = pending.resolve;
  pending = null;
  resolve({ approved });
  res.json({ ok: true });
});

app.post("/api/stop", (_req, res) => {
  stopAgent();
  res.json({ ok: true });
});

app.post("/api/clear", (_req, res) => {
  stopAgent();
  events.length = 0;
  history.length = 0;
  res.json({ ok: true });
});

app.post("/api/auto-approve", (req, res) => {
  autoApprove = Boolean(readJson(req).enabled);
  res.json({ ok: true, autoApprove });
});

app.get("/api/config", (_req, res) => {
  const masked: Record<string, unknown> = {
    provider: config.provider,
    model: config.model,
    passTokensToShell: config.passTokensToShell,
    mcpServers: Object.fromEntries(Object.entries(config.mcpServers).map(([name, server]) => [name, { ...server, token: server.token ? "***" : undefined }])),
    configured: Boolean(config.apiKey),
    mistralConfigured: Boolean(config.mistralApiKey),
    deepseekConfigured: Boolean(config.deepseekApiKey),
    openrouterConfigured: Boolean(config.openrouterApiKey),
    geminiOauthConfigured: Boolean(config.geminiOauthTokens),
    geminiOauthTokenCount: config.geminiOauthTokens.split(/\s+/).filter(Boolean).length,
    githubConfigured: Boolean(config.githubToken),
    cloudflareConfigured: Boolean(config.cloudflareToken),
    linearConfigured: Boolean(config.linearApiKey),
    hfConfigured: Boolean(config.hfToken),
    gmailConfigured: Boolean(config.gmailAddress && config.gmailAppPassword),
    driveConfigured: Boolean(config.driveClientId && config.driveClientSecret && config.driveRefreshToken),
  };
  res.json(masked);
});

const CLEAR_FLAGS: Record<string, keyof Config> = {
  clearApiKey: "apiKey", clearMistralApiKey: "mistralApiKey", clearDeepseekApiKey: "deepseekApiKey",
  clearOpenrouterApiKey: "openrouterApiKey", clearLinearApiKey: "linearApiKey", clearHfToken: "hfToken",
  clearGithubToken: "githubToken", clearCloudflareToken: "cloudflareToken", clearGeminiOauthTokens: "geminiOauthTokens",
};

app.post("/api/config", (req, res) => {
  const body = readJson(req);
  if (str(body.provider)) {
    const provider = PROVIDERS.find((p) => p.id === body.provider);
    if (!provider) { res.status(400).json({ error: "سرویس‌دهنده نامعتبر است." }); return; }
    config.provider = provider.id;
  }
  if (str(body.model)) config.model = str(body.model);

  const textFields: (keyof Config)[] = [
    "apiKey", "mistralApiKey", "deepseekApiKey", "openrouterApiKey", "geminiOauthTokens", "githubToken", "cloudflareToken",
    "linearApiKey", "hfToken", "gmailAddress", "gmailAppPassword", "driveClientId", "driveClientSecret", "driveRefreshToken",
  ];
  for (const field of textFields) {
    const value = str(body[field]).trim();
    if (value) (config[field] as string) = value;
  }
  if (Array.isArray(body.geminiOauthTokens)) config.geminiOauthTokens = (body.geminiOauthTokens as string[]).join("\n");
  for (const [flag, field] of Object.entries(CLEAR_FLAGS)) {
    if (body[flag]) (config[field] as string) = "";
  }
  if (body.clearGmail) { config.gmailAddress = ""; config.gmailAppPassword = ""; }
  if (body.clearDrive) { config.driveClientId = ""; config.driveClientSecret = ""; config.driveRefreshToken = ""; }
  if (typeof body.passTokensToShell === "boolean") config.passTokensToShell = body.passTokensToShell;
  if (body.mcpServers && typeof body.mcpServers === "object") {
    config.mcpServers = body.mcpServers as Record<string, McpServer>;
  }
  saveConfig();
  res.json({ ok: true });
});

app.get("/api/models", (_req, res) => {
  const keyByProvider: Record<string, keyof Config> = {
    gemini: "apiKey",
    mistral: "mistralApiKey",
    deepseek: "deepseekApiKey",
    openrouter: "openrouterApiKey",
  };
  res.json({
    provider: config.provider,
    model: config.model,
    providers: PROVIDERS.map((p) => ({
      id: p.id,
      label: p.label,
      free: false,
      configured: Boolean(p.env.some((name) => process.env[name])) || Boolean(config[keyByProvider[p.id]]),
      models: p.models.map((id) => ({ id })),
    })),
  });
});

app.get("/api/system/session", (_req, res) => {
  res.json({
    platform: os.platform(),
    arch: os.arch(),
    nodeVersion: process.version,
    pid: process.pid,
    uptime: process.uptime(),
    memory: { rssMb: Math.round(process.memoryUsage().rss / 1048576), systemTotalMb: Math.round(os.totalmem() / 1048576) },
    workspace: WORKSPACE,
    activeModel: config.model,
    model: config.model,
  });
});

app.get("/api/files", (req, res) => {
  const target = workspacePath(str(req.query.path));
  if (!target) { res.status(400).json({ error: "مسیر خارج از فضای کاری است." }); return; }
  try {
    const entries = fs.readdirSync(target, { withFileTypes: true }).map((entry) => {
      const full = path.join(target, entry.name);
      let size = 0;
      try { size = entry.isDirectory() ? 0 : fs.statSync(full).size; } catch { size = 0; }
      return {
        name: entry.name,
        type: entry.isDirectory() ? "directory" : "file",
        path: path.relative(WORKSPACE, full).split(path.sep).join("/") || ".",
        size,
      };
    }).sort((a, b) => (a.type === b.type ? a.name.localeCompare(b.name) : a.type === "directory" ? -1 : 1));
    res.json({ path: path.relative(WORKSPACE, target).split(path.sep).join("/") || ".", entries });
  } catch (error) {
    res.status(404).json({ error: error instanceof Error ? error.message : "پوشه پیدا نشد." });
  }
});

const MIME: Record<string, string> = {
  ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8", ".md": "text/markdown; charset=utf-8", ".txt": "text/plain; charset=utf-8",
  ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".gif": "image/gif", ".svg": "image/svg+xml",
  ".pdf": "application/pdf", ".webp": "image/webp",
};

app.get("/api/file", (req, res) => {
  const target = workspacePath(str(req.query.path));
  if (!target) { res.status(400).send("مسیر خارج از فضای کاری است."); return; }
  if (!fs.existsSync(target) || !fs.statSync(target).isFile()) { res.status(404).send("فایل پیدا نشد."); return; }
  res.type(MIME[path.extname(target).toLowerCase()] || "application/octet-stream");
  if (req.query.download) res.attachment(path.basename(target));
  res.sendFile(target);
});

app.post("/api/upload", (req, res) => {
  const body = readJson(req);
  const name = path.basename(str(body.name) || "file");
  const data = str(body.data);
  if (!data) { res.status(400).json({ error: "محتوای فایل خالی است." }); return; }
  fs.mkdirSync(UPLOAD_DIR, { recursive: true, mode: 0o700 });
  const safe = `${createHash("sha1").update(name).digest("hex").slice(0, 8)}-${name}`;
  const target = path.join(UPLOAD_DIR, safe);
  fs.writeFileSync(target, Buffer.from(data, "base64"));
  res.json({ file: { name, path: target, mimeType: str(body.mimeType) || "application/octet-stream" } });
});

app.post("/api/speak", async (req, res) => {
  if (process.platform === "win32") { res.status(501).json({ error: "TTS فقط روی لینوکس/ترموکس پشتیبانی می‌شود." }); return; }
  if (readJson(req).stop) {
    try { (await import("node:child_process")).execFileSync("termux-tts-speak", ["-s"], { timeout: 3000 }); } catch { /* ignore */ }
    res.json({ ok: true });
    return;
  }
  const text = str(readJson(req).text);
  if (!text) { res.status(400).json({ error: "متن خالی است." }); return; }
  try {
    (await import("node:child_process")).execFile("termux-tts-speak", [text], () => undefined);
    res.json({ ok: true });
  } catch {
    res.status(501).json({ error: "termux-api نصب نیست (pkg install termux-api)." });
  }
});

app.get("/api/github/repos", async (req, res) => {
  try {
    const filter = str(req.query.filter) || "all";
    const user = await github("/user") as { login: string };
    const repos = await github(`/user/repos?per_page=100&sort=updated&visibility=${filter === "private" ? "private" : filter === "public" ? "public" : "all"}`) as { name: string; full_name: string; default_branch: string; private: boolean; description: string | null }[];
    res.json({ user: user.login, repos: repos.map((r) => ({ name: r.name, full_name: r.full_name, default_branch: r.default_branch, private: r.private, description: r.description })) });
  } catch (error) {
    res.status(400).json({ error: error instanceof Error ? error.message : "خطای GitHub" });
  }
});

app.get("/api/github/repo-tree", async (req, res) => {
  try {
    const repo = str(req.query.repo);
    const branch = str(req.query.branch) || "main";
    const dir = str(req.query.path);
    if (!/^[\w.-]+\/[\w.-]+$/.test(repo)) throw new Error("نام مخزن نامعتبر است.");
    const data = await github(`/repos/${repo}/contents/${encodeURIComponent(dir).replace(/%2F/g, "/")}?ref=${encodeURIComponent(branch)}`) as unknown;
    const list = Array.isArray(data) ? data : [];
    const entries = (list as { name: string; type: string; path: string; size: number }[]).map((item) => ({ name: item.name, type: item.type === "dir" ? "directory" : "file", path: item.path, size: item.size }));
    res.json({ repo, branch, path: dir, entries });
  } catch (error) {
    res.status(400).json({ error: error instanceof Error ? error.message : "خطای GitHub" });
  }
});

app.use((_req, res) => {
  res.status(404).json({ error: "not found" });
});

fs.mkdirSync(WORKSPACE, { recursive: true });

app.listen(PORT, HOST, () => {
  console.log(`Terminux on http://${HOST}:${PORT}  workspace=${WORKSPACE}`);
});
