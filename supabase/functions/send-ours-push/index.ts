import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { importPKCS8, SignJWT } from "npm:jose@5";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-ours-webhook-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return new Response("Method not allowed", { status: 405, headers: cors });

  const expected = Deno.env.get("OURS_PUSH_WEBHOOK_SECRET");
  if (!expected || req.headers.get("x-ours-webhook-secret") !== expected) {
    return new Response("Unauthorized", { status: 401, headers: cors });
  }

  try {
    const payload = await req.json();
    const row = payload?.record ?? payload;
    const userId = row?.user_id;
    const actorId = row?.actor_id;
    if (!userId || (actorId && actorId === userId)) {
      return new Response(JSON.stringify({ skipped: true }), {
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const serviceUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const accountRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
    if (!serviceUrl || !serviceKey || !accountRaw) throw new Error("Push secrets missing");

    const account = JSON.parse(accountRaw);
    const supabase = createClient(serviceUrl, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: rows, error } = await supabase
      .from("duo_push_tokens").select("token").eq("user_id", userId);
    if (error) throw error;
    if (!rows?.length) {
      return new Response(JSON.stringify({ sent: 0, reason: "no_registered_devices" }), {
        headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const key = await importPKCS8(account.private_key, "RS256");
    const assertion = await new SignJWT({
      scope: "https://www.googleapis.com/auth/firebase.messaging",
    })
      .setProtectedHeader({ alg: "RS256", typ: "JWT" })
      .setIssuer(account.client_email)
      .setSubject(account.client_email)
      .setAudience("https://oauth2.googleapis.com/token")
      .setIssuedAt().setExpirationTime("1h").sign(key);

    const oauth = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion,
      }),
    });
    const oauthData = await oauth.json();
    if (!oauth.ok) throw new Error("Firebase OAuth failed");

    const data = Object.fromEntries(
      Object.entries(row.data ?? {}).map(([k, v]) => [k, String(v)]),
    );
    let sent = 0;
    let failed = 0;
    for (const item of rows) {
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${oauthData.access_token}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: item.token,
              notification: {
                title: String(row.title ?? "OURS").slice(0, 120),
                body: String(row.body ?? "لديك إشعار جديد").slice(0, 240),
              },
              data,
              android: {
                priority: "high",
                notification: { channel_id: "ours_messages", sound: "default" },
              },
            },
          }),
        },
      );
      if (response.ok) sent++; else failed++;
    }
    return new Response(JSON.stringify({ sent, failed }), {
      headers: { ...cors, "Content-Type": "application/json" },
    });
  } catch (_error) {
    return new Response(JSON.stringify({ error: "Push delivery failed" }), {
      status: 500,
      headers: { ...cors, "Content-Type": "application/json" },
    });
  }
});
