
import 'dart:io';
import 'dart:ui' as ui;
import 'notifications/ours_push_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'worlds/world_hub_page.dart';
import 'social/ours_social_pages.dart';
import 'notifications/ours_notifications.dart';
import 'memories/ours_albums_page.dart';
import 'chat/ours_message_reactions.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// ==================== COLORS ====================

const navy = Color(0xFF10101C);
const purple = Color(0xFF29213D);
const lavender = Color(0xFFB9A2D5);
const gold = Color(0xFFD9BC86);

String oursText(BuildContext context, String ar, String en) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

// Preview builds open the home screen without requiring an account.
const bool previewMode = bool.fromEnvironment('OURS_PREVIEW_MODE', defaultValue: false);

// ==================== APP PREFERENCES ====================

class OursAppSettings {
  static final ValueNotifier<Locale> locale = ValueNotifier(const Locale('ar'));

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    locale.value = Locale(prefs.getString('ours_language') ?? 'ar');
  }

  static Future<void> setLanguage(String languageCode) async {
    final normalized = languageCode == 'en' ? 'en' : 'ar';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ours_language', normalized);
    locale.value = Locale(normalized);
  }
}

// ==================== MAIN ====================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await OursAppSettings.load();

  await Supabase.initialize(
    url: 'https://sthlcrgwpzqhxtpevqwg.supabase.co',
    publishableKey: 'sb_publishable_xUgF7Wh8fE4wMpuZSrROwA_DNdPJKGM',
  );

  await OursPushService.initialize();

  runApp(const OursApp());
}

// ==================== APP ====================

class OursApp extends StatelessWidget {
  const OursApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: OursAppSettings.locale,
      builder: (context, locale, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'OURS',
        locale: locale,
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => Directionality(
          textDirection: locale.languageCode == 'ar' ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: child ?? const SizedBox.shrink(),
        ),
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: navy,
          colorScheme: const ColorScheme.dark(
            primary: gold,
            secondary: lavender,
            surface: purple,
          ),
          useMaterial3: true,
        ),
        home: previewMode ? const HomePage() : const OursEntryGate(),
      ),
    );
  }
}

// First-launch welcome screen. It is shown once before authentication.
class OursEntryGate extends StatefulWidget {
  const OursEntryGate({super.key});
  @override
  State<OursEntryGate> createState() => _OursEntryGateState();
}

class _OursEntryGateState extends State<OursEntryGate> {
  bool? _hasSeenWelcome;
  @override
  void initState() { super.initState(); _loadWelcomeState(); }

  Future<void> _loadWelcomeState() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _hasSeenWelcome = prefs.getBool('ours_welcome_seen') ?? false);
  }

  Future<void> _finishWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ours_welcome_seen', true);
    if (mounted) setState(() => _hasSeenWelcome = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSeenWelcome == null) {
      return const Scaffold(backgroundColor: navy, body: Center(child: CircularProgressIndicator(color: gold)));
    }
    if (_hasSeenWelcome!) return const OursAuthGate();
    return WelcomePage(onLogin: _finishWelcome, onRegister: _finishWelcome);
  }
}

class WelcomePage extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  const WelcomePage({super.key, required this.onLogin, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 184, height: 184,
                  decoration: BoxDecoration(color: purple.withValues(alpha: .55), shape: BoxShape.circle,
                    border: Border.all(color: lavender.withValues(alpha: .25))),
                  child: const Icon(Icons.all_inclusive_rounded, color: gold, size: 112),
                ),
                const SizedBox(height: 30),
                const Text('OURS', style: TextStyle(color: gold, fontSize: 44, letterSpacing: 12, fontWeight: FontWeight.w300)),
                const SizedBox(height: 8),
                const Text('YOUR PRIVATE UNIVERSE', style: TextStyle(color: lavender, letterSpacing: 3, fontSize: 11)),
                const SizedBox(height: 30),
                Text(oursText(context, 'عالمك الخاص، بطريقتكما', 'A private universe for two'), textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Text(oursText(context, 'مساحة رقمية خاصة تجمعك أنت وشريكك فقط؛ للمحادثات والذكريات والعوالم التي تصنعانها معًا.', 'A private space for you and your partner to chat, share memories, and build your own worlds together.'),
                  textAlign: TextAlign.center, style: const TextStyle(color: lavender, height: 1.8, fontSize: 15)),
                const SizedBox(height: 38),
                SizedBox(width: double.infinity, height: 54,
                  child: FilledButton(onPressed: () {
                    onRegister();
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage(initialCreatingAccount: true)));
                  }, child: Text(oursText(context, 'إنشاء حساب', 'Create account')))),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, height: 54,
                  child: OutlinedButton(onPressed: () {
                    onLogin();
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
                  }, style: OutlinedButton.styleFrom(foregroundColor: lavender, side: const BorderSide(color: lavender)),
                    child: Text(oursText(context, 'تسجيل الدخول', 'Log in')))),
                const SizedBox(height: 28),
                Text(oursText(context, 'عالم خاص لشخصين فقط', 'A private world for two only'), style: const TextStyle(color: gold, fontSize: 12, letterSpacing: 1.2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Keep the root page synchronized with Supabase's persisted session.
// This avoids relying on one-time startup checks or manual navigation after auth.
class OursAuthGate extends StatelessWidget {
  const OursAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;
        if (session != null) {
          return OursSocialHomePage(
            onProfileTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: navy,
            body: Center(child: CircularProgressIndicator(color: gold)),
          );
        }
        return const LoginPage();
      },
    );
  }
}

// ==================== LOGIN PAGE ====================

class LoginPage extends StatefulWidget {
  final bool initialCreatingAccount;
  const LoginPage({super.key, this.initialCreatingAccount = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  bool loading = false;
  late bool creatingAccount = widget.initialCreatingAccount;

  SupabaseClient get db => Supabase.instance.client;

  void showMessage(String value) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  Future<void> login() async {
    final user = username.text.trim().toLowerCase();

    if (user.isEmpty || password.text.isEmpty) {
      showMessage('أدخل اسم المستخدم وكلمة المرور');
      return;
    }

    setState(() => loading = true);

    try {
      final response = await db.functions.invoke(
        'duo-username-login',
        body: {
          'username': user,
          'password': password.text,
        },
      );

      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data)
          : <String, dynamic>{};

      if (response.status != 200) {
        throw Exception(data['error'] ?? 'تعذر تسجيل الدخول');
      }

      final refreshToken = data['refresh_token'];

      if (refreshToken == null) {
        throw Exception('لم يتم استلام بيانات الجلسة');
      }

      await db.auth.setSession(refreshToken);

      if (!mounted) return;

      // OursAuthGate observes the authenticated session and opens HomePage.
    } catch (e) {
      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> register() async {
    final user = username.text.trim().toLowerCase();
    final pass = password.text;
    final confirm = confirmPassword.text;

    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(user)) {
      showMessage(
        'اسم المستخدم يجب أن يكون من 3 إلى 20 حرفًا، '
        'ويحتوي على أحرف إنجليزية أو أرقام أو _ فقط',
      );
      return;
    }

    if (pass.length < 8) {
      showMessage('كلمة المرور يجب أن تكون 8 أحرف على الأقل');
      return;
    }

    if (pass != confirm) {
      showMessage('كلمتا المرور غير متطابقتين');
      return;
    }

    setState(() => loading = true);

    try {
      final response = await db.functions.invoke(
        'duo-username-register',
        body: {
          'username': user,
          'password': pass,
        },
      );

      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data)
          : <String, dynamic>{};

      if (response.status < 200 || response.status >= 300) {
        throw Exception(data['error'] ?? 'تعذر إنشاء الحساب');
      }

      final loginResponse = await db.functions.invoke(
        'duo-username-login',
        body: {
          'username': user,
          'password': pass,
        },
      );

      final loginData = loginResponse.data is Map
          ? Map<String, dynamic>.from(loginResponse.data)
          : <String, dynamic>{};

      if (loginResponse.status != 200) {
        throw Exception(
          loginData['error'] ?? 'تم إنشاء الحساب، تعذر تسجيل الدخول',
        );
      }

      final refreshToken = loginData['refresh_token'];

      if (refreshToken == null) {
        throw Exception('لم يتم استلام بيانات الجلسة');
      }

      await db.auth.setSession(refreshToken);

      if (!mounted) return;

      // OursAuthGate observes the authenticated session and opens HomePage.
    } catch (e) {
      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                const Icon(
                  Icons.all_inclusive,
                  size: 76,
                  color: gold,
                ),
                const SizedBox(height: 18),
                const Text(
                  'OURS',
                  style: TextStyle(
                    color: gold,
                    fontSize: 46,
                    letterSpacing: 12,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const Text(
                  'YOUR PRIVATE UNIVERSE',
                  style: TextStyle(
                    color: lavender,
                    letterSpacing: 3,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 50),
                Text(
                  creatingAccount ? oursText(context, 'أنشئ حسابك', 'Create your account') : oursText(context, 'مرحبًا بعودتك', 'Welcome back'),
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: username,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: oursText(context, 'اسم المستخدم', 'Username'),
                    hintText: 'مثال: ours_user',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: oursText(context, 'كلمة المرور', 'Password'),
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (creatingAccount) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPassword,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: oursText(context, 'تأكيد كلمة المرور', 'Confirm password'),
                      prefixIcon: Icon(Icons.lock_reset),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'اسم المستخدم: أحرف إنجليزية وأرقام و _ فقط',
                    style: TextStyle(
                      color: lavender,
                      fontSize: 12,
                    ),
                  ),
                  const Text(
                    'كلمة المرور: 8 أحرف على الأقل',
                    style: TextStyle(
                      color: lavender,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: loading
                        ? null
                        : creatingAccount
                            ? register
                            : login,
                    child: loading
                        ? const CircularProgressIndicator(
                            color: navy,
                          )
                        : Text(
                            creatingAccount
                                ? oursText(context, 'إنشاء الحساب', 'Create account')
                                : oursText(context, 'تسجيل الدخول', 'Log in'),
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          setState(() {
                            creatingAccount = !creatingAccount;
                            password.clear();
                            confirmPassword.clear();
                          });
                        },
                  child: Text(
                    creatingAccount
                        ? oursText(context, 'لديك حساب بالفعل؟ تسجيل الدخول', 'Already have an account? Log in')
                        : oursText(context, 'ليس لديك حساب؟ إنشاء حساب جديد', 'New here? Create an account'),
                    style: const TextStyle(color: lavender),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'A WORLD OF TWO',
                  style: TextStyle(
                    color: lavender,
                    letterSpacing: 3,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== HOME PAGE ====================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedWorldIndex = 0;
  bool loading = true;
  String? inviteCode;
  String? spaceId;

  final codeController = TextEditingController();

  SupabaseClient get db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    loadExistingSpace();
  }

  Future<void> loadExistingSpace() async {
    try {
      final userId = db.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => loading = false);
        return;
      }

      final membership = await db
          .from('duo_members')
          .select('space_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        spaceId = membership?['space_id']?.toString();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      message('تعذر استرجاع مساحتك: $e');
    }
  }

  void message(String value) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  Future<void> createSpace() async {
    setState(() => loading = true);

    try {
      final createdSpace = await db.rpc('create_duo_space');
      final createdId = createdSpace?.toString() ?? '';
      if (createdId.isEmpty) throw Exception('لم يرجع الخادم معرّف المساحة');
      if (!mounted) return;
      setState(() => spaceId = createdId);

      // Space creation and invite generation are separate operations.
      // Preserve the created space if invite generation fails.
      try {
        final code = await db.rpc('create_duo_invite');
        if (!mounted) return;
        setState(() => inviteCode = code.toString());
        message('تم إنشاء المساحة بنجاح');
      } catch (inviteError) {
        if (!mounted) return;
        message('تم إنشاء المساحة، لكن تعذر إنشاء رمز الدعوة. يمكنك إعادة المحاولة لاحقًا. ($inviteError)');
      }
    } catch (e) {
      if (!mounted) return;
      message('تعذر إنشاء المساحة: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> joinSpace() async {
    final code = codeController.text.trim();

    if (code.length != 8) {
      message('أدخل رمز الدعوة المكوّن من 8 خانات');
      return;
    }

    setState(() => loading = true);

    try {
      final joinedSpace = await db.rpc(
        'redeem_duo_invite',
        params: {'p_code': code},
      );

      if (!mounted) return;

      setState(() {
        spaceId = joinedSpace.toString();
        inviteCode = null;
      });

      codeController.clear();
      message('تم الانضمام إلى المساحة بنجاح');
    } catch (e) {
      message('تعذر الانضمام: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void openChat() {
    if (spaceId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(spaceId: spaceId!),
      ),
    );
  }

  void showJoinDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: purple,
        title: const Text('الانضمام إلى مساحة'),
        content: TextField(
          controller: codeController,
          maxLength: 8,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'رمز الدعوة',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: loading
                ? null
                : () {
                    Navigator.pop(dialogContext);
                    joinSpace();
                  },
            child: const Text('انضمام'),
          ),
        ],
      ),
    );
  }

  Widget actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Card(
      color: purple,
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: Icon(
          icon,
          color: gold,
          size: 32,
        ),
        title: Text(title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            subtitle,
            style: const TextStyle(color: lavender),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: gold,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'OURS',
          style: TextStyle(
            color: gold,
            letterSpacing: 5,
          ),
        ),
        centerTitle: true,
        backgroundColor: navy,
        actions: previewMode ? const [] : [
          OursNotificationBell(spaceId: spaceId),
          IconButton(
            tooltip: 'الملف الشخصي والإعدادات',
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileSettingsPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  backgroundColor: purple,
                  icon: const Icon(Icons.logout_rounded, color: gold),
                  title: const Text('تسجيل الخروج'),
                  content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
                    FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('تسجيل الخروج')),
                  ],
                ),
              );
              if (confirmed != true) return;
              try {
                await OursPushService.unregisterCurrentToken();
                await db.auth.signOut();

                if (!mounted) return;

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(),
                  ),
                );
              } catch (e) {
                message('تعذر تسجيل الخروج: $e');
              }
            },
          ),
        ],
      ),
      body: selectedWorldIndex == 0 ? SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.all_inclusive_rounded,
                  color: gold,
                  size: 65,
                ),
                const SizedBox(height: 20),
                const Text(
                  'عالمك الخاص يبدأ هنا',
                  style: TextStyle(fontSize: 25),
                ),
                const SizedBox(height: 10),
                const Text(
                  'مساحة تجمع شخصين فقط',
                  style: TextStyle(color: lavender),
                ),
                const SizedBox(height: 45),
                if (previewMode) ...[
                  Card(
                    color: purple,
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(Icons.visibility_outlined, color: gold),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'وضع معاينة — يمكنك استكشاف الواجهة، لكن إنشاء المساحات والمحادثات يتطلب تسجيل الدخول.',
                              style: TextStyle(color: lavender),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                if (spaceId == null) ...[
                  actionCard(
                    icon: Icons.add_circle_outline,
                    title: 'إنشاء مساحة جديدة',
                    subtitle: 'أنشئ عالمك الخاص وأرسل رمز الدعوة',
                    onTap: loading ? null : previewMode
                        ? () => message('هذه نسخة معاينة؛ إنشاء مساحة يتطلب حسابًا.')
                        : createSpace,
                  ),
                  const SizedBox(height: 18),
                  actionCard(
                    icon: Icons.vpn_key_outlined,
                    title: 'الانضمام إلى مساحة',
                    subtitle: 'أدخل رمز الدعوة الذي وصلك',
                    onTap: loading ? null : previewMode
                        ? () => message('هذه نسخة معاينة؛ الانضمام يتطلب حسابًا.')
                        : showJoinDialog,
                  ),
                ] else ...[
                  const Card(
                    color: purple,
                    child: ListTile(
                      leading: Icon(Icons.verified_user_outlined, color: gold, size: 30),
                      title: Text('مساحتك جاهزة'),
                      subtitle: Text(
                        'لديك مساحة خاصة بالفعل. يمكنك فتح محادثتك من الزر أدناه.',
                        style: TextStyle(color: lavender),
                      ),
                    ),
                  ),
                ],
                if (loading) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: gold),
                ],
                if (inviteCode != null) ...[
                  const SizedBox(height: 30),
                  const Text('رمز الدعوة الخاص بك'),
                  const SizedBox(height: 12),
                  SelectableText(
                    inviteCode!,
                    style: const TextStyle(
                      fontSize: 30,
                      color: gold,
                      letterSpacing: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'شاركه مع الشخص الذي تريد دعوته',
                    style: TextStyle(color: lavender),
                  ),
                ],
                if (spaceId != null) ...[
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: FilledButton.icon(
                      onPressed: openChat,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text(
                        'فتح المحادثة',
                        style: TextStyle(fontSize: 17),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ) : OursWorldHubPage(
        key: ValueKey('ours-world-$selectedWorldIndex'),
        spaceId: spaceId,
        worldIndex: selectedWorldIndex,
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: purple,
        selectedIndex: selectedWorldIndex,
        onDestinationSelected: (index) => setState(() => selectedWorldIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.forum_outlined), label: 'Connect'),
          NavigationDestination(icon: Icon(Icons.public_outlined), label: 'Universe'),
          NavigationDestination(icon: Icon(Icons.sports_esports_outlined), label: 'Play'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), label: 'Memories'),
          NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Together'),
        ],
      ),
    );
  }
}

 // ==================== CHAT PAGE ====================

class ChatPage extends StatefulWidget {
  final String spaceId;

  const ChatPage({
    super.key,
    required this.spaceId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageController =
      TextEditingController();

  final ScrollController scrollController = ScrollController();

  SupabaseClient get db => Supabase.instance.client;

  List<Map<String, dynamic>> messages = [];

  bool loading = true;
  bool sending = false;
  bool quietMode = false;
  bool uploadingImage = false;
  bool uploadingFile = false;
  bool recordingAudio = false;
  AudioRecorder? audioRecorder;
  String? activeRecordingPath;
  final ImagePicker imagePicker = ImagePicker();
  final Map<String, Future<String>> signedImageUrls = {};
  final Map<String, String> participantNames = {};
  Map<String, dynamic>? replyingTo;
  String partnerName = 'مساحتكما الخاصة';
  int unreadIncomingCount = 0;
  String searchQuery = '';

  RealtimeChannel? channel;
  RealtimeChannel? presenceChannel;
  bool partnerOnline = false;

  String get currentUserId => db.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    loadMessages();
    loadQuietMode();
    loadParticipantNames();
    listenToMessages();
    listenToPresence();
  }

  Future<void> loadQuietMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => quietMode = prefs.getBool('ours_quiet_mode') ?? false);
  }

  Future<void> listenToPresence() async {
    // Respect the local visibility preference and use a unique key per user.
    final prefs = await SharedPreferences.getInstance();
    final showOnline = prefs.getBool('ours_show_online') ?? true;
    if (!mounted || !showOnline) return;

    presenceChannel = db.channel(
      'ours-presence-${widget.spaceId}',
      opts: RealtimeChannelConfig(key: currentUserId),
    );
    presenceChannel!
      .onPresenceSync((payload) {
        final states = presenceChannel!.presenceState();
        final onlineIds = <String>{};
        for (final state in states) {
          for (final presence in state.presences) {
            final id = presence.payload['user_id']?.toString();
            if (id != null) onlineIds.add(id);
          }
        }
        if (mounted) {
          setState(() => partnerOnline = onlineIds.any((id) => id != currentUserId));
        }
      })
      .subscribe((status, error) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          await presenceChannel!.track({
            'user_id': currentUserId,
            'online_at': DateTime.now().toUtc().toIso8601String(),
          });
        }
      });
  }

  Future<void> loadParticipantNames() async {
    try {
      final members = await db
          .from('duo_members')
          .select('user_id')
          .eq('space_id', widget.spaceId);

      final ids = members
          .map((row) => row['user_id'].toString())
          .toList();

      if (ids.isEmpty) return;

      final profiles = await db
          .from('duo_profiles')
          .select('user_id, username, display_name')
          .inFilter('user_id', ids);

      final names = <String, String>{};
      for (final profile in profiles) {
        final id = profile['user_id'].toString();
        final displayName = profile['display_name']?.toString().trim() ?? '';
        final username = profile['username']?.toString() ?? '';
        names[id] = displayName.isNotEmpty ? displayName : username;
      }

      if (!mounted) return;
      setState(() {
        participantNames
          ..clear()
          ..addAll(names);
        final otherIds = ids.where((id) => id != currentUserId).toList();
        if (otherIds.isNotEmpty) {
          partnerName = names[otherIds.first] ?? 'الشريك';
        }
      });
    } catch (e) {
      debugPrint('Could not load chat participant names: $e');
    }
  }

  void showImagePreview(String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: navy,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('تعذر تحميل الصورة'),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close, color: gold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> loadMessages() async {
    try {
      final result = await db
          .from('duo_messages')
          .select()
          .eq('space_id', widget.spaceId)
          .order('created_at', ascending: true);

      if (!mounted) return;

      setState(() {
        messages = List<Map<String, dynamic>>.from(result);
        loading = false;
      });

      scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      showMessage('تعذر تحميل الرسائل: $e');
    }
  }

  void listenToMessages() {
    channel = db
        .channel('ours-chat-${widget.spaceId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'duo_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'space_id',
            value: widget.spaceId,
          ),
          callback: (payload) {
            final newMessage =
                Map<String, dynamic>.from(payload.newRecord);

            if (!mounted) return;

            final alreadyExists = messages.any(
              (item) => item['id'] == newMessage['id'],
            );

            if (!alreadyExists) {
              setState(() {
                messages.add(newMessage);
                if (newMessage['sender_id'] != currentUserId) unreadIncomingCount++;
              });
              if (newMessage['sender_id'] != currentUserId) {
                if (!quietMode) showMessage('رسالة جديدة من $partnerName');
              }
              scrollToBottom();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'duo_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'space_id',
            value: widget.spaceId,
          ),
          callback: (payload) {
            final updated = Map<String, dynamic>.from(payload.newRecord);
            if (!mounted) return;
            setState(() {
              final index = messages.indexWhere((item) => item['id'] == updated['id']);
              if (index >= 0) messages[index] = updated;
            });
          },
        )
        .subscribe();
  }



  String _messagePreview(Map<String, dynamic> item) {
    if (item['deleted_at'] != null) return 'رسالة محذوفة';
    switch (item['message_type']) {
      case 'image':
        return 'صورة';
      case 'file':
        return 'ملف';
      case 'audio':
        return 'رسالة صوتية';
      default:
        final body = item['body']?.toString() ?? '';
        return body.length > 70 ? '${body.substring(0, 70)}…' : body;
    }
  }

  void _replyToMessage(Map<String, dynamic> item) {
    setState(() => replyingTo = item);
    showMessage('الرد على: ${_messagePreview(item)}');
  }

  Future<void> _deleteMessage(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: purple,
        title: const Text('حذف الرسالة؟'),
        content: const Text('ستظهر الرسالة كمحذوفة داخل المحادثة.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await db.from('duo_messages').update({
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
        'body': 'تم حذف الرسالة',
        'reply_to': null,
      }).eq('id', item['id']).eq('sender_id', currentUserId);
      if (mounted) showMessage('تم حذف الرسالة');
    } catch (e) {
      if (mounted) showMessage('تعذر حذف الرسالة: $e');
    }
  }

  Future<void> sendImage() async {
    if (uploadingImage || sending) return;

    try {
      final picked = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1920,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        showMessage('الصورة المحددة فارغة');
        return;
      }
      if (bytes.length > 15 * 1024 * 1024) {
        showMessage('حجم الصورة كبير. اختر صورة أقل من 15 ميجابايت');
        return;
      }

      setState(() => uploadingImage = true);

      final originalName = picked.name;
      final extension = originalName.contains('.')
          ? originalName.split('.').last.toLowerCase()
          : 'jpg';
      const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif'};
      if (!allowedExtensions.contains(extension)) {
        showMessage('صيغة الصورة غير مدعومة. استخدم JPG أو PNG أو WEBP أو GIF');
        return;
      }
      final safeExtension = extension;
      final contentType = switch (safeExtension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };

      final storagePath =
          '${widget.spaceId}/$currentUserId/'
          '${DateTime.now().microsecondsSinceEpoch}.$safeExtension';

      await db.storage.from('duo-private').uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          cacheControl: '3600',
          upsert: false,
        ),
      );

      try {
        await db.from('duo_messages').insert({
          'space_id': widget.spaceId,
          'sender_id': currentUserId,
          'body': storagePath,
          'message_type': 'image',
          if (replyingTo != null) 'reply_to': replyingTo!['id'],
        });
        if (mounted) setState(() => replyingTo = null);
      } catch (_) {
        await db.storage.from('duo-private').remove([storagePath]);
        rethrow;
      }

      if (mounted) showMessage('تم إرسال الصورة');
    } catch (e) {
      if (mounted) showMessage('تعذر إرسال الصورة: $e');
    } finally {
      if (mounted) setState(() => uploadingImage = false);
    }
  }

  Future<void> sendFile() async {
    if (uploadingFile || uploadingImage || sending) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'csv', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'zip'],
        withData: true,
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) { showMessage('تعذر قراءة الملف المحدد'); return; }
      if (bytes.length > 20 * 1024 * 1024) { showMessage('حجم الملف يتجاوز الحد المسموح (20 ميجابايت)'); return; }
      setState(() => uploadingFile = true);
      final extension = (file.extension ?? '').toLowerCase();
      final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_').replaceAll('..', '_');
      final storagePath = '${widget.spaceId}/$currentUserId/${DateTime.now().microsecondsSinceEpoch}_$safeName';
      await db.storage.from('duo-private').uploadBinary(storagePath, bytes, fileOptions: FileOptions(contentType: _fileMimeType(extension), cacheControl: '3600', upsert: false));
      try {
        await db.from('duo_messages').insert({'space_id': widget.spaceId, 'sender_id': currentUserId, 'body': storagePath, 'message_type': 'file', if (replyingTo != null) 'reply_to': replyingTo!['id']});
        if (mounted) setState(() => replyingTo = null);
      } catch (_) { await db.storage.from('duo-private').remove([storagePath]); rethrow; }
      if (mounted) showMessage('تم إرسال الملف');
    } catch (e) { if (mounted) showMessage('تعذر إرسال الملف: $e'); }
    finally { if (mounted) setState(() => uploadingFile = false); }
  }

  String _fileMimeType(String extension) {
    const types = {'pdf':'application/pdf','txt':'text/plain','csv':'text/csv','doc':'application/msword','docx':'application/vnd.openxmlformats-officedocument.wordprocessingml.document','xls':'application/vnd.ms-excel','xlsx':'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','ppt':'application/vnd.ms-powerpoint','pptx':'application/vnd.openxmlformats-officedocument.presentationml.presentation','zip':'application/zip'};
    return types[extension] ?? 'application/octet-stream';
  }

  Future<void> openSharedFile(String path) async {
    try {
      final url = await db.storage.from('duo-private').createSignedUrl(path, 900);
      final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!opened && mounted) showMessage('تعذر فتح الملف');
    } catch (e) { if (mounted) showMessage('تعذر فتح الملف: $e'); }
  }
  Future<String> signedImageUrl(String path) {
    final cached = signedImageUrls[path];
    if (cached != null) return cached;

    final future = db.storage
        .from('duo-private')
        .createSignedUrl(path, 900);
    signedImageUrls[path] = future;

    // Refresh before the 15-minute signed URL expires.
    future.then((_) {
      Future<void>.delayed(const Duration(minutes: 10), () {
        if (!identical(signedImageUrls[path], future)) return;
        signedImageUrls.remove(path);
        if (mounted) setState(() {});
      });
    }, onError: (Object _) {
      if (identical(signedImageUrls[path], future)) {
        signedImageUrls.remove(path);
      }
    });

    return future;
  }


  Future<void> startAudioRecording() async {
    if (recordingAudio || sending || uploadingImage || uploadingFile) return;
    final recorder = audioRecorder ??= AudioRecorder();
    try {
      final permitted = await recorder.hasPermission();
      if (!permitted) {
        showMessage('يلزم السماح باستخدام الميكروفون لتسجيل رسالة صوتية');
        return;
      }
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/ours_${DateTime.now().microsecondsSinceEpoch}.m4a';
      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 96000,
          sampleRate: 44100,
          numChannels: 1,
          echoCancel: true,
          noiseSuppress: true,
        ),
        path: path,
      );
      if (!mounted) {
        await recorder.cancel();
        return;
      }
      setState(() {
        activeRecordingPath = path;
        recordingAudio = true;
      });
    } catch (e) {
      showMessage('تعذر بدء التسجيل: $e');
    }
  }

  Future<void> cancelAudioRecording() async {
    final recorder = audioRecorder;
    if (recorder == null || !recordingAudio) return;
    try {
      await recorder.cancel();
      final path = activeRecordingPath;
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    } catch (e) {
      debugPrint('Audio recording cancel failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          recordingAudio = false;
          activeRecordingPath = null;
        });
      }
    }
  }

  Future<void> stopAndSendAudio() async {
    final recorder = audioRecorder;
    if (recorder == null || !recordingAudio) return;
    setState(() => sending = true);
    String? path;
    try {
      path = await recorder.stop();
      if (path == null || path.isEmpty) {
        throw Exception('لم يتم حفظ التسجيل');
      }
      final audioFile = File(path);
      if (!await audioFile.exists()) {
        throw Exception('تعذر العثور على التسجيل');
      }
      final bytes = await audioFile.readAsBytes();
      if (bytes.isEmpty) throw Exception('التسجيل فارغ');
      if (bytes.length > 15 * 1024 * 1024) {
        throw Exception('حجم التسجيل يتجاوز 15 ميجابايت');
      }

      final storagePath =
          '${widget.spaceId}/$currentUserId/'
          '${DateTime.now().microsecondsSinceEpoch}.m4a';
      await db.storage.from('duo-private').uploadBinary(
        storagePath,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'audio/mp4',
          cacheControl: '3600',
          upsert: false,
        ),
      );
      try {
        await db.from('duo_messages').insert({
          'space_id': widget.spaceId,
          'sender_id': currentUserId,
          'body': storagePath,
          'message_type': 'audio',
          if (replyingTo != null) 'reply_to': replyingTo!['id'],
        });
        if (mounted) setState(() => replyingTo = null);
      } catch (_) {
        await db.storage.from('duo-private').remove([storagePath]);
        rethrow;
      }
      if (mounted) showMessage('تم إرسال الرسالة الصوتية');
    } catch (e) {
      if (mounted) showMessage('تعذر إرسال التسجيل: $e');
    } finally {
      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
      if (mounted) {
        setState(() {
          recordingAudio = false;
          activeRecordingPath = null;
          sending = false;
        });
      }
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty || sending) return;

    setState(() => sending = true);

    try {
      await db.from('duo_messages').insert({
        'space_id': widget.spaceId,
        'sender_id': currentUserId,
        'body': text,
        'message_type': 'text',
        if (replyingTo != null) 'reply_to': replyingTo!['id'],
      });

      if (!mounted) return;

      messageController.clear();
      setState(() => replyingTo = null);
    } catch (e) {
      showMessage('تعذر إرسال الرسالة: $e');
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }

  String _formatMessageTime(dynamic value) {
    if (value == null) return '';
    try {
      final date = DateTime.parse(value.toString()).toLocal();
      return DateFormat('h:mm a').format(date);
    } catch (_) {
      return '';
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void showMessage(String value) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  Future<void> showMessageSearch() async {
    final controller = TextEditingController(text: searchQuery);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: purple,
        title: const Text('البحث في المحادثة'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'اكتب كلمة أو جزءًا من رسالة',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            if (mounted) setState(() => searchQuery = value.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) setState(() => searchQuery = '');
              Navigator.pop(dialogContext);
            },
            child: const Text('مسح البحث'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('تم'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  void openAlbums() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => OursAlbumsPage(spaceId: widget.spaceId),
    ));
  }

  void openMediaGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SharedMediaPage(messages: List<Map<String, dynamic>>.from(messages)),
      ),
    );
    if (mounted) setState(() => unreadIncomingCount = 0);
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    audioRecorder?.dispose();

    if (channel != null) db.removeChannel(channel!);
    if (presenceChannel != null) {
      presenceChannel!.untrack();
      db.removeChannel(presenceChannel!);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.toLowerCase();
    final displayedMessages = query.isEmpty
        ? messages
        : messages.where((item) {
            final body = item['body']?.toString().toLowerCase() ?? '';
            final preview = _messagePreview(item).toLowerCase();
            return body.contains(query) || preview.contains(query);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'OURS',
              style: TextStyle(
                color: gold,
                letterSpacing: 5,
              ),
            ),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(
                color: partnerOnline ? Colors.lightGreenAccent : Colors.grey,
                shape: BoxShape.circle,
              )),
              const SizedBox(width: 5),
              Text(
                partnerOnline ? '$partnerName · متصل الآن' : '$partnerName · غير متصل',
                style: const TextStyle(color: lavender, fontSize: 11, letterSpacing: 0),
              ),
            ]),
          ],
        ),
        centerTitle: true,
        backgroundColor: navy,
        actions: [
          IconButton(
            tooltip: 'البحث في المحادثة',
            onPressed: showMessageSearch,
            icon: Icon(
              Icons.search,
              color: searchQuery.isEmpty ? gold : Colors.lightGreenAccent,
            ),
          ),
          IconButton(
            tooltip: 'ألبومات الصور المشتركة',
            onPressed: openAlbums,
            icon: const Icon(Icons.photo_album_outlined, color: gold),
          ),
          IconButton(
            tooltip: 'الوسائط والملفات المشتركة',
            onPressed: openMediaGallery,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.perm_media_outlined, color: gold),
                if (unreadIncomingCount > 0)
                  Positioned(
                    top: -5,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      child: Text('$unreadIncomingCount', style: const TextStyle(fontSize: 9, color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: gold),
                  )
                : messages.isEmpty
                    ? const Center(
                        child: Text(
                          'بداية عالمكما الخاص',
                          style: TextStyle(
                            color: lavender,
                            fontSize: 18,
                          ),
                        ),
                      )
                    : displayedMessages.isEmpty
                        ? const Center(
                            child: Text(
                              'لا توجد رسائل تطابق البحث',
                              style: TextStyle(color: lavender),
                            ),
                          )
                        : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: displayedMessages.length,
                        itemBuilder: (context, index) {
                          final item = displayedMessages[index];
                          final isMe =
                              item['sender_id'] == currentUserId;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(
                                maxWidth: 280,
                              ),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? purple
                                    : const Color(0xFF211D30),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: gold.withOpacity(0.25),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isMe)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        participantNames[item['sender_id']?.toString()] ?? 'الشريك',
                                        style: const TextStyle(
                                          color: gold,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  if (item['reply_to'] != null)
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: navy.withOpacity(0.65),
                                        borderRadius: BorderRadius.circular(8),
                                        border: const Border(left: BorderSide(color: gold, width: 3)),
                                      ),
                                      child: Text(
                                        'رد على: ${_messagePreview(messages.firstWhere(
                                          (message) => message['id']?.toString() == item['reply_to']?.toString(),
                                          orElse: () => <String, dynamic>{'deleted_at': true},
                                        ))}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: lavender, fontSize: 11),
                                      ),
                                    ),
                                  if (item['deleted_at'] != null)
                                    const Text('تم حذف الرسالة', style: TextStyle(color: lavender, fontStyle: FontStyle.italic))
                                  else if (item['message_type'] == 'file')
                                    InkWell(
                                      onTap: () => openSharedFile(item['body']?.toString() ?? ''),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                                        const Icon(Icons.insert_drive_file_outlined, color: gold, size: 30),
                                        const SizedBox(width: 10),
                                        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text((item['body']?.toString() ?? '').split('/').last.replaceFirst(RegExp(r'^\d+_'), ''), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 3),
                                          const Text('اضغط لفتح الملف', style: TextStyle(color: lavender, fontSize: 11)),
                                        ])),
                                      ]),
                                    )
                                  else if (item['message_type'] == 'audio')
                                    AudioMessageBubble(
                                      audioPath: item['body']?.toString() ?? '',
                                      isMine: isMe,
                                    )
                                  else if (item['message_type'] == 'image')
                                    FutureBuilder<String>(
                                      future: signedImageUrl(
                                        item['body']?.toString() ?? '',
                                      ),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasError) {
                                          return const Text(
                                            'تعذر تحميل الصورة',
                                            style: TextStyle(color: lavender),
                                          );
                                        }
                                        if (!snapshot.hasData) {
                                          return const SizedBox(
                                            width: 190,
                                            height: 150,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                color: gold,
                                              ),
                                            ),
                                          );
                                        }
                                        return GestureDetector(
                                          onTap: () => showImagePreview(snapshot.data!),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              snapshot.data!,
                                              width: 220,
                                              fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const SizedBox(
                                              width: 190,
                                              height: 100,
                                              child: Center(
                                                child: Text(
                                                  'تعذر عرض الصورة',
                                                  style: TextStyle(color: lavender),
                                                ),
                                              ),
                                            ),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  else
                                    Text(
                                      item['body']?.toString() ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                                  if (item['deleted_at'] == null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: OursMessageReactions(
                                        messageId: item['id'].toString(),
                                        spaceId: widget.spaceId,
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatMessageTime(item['created_at']),
                                        style: const TextStyle(color: lavender, fontSize: 10),
                                      ),
                                      const SizedBox(width: 8),
                                      if (item['deleted_at'] == null)
                                        InkWell(
                                          onTap: () => _replyToMessage(item),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(Icons.reply_rounded, color: lavender, size: 17),
                                          ),
                                        ),
                                      if (isMe && item['deleted_at'] == null)
                                        InkWell(
                                          onTap: () => _deleteMessage(item),
                                          child: const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(Icons.delete_outline, color: Colors.redAccent, size: 17),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
            decoration: BoxDecoration(
              color: purple,
              border: Border(
                top: BorderSide(
                  color: gold.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                if (recordingAudio) ...[
                  IconButton(
                    tooltip: 'إلغاء التسجيل',
                    onPressed: sending ? null : cancelAudioRecording,
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  ),
                  Expanded(
                    child: Text(
                      'جارٍ تسجيل الرسالة الصوتية...',
                      style: const TextStyle(color: gold, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    tooltip: 'إيقاف وإرسال التسجيل',
                    onPressed: sending ? null : stopAndSendAudio,
                    icon: sending
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: gold, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: gold),
                  ),
                ] else ...[
                IconButton(
                  tooltip: 'إرسال ملف',
                  onPressed: uploadingFile || uploadingImage || sending ? null : sendFile,
                  icon: uploadingFile ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: gold, strokeWidth: 2)) : const Icon(Icons.attach_file, color: gold),
                ),
                IconButton(
                  tooltip: 'إرسال صورة',
                  onPressed: uploadingImage || uploadingFile || sending ? null : sendImage,
                  icon: uploadingImage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: gold,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.image_outlined, color: gold),
                ),
                Expanded(
                  child: TextField(
                    controller: messageController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => sendMessage(),
                    decoration: InputDecoration(
                      hintText: replyingTo == null
                          ? 'اكتب رسالتك...'
                          : 'الرد على: ${_messagePreview(replyingTo!)}',
                      filled: true,
                      fillColor: navy,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: sending ? null : sendMessage,
                  icon: sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: gold,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: gold,
                        ),
                ),
                if (replyingTo != null)
                  IconButton(
                    tooltip: 'إلغاء الرد',
                    onPressed: () => setState(() => replyingTo = null),
                    icon: const Icon(Icons.close, color: lavender),
                  ),
                IconButton(
                  tooltip: 'تسجيل رسالة صوتية',
                  onPressed: sending || uploadingFile || uploadingImage ? null : startAudioRecording,
                  icon: const Icon(Icons.mic_none_rounded, color: gold),
                ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ==================== SHARED MEDIA ====================

class SharedMediaPage extends StatelessWidget {
  final List<Map<String, dynamic>> messages;

  const SharedMediaPage({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    final visible = messages
        .where((item) => item['deleted_at'] == null &&
            {'image', 'file', 'audio'}.contains(item['message_type']))
        .toList()
      ..sort((a, b) => DateTime.parse(b['created_at'].toString())
          .compareTo(DateTime.parse(a['created_at'].toString())));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الوسائط والملفات', style: TextStyle(color: gold)),
          backgroundColor: navy,
          bottom: const TabBar(
            labelColor: gold,
            unselectedLabelColor: lavender,
            indicatorColor: gold,
            tabs: [
              Tab(icon: Icon(Icons.image_outlined), text: 'الصور'),
              Tab(icon: Icon(Icons.insert_drive_file_outlined), text: 'الملفات'),
              Tab(icon: Icon(Icons.mic_none), text: 'الصوت'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MediaList(items: visible.where((m) => m['message_type'] == 'image').toList()),
            _MediaList(items: visible.where((m) => m['message_type'] == 'file').toList()),
            _MediaList(items: visible.where((m) => m['message_type'] == 'audio').toList()),
          ],
        ),
      ),
    );
  }
}

class _MediaList extends StatelessWidget {
  final List<Map<String, dynamic>> items;

  const _MediaList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('لا توجد عناصر مشتركة بعد', style: TextStyle(color: lavender)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(color: purple),
      itemBuilder: (context, index) {
        final item = items[index];
        final type = item['message_type'];
        final path = item['body']?.toString() ?? '';
        final created = DateTime.tryParse(item['created_at']?.toString() ?? '');
        final label = type == 'image' ? 'صورة مشتركة' : type == 'audio' ? 'رسالة صوتية' : path.split('/').last;
        return ListTile(
          leading: Icon(
            type == 'image' ? Icons.image_outlined : type == 'audio' ? Icons.audio_file_outlined : Icons.insert_drive_file_outlined,
            color: gold,
          ),
          title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            created == null ? '' : DateFormat('yyyy/MM/dd • HH:mm').format(created.toLocal()),
            style: const TextStyle(color: lavender, fontSize: 11),
          ),
          trailing: const Icon(Icons.open_in_new, color: lavender),
          onTap: () async {
            try {
              final url = await Supabase.instance.client.storage.from('duo-private').createSignedUrl(path, 900);
              final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح العنصر')));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر فتح العنصر: $e')));
              }
            }
          },
        );
      },
    );
  }
}


// ==================== PROFILE & SETTINGS ====================

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final displayNameController = TextEditingController();
  final bioController = TextEditingController();
  SupabaseClient get db => Supabase.instance.client;

  String username = '';
  String email = '';
  String? avatarUrl;
  String languageCode = 'ar';
  bool uploadingAvatar = false;
  bool loading = true;
  bool saving = false;
  bool quietMode = false;
  bool confirmBeforeDelete = true;

  @override
  void initState() {
    super.initState();
    loadPreferences();
    loadProfile();
  }

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      quietMode = prefs.getBool('ours_quiet_mode') ?? false;
      confirmBeforeDelete = prefs.getBool('ours_confirm_delete') ?? true;
      languageCode = prefs.getString('ours_language') ?? 'ar';
    });
  }

  Future<void> savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> loadProfile() async {
    try {
      final user = db.auth.currentUser;
      if (user == null) throw Exception('انتهت جلسة تسجيل الدخول');

      email = user.email ?? '';
      final profile = await db
          .from('duo_profiles')
          .select('username, display_name, avatar_path, bio')
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;
      username = profile?['username']?.toString() ?? '';
      final avatarPath = profile?['avatar_path']?.toString();
      avatarUrl = avatarPath == null ? null : db.storage.from('ours-avatars').getPublicUrl(avatarPath);
      displayNameController.text =
          profile?['display_name']?.toString() ?? '';
      bioController.text = profile?['bio']?.toString() ?? '';
      setState(() => loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      showMessage('تعذر تحميل الملف الشخصي: $e');
    }
  }

  void showMessage(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  Future<void> chooseAvatar() async {
    if (uploadingAvatar) return;
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: purple,
        builder: (sheetContext) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: gold),
              title: const Text('اختيار من المعرض'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: gold),
              title: const Text('التقاط صورة بالكاميرا'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
          ]),
        ),
      );
      if (source == null) return;
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 86,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (picked == null) return;
      final user = db.auth.currentUser;
      if (user == null) throw Exception('انتهت جلسة تسجيل الدخول');
      setState(() => uploadingAvatar = true);
      final extension = picked.name.split('.').last.toLowerCase();
      final safeExtension = ['jpg', 'jpeg', 'png', 'webp'].contains(extension) ? extension : 'jpg';
      final oldProfile = await db.from('duo_profiles').select('avatar_path').eq('user_id', user.id).maybeSingle();
      final oldPath = oldProfile?['avatar_path']?.toString();
      final path = '${user.id}/avatar_${DateTime.now().microsecondsSinceEpoch}.$safeExtension';
      final bytes = await picked.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) throw Exception('حجم الصورة يتجاوز 5 ميجابايت');
      await db.storage.from('ours-avatars').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(upsert: false, contentType: safeExtension == 'png' ? 'image/png' : safeExtension == 'webp' ? 'image/webp' : 'image/jpeg'),
      );
      try {
        await db.from('duo_profiles').update({'avatar_path': path}).eq('user_id', user.id);
      } catch (_) {
        await db.storage.from('ours-avatars').remove([path]);
        rethrow;
      }
      if (oldPath != null && oldPath != path) {
        try { await db.storage.from('ours-avatars').remove([oldPath]); } catch (_) {}
      }
      if (!mounted) return;
      setState(() => avatarUrl = db.storage.from('ours-avatars').getPublicUrl(path) + '?v=' + DateTime.now().millisecondsSinceEpoch.toString());
      showMessage('تم تحديث الصورة الشخصية');
    } catch (e) {
      showMessage('تعذر تحديث الصورة: $e');
    } finally {
      if (mounted) setState(() => uploadingAvatar = false);
    }
  }

  Future<void> saveProfile() async {
    final value = displayNameController.text.trim();
    if (value.length > 30) {
      showMessage('الاسم الظاهر يجب ألا يتجاوز 30 حرفًا');
      return;
    }

    final userId = db.auth.currentUser?.id;
    if (userId == null) {
      showMessage('انتهت جلسة تسجيل الدخول');
      return;
    }

    setState(() => saving = true);
    try {
      final bio = bioController.text.trim();
      if (bio.length > 160) {
        showMessage('النبذة يجب ألا تتجاوز 160 حرفًا');
        return;
      }
      await db
          .from('duo_profiles')
          .update({
            'display_name': value.isEmpty ? null : value,
            'bio': bio,
          })
          .eq('user_id', userId);

      if (!mounted) return;
      showMessage('تم حفظ الملف الشخصي');
    } catch (e) {
      showMessage('تعذر حفظ التغييرات: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: purple,
        icon: const Icon(Icons.logout_rounded, color: gold),
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('تسجيل الخروج')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await OursPushService.unregisterCurrentToken();
                await db.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      showMessage('تعذر تسجيل الخروج: $e');
    }
  }

  Future<void> changePassword() async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: purple,
        title: const Text('تغيير كلمة المرور'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'كلمة المرور الجديدة',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (password == null) return;
    if (password.length < 8) {
      showMessage('كلمة المرور يجب أن تكون 8 أحرف على الأقل');
      return;
    }
    try {
      await db.auth.updateUser(UserAttributes(password: password));
      showMessage('تم تحديث كلمة المرور');
    } catch (e) {
      showMessage('تعذر تغيير كلمة المرور: $e');
    }
  }

  Widget settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      color: purple,
      child: ListTile(
        leading: Icon(icon, color: gold),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: lavender),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  void dispose() {
    displayNameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          oursText(context, 'الملف الشخصي والإعدادات', 'Profile & settings'),
          style: TextStyle(color: gold, fontSize: 18),
        ),
        backgroundColor: navy,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: uploadingAvatar ? null : chooseAvatar,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: purple,
                        backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl!),
                        child: avatarUrl == null ? const Icon(Icons.person_rounded, color: gold, size: 48) : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: CircleAvatar(
                          radius: 16, backgroundColor: gold,
                          child: uploadingAvatar
                              ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: navy))
                              : const Icon(Icons.camera_alt_outlined, color: navy, size: 17),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(oursText(context, 'اضغط لتغيير الصورة', 'Tap to change photo'), style: const TextStyle(color: lavender, fontSize: 12)),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    username.isEmpty ? oursText(context, 'حساب OURS', 'OURS account') : '@$username',
                    style: const TextStyle(
                      color: lavender,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  oursText(context, 'معلومات الحساب', 'Account information'),
                  style: TextStyle(color: gold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: displayNameController,
                  maxLength: 30,
                  decoration: InputDecoration(
                    labelText: oursText(context, 'الاسم الظاهر', 'Display name'),
                    hintText: oursText(context, 'كيف تريد أن يظهر اسمك؟', 'How should your name appear?'),
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioController,
                  maxLength: 160,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: oursText(context, 'نبذة عنك', 'About you'),
                    hintText: oursText(context, 'اكتب نبذة قصيرة تظهر في ملفك الشخصي', 'Write a short profile bio'),
                    prefixIcon: Icon(Icons.notes_rounded),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: oursText(context, 'اسم المستخدم', 'Username'),
                    prefixIcon: Icon(Icons.alternate_email),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(username.isEmpty ? '—' : username),
                ),
                const SizedBox(height: 14),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: oursText(context, 'البريد المرتبط بالحساب', 'Account email'),
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(email.isEmpty ? oursText(context, 'غير متاح', 'Not available') : email),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: saving ? null : saveProfile,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: navy,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(oursText(context, 'حفظ التغييرات', 'Save changes')),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  oursText(context, 'الإعدادات والخصوصية', 'Settings & privacy'),
                  style: TextStyle(color: gold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: quietMode,
                  activeColor: gold,
                  secondary: const Icon(Icons.notifications_off_outlined, color: gold),
                  title: Text(oursText(context, 'الوضع الهادئ', 'Quiet mode')),
                  subtitle: Text(oursText(context, 'كتم التنبيهات التي تصل أثناء استخدام التطبيق', 'Mute notifications while using the app'),
                      style: TextStyle(color: lavender)),
                  onChanged: (value) {
                    setState(() => quietMode = value);
                    savePreference('ours_quiet_mode', value);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: gold),
                  title: Text(oursText(context, 'لغة التطبيق', 'App language')),
                  subtitle: Text(languageCode == 'ar' ? 'العربية' : 'English'),
                  trailing: DropdownButton<String>(
                    value: languageCode,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'ar', child: Text('العربية')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: (value) async {
                      if (value == null) return;
                      setState(() => languageCode = value);
                      await OursAppSettings.setLanguage(value);
                    },
                  ),
                ),
                SwitchListTile(
                  value: confirmBeforeDelete,
                  activeColor: gold,
                  secondary: const Icon(Icons.delete_outline, color: gold),
                  title: Text(oursText(context, 'تأكيد الحذف', 'Confirm before deleting')),
                  subtitle: Text(oursText(context, 'الاحتفاظ بتأكيد قبل حذف العناصر', 'Ask before deleting items'),
                      style: TextStyle(color: lavender)),
                  onChanged: (value) {
                    setState(() => confirmBeforeDelete = value);
                    savePreference('ours_confirm_delete', value);
                  },
                ),
                settingsTile(
                  icon: Icons.password_rounded,
                  title: oursText(context, 'تغيير كلمة المرور', 'Change password'),
                  subtitle: oursText(context, 'حدّث كلمة مرور حسابك', 'Update your account password'),
                  onTap: changePassword,
                ),
                settingsTile(
                  icon: Icons.lock_outline,
                  title: oursText(context, 'مساحتك الخاصة', 'Your private space'),
                  subtitle: oursText(context, 'المحادثة والملفات مخصصة لأعضاء مساحتك فقط', 'Your private content is only visible to your connected partner'),
                ),
                settingsTile(
                  icon: Icons.people_outline,
                  title: oursText(context, 'عدد الأعضاء', 'Members'),
                  subtitle: oursText(context, 'كل مساحة في OURS مخصصة لشخصين فقط', 'Every OURS space is designed for two people'),
                ),
                settingsTile(
                  icon: Icons.info_outline,
                  title: oursText(context, 'حول OURS', 'About OURS'),
                  subtitle: 'YOUR PRIVATE UNIVERSE · الإصدار 1.0.0',
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: signOut,
                  icon: const Icon(Icons.logout),
                  label: Text(oursText(context, 'تسجيل الخروج', 'Log out')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: gold,
                    side: const BorderSide(color: gold),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ],
            ),
    );
  }
}

class AudioMessageBubble extends StatefulWidget {
  final String audioPath;
  final bool isMine;

  const AudioMessageBubble({
    super.key,
    required this.audioPath,
    required this.isMine,
  });

  @override
  State<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends State<AudioMessageBubble> {
  final AudioPlayer player = AudioPlayer();
  bool loadingUrl = false;

  Future<void> togglePlayback() async {
    if (player.state == PlayerState.playing) {
      await player.pause();
      return;
    }

    setState(() => loadingUrl = true);
    try {
      // Generate a fresh signed URL each time so long-open chats do not
      // attempt playback with an expired 15-minute URL.
      final url = await Supabase.instance.client.storage
          .from('duo-private')
          .createSignedUrl(widget.audioPath, 900);
      await player.play(UrlSource(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تشغيل الرسالة الصوتية')),
        );
      }
      debugPrint('Audio playback failed: $e');
    } finally {
      if (mounted) setState(() => loadingUrl = false);
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: player.onPlayerStateChanged,
      initialData: player.state,
      builder: (context, snapshot) {
        final playing = snapshot.data == PlayerState.playing;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: loadingUrl ? null : togglePlayback,
              icon: loadingUrl
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: gold,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      playing
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: gold,
                      size: 34,
                    ),
            ),
            const SizedBox(width: 6),
            Text(
              loadingUrl
                  ? 'جارٍ التحميل...'
                  : playing
                      ? 'تشغيل الرسالة...'
                      : 'رسالة صوتية',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        );
      },
    );
  }
}
