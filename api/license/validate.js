import { json, methodNotAllowed, parseFlatBody, readRawBody } from "../_lib/http.js";
import { proxyLicenseRequest } from "../_lib/lemonsqueezy.js";

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return methodNotAllowed(res, "POST");
  }

  const raw = await readRawBody(req);
  let values;
  try {
    values = parseFlatBody(raw, req.headers["content-type"]);
  } catch {
    return json(res, 400, { error: "Invalid request body" });
  }

  if (!values.license_key || !values.instance_id) {
    return json(res, 400, { error: "Missing or invalid license fields" });
  }

  try {
    const upstream = await proxyLicenseRequest({
      action: "validate",
      values: {
        license_key: String(values.license_key),
        instance_id: String(values.instance_id),
      },
      headers: {
        "x-macwifi-license-proxy": "1",
      },
    });

    const body = await upstream.text();
    res.status(upstream.status);
    res.setHeader("Content-Type", upstream.headers.get("content-type") || "application/json");
    res.setHeader("Cache-Control", "no-store");
    res.setHeader("x-macwifi-license-proxy", "1");
    res.send(body);
  } catch {
    json(res, 503, { error: "License upstream unreachable" });
  }
}
