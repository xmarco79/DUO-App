import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _profileBg = Color(0xFF10101C);
const _profilePanel = Color(0xFF211D30);
const _profileGold = Color(0xFFD9BC86);
const _profileLilac = Color(0xFFB9A2D5);

class OursProfilePage extends StatefulWidget {
  final String userId;
  const OursProfilePage({super.key, required this.userId});

  @override
  State<OursProfilePage> createState() => _OursProfilePageState();
}

class _OursProfilePageState extends State<OursProfilePage> {
  final _db = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final row = await _db
          .from('duo_profiles')
          .select('user_id, username, display_name, avatar_path, bio, created_at')
          .eq('user_id', widget.userId)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _profile = row == null ? null : Map<String, dynamic>.from(row);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final name = (_profile?['display_name']?.toString().trim().isNotEmpty == true)
        ? _profile!['display_name'].toString()
        : (_profile?['username']?.toString() ?? 'OURS');
    final username = _profile?['username']?.toString() ?? '';
    final bio = _profile?['bio']?.toString().trim() ?? '';
    final avatarPath = _profile?['avatar_path']?.toString();
    final avatarUrl = avatarPath == null || avatarPath.isEmpty
        ? null
        : _db.storage.from('ours-avatars').getPublicUrl(avatarPath);

    return Scaffold(
      backgroundColor: _profileBg,
      appBar: AppBar(
        backgroundColor: _profileBg,
        title: Text(ar ? 'الملف الشخصي' : 'Profile',
            style: const TextStyle(color: _profileGold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _profileGold))
          : _error != null
              ? Center(
                  child: Text(
                    ar ? 'تعذر تحميل الملف الشخصي' : 'Could not load profile',
                    style: const TextStyle(color: _profileLilac),
                  ),
                )
              : _profile == null
                  ? Center(
                      child: Text(
                        ar ? 'الحساب غير متاح' : 'Profile unavailable',
                        style: const TextStyle(color: _profileLilac),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(22),
                      children: [
                        const SizedBox(height: 24),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [_profileGold, _profileLilac, Color(0xFF6D5B91)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _profileGold.withValues(alpha: .16),
                                  blurRadius: 30,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 58,
                              backgroundColor: _profilePanel,
                              backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl),
                              child: avatarUrl == null
                                  ? Text(
                                      name.isEmpty ? 'O' : name.characters.first.toUpperCase(),
                                      style: const TextStyle(
                                        color: _profileGold,
                                        fontSize: 38,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(height: 5),
                        Center(
                          child: Text('@$username',
                              style: const TextStyle(
                                  color: _profileLilac, fontSize: 14)),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: _profilePanel,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _profileGold.withValues(alpha: .18)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ar ? 'نبذة' : 'About',
                                  style: const TextStyle(
                                      color: _profileGold,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 10),
                              Text(
                                bio.isEmpty
                                    ? (ar ? 'لم تُضف نبذة بعد.' : 'No bio added yet.')
                                    : bio,
                                style: const TextStyle(
                                    color: Colors.white, height: 1.7),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _profilePanel.withValues(alpha: .65),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_outline, color: _profileGold),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  ar
                                      ? 'حساب ضمن عالم OURS الخاص'
                                      : 'A member of the private OURS universe',
                                  style: const TextStyle(
                                      color: _profileLilac, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}
