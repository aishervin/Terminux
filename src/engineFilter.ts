// Text sanitizer to ensure no reference to 'opencode' appears in logs or UI
export function sanitizeText(text: unknown): string {
  if (typeof text !== "string") {
    if (text && typeof text === "object") {
      try {
        return JSON.parse(JSON.stringify(text, (key, val) => {
          if (typeof val === "string") {
            return val.replace(/opencode/gi, "Terminux").replace(/OpenCode/gi, "Terminux");
          }
          return val;
        }));
      } catch {
        return String(text);
      }
    }
    return String(text || "");
  }
  return text
    .replace(/opencode/gi, "Terminux")
    .replace(/OpenCode/gi, "Terminux")
    .replace(/OPENCODE/gi, "TERMINUX");
}
