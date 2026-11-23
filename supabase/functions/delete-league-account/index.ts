const webOrigin = "https://thai-for-myanmar-web-preview.onrender.com";

Deno.serve(async (request) => {
  const origin = request.headers.get("origin");
  const headers = {
    "Access-Control-Allow-Origin": webOrigin,
    "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Cache-Control": "no-store",
    Vary: "Origin",
  };
  const reply = (status: number, body: Record<string, boolean | string>) =>
    Response.json(body, { status, headers });

  if (origin && origin !== webOrigin) return reply(403, { error: "origin" });
  if (request.method === "OPTIONS") return new Response(null, { status: 204, headers });
  if (request.method !== "POST") return reply(405, { error: "method" });
  const authorization = request.headers.get("authorization") ?? "";
  if (!/^Bearer [^\s]+$/i.test(authorization)) return reply(401, { error: "auth" });

  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) return reply(503, { error: "unavailable" });

  try {
    // Resolve the account from a token verified by Auth. The body cannot select an account.
    const userResponse = await fetch(`${url}/auth/v1/user`, {
      headers: { apikey: key, authorization },
    });
    if (!userResponse.ok) {
      return reply(userResponse.status < 500 ? 401 : 502, { error: "auth" });
    }
    const user = await userResponse.json();
    if (typeof user.id !== "string" ||
        !/^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$/i.test(user.id)) {
      return reply(401, { error: "auth" });
    }
    // Hard-delete Auth. Existing cascading foreign keys remove the League rows.
    const deleted = await fetch(`${url}/auth/v1/admin/users/${user.id}`, {
      method: "DELETE",
      headers: {
        apikey: key,
        authorization: `Bearer ${key}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ should_soft_delete: false }),
    });
    return deleted.ok
      ? reply(200, { deleted: true })
      : reply(502, { error: "delete_failed" });
  } catch {
    return reply(502, { error: "unavailable" });
  }
});
