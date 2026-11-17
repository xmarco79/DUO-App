import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _navy = Color(0xFF10101C);
const _purple = Color(0xFF29213D);
const _lavender = Color(0xFFB9A2D5);
const _gold = Color(0xFFD9BC86);

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'حساب OURS';
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        centerTitle: true,
        title: const Text(
          'الإعدادات',
          style: TextStyle(color: _gold, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_purple, Color(0xFF3A304C)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _gold.withOpacity(.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: _gold.withOpacity(.13),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Icon(Icons.all_inclusive, color: _gold, size: 32),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('OURS', style: TextStyle(color: _gold, fontSize: 20, letterSpacing: 3)),
                        const SizedBox(height: 5),
                        Text(email, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _lavender, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            _sectionTitle('الحساب'),
            _settingsCard([
              _tile(Icons.person_outline, 'معلومات الحساب', email,
                onTap: () => _info(context, 'الحساب', 'هذا الحساب مخصص للدخول إلى عالمك الخاص في OURS.')),
              _tile(Icons.lock_outline, 'الأمان والخصوصية', 'مساحة خاصة ومحتوى محمي بين العضوين',
                onTap: () => _info(context, 'الخصوصية', 'المساحة خاصة بعضوين فقط. تُحمى الرسائل والملصقات بسياسات الوصول الخاصة بالمساحة.')),
            ]),
            const SizedBox(height: 22),
            _sectionTitle('التخصيص'),
            _settingsCard([
              _tile(Icons.language, 'لغة التطبيق', 'العربية', onTap: () =>
                _info(context, 'اللغة', 'الواجهة الحالية باللغة العربية.')),
              _tile(Icons.dark_mode_outlined, 'المظهر', 'داكن — هوية OURS',
                onTap: () => _info(context, 'المظهر', 'يستخدم OURS المظهر الداكن مع ألوان الكحلي والبنفسجي والذهبي.')),
            ]),
            const SizedBox(height: 22),
            _sectionTitle('الميزات'),
            _settingsCard([
              _tile(Icons.auto_awesome, 'OURS AI', 'محادثة ذكية وأفكار وملخصات',
                onTap: () => _info(context, 'OURS AI', 'تُرسل رسالتك إلى خدمة الذكاء الاصطناعي عند استخدامها. لا تُرسل محادثات المساحة كسياق إلا عند اختيار مهمة تعتمد عليها.')),
              _tile(Icons.emoji_emotions_outlined, 'الملصقات', 'ملصقات نصية وصور وإنشاء بالذكاء الاصطناعي',
                onTap: () => _info(context, 'الملصقات', 'يمكن إنشاء ملصقات نصية، وإزالة خلفية الصور، أو توليد ملصق من وصف. قد تترتب تكلفة على عمليات توليد الصور حسب إعدادات الخدمة.')),
            ]),
            const SizedBox(height: 22),
            _sectionTitle('حول التطبيق'),
            _settingsCard([
              _tile(Icons.info_outline, 'إصدار التطبيق', '1.0.0', onTap: null),
              _tile(Icons.favorite_border, 'صُنع لعالمٍ من شخصين', 'OURS · YOUR PRIVATE UNIVERSE', onTap: null),
            ]),
            const SizedBox(height: 18),
            const Center(
              child: Text('خصوصيتكما هي أساس OURS', style: TextStyle(color: _lavender, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _sectionTitle(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10, right: 4),
    child: Text(value, style: const TextStyle(color: _gold, fontSize: 14, fontWeight: FontWeight.w600)),
  );

  static Widget _settingsCard(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: _purple,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _gold.withOpacity(.13)),
    ),
    child: Column(children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) Divider(height: 1, indent: 58, color: _lavender.withOpacity(.12)),
        children[i],
      ],
    ]),
  );

  static Widget _tile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) =>
    ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: _gold.withOpacity(.10), borderRadius: BorderRadius.circular(13)),
        child: Icon(icon, color: _gold, size: 21),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle, style: const TextStyle(color: _lavender, fontSize: 11)),
      ),
      trailing: onTap == null ? null : const Icon(Icons.chevron_left, color: _lavender),
      onTap: onTap,
    );

  static void _info(BuildContext context, String title, String description) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _purple,
        title: Text(title, style: const TextStyle(color: _gold)),
        content: Text(description, style: const TextStyle(height: 1.6)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسنًا')),
        ],
      ),
    );
  }
}
