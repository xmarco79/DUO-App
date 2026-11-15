
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const navy = Color(0xFF10101C);
const purple = Color(0xFF29213D);
const lavender = Color(0xFFB9A2D5);
const gold = Color(0xFFD9BC86);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://sthlcrgwpzqhxtpevqwg.supabase.co',
    anonKey: 'sb_publishable_xUgF7Wh8fE4wMpuZSrROwA_DNdPJKGM',
  );

  runApp(const OursApp());
}

class OursApp extends StatelessWidget {
  const OursApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OURS',
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
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  Future<void> login() async {
    setState(() => loading = true);

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'duo-username-login',
        body: {
          'username': username.text.trim(),
          'password': password.text,
        },
      );

      final data = Map<String, dynamic>.from(response.data);

      if (response.status != 200) {
        throw Exception(data['error'] ?? 'تعذر تسجيل الدخول');
      }

      await Supabase.instance.client.auth.setSession(
        data['refresh_token'],
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                const Icon(Icons.all_inclusive, size: 76, color: gold),
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
                const SizedBox(height: 55),
                const Text(
                  'مرحبًا بعودتك',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: username,
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
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
                        ? const CircularProgressIndicator()
                        : const Text('تسجيل الدخول'),
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = false;
  String? inviteCode;

  final codeController = TextEditingController();

  SupabaseClient get db => Supabase.instance.client;

  Future<void> createSpace() async {
    setState(() => loading = true);

    try {
      await db.rpc('create_duo_space');
      final code = await db.rpc('create_duo_invite');

      setState(() => inviteCode = code.toString());
    } catch (e) {
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
      await db.rpc(
        'redeem_duo_invite',
        params: {'p_code': code},
      );

      message('تم الانضمام إلى المساحة بنجاح');
    } catch (e) {
      message('تعذر الانضمام: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
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
          style: TextStyle(color: gold, letterSpacing: 5),
        ),
        centerTitle: true,
        backgroundColor: navy,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await db.auth.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.nights_stay, color: gold, size: 65),
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
                actionCard(
                  icon: Icons.add_circle_outline,
                  title: 'إنشاء مساحة جديدة',
                  subtitle: 'أنشئ عالمك الخاص وأرسل رمز الدعوة',
                  onTap: loading ? null : createSpace,
                ),
                const SizedBox(height: 18),
                actionCard(
                  icon: Icons.vpn_key_outlined,
                  title: 'الانضمام إلى مساحة',
                  subtitle: 'أدخل رمز الدعوة الذي وصلك',
                  onTap: () => showJoinDialog(),
                ),
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
              ],
            ),
          ),
        ),
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
        leading: Icon(icon, color: gold, size: 32),
        title: Text(title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            subtitle,
            style: const TextStyle(color: lavender),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: gold),
        onTap: onTap,
      ),
    );
  }

  void showJoinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: purple,
        title: const Text('الانضمام إلى مساحة'),
        content: TextField(
          controller: codeController,
          maxLength: 8,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'رمز الدعوة',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: loading
                ? null
                : () {
                    Navigator.pop(context);
                    joinSpace();
                  },
            child: const Text('انضمام'),
          ),
        ],
      ),
    );
  }
}
