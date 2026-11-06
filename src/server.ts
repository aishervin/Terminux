import express from "express";
import { startBridge } from "./bridge.ts";
import fs from "fs";

const app = express();
const PORT = 3000;

// Simple UI server
app.use(express.static("./web"));

// Start bridge
const password = fs.readFileSync("/data/data/com.termux/files/usr/tmp/opencode/serve.log", "utf8").match(/server password ([^\s]+)/)?.[1] || "";
startBridge(password);

app.listen(PORT, "127.0.0.1", () => {
  console.log("Terminux UI running on http://127.0.0.1:3000");
});
