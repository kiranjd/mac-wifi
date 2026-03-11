import { json, readRawBody } from "./_lib/http.js";
import { sendResendEmail } from "./_lib/resend.js";

function escapeText(input = "") {
  return String(input)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

export default async function handler(req, res) {
  if (req.method !== "POST") {
    res.setHeader("Allow", "POST");
    return json(res, 405, { error: "Method not allowed" });
  }

  const secret = process.env.RESEND_INBOUND_SECRET;
  const token = String(req.headers.authorization || "").replace(/^Bearer\s+/i, "");
  if (secret && token !== secret) {
    return json(res, 401, { error: "Unauthorized" });
  }

  let payload;
  try {
    const rawBody = await readRawBody(req);
    payload = JSON.parse(rawBody || "{}");
  } catch {
    return json(res, 400, { error: "Invalid JSON" });
  }

  const recipient = String(payload.to || "").trim();
  const originalFrom = String(payload.from || "").trim();
  const subject = String(payload.subject || "(no subject)").trim();
  const html = typeof payload.html === "string" ? payload.html : "";
  const text = typeof payload.text === "string" ? payload.text : "";
  const forwardTo = process.env.FORWARD_TO_EMAIL || "kiranjd8@gmail.com";

  const body = `<!doctype html>
<html lang="en">
  <body style="font-family:-apple-system,BlinkMacSystemFont,'SF Pro Text',sans-serif;color:#1d2731;">
    <p><strong>Forwarded from:</strong> ${escapeText(originalFrom || "unknown")}</p>
    <p><strong>Original recipient:</strong> ${escapeText(recipient || "unknown")}</p>
    <p><strong>Subject:</strong> ${escapeText(subject)}</p>
    <hr />
    ${html || `<pre style="white-space:pre-wrap;">${escapeText(text || "No plain text body was provided.")}</pre>`}
  </body>
</html>`;

  try {
    const response = await sendResendEmail({
      apiKey: process.env.RESEND_API_KEY,
      from: process.env.FROM_EMAIL || "MacWiFi <hi@macwifi.live>",
      replyTo: originalFrom || undefined,
      to: forwardTo,
      subject: `[MacWiFi Inbox] ${subject}`,
      html: body,
      text: `Forwarded from: ${originalFrom || "unknown"}\nOriginal recipient: ${recipient || "unknown"}\nSubject: ${subject}\n\n${text || "[HTML-only email]"}`,
      idempotencyKey: `macwifi-inbound-${payload.email_id || Date.now()}`,
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("MacWiFi inbound forward failed", errorText);
      return json(res, 502, { error: "Forward failed" });
    }

    return json(res, 200, { ok: true });
  } catch (error) {
    console.error("MacWiFi inbound handler failed", error);
    return json(res, 500, { error: "Forward failed" });
  }
}
