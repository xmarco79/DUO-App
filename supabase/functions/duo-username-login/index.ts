import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const { username, password } = await req.json();
    const normalized = typeof username === "string" ? username.trim().toLowerCase() : "";
    if (!/^[a-z0-9_]{3,20}$/.test(normalized) ||
        typeof password !== "string" || password.length < 1 || password.length > 128) {
      return json({ error: "اسم المستخدم أو كلمة المرور غير صحيحة" }, 400);
    }
    if (normalized !== "naif" && normalized !== "zoi") {
      return json({ error: "هذا التطبيق مخصص لحسابَي naif و zoi فقط." }, 403);
    }


    const url = Deno.env.get("SUPABASE_URL");
    const secretKeysRaw = Deno.env.get("SUPABASE_SECRET_KEYS");
    const legacySecret = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const publishableRaw = Deno.env.get("SUPABASE_PUBLISHABLE_KEYS");
    const legacyAnon = Deno.env.get("SUPABASE_ANON_KEY");
    const secretKey = secretKeysRaw ? JSON.parse(secretKeysRaw).default : legacySecret;
    const publicKey = publishableRaw ? JSON.parse(publishableRaw).default : legacyAnon;
    if (!url || !secretKey || !publicKey) {
      console.error("Required Supabase environment configuration is missing");
      return json({ error: "خدمة تسجيل الدخول غير مهيأة حاليًا" }, 503);
    }

    const admin = createClient(url, secretKey, {
      auth: { autoRefreshToken: false, persistSession: false, detectSessionInUrl: false },
    });
    const authClient = createClient(url, publicKey, {
      auth: { autoRefreshToken: false, persistSession: false, detectSessionInUrl: false },
    });

    const { data: profile, error: profileError } = await admin
      .from("duo_profiles")
      .select("user_id")
      .eq("username", normalized)
      .maybeSingle();

    if (profileError || !profile) {
      return json({ error: "اسم المستخدم أو كلمة المرور غير صحيحة" }, 401);
    }

    const { data: userData, error: userError } = await admin.auth.admin.getUserById(profile.user_id);
    const email = userData?.user?.email;
    if (userError || !email) {
      return json({ error: "اسم المستخدم أو كلمة المرور غير صحيحة" }, 401);
    }

    const { data, error } = await authClient.auth.signInWithPassword({ email, password });
    if (error || !data.session) {
      return json({ error: "اسم المستخدم أو كلمة المرور غير صحيحة، أو أن البريد لم يتم التحقق منه" }, 401);
    }

    return json({
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
      token_type: data.session.token_type,
      expires_in: data.session.expires_in,
      user: { id: data.user.id, email: data.user.email },
    });
  } catch (_error) {
    return json({ error: "تعذر إكمال تسجيل الدخول. تحقق من البيانات وحاول مجددًا." }, 400);
  }
});