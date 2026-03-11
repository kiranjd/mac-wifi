export async function readRawBody(req) {
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(typeof chunk === "string" ? Buffer.from(chunk) : chunk);
  }
  return Buffer.concat(chunks).toString("utf8");
}

export function json(res, status, body) {
  res.status(status).setHeader("Content-Type", "application/json");
  res.setHeader("Cache-Control", "no-store");
  res.send(JSON.stringify(body));
}

export function html(res, status, body) {
  res.status(status).setHeader("Content-Type", "text/html; charset=utf-8");
  res.setHeader("Cache-Control", "no-store");
  res.send(body);
}

export function methodNotAllowed(res, allowed = "POST") {
  res.setHeader("Allow", allowed);
  json(res, 405, { error: "Method not allowed" });
}

export function parseFlatBody(raw, contentType = "") {
  const lower = contentType.toLowerCase();
  if (lower.includes("application/json")) {
    return JSON.parse(raw || "{}");
  }

  const params = new URLSearchParams(raw || "");
  return Object.fromEntries(params.entries());
}
