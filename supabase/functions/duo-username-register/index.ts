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
      user_metadata: { username },
    });

    if (createError || !created.user) {
      console.error("registration: auth user creation failed", createError?.code, createError?.message);
      if (createError?.code === "email_exists" || createError?.code === "user_already_exists") {
        return json({ error: "تعذر إنشاء الحساب بهذا الاسم بسبب تعارض في سجل الدخول. تواصل مع الدعم." }, 409);
      }
      return json({ error: "تعذر إنشاء الحساب حاليًا. حاول مرة أخرى." }, 400);
    }

    const { error: profileError } = await admin.from("duo_profiles").insert({
      user_id: created.user.id,
      username,
      display_name: username,
    });

    if (profileError) {
      await admin.auth.admin.deleteUser(created.user.id);
      if (profileError.code === "23505") {
        const { data: conflict, error: conflictLookupError } = await admin
          .from("duo_profiles")
          .select("user_id")
          .eq("username", username)
          .maybeSingle();

        if (!conflictLookupError && conflict) {
          return json({ error: "اسم المستخدم مستخدم بالفعل" }, 409);
        }
        console.error("registration: unique conflict without matching username row", profileError.code, profileError.message, conflictLookupError?.message);
        return json({ error: "حدث تعارض في إنشاء الحساب، لكن الاسم لا يظهر كمستخدم. أعد المحاولة أو تواصل مع الدعم." }, 500);
      }
      console.error("registration: profile insert failed", profileError.code, profileError.message);
      return json({ error: "تعذر حفظ بيانات الحساب حاليًا" }, 500);
    }

    return json({ success: true, message: "تم إنشاء الحساب. يمكنك تسجيل الدخول الآن." }, 201);
  } catch (error) {
    console.error("registration: unexpected failure", error);
    return json({ error: "تعذر إكمال إنشاء الحساب. حاول مرة أخرى." }, 500);
  }
});