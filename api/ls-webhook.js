import { readRawBody, json, methodNotAllowed } from "./_lib/http.js";
import { verifyWebhookSignature } from "./_lib/lemonsqueezy.js";
import { sendResendEmail } from "./_lib/resend.js";
import { purchaseEmail } from "./_lib/templates.js";

const MACWIFI_PRODUCT_ID = 883028;
const MACWIFI_PRODUCT_NAME = "MacWiFi";

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return methodNotAllowed(res, "POST");
  }

  const raw = await readRawBody(req);
  const signature = req.headers["x-signature"];
  const secret = process.env.LS_WEBHOOK_SECRET;

  if (!verifyWebhookSignature(raw, signature, secret)) {
    return json(res, 401, { error: "Invalid signature" });
  }

  const payload = JSON.parse(raw || "{}");
  const eventName = payload?.meta?.event_name;

  if (eventName !== "license_key_created") {
    return json(res, 200, { ok: true, ignored: eventName || "unknown" });
  }

  const attrs = payload?.data?.attributes || {};
  if (!isMacWiFiEvent(attrs)) {
    return json(res, 200, { ok: true, ignored: "non-macwifi-product" });
  }

  const customerEmail = attrs.user_email;
  const licenseKey = attrs.key;
  const orderId = attrs.order_id || attrs.order_number || payload?.data?.id || customerEmail;

  if (!customerEmail || !licenseKey) {
    return json(res, 400, { error: "Webhook missing customer email or license key" });
  }

  const emailResponse = await sendResendEmail({
    apiKey: process.env.RESEND_API_KEY,
    from: process.env.FROM_EMAIL || "MacWiFi <hi@macwifi.live>",
    replyTo: process.env.REPLY_TO || "support@macwifi.live",
    to: customerEmail,
    subject: "Your MacWiFi license and download link",
    html: purchaseEmail({ licenseKey }),
    text: `Thanks for buying MacWiFi.\n\nDownload: https://github.com/kiranjd/mac-wifi/releases/latest\nActivate: https://macwifi.live/api/activate?key=${encodeURIComponent(licenseKey)}\n\nIf the button flow fails, paste this key into MacWiFi settings:\n${licenseKey}`,
    idempotencyKey: `macwifi-order-${orderId}`,
  });

  if (!emailResponse.ok) {
    return json(res, 502, {
      error: "Failed to send email",
      details: await emailResponse.text(),
    });
  }

  return json(res, 200, { ok: true });
}

function isMacWiFiEvent(attrs) {
  const rawProductId = attrs.product_id ?? attrs?.first_order_item?.product_id;
  const numericProductId = Number(rawProductId);
  if (Number.isFinite(numericProductId) && numericProductId > 0) {
    return numericProductId == MACWIFI_PRODUCT_ID;
  }

  const candidateNames = [
    attrs.product_name,
    attrs?.first_order_item?.product_name,
  ]
    .filter(Boolean)
    .map((value) => String(value).trim().toLowerCase());

  if (candidateNames.length > 0) {
    return candidateNames.some((value) => value === MACWIFI_PRODUCT_NAME.toLowerCase());
  }

  return false;
}
