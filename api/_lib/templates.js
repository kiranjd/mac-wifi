function frame({ preheader, title, intro, body, footer }) {
  return `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${title}</title>
  </head>
  <body style="margin:0;padding:0;background:#f5f1e8;color:#17202a;font-family:-apple-system,BlinkMacSystemFont,'SF Pro Text','Helvetica Neue',sans-serif;">
    <div style="display:none!important;visibility:hidden;opacity:0;max-height:0;max-width:0;overflow:hidden;">${preheader}</div>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#f5f1e8;">
      <tr>
        <td align="center" style="padding:36px 20px;">
          <table role="presentation" width="560" cellpadding="0" cellspacing="0" style="max-width:560px;background:#fffdf9;border:1px solid #e6dfd1;border-radius:14px;">
            <tr>
              <td style="padding:28px 28px 18px;">
                <p style="margin:0 0 10px;font-size:13px;letter-spacing:.06em;text-transform:uppercase;color:#6c7681;">MacWiFi</p>
                <h1 style="margin:0 0 14px;font-size:26px;line-height:1.1;letter-spacing:-0.03em;">${title}</h1>
                <p style="margin:0 0 18px;font-size:16px;line-height:1.65;color:#4d5863;">${intro}</p>
                ${body}
              </td>
            </tr>
            <tr>
              <td style="padding:18px 28px 28px;border-top:1px solid #eee5d7;">
                <p style="margin:0;font-size:13px;line-height:1.7;color:#6c7681;">${footer}</p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>`;
}

export function purchaseEmail({ licenseKey }) {
  const activationUrl = `https://macwifi.live/api/activate?key=${encodeURIComponent(licenseKey)}`;
  const downloadUrl = "https://github.com/kiranjd/mac-wifi/releases/latest";

  return frame({
    preheader: "Your MacWiFi purchase is ready.",
    title: "Thanks for buying MacWiFi",
    intro:
      "Here’s the fastest way to get going. Install the app, activate the key on this Mac, and use the menu bar whenever your connection gets weird.",
    body: `
      <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="margin:20px 0 18px;">
        <tr>
          <td>
            <a href="${downloadUrl}" style="display:inline-block;padding:12px 18px;border-radius:10px;background:#127c76;color:#ffffff;text-decoration:none;font-size:14px;font-weight:700;">Download MacWiFi</a>
            <a href="${activationUrl}" style="display:inline-block;margin-left:10px;padding:12px 18px;border-radius:10px;border:1px solid #d9d0c2;background:#fffaf0;color:#17202a;text-decoration:none;font-size:14px;font-weight:700;">Activate License</a>
          </td>
        </tr>
      </table>
      <p style="margin:0 0 12px;font-size:15px;line-height:1.7;color:#4d5863;">If the activate button doesn’t open the app, paste this key into MacWiFi settings:</p>
      <p style="margin:0 0 18px;padding:12px 14px;border-radius:10px;background:#f5f1e8;font:600 14px/1.6 ui-monospace,SFMono-Regular,Menlo,monospace;color:#17202a;">${licenseKey}</p>
      <ul style="margin:0;padding-left:18px;color:#4d5863;font-size:15px;line-height:1.7;">
        <li>Start with the menu bar popover.</li>
        <li>Use the result to see if the issue is local Wi-Fi or the upstream internet path.</li>
        <li>If you get stuck, reply directly to this email.</li>
      </ul>
    `,
    footer:
      'Questions? Reply to this email or reach us at support@macwifi.live. MacWiFi is a one-time purchase and the current license is tied to this Mac.',
  });
}

export function inboxForwardEmail({ originalFrom, originalTo, subject, text, html }) {
  const safeText = text || "No plain text body was provided.";
  const renderedHtml = html
    ? `<div style="margin:18px 0;padding:16px;border:1px solid #e6dfd1;border-radius:10px;">${html}</div>`
    : `<pre style="margin:18px 0;padding:16px;border:1px solid #e6dfd1;border-radius:10px;white-space:pre-wrap;font:14px/1.6 ui-monospace,SFMono-Regular,Menlo,monospace;">${escapeHtml(safeText)}</pre>`;

  return frame({
    preheader: `Forwarded message from ${originalFrom}`,
    title: `Forwarded email for ${originalTo}`,
    intro: `Incoming message from ${originalFrom}`,
    body: `
      <p style="margin:0 0 8px;font-size:14px;color:#4d5863;"><strong>Subject:</strong> ${escapeHtml(subject || "(no subject)")}</p>
      ${renderedHtml}
    `,
    footer: "This message was forwarded by the MacWiFi Resend inbound route.",
  });
}

function escapeHtml(input = "") {
  return input
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}
