export function safeRedirect(path: string, fallback = "/app") {
  if (!path.startsWith("/") || path.startsWith("//") || /[\\\u0000-\u001f\u007f]/.test(path)) {
    return fallback;
  }
  return path;
}
