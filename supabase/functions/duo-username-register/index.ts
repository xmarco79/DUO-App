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
    const body = await req.json();
    const username = typeof body?.username === "string" ? body.username.trim().toLowerCase() : "";
    const password = typeof body?.password === "string" ? body.password : "";

    if (!/^[a-z0-9_]{3,20}$/.test(username)) {
      return json({ error: "اسم المستخدم يجب أن يكون من 3 إلى 20 حرفًا إنجليزيًا أو رقمًا أو _" }, 400);
    }
    if (password.length < 8 || password.length > 72) {
      return json({ error: "كلمة المرور يجب أن تكون من 8 إلى 72 حرفًا" }, 400);
    }

    const url = Deno.env.get("SUPABASE_URL");
    const secretKeysRaw = Deno.env.get("SUPABASE_SECRET_KEYS");
    const legacySecret = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const secretKey = secretKeysRaw ? JSON.parse(secretKeysRaw).default : legacySecret;

    if (!url || !secretKey) {
      console.error("registration: server configuration missing");
      return json({ error: "خدمة إنشاء الحساب غير مهيأة حاليًا" }, 503);
    }

    const admin = createClient(url, secretKey, {
      auth: { autoRefreshToken: false, persistSession: false, detectSessionInUrl: false },
    });

    const { data: existing, error: lookupError } = await admin
      .from("duo_profiles")
      .select("user_id")
      .eq("username", username)
      .maybeSingle();

    if (lookupError) {
      console.error("registration: username lookup failed", lookupError.code, lookupError.message);
      return json({ error: "تعذر التحقق من اسم المستخدم حاليًا. حاول مرة أخرى." }, 503);
    }
    if (existing) return json({ error: "اسم المستخدم مستخدم بالفعل" }, 409);

    const syntheticEmail = username + "@ours.invalid";
    const { data: created, error: createError } = await admin.auth.admin.createUser({
      email: syntheticEmail,
      password,
      email_confirm: true,
      user_metadata: { username, display_name: username },
    });

    if (createError || !created.user) {
      const errorCode = createError?.code ?? "";
      const errorMessage = createError?.message ?? "";
      console.error("registration: auth user creation failed", errorCode, errorMessage);

      if (
        errorCode === "email_exists" ||
        errorCode === "user_already_exists" ||
        errorMessage.includes("duo_profiles_username_lower_idx")
      ) {
        return json({ error: "اسم المستخدم مستخدم بالفعل" }, 409);
      }

      if (errorMessage.includes("duo_profiles_pkey")) {
        return json({ error: "تعذر ربط الحساب بملفه الشخصي بسبب تعارض داخلي. حاول مرة أخرى لاحقًا." }, 500);
      }

      return json({ error: "تعذر إنشاء الحساب حاليًا. حاول مرة أخرى." }, 400);
    }

    // The on_auth_user_created_duo_profile database trigger creates duo_profiles.
    // Do not insert a second profile here: that would collide with duo_profiles_pkey.
    const { data: profile, error: profileLookupError } = await admin
      .from("duo_profiles")
      .select("user_id, username")
      .eq("user_id", created.user.id)
      .maybeSingle();

    if (profileLookupError || !profile || profile.username !== username) {
      console.error(
        "registration: auth trigger did not create the expected profile",
        profileLookupError?.code,
        profileLookupError?.message,
      );
      await admin.auth.admin.deleteUser(created.user.id);
      return json({ error: "تعذر إكمال إعداد الملف الشخصي للحساب. حاول مرة أخرى." }, 500);
    }

    return json({ success: true, message: "تم إنشاء الحساب. يمكنك تسجيل الدخول الآن." }, 201);
  } catch (error) {
    console.error("registration: unexpected failure", error);
    return json({ error: "تعذر إكمال إنشاء الحساب. حاول مرة أخرى." }, 500);
  }
});