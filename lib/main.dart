
import 'dart:async';
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

// The entry gate remains mounted so auth changes always route to the right screen.
class OursEntryGate extends StatefulWidget {
  const OursEntryGate({super.key});
  @override
  State<OursEntryGate> createState() => _OursEntryGateState();
}

class _OursEntryGateState extends State<OursEntryGate> {
  bool showLogin = false;
  bool creatingAccount = false;
  StreamSubscription<AuthState>? authSubscription;

  @override
  void initState() {
    super.initState();
    authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedOut && mounted) {
        setState(() {
          showLogin = false;
          creatingAccount = false;
        });
      }
    });
  }

  @override
  void dispose() {
    authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth;
    return StreamBuilder<AuthState>(
      stream: auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;
        if (session != null) {
          return const OursLockedPreviewPage();
          // The full social home remains unchanged on the stable branch.
        }
        if (false) {
          return OursSocialHomePage(
            onProfileTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
            ),
          );
        }
        if (showLogin) return LoginPage(initialCreatingAccount: creatingAccount);
        return WelcomePage(
          onLogin: () => setState(() { showLogin = true; creatingAccount = false; }),
          onRegister: () => setState(() { showLogin = true; creatingAccount = true; }),
        );
      },
    );
  }
}

class OursLockedPreviewPage extends StatelessWidget {
  const OursLockedPreviewPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(oursText(context, 'تعذر تسجيل الخروج، حاول مرة أخرى', 'Could not sign out. Please try again.'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 142,
                  height: 142,
                  decoration: BoxDecoration(
                    color: purple.withValues(alpha: .58),
                    shape: BoxShape.circle,
                    border: Border.all(color: lavender.withValues(alpha: .28)),
                    boxShadow: [
                      BoxShadow(color: lavender.withValues(alpha: .10), blurRadius: 34, spreadRadius: 4),
                    ],
                  ),
                  child: const Icon(Icons.lock_clock_rounded, color: gold, size: 72),
                ),
                const SizedBox(height: 30),
                const Text(
                  'OURS',
                  style: TextStyle(color: gold, fontSize: 38, letterSpacing: 10, fontWeight: FontWeight.w300),
                ),
                const SizedBox(height: 18),
                Text(
                  isArabic ? 'عالمك الخاص قيد التجهيز' : 'Your private universe is getting ready',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                Text(
                  isArabic
                      ? 'شكرًا لانضمامك إلى OURS. نعمل حاليًا على تجهيز تجربتك، وسيتم فتح التطبيق عند اكتمال التطوير.'
                      : 'Thanks for joining OURS. We are preparing your experience. The app will open when development is complete.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: lavender, fontSize: 15, height: 1.9),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    color: purple,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: gold.withValues(alpha: .35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.construction_rounded, color: gold, size: 18),
                      const SizedBox(width: 9),
                      Text(
                        isArabic ? 'قيد التطوير' : 'Under development',
                        style: const TextStyle(color: gold, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 42),
                TextButton.icon(
                  onPressed: () => _signOut(context),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(isArabic ? 'تسجيل الخروج' : 'Sign out'),
                  style: TextButton.styleFrom(foregroundColor: lavender),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                  child: FilledButton(onPressed: onRegister, child: Text(oursText(context, 'إنشاء حساب', 'Create account')))),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, height: 54,                  child: OutlinedButton(onPressed: onLogin, style: OutlinedButton.styleFrom(foregroundColor: lavender, side: const BorderSide(color: lavender)),
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
      showMessage(oursText(context, 'أدخل اسم المستخدم وكلمة المرور', 'Enter your username and password'));
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
        throw Exception(data['error'] ?? oursText(context, 'تعذر تسجيل الدخول', 'Could not log in'));
      }

      final refreshToken = data['refresh_token'];

      if (refreshToken == null) {
        throw Exception(oursText(context, 'لم يتم استلام بيانات الجلسة', 'Session data was not received'));
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
      showMessage(oursText(
        context,
        'اسم المستخدم يجب أن يكون من 3 إلى 20 حرفًا، ويحتوي على أحرف إنجليزية أو أرقام أو _ فقط',
        'Username must be 3–20 characters using English letters, numbers, or _ only',
      ));
      return;
    }

    if (pass.length < 8) {
      showMessage(oursText(context, 'كلمة المرور يجب أن تكون 8 أحرف على الأقل', 'Password must be at least 8 characters'));
      return;
    }

    if (pass != confirm) {
      showMessage(oursText(context, 'كلمتا المرور غير متطابقتين', 'Passwords do not match'));
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
        throw Exception(data['error'] ?? oursText(context, 'تعذر إنشاء الحساب', 'Could not create account'));
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
          loginData['error'] ?? oursText(context, 'تم إنشاء الحساب، تعذر تسجيل الدخول', 'Account created, but login failed'),
        );
      }

      final refreshToken = loginData['refresh_token'];

      if (refreshToken == null) {
        throw Exception(oursText(context, 'لم يتم استلام بيانات الجلسة', 'Session data was not received'));
      }

      await db.auth.setSession(refreshToken);

      if (!mounted) return;

      // OursAuthGate observes the authenticated session and opens HomePage.
    } catch (e) {
      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {        setState(() => loading = false);
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
                    hintText: 'e.g. ours_user',
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
                  Text(
                    oursText(context, 'اسم المستخدم: أحرف إنجليزية وأرقام و _ فقط', 'Username: English letters, numbers and _ only'),
                    style: TextStyle(
                      color: lavender,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    oursText(context, 'كلمة المرور: 8 أحرف على الأقل', 'Password: at least 8 characters'),
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
    } catch (e) {      if (!mounted) return;
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
            child: Text(oursText(context, 'إلغاء', 'Cancel')),
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
                  title: Text(oursText(context, 'تسجيل الخروج', 'Log out')),
                  content: Text(oursText(context, 'هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟', 'Are you sure you want to log out?')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(oursText(context, 'إلغاء', 'Cancel'))),
                    FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(oursText(context, 'تسجيل الخروج', 'Log out'))),
                  ],                ),
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

  RealtimeChannel? channel;  RealtimeChannel? presenceChannel;
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
            setState(() {              final index = messages.indexWhere((item) => item['id'] == updated['id']);
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
            child: Text(oursText(context, 'إلغاء', 'Cancel')),
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

    return future;  }


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
        ),        actions: [
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