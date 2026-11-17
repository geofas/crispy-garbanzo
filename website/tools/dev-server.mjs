// Local stand-in for Cloudflare Pages: serves public/ and runs the waitlist
// function. Usage: node tools/dev-server.mjs [port]
// Set SUPABASE_URL and SUPABASE_KEY to exercise the real database call.
import http from "node:http";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { onRequestPost, onRequest } from "../functions/api/waitlist.js";

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "public");
const port = Number(process.argv[2] || 8788);
const types = { ".html": "text/html; charset=utf-8", ".css": "text/css", ".js": "text/javascript", ".svg": "image/svg+xml", ".png": "image/png", ".xml": "application/xml", ".txt": "text/plain" };

http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  if (url.pathname === "/api/waitlist") {
    const chunks = [];
    for await (const chunk of req) chunks.push(chunk);
    const request = new Request(url, { method: req.method, headers: req.headers, body: req.method === "POST" ? Buffer.concat(chunks) : undefined });
    const response = req.method === "POST" ? await onRequestPost({ request, env: process.env }) : onRequest();
    res.writeHead(response.status, Object.fromEntries(response.headers));
    res.end(await response.text());
    return;
  }
  let file = url.pathname === "/" ? "/index.html" : url.pathname;
  if (!path.extname(file)) file += ".html";
  try {
    const body = await readFile(path.join(root, path.normalize(file)));
    res.writeHead(200, { "content-type": types[path.extname(file)] || "application/octet-stream" });
    res.end(body);
  } catch {
    res.writeHead(404, { "content-type": types[".html"] });
    res.end(await readFile(path.join(root, "404.html")));
  }
}).listen(port, () => console.log(`http://localhost:${port}`));
