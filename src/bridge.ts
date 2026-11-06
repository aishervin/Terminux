import http from "http";

const OPENCODE_PORT = 4096;
const TERMINUX_PORT = 3000;

export function startBridge(password: string) {
  const auth = Buffer.from(`opencode:${password}`).toString("base64");

  const server = http.createServer((req, res) => {
    // Proxy API requests to OpenCode
    if (req.url?.startsWith("/api/")) {
      const proxyReq = http.request({
        hostname: "127.0.0.1",
        port: OPENCODE_PORT,
        path: req.url,
        method: req.method,
        headers: {
          ...req.headers,
          "Authorization": `Basic ${auth}`,
          "Host": "127.0.0.1:4096"
        }
      }, (proxyRes) => {
        res.writeHead(proxyRes.statusCode!, proxyRes.headers);
        proxyRes.pipe(res);
      });
      req.pipe(proxyReq);
    } else {
      // Serve Farsi UI (Terminux)
      // This is handled by express static in server.ts, so we just pass through
    }
  });

  server.listen(TERMINUX_PORT, "127.0.0.1", () => {
    console.log("Terminux UI Bridge active on port " + TERMINUX_PORT);
  });
}
