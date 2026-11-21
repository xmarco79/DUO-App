
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'notifications/ours_push_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'social/ours_home_page.dart';
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

class _OursChatTheme {
  final String id, titleAr, titleEn, detailAr, detailEn;
  final Color background, mine, partner, accent;
  final List<Color> mineGradient, partnerGradient;
  final IconData symbol;
  const _OursChatTheme(
    this.id, this.titleAr, this.titleEn, this.detailAr, this.detailEn,
    this.background, this.mine, this.partner, this.accent,
    this.mineGradient, this.partnerGradient, this.symbol,
  );
}

const _oursChatThemes = [
  _OursChatTheme('ours','نبض OURS','OURS Pulse','هوية نابضة بتدرجات ليلية ولمعة ذهبية','OURS signature with lively gradients and gold glows',
    Color(0xFF10101C),Color(0xFF3B285C),Color(0xFF241B36),Color(0xFFFFD66B),
    [Color(0xFF6D42A8),Color(0xFF39275D)],[Color(0xFF332345),Color(0xFF21182F)],Icons.all_inclusive_rounded),
  _OursChatTheme('aurora','أورورا لايف','Aurora Live','شفق متحرك بطيف فيروزي وأزرق','Vivid teal and blue aurora',
    Color(0xFF071A27),Color(0xFF147B82),Color(0xFF123D50),Color(0xFF75F1D6),
    [Color(0xFF20B7A6),Color(0xFF2368B7)],[Color(0xFF174D60),Color(0xFF0D2B3A)],Icons.auto_awesome),
  _OursChatTheme('flamenco','فلامنكو','Flamenco','مرجان ووردي بلمسة بنفسجية','Coral, rose and violet',
    Color(0xFF25101D),Color(0xFFB33C6D),Color(0xFF54233E),Color(0xFFFFA36D),
    [Color(0xFFE65370),Color(0xFF943C93)],[Color(0xFF6A2C55),Color(0xFF351C36)],Icons.wb_twilight),
  _OursChatTheme('bloom','بلوم','Bloom','وردي زاهي وموف ناعم','Vibrant pink and soft violet',
    Color(0xFF261322),Color(0xFFB34F8B),Color(0xFF4B2844),Color(0xFFFFC2DE),
    [Color(0xFFE36AA8),Color(0xFF9B5BDB)],[Color(0xFF623B5B),Color(0xFF35243D)],Icons.local_florist),
  _OursChatTheme('lagoon','بلو لاجون','Blue Lagoon','موج أزرق ولمعة سماوية','Blue waves and cyan glow',
    Color(0xFF061827),Color(0xFF167FB0),Color(0xFF123D58),Color(0xFF80E8FF),
    [Color(0xFF168FCA),Color(0xFF2558B5)],[Color(0xFF194B68),Color(0xFF0D2B43)],Icons.waves),
  _OursChatTheme('emerald','إميرالد','Emerald','أخضر زمردي ونعناع','Emerald and mint',
    Color(0xFF0C1D18),Color(0xFF168B67),Color(0xFF18473A),Color(0xFF91F5B8),
    [Color(0xFF20A879),Color(0xFF147B78)],[Color(0xFF285343),Color(0xFF17372F)],Icons.eco),
  _OursChatTheme('dreamscape','دريم سكيب','Dreamscape','بنفسجي كوني وتوهج ليلي','Cosmic violet glow',
    Color(0xFF100C2A),Color(0xFF7045D8),Color(0xFF342458),Color(0xFFD6B7FF),
    [Color(0xFF8D59F0),Color(0xFF4B39B6)],[Color(0xFF443B68),Color(0xFF282442)],Icons.nights_stay),
  _OursChatTheme('sundust','صن داست','Sun Dust','عنبر ونحاس وألوان غروب','Amber, copper and sunset',
    Color(0xFF241813),Color(0xFFB66B35),Color(0xFF4C3024),Color(0xFFFFDA87),
    [Color(0xFFD8873D),Color(0xFF9A4C39)],[Color(0xFF60452F),Color(0xFF35291F)],Icons.wb_sunny),
  _OursChatTheme('cyberpop','سايبر بوب','Cyber Pop','نيون فوشيا وسماوي','Neon fuchsia and cyan',
    Color(0xFF140A22),Color(0xFF8144C7),Color(0xFF36234D),Color(0xFF7CFFF1),
    [Color(0xFFB53ED1),Color(0xFF4C68DA)],[Color(0xFF3B315F),Color(0xFF24203F)],Icons.bolt),
];

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
            onPrimary: navy,
            secondary: lavender,
            onSecondary: navy,
            surface: purple,
            onSurface: Colors.white,
            error: Color(0xFFFF7777),
          ),
          useMaterial3: true,
          visualDensity: VisualDensity.standard,
          appBarTheme: const AppBarTheme(
            backgroundColor: navy,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: gold,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
            iconTheme: IconThemeData(color: lavender),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: purple.withValues(alpha: .58),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            labelStyle: const TextStyle(color: lavender),
            hintStyle: TextStyle(color: lavender.withValues(alpha: .65)),
            prefixIconColor: lavender,
            suffixIconColor: lavender,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: lavender.withValues(alpha: .24)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: lavender.withValues(alpha: .20)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: gold, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFFF7777)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFFF7777), width: 1.5),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: navy,
              disabledBackgroundColor: gold.withValues(alpha: .22),
              disabledForegroundColor: lavender.withValues(alpha: .65),
              minimumSize: const Size(48, 50),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: lavender,
              minimumSize: const Size(48, 48),
              side: BorderSide(color: lavender.withValues(alpha: .55)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: gold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: purple,
            contentTextStyle: const TextStyle(color: Colors.white),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: purple,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: purple,
            indicatorColor: lavender.withValues(alpha: .18),
            labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              color: states.contains(WidgetState.selected) ? gold : lavender,
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            )),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(color: gold),
          dividerTheme: DividerThemeData(color: lavender.withValues(alpha: .14), thickness: 1),
        ),
        home: const OursEntryGate(),
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
  StreamSubscription<AuthState>? authSubscription;

  @override
  void initState() {
    super.initState();
    authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedOut && mounted) {
        setState(() {
          showLogin = false;
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
          return OursSocialHomePage(
            onChatTap: (spaceId) => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ChatPage(spaceId: spaceId)),
            ),
            onProfileTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
            ),
          );
        }
        if (showLogin) return const LoginPage();
        return WelcomePage(
          onLogin: () => setState(() { showLogin = true; }),
        );
      },
    );
  }
}

class WelcomePage extends StatelessWidget {
  final VoidCallback onLogin;
  const WelcomePage({super.key, required this.onLogin});

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
                Text(oursText(context, 'مساحة رقمية خاصة تجمع naif و zoi للمحادثات والإبداع والموسيقى.', 'A private space for naif and zoi to chat, create, and enjoy music together.'),
                  textAlign: TextAlign.center, style: const TextStyle(color: lavender, height: 1.8, fontSize: 15)),
                const SizedBox(height: 38),
                SizedBox(width: double.infinity, height: 54,
                  child: OutlinedButton(onPressed: onLogin, style: OutlinedButton.styleFrom(foregroundColor: lavender, side: const BorderSide(color: lavender)),
                    child: Text(oursText(context, 'تسجيل الدخول', 'Log in')))),
                const SizedBox(height: 18),
                Text(oursText(context, 'الحسابان المعتمدان: naif و zoi فقط', 'The only accounts: naif and zoi'), textAlign: TextAlign.center, style: const TextStyle(color: gold, fontSize: 12, letterSpacing: 0.5)),
                const SizedBox(height: 10),
                Text(oursText(context, 'عالم خاص لشخصين فقط', 'A private world for two only'), style: const TextStyle(color: lavender, fontSize: 11, letterSpacing: 1.2)),
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
            onChatTap: (spaceId) => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ChatPage(spaceId: spaceId)),
            ),
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
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();

  bool loading = false;

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
      final raw = e.toString().toLowerCase();
      final message = raw.contains('invalid login') || raw.contains('invalid credentials') || raw.contains('password')
          ? oursText(context, 'اسم المستخدم أو كلمة المرور غير صحيحة', 'Username or password is incorrect')
          : raw.contains('socket') || raw.contains('network') || raw.contains('connection') || raw.contains('timeout')
              ? oursText(context, 'تعذر الاتصال بالخادم. تحقق من الإنترنت وحاول مجددًا.', 'Could not connect. Check your internet and retry.')
              : oursText(context, 'تعذر تسجيل الدخول الآن. حاول مرة أخرى.', 'Login failed. Please try again.');
      showMessage(message);
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
                  oursText(context, 'مرحبًا بعودتك', 'Welcome back'),
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: username,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: oursText(context, 'اسم المستخدم', 'Username'),
                    hintText: 'naif / zoi',
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
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: loading ? null : login,
                    child: loading
                        ? const CircularProgressIndicator(
                            color: navy,
                          )
                        : Text(
                            oursText(context, 'تسجيل الدخول', 'Log in'),
                          ),
                  ),
                ),
                const SizedBox(height: 18),
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
  _OursChatTheme chatTheme = _oursChatThemes.first;

  RealtimeChannel? channel;
  RealtimeChannel? presenceChannel;
  bool partnerOnline = false;

  String get currentUserId => db.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    loadMessages();
    loadChatTheme();
    loadQuietMode();
    loadParticipantNames();
    listenToMessages();
    listenToPresence();
  }

  Future<void> loadChatTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('ours_chat_theme_${currentUserId}') ?? 'ours';
    final selected = _oursChatThemes.where((theme) => theme.id == id);
    if (mounted) setState(() => chatTheme = selected.isEmpty ? _oursChatThemes.first : selected.first);
  }

  Future<void> chooseChatTheme() async {
    final selected = await showModalBottomSheet<_OursChatTheme>(
      context: context,
      backgroundColor: const Color(0xFF171326),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.68,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(oursText(context, 'اختر أجواء محادثتكما', 'Choose your chat atmosphere'),
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(oursText(context, 'كل ثيم له خلفية وفقاعات وألوانه الخاصة', 'Every theme has its own mood, bubbles and colors'),
                  style: const TextStyle(color: lavender, fontSize: 12)),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    itemCount: _oursChatThemes.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, childAspectRatio: 1.32,
                      crossAxisSpacing: 11, mainAxisSpacing: 11,
                    ),
                    itemBuilder: (context, index) {
                      final theme = _oursChatThemes[index];
                      final active = chatTheme.id == theme.id;
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.pop(sheetContext, theme),
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [theme.background, theme.partner], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: active ? theme.accent : theme.accent.withValues(alpha: .28), width: active ? 2 : 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(theme.symbol, color: theme.accent, size: 19),
                                const Spacer(),
                                if (active) Icon(Icons.check_circle_rounded, color: theme.accent, size: 19),
                              ]),
                              const Spacer(),
                              Align(alignment: AlignmentDirectional.centerEnd, child: Container(
                                width: 76, height: 22, decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: theme.mineGradient),
                                  borderRadius: const BorderRadiusDirectional.only(topStart: Radius.circular(12), bottomStart: Radius.circular(12), bottomEnd: Radius.circular(12)),
                                ),
                              )),
                              const SizedBox(height: 5),
                              Align(alignment: AlignmentDirectional.centerStart, child: Container(
                                width: 62, height: 19, decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: theme.partnerGradient),
                                  borderRadius: const BorderRadiusDirectional.only(topEnd: Radius.circular(12), bottomStart: Radius.circular(12), bottomEnd: Radius.circular(12)),
                                  border: Border.all(color: theme.accent.withValues(alpha: .24)),
                                ),
                              )),
                              const SizedBox(height: 9),
                              Text(oursText(context, theme.titleAr, theme.titleEn),
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                              Text(oursText(context, theme.detailAr, theme.detailEn),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: theme.accent.withValues(alpha: .9), fontSize: 9)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => chatTheme = selected);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ours_chat_theme_${currentUserId}', selected.id);
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

  Future<void> _showMessageActions(Map<String, dynamic> item, bool isMine) async {
    if (item['deleted_at'] != null) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: chatTheme.partner,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(Icons.reply_rounded, color: chatTheme.accent),
            title: Text(oursText(context, 'الرد على الرسالة', 'Reply')),
            onTap: () => Navigator.pop(sheetContext, 'reply'),
          ),
          if (item['message_type'] == 'text')
            ListTile(
              leading: Icon(Icons.copy_rounded, color: chatTheme.accent),
              title: Text(oursText(context, 'نسخ النص', 'Copy text')),
              onTap: () => Navigator.pop(sheetContext, 'copy'),
            ),
          if (isMine)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: Text(oursText(context, 'حذف الرسالة', 'Delete message')),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
        ]),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'reply') _replyToMessage(item);
    if (action == 'copy') await _copyMessage(item['body']?.toString() ?? '');
    if (action == 'delete') await _deleteMessage(item);
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
      return DateFormat(Localizations.localeOf(context).languageCode == 'ar' ? 'HH:mm' : 'h:mm a').format(date);
    } catch (_) {
      return '';
    }
  }

  bool _sameChatDay(dynamic first, dynamic second) {
    final a = DateTime.tryParse(first?.toString() ?? '')?.toLocal();
    final b = DateTime.tryParse(second?.toString() ?? '')?.toLocal();
    return a != null && b != null && a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatChatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) return oursText(context, 'اليوم', 'Today');
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) return oursText(context, 'أمس', 'Yesterday');
    return DateFormat('d MMM yyyy', Localizations.localeOf(context).languageCode).format(date);
  }

  Future<void> _copyMessage(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    showMessage(oursText(context, 'تم نسخ الرسالة', 'Message copied'));
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
      backgroundColor: chatTheme.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: chatTheme.accent.withValues(alpha: .18),
              child: Text(
                partnerName.isNotEmpty ? partnerName.substring(0, 1).toUpperCase() : 'O',
                style: TextStyle(color: chatTheme.accent, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(partnerName, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 7, height: 7, decoration: BoxDecoration(
                      color: partnerOnline ? const Color(0xFF61D69A) : Colors.grey,
                      shape: BoxShape.circle,
                    )),
                    const SizedBox(width: 5),
                    Text(
                      partnerOnline ? oursText(context, 'متصل الآن', 'online') : oursText(context, 'غير متصل', 'offline'),
                      style: TextStyle(color: chatTheme.accent, fontSize: 10),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: chatTheme.background,
        actions: [
          IconButton(
            tooltip: 'مظهر المحادثة',
            onPressed: chooseChatTheme,
            icon: const Icon(Icons.palette_outlined, color: gold),
          ),
          IconButton(
            tooltip: 'البحث في المحادثة',
            onPressed: showMessageSearch,
            icon: Icon(
              Icons.search,
              color: searchQuery.isEmpty ? gold : Colors.lightGreenAccent,
            ),
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

                          final showDate = index == 0 ||
                              !_sameChatDay(displayedMessages[index - 1]['created_at'], item['created_at']);
                          final groupedWithPrevious = index > 0 &&
                              !showDate &&
                              displayedMessages[index - 1]['sender_id'] == item['sender_id'];
                          final previousMessageTime = index > 0
                              ? DateTime.tryParse(displayedMessages[index - 1]['created_at']?.toString() ?? '')
                              : null;
                          final currentMessageTime = DateTime.tryParse(item['created_at']?.toString() ?? '');
                          final showGapTime = previousMessageTime != null &&
                              currentMessageTime != null &&
                              currentMessageTime.difference(previousMessageTime) > const Duration(minutes: 5);
                          final isImageMessage = item['message_type'] == 'image';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showDate)
                                Center(
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 8, bottom: 14),
                                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: chatTheme.partner.withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: chatTheme.accent.withValues(alpha: 0.18)),
                                    ),
                                    child: Text(_formatChatDate(item['created_at']), style: TextStyle(color: chatTheme.accent, fontSize: 10)),
                                  ),
                                ),
                              if (showGapTime)
                                Center(
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10, top: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: chatTheme.partner.withValues(alpha: 0.78),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: chatTheme.accent.withValues(alpha: 0.16)),
                                    ),
                                    child: Text(_formatMessageTime(item['created_at']),
                                      style: TextStyle(color: chatTheme.accent, fontSize: 10, fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              Align(
                            alignment: isMe
                                ? AlignmentDirectional.centerEnd
                                : AlignmentDirectional.centerStart,
                            child: GestureDetector(
                              onLongPress: () => _showMessageActions(item, isMe),
                              child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.80,
                              ),
                              margin: EdgeInsets.only(bottom: groupedWithPrevious ? 4 : 12),
                              padding: isImageMessage ? EdgeInsets.zero : const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: isImageMessage ? null : BoxDecoration(
                                gradient: LinearGradient(colors: isMe ? chatTheme.mineGradient : chatTheme.partnerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(19),
                                  topRight: const Radius.circular(19),
                                  bottomLeft: Radius.circular(isMe ? 19 : 5),
                                  bottomRight: Radius.circular(isMe ? 5 : 19),
                                ),
                                border: Border.all(color: chatTheme.accent.withValues(alpha: 0.18)),
                              ),
                              child: IntrinsicWidth(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isMe && !groupedWithPrevious)
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
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: chatTheme.background.withValues(alpha: 0.65),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border(left: BorderSide(color: chatTheme.accent, width: 3)),
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
                                                SizedBox(
                                              width: 220,
                                              height: 120,
                                              child: Center(
                                                child: TextButton.icon(
                                                  onPressed: () {
                                                    final imagePath = item['body']?.toString() ?? '';
                                                    signedImageUrls.remove(imagePath);
                                                    if (mounted) setState(() {});
                                                  },
                                                  icon: const Icon(Icons.refresh_rounded, color: gold),
                                                  label: const Text('إعادة تحميل الصورة', style: TextStyle(color: lavender)),
                                                ),
                                              ),
                                            ),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  else
                                    SelectableText(
                                      item['body']?.toString() ?? '',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                                    ),
                                  if (item['deleted_at'] == null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: OursMessageReactions(
                                        messageId: item['id'].toString(),
                                        spaceId: widget.spaceId,
                                      ),
                                    ),
                                  if (!isImageMessage && item['deleted_at'] == null)
                                    const SizedBox(height: 4),
                                ],
                              ),
                            ),
                            ),
                            ),
                          ),
                            ],
                          );
                        },
                      ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [chatTheme.mine.withValues(alpha: 0.96), chatTheme.background], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24), bottom: Radius.circular(20)),
              border: Border.all(color: chatTheme.accent.withValues(alpha: 0.20)),
              boxShadow: [BoxShadow(color: chatTheme.accent.withValues(alpha: 0.06), blurRadius: 18, spreadRadius: 1)],
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
                      fillColor: chatTheme.partner,
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
  DateTime? birthDate;
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
      if (user == null) throw Exception(oursText(context, 'انتهت جلسة تسجيل الدخول', 'Your session has expired'));

      email = user.email ?? '';
      final profile = await db
          .from('duo_profiles')
          .select('username, display_name, avatar_path, bio, birth_date')
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;
      username = profile?['username']?.toString() ?? '';
      final avatarPath = profile?['avatar_path']?.toString();
      avatarUrl = avatarPath == null ? null : db.storage.from('ours-avatars').getPublicUrl(avatarPath);
      displayNameController.text =
          profile?['display_name']?.toString() ?? '';
      bioController.text = profile?['bio']?.toString() ?? '';
      final birthRaw = profile?['birth_date']?.toString();
      birthDate = birthRaw == null ? null : DateTime.tryParse(birthRaw);
      setState(() => loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      showMessage(oursText(context, 'تعذر تحميل الملف الشخصي. تحقق من الاتصال ثم أعد المحاولة.', 'Could not load profile. Check your connection and retry.'));
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
              title: Text(oursText(context, 'اختيار من المعرض', 'Choose from gallery')),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: gold),
              title: Text(oursText(context, 'التقاط صورة بالكاميرا', 'Take a photo')),
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
      if (user == null) throw Exception(oursText(context, 'انتهت جلسة تسجيل الدخول', 'Your session has expired'));
      setState(() => uploadingAvatar = true);
      final extension = picked.name.split('.').last.toLowerCase();
      final safeExtension = ['jpg', 'jpeg', 'png', 'webp'].contains(extension) ? extension : 'jpg';
      final oldProfile = await db.from('duo_profiles').select('avatar_path').eq('user_id', user.id).maybeSingle();
      final oldPath = oldProfile?['avatar_path']?.toString();
      final path = '${user.id}/avatar_${DateTime.now().microsecondsSinceEpoch}.$safeExtension';
      final bytes = await picked.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) throw Exception(oursText(context, 'حجم الصورة يتجاوز 5 ميجابايت', 'Image exceeds 5 MB'));
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
      showMessage(oursText(context, 'تم تحديث الصورة الشخصية', 'Profile photo updated'));
    } catch (e) {
      showMessage(oursText(context, 'تعذر تحديث الصورة الشخصية. حاول مرة أخرى.', 'Could not update profile photo. Please retry.'));
    } finally {
      if (mounted) setState(() => uploadingAvatar = false);
    }
  }

  Future<void> saveProfile() async {
    final value = displayNameController.text.trim();
    if (value.length > 30) {
      showMessage(oursText(context, 'الاسم الظاهر يجب ألا يتجاوز 30 حرفًا', 'Display name must be 30 characters or less'));
      return;
    }

    final userId = db.auth.currentUser?.id;
    if (userId == null) {
      showMessage(oursText(context, 'انتهت جلسة تسجيل الدخول', 'Your session has expired'));
      return;
    }

    setState(() => saving = true);
    try {
      final bio = bioController.text.trim();
      if (bio.length > 160) {
        showMessage(oursText(context, 'النبذة يجب ألا تتجاوز 160 حرفًا', 'Bio must be 160 characters or less'));
        return;
      }
      await db
          .from('duo_profiles')
          .update({
            'display_name': value.isEmpty ? null : value,
            'bio': bio,
            'birth_date': birthDate?.toIso8601String().split('T').first,
          })
          .eq('user_id', userId)
          .select('user_id')
          .single();

      if (!mounted) return;
      showMessage(oursText(context, 'تم حفظ الملف الشخصي', 'Profile saved'));
    } catch (e) {
      showMessage(oursText(context, 'تعذر حفظ التغييرات. تحقق من الاتصال وحاول مجددًا.', 'Could not save changes. Check your connection and retry.'));
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
        title: Text(oursText(context, 'تسجيل الخروج', 'Log out')),
        content: Text(oursText(context, 'هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟', 'Are you sure you want to log out?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(oursText(context, 'إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(oursText(context, 'تسجيل الخروج', 'Log out'))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await OursPushService.unregisterCurrentToken();
                await db.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      showMessage(oursText(context, 'تعذر تسجيل الخروج. حاول مرة أخرى.', 'Could not log out. Please retry.'));
    }
  }

  Future<void> changePassword() async {
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: purple,
        title: Text(oursText(context, 'تغيير كلمة المرور', 'Change password')),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
            labelText: oursText(context, 'كلمة المرور الجديدة', 'New password'),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(oursText(context, 'إلغاء', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(oursText(context, 'حفظ', 'Save')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (password == null) return;
    if (password.length < 8) {
      showMessage(oursText(context, 'كلمة المرور يجب أن تكون 8 أحرف على الأقل', 'Password must be at least 8 characters'));
      return;
    }
    try {
      await db.auth.updateUser(UserAttributes(password: password));
      showMessage(oursText(context, 'تم تحديث كلمة المرور', 'Password updated'));
    } catch (e) {
      showMessage(oursText(context, 'تعذر تغيير كلمة المرور. تحقق من اتصالك وحاول مجددًا.', 'Could not change password. Check your connection and retry.'));
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

  Widget sectionTitle(String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: gold.withOpacity(0.18)),
            ),
            child: Icon(icon, color: gold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: gold, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: lavender, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget settingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: purple.withOpacity(0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withOpacity(0.12)),
      ),
      child: Column(children: children),
    );
  }

  Widget settingsRow({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    Color? iconColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? gold).withOpacity(0.10),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: iconColor ?? gold, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(subtitle, style: const TextStyle(color: lavender, fontSize: 11, height: 1.35)),
      ),
      trailing: trailing ?? (onTap == null ? null : const Icon(Icons.chevron_right_rounded, color: lavender)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = displayNameController.text.trim();
    final accountTitle = displayName.isNotEmpty
        ? displayName
        : (username.isNotEmpty ? '@$username' : oursText(context, 'حساب OURS', 'OURS account'));

    return Scaffold(
      backgroundColor: navy,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: navy,
        centerTitle: false,
        title: Text(
          oursText(context, 'الإعدادات', 'Settings'),
          style: const TextStyle(color: gold, fontSize: 19, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: oursText(context, 'تحديث البيانات', 'Refresh account'),
            onPressed: loading ? null : () {
              setState(() => loading = true);
              loadProfile();
              loadPreferences();
            },
            icon: const Icon(Icons.refresh_rounded, color: lavender),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [purple, navy.withOpacity(0.96)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: gold.withOpacity(0.24)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: uploadingAvatar ? null : chooseAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 34,
                              backgroundColor: navy,
                              backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl!),
                              child: avatarUrl == null ? const Icon(Icons.person_rounded, color: gold, size: 34) : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 23,
                                height: 23,
                                decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
                                child: uploadingAvatar
                                    ? const Padding(
                                        padding: EdgeInsets.all(5),
                                        child: CircularProgressIndicator(strokeWidth: 2, color: navy),
                                      )
                                    : const Icon(Icons.edit_rounded, color: navy, size: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(accountTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(email.isEmpty ? oursText(context, 'البريد غير متاح', 'Email unavailable') : email,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: lavender, fontSize: 11)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: gold.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: gold.withOpacity(0.22)),
                              ),
                              child: Text(
                                username.isEmpty ? 'OURS · PRIVATE ACCOUNT' : '@$username  ·  OURS',
                                style: const TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                sectionTitle(
                  oursText(context, 'الملف الشخصي', 'Profile'),
                  oursText(context, 'عدّل المعلومات التي تظهر لشريكك', 'Manage the details your partner sees'),
                  Icons.person_outline_rounded,
                ),
                settingsCard(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: TextField(
                      controller: displayNameController,
                      maxLength: 30,
                      decoration: InputDecoration(
                        labelText: oursText(context, 'الاسم الظاهر', 'Display name'),
                        hintText: oursText(context, 'اكتب اسمك', 'Enter your name'),
                        prefixIcon: const Icon(Icons.badge_outlined),
                        filled: true,
                        fillColor: navy.withOpacity(0.6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        counterStyle: const TextStyle(color: lavender, fontSize: 10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cake_outlined),
                      label: Text(birthDate == null
                        ? oursText(context, 'إضافة تاريخ الميلاد', 'Add birthday')
                        : oursText(context, 'تاريخ الميلاد: ${DateFormat('yyyy/MM/dd').format(birthDate!)}', 'Birthday: ${DateFormat('yyyy/MM/dd').format(birthDate!)}')),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: birthDate ?? DateTime(2008, 1, 1),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null && mounted) setState(() => birthDate = picked);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    child: TextField(
                      controller: bioController,
                      maxLength: 160,
                      minLines: 2,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: oursText(context, 'نبذة شخصية', 'About you'),
                        hintText: oursText(context, 'مساحة صغيرة تعبّر عنك', 'A short introduction'),
                        prefixIcon: const Icon(Icons.notes_rounded),
                        filled: true,
                        fillColor: navy.withOpacity(0.6),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        counterStyle: const TextStyle(color: lavender, fontSize: 10),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: saving ? null : saveProfile,
                        icon: saving
                            ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: navy))
                            : const Icon(Icons.check_rounded),
                        label: Text(oursText(context, 'حفظ الملف الشخصي', 'Save profile')),
                      ),
                    ),
                  ),
                ]),

                sectionTitle(
                  oursText(context, 'التفضيلات', 'Preferences'),
                  oursText(context, 'تحكّم بتجربة استخدام OURS', 'Make OURS work the way you like'),
                  Icons.tune_rounded,
                ),
                settingsCard(children: [
                  settingsRow(
                    icon: Icons.notifications_off_outlined,
                    title: oursText(context, 'الوضع الهادئ', 'Quiet mode'),
                    subtitle: oursText(context, 'كتم التنبيهات أثناء استخدام التطبيق', 'Mute notifications while using the app'),
                    trailing: Switch(
                      value: quietMode,
                      activeColor: gold,
                      onChanged: (value) async {
                        setState(() => quietMode = value);
                        await savePreference('ours_quiet_mode', value);
                      },
                    ),
                  ),
                  Divider(height: 1, indent: 68, color: gold.withOpacity(0.10)),
                  settingsRow(
                    icon: Icons.language_rounded,
                    title: oursText(context, 'لغة التطبيق', 'App language'),
                    subtitle: languageCode == 'ar' ? 'العربية' : 'English',
                    trailing: DropdownButton<String>(
                      value: languageCode,
                      underline: const SizedBox.shrink(),
                      dropdownColor: purple,
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
                  Divider(height: 1, indent: 68, color: gold.withOpacity(0.10)),
                  settingsRow(
                    icon: Icons.delete_outline_rounded,
                    title: oursText(context, 'تأكيد الحذف', 'Confirm before deleting'),
                    subtitle: oursText(context, 'اطلب تأكيدًا قبل حذف العناصر', 'Ask before deleting items'),
                    trailing: Switch(
                      value: confirmBeforeDelete,
                      activeColor: gold,
                      onChanged: (value) async {
                        setState(() => confirmBeforeDelete = value);
                        await savePreference('ours_confirm_delete', value);
                      },
                    ),
                  ),
                ]),

                sectionTitle(
                  oursText(context, 'الأمان والخصوصية', 'Security & privacy'),
                  oursText(context, 'حسابك ومساحتكما الخاصة', 'Your account and private space'),
                  Icons.shield_outlined,
                ),
                settingsCard(children: [
                  settingsRow(
                    icon: Icons.password_rounded,
                    title: oursText(context, 'تغيير كلمة المرور', 'Change password'),
                    subtitle: oursText(context, 'استخدم كلمة مرور قوية وخاصة', 'Keep your account protected'),
                    onTap: changePassword,
                  ),
                  Divider(height: 1, indent: 68, color: gold.withOpacity(0.10)),
                  settingsRow(
                    icon: Icons.lock_outline_rounded,
                    title: oursText(context, 'مساحتك الخاصة', 'Your private space'),
                    subtitle: oursText(context, 'محتوى OURS مخصص لك ولشريكك فقط', 'Your OURS content is only for you and your partner'),
                  ),
                  Divider(height: 1, indent: 68, color: gold.withOpacity(0.10)),
                  settingsRow(
                    icon: Icons.people_alt_outlined,
                    title: oursText(context, 'حد الأعضاء', 'Member limit'),
                    subtitle: oursText(context, 'حسابان فقط في كل مساحة', 'Exactly two accounts per space'),
                    trailing: const Text('2 / 2', style: TextStyle(color: gold, fontWeight: FontWeight.w700)),
                  ),
                ]),

                sectionTitle(
                  oursText(context, 'حول التطبيق', 'About the app'),
                  oursText(context, 'معلومات عن تجربتك مع OURS', 'Your OURS experience'),
                  Icons.info_outline_rounded,
                ),
                settingsCard(children: [
                  settingsRow(
                    icon: Icons.all_inclusive_rounded,
                    title: 'OURS',
                    subtitle: 'YOUR PRIVATE UNIVERSE',
                    trailing: const Text('1.0.0', style: TextStyle(color: lavender, fontSize: 12)),
                  ),
                ]),

                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: signOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(oursText(context, 'تسجيل الخروج من الحساب', 'Sign out of account')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.55)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text('MADE FOR TWO  ·  OURS',
                    style: TextStyle(color: lavender.withOpacity(0.65), fontSize: 10, letterSpacing: 2)),
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
