
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://sthlcrgwpzqhxtpevqwg.supabase.co',
    anonKey: 'sb_publishable_xUgF7Wh8fE4wMpuZSrROwA_DNdPJKGM',
  );

  runApp(const DuoApp());
}

class DuoApp extends StatelessWidget {
  const DuoApp({super.key});

  static const Color background = Color(0xFF101010);
  static const Color champagne = Color(0xFFD6B878);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DUO',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: champagne,
          surface: Color(0xFF1B1B1B),
        ),
        useMaterial3: true,
      ),
      home: const DuoHomePage(),
    );
  }
}

class DuoHomePage extends StatelessWidget {
  const DuoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  color: DuoApp.champagne,
                  size: 58,
                ),
                const SizedBox(height: 22),
                const Text(
                  'DUO',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 12,
                    color: DuoApp.champagne,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'YOUR PRIVATE UNIVERSE',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 3,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 55),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B1B1B),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: DuoApp.champagne.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: DuoApp.champagne,
                        size: 34,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'مساحتك الخاصة تبدأ هنا',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 9),
                      Text(
                        'عالم صغير يجمع شخصين فقط.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                    ],
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
