export async function sendResendEmail({
  apiKey,
  from,
  replyTo,
  to,
  subject,
  html,
  text,
  idempotencyKey,
}) {
  const headers = {
    Authorization: `Bearer ${apiKey}`,
    "Content-Type": "application/json",
  };

  if (idempotencyKey) {
    headers["Idempotency-Key"] = idempotencyKey;
  }

  return fetch("https://api.resend.com/emails", {
    method: "POST",
    headers,
    body: JSON.stringify({
      from,
      reply_to: replyTo,
      to: Array.isArray(to) ? to : [to],
      subject,
      html,
      text,
    }),
  });
}
