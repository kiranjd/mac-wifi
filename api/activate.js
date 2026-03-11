import { html, json, methodNotAllowed } from "./_lib/http.js";

export default async function handler(req, res) {
  if (req.method !== "GET") {
    return methodNotAllowed(res, "GET");
  }

  const { key = "" } = req.query;
  if (!key) {
    return json(res, 400, { error: "Missing license key" });
  }

  const deepLink = `macwifi://activate?key=${encodeURIComponent(String(key))}&utm_source=email&utm_medium=lifecycle&utm_campaign=welcome`;
  return html(
    res,
    200,
    `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Activating MacWiFi…</title>
    <meta http-equiv="refresh" content="0;url=${deepLink}" />
    <style>
      body{margin:0;min-height:100vh;display:grid;place-items:center;background:#f5f1e8;color:#17202a;font:16px/1.6 -apple-system,BlinkMacSystemFont,'SF Pro Text',sans-serif}
      main{max-width:520px;padding:28px;text-align:center}
      a{color:#127c76}
    </style>
  </head>
  <body>
    <main>
      <h1 style="margin:0 0 12px;font-size:28px;line-height:1.1;">Opening MacWiFi…</h1>
      <p style="margin:0 0 16px;">If the app is already installed, this activation should hand the license key straight to MacWiFi.</p>
      <p style="margin:0;"><a href="${deepLink}">Open MacWiFi manually</a></p>
    </main>
  </body>
</html>`
  );
}
