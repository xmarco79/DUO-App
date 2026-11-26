import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status, headers: { ...corsHeaders, "Content-Type": "application/json" },
});

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  try {
    const body = await req.json();
    const username = typeof body?.username === "string" ? body.username.trim().toLowerCase() : "";
    if (!/^[a-z0-9_]{3,20}$/.test(username)) {
      return json({ error: "اسم المستخدم من 3 إلى 20 حرفًا إنجليزيًا صغيرًا أو رقمًا أو _" }, 400);
    }
    const url = Deno.env.get("SUPABASE_URL");
    const secretKeysRaw = Deno.env.get("SUPABASE_SECRET_KEYS");
    const legacySecret = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const publishableRaw = Deno.env.get("SUPABASE_PUBLISHABLE_KEYS");
    const legacyAnon = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceKey = secretKeysRaw ? JSON.parse(secretKeysRaw).default : legacySecret;
    const publicKey = publishableRaw ? JSON.parse(publishableRaw).default : legacyAnon;
    if (!url || !serviceKey || !publicKey) return json({ error: "Service configuration unavailable" }, 503);

    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : "";
    if (!token) return json({ error: "Authentication required" }, 401);
    const authClient = createClient(url, publicKey, { auth: { autoRefreshToken: false, persistSession: false } });
    const { data: authData, error: authError } = await authClient.auth.getUser(token);
    if (authError || !authData.user) return json({ error: "Invalid session" }, 401);
    const userId = authData.user.id;

    const admin = createClient(url, serviceKey, { auth: { autoRefreshToken: false, persistSession: false } });
    const { data: current, error: currentError } = await admin.from("duo_profiles")
      .select("username").eq("user_id", userId).maybeSingle();
    if (currentError || !current) return json({ error: "Profile not found" }, 404);
    if (current.username === username) return json({ success: true, username });
    const { error: updateError } = await admin.from("duo_profiles")
      .update({ username }).eq("user_id", userId);
    if (updateError) {
      if (updateError.code === "23505") return json({ error: "اسم المستخدم مستخدم بالفعل" }, 409);
      console.error("username update failed", updateError.code, updateError.message);
      return json({ error: "تعذر تحديث اسم المستخدم" }, 500);
    }
    const metadata = { ...(authData.user.user_metadata ?? {}), username };
    const { error: metadataError } = await admin.auth.admin.updateUserById(userId, { user_metadata: metadata });
    if (metadataError) console.error("username metadata sync failed", metadataError.message);
    return json({ success: true, username });
  } catch (error) {
    console.error("username update unexpected error", error);
    return json({ error: "تعذر إكمال تغيير اسم المستخدم" }, 500);
  }
});
