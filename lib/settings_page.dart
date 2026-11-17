import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_preferences.dart';

const _navy = Color(0xFF10101C);
const _purple = Color(0xFF29213D);
const _lavender = Color(0xFFB9A2D5);
const _gold = Color(0xFFD9BC86);

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final db = Supabase.instance.client;
  final displayName = TextEditingController();
  final bio = TextEditingController();
  bool loading = true;
  bool saving = false;
  String username = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = db.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => loading = false);
      return;
    }
    try {
      final row = await db.from('duo_profiles')
          .select('username,display_name,bio')
          .eq('user_id', user.id).maybeSingle();
      if (!mounted) return;
      displayName.text = row?['display_name']?.toString() ?? '';
      bio.text = row?['bio']?.toString() ?? '';
      username = row?['username']?.toString() ?? '';
    } catch (e) {
      _show('تعذر تحميل الملف الشخصي: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = db.auth.currentUser;
    if (user == null || saving) return;
    if (displayName.text.trim().length > 40 || bio.text.trim().length > 160) {
      _show('الاسم 40 حرفًا كحد أقصى، والنبذة 160 حرفًا.');
      return;
    }
    setState(() => saving = true);
    try {
      await db.from('duo_profiles').update({
        'display_name': displayName.text.trim(),
        'bio': bio.text.trim(),
      }).eq('user_id', user.id);
      _show('تم حفظ الملف الشخصي.');
    } catch (e) {
      _show('تعذر حفظ التغييرات: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _setDarkMode(bool value) async {
    AppPreferences.themeMode.value = value ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ours_dark_theme', value);
  }

  void _show(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  @override
  void dispose() {
    displayName.dispose();
    bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = db.auth.currentUser;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('الإعدادات', style: TextStyle(color: _gold)),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: _gold))
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _purple,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _gold.withOpacity(.22)),
                  ),
                  child: Row(children: [
                    const CircleAvatar(
                      radius: 27,
                      backgroundColor: _navy,
                      child: Icon(Icons.person, color: _gold, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('OURS', style: TextStyle(color: _gold, fontSize: 19)),
                        Text('@$username', style: const TextStyle(color: _lavender)),
                      ],
                    )),
                  ]),
                ),
                const SizedBox(height: 22),
                const Text('الملف الشخصي', style: TextStyle(color: _gold, fontSize: 16)),
                const SizedBox(height: 10),
                TextField(
                  controller: displayName,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الظاهر',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: bio,
                  maxLength: 160,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'النبذة الشخصية',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: saving ? null : _saveProfile,
                    icon: saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save_outlined),
                    label: const Text('حفظ التغييرات'),
                  ),
                ),
                const SizedBox(height: 28),
                const Text('التخصيص', style: TextStyle(color: _gold, fontSize: 16)),
                const SizedBox(height: 8),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: AppPreferences.themeMode,
                  builder: (context, mode, _) => SwitchListTile(
                    value: mode == ThemeMode.dark,
                    onChanged: _setDarkMode,
                    activeColor: _gold,
                    secondary: const Icon(Icons.dark_mode_outlined, color: _gold),
                    title: const Text('المظهر الداكن'),
                    subtitle: const Text('تغيير مظهر التطبيق وحفظ اختيارك'),
                  ),
                ),
                const SizedBox(height: 18),
                const Text('الحساب', style: TextStyle(color: _gold, fontSize: 16)),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined, color: _gold),
                  title: const Text('الخصوصية'),
                  subtitle: const Text('المساحة خاصة بعضوين فقط'),
                ),
                ListTile(
                  leading: const Icon(Icons.alternate_email, color: _gold),
                  title: const Text('البريد المرتبط'),
                  subtitle: Text(user?.email ?? 'تسجيل دخول باسم مستخدم'),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text('OURS · YOUR PRIVATE UNIVERSE',
                    style: TextStyle(color: _lavender, fontSize: 11, letterSpacing: 1.2)),
                ),
              ],
            ),
    );
  }
}
