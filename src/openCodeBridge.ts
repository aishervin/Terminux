export const GEMINI_TOKEN = process.env.GEMINI_TOKEN || "";
import fs from "node:fs";
import http from "node:http";

let opencodePort = 4096;
let opencodePassword = "";

function findPassword(): string {
  try {
    const logFile = "/data/data/com.termux/files/usr/tmp/opencode/serve.log";
    if (fs.existsSync(logFile)) {
      const content = fs.readFileSync(logFile, "utf8");
      const match = content.match(/server password ([^\s]+)/);
      if (match) return match[1];
    }
  } catch {}
  return process.env.OPENCODE_SERVER_PASSWORD || "";
}

export async function callOpenCodeApi(pathname: string, method = "GET", body?: unknown): Promise<any> {
  if (!opencodePassword) opencodePassword = findPassword();
  const auth = Buffer.from(`opencode:${opencodePassword}`).toString("base64");
  
  return new Promise((resolve, reject) => {
    const dataStr = body ? JSON.stringify(body) : "";
    const req = http.request({
      hostname: "127.0.0.1",
      port: opencodePort,
      path: pathname,
      method,
      headers: {
        "Authorization": `Basic ${auth}`,
        "X-Gemini-Token": GEMINI_TOKEN,
        "Accept": "application/json",
        "Content-Type": "application/json",
        ...(body ? { "Content-Length": Buffer.byteLength(dataStr) } : {})
      }
    }, (res) => {
      let data = "";
      res.on("data", chunk => data += chunk);
      res.on("end", () => {
        try { resolve(JSON.parse(data)); } catch { resolve(data); }
      });
    });
    req.on("error", err => reject(err));
    if (dataStr) req.write(dataStr);
    req.end();
  });
}
