const origin = "https://thai-for-myanmar-web-preview.onrender.com";
const headers = {
  "Access-Control-Allow-Origin": origin,
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Cache-Control": "no-store",
  Vary: "Origin",
};
const json = (status: number, data: unknown) => Response.json(data, { status, headers });
const encoder = new TextEncoder();
function base64url(bytes: Uint8Array) {
  return btoa(String.fromCharCode(...bytes)).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "");
}

async function googleToken(account: { client_email: string; private_key: string }) {
  const now = Math.floor(Date.now() / 1000);
  const encode = (data: unknown) => base64url(encoder.encode(JSON.stringify(data)));
  const assertion = [
    encode({ alg: "RS256", typ: "JWT" }),
    encode({
      iss: account.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 300,
    }),
  ].join(".");
  const pkcs8 = Uint8Array.from(atob(account.private_key.replace(/-----[^-]+-----|\s/g, "")), c => c.charCodeAt(0));
  const key = await crypto.subtle.importKey("pkcs8", pkcs8, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]);
  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, encoder.encode(assertion));
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: assertion + "." + base64url(new Uint8Array(signature)),
    }),
  });
  if (!response.ok) throw new Error("Firebase credentials rejected");
  const { access_token } = await response.json();
  if (typeof access_token !== "string") throw new Error("Firebase token missing");
  return access_token;
}

Deno.serve(async request => {
  if (request.headers.get("origin") !== origin) return json(403, { error: "origin" });
  if (request.method === "OPTIONS") return new Response(null, { status: 204, headers });
  if (request.method !== "POST") return json(405, { error: "method" });
  const authorization = request.headers.get("authorization") ?? "";
  if (!/^Bearer [^\s]+$/i.test(authorization)) return json(401, { error: "auth" });
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) return json(503, { error: "unavailable" });
  try {
    const userResponse = await fetch(url + "/auth/v1/user", { headers: { apikey: key, authorization } });
    if (!userResponse.ok) return json(401, { error: "auth" });
    const user = await userResponse.json();
    const encodedClaims = authorization.split(".")[1] ?? "";
    const payload = encodedClaims.replaceAll("-", "+").replaceAll("_", "/");
    const claims = JSON.parse(atob(payload.padEnd(Math.ceil(payload.length / 4) * 4, "=")));
    if (claims.sub !== user.id ||
        user.app_metadata?.chang_thai_admin !== true ||
        !Array.isArray(claims.amr) ||
        !claims.amr.some((item: { method?: string }) => item.method === "password")) {
      return json(403, { error: "admin" });
    }

    const rawAccount = Deno.env.get("CHANG_THAI_FCM_SERVICE_ACCOUNT");
    if (!rawAccount) return json(503, { error: "firebase_not_configured" });
    const account = JSON.parse(rawAccount);
    if (!/^[a-z0-9-]+$/.test(account.project_id ?? "")) return json(503, { error: "firebase_not_configured" });
    const adminHeaders = { apikey: key, Authorization: "Bearer " + key, "Content-Type": "application/json" };
    const published = await fetch(url + "/rest/v1/chang_thai_controls?id=eq.1&select=revision,settings", { headers: adminHeaders });
    if (!published.ok) return json(502, { error: "controls" });
    const [row] = await published.json();
    const a = row?.settings?.announcement;
    const requested = await request.json();
    if (!Number.isSafeInteger(row?.revision) || requested.revision !== row.revision) return json(409, { error: "publish_changed" });
    const ttl = Math.min(2419200, Math.floor((Date.parse(a?.expiresAt) - Date.now()) / 1000));
    if (a?.enabled !== true || !Number.isFinite(ttl) || ttl <= 0 ||
        typeof a.title !== "string" || !a.title.trim() || a.title.length > 100 ||
        typeof a.body !== "string" || !a.body.trim() || a.body.length > 500) {
      return json(400, { error: "no_active_announcement" });
    }
    const accessToken = await googleToken(account);
    const queue = url + "/rest/v1/chang_thai_push_sends";
    const claim = await fetch(queue, {
      method: "POST", headers: adminHeaders, body: JSON.stringify({ revision: row.revision }),
    });
    if (claim.status === 409) return json(409, { error: "already_requested" });
    if (!claim.ok) return json(502, { error: "queue" });

    const sent = await fetch(`https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`, {
      method: "POST",
      headers: { Authorization: "Bearer " + accessToken, "Content-Type": "application/json" },
      body: JSON.stringify({
        message: {
          topic: "chang_thai_announcements_v1",
          notification: { title: a.title, body: a.body },
          android: { ttl: ttl + "s", notification: { channel_id: "chang_thai_announcements" } },
        },
      }),
    });
    const result = await sent.json();
    await fetch(queue + "?revision=eq." + row.revision, {
      method: "PATCH", headers: adminHeaders,
      body: JSON.stringify({ status: sent.ok ? "sent" : "failed", firebase_message: sent.ok ? result.name : null }),
    });
    return sent.ok ? json(200, { accepted: true }) : json(502, { error: "firebase_rejected" });
  } catch {
    return json(502, { error: "unavailable" });
  }
});
