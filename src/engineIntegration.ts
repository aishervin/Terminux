import { callOpenCodeApi } from "./openCodeBridge.ts";
import { sanitizeText } from "./engineFilter.ts";

export async function sendEnginePrompt(workspaceDir: string, promptText: string): Promise<string> {
  try {
    // Model from our list: providerID: 'google', id: 'gemini-3.5-flash'
    const res = await callOpenCodeApi("/api/experimental/generate", "POST", {
      prompt: promptText,
      model: { id: "gemini-3.5-flash", providerID: "google" }
    });
    
    if (res?.data?.text) return sanitizeText(res.data.text);
    return sanitizeText("Pasooh daryaft shod ama matn khali-e: " + JSON.stringify(res));
  } catch (err) {
    return sanitizeText(`Khata dar ertebat ba motor: ${String(err)}`);
  }
}
