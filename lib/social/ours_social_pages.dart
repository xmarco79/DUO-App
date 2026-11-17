import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ours_direct_chat_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../worlds/world_hub_page.dart';
import '../notifications/ours_notifications.dart';

String _oursText(BuildContext context, String ar, String en) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

const _navy = Color(0xFF10101C);
const _purple = Color(0xFF29213D);
const _lavender = Color(0xFFB9A2D5);
const _gold = Color(0xFFD9BC86);

class OursSocialHomePage extends StatefulWidget {
  final VoidCallback onProfileTap;
  final ValueChanged<String> onChatTap;
  const OursSocialHomePage({super.key, required this.onProfileTap, required this.onChatTap});
  @override
  State<OursSocialHomePage> createState() => _OursSocialHomePageState();
}

class _OursSocialHomePageState extends State<OursSocialHomePage> {
  int index = 0;
  String? spaceId;
  bool loadingSpace = true;
  final db = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadSpace();
  }

  Future<void> _loadSpace() async {
    try {
      final uid = db.auth.currentUser?.id;
      if (uid == null) return;
      final row = await db.from('duo_members').select('space_id')
          .eq('user_id', uid).maybeSingle();
      if (mounted) setState(() => spaceId = row?['space_id']?.toString());
    } catch (e) {
      debugPrint('OURS world membership lookup failed: $e');
    } finally {
      if (mounted) setState(() => loadingSpace = false);
    }
  }

  void _updateSpace(String id) {
    if (mounted) setState(() { spaceId = id; loadingSpace = false; });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      OursConnectHubPage(
        key: const ValueKey('private-pair'),
        spaceId: spaceId,
        loading: loadingSpace,
        onSpaceChanged: _updateSpace,
        onChatTap: widget.onChatTap,
      ),
      OursWorldHubPage(key: ValueKey('universe-$spaceId'), spaceId: spaceId, worldIndex: 1, onSpaceChanged: _updateSpace),
      OursWorldHubPage(key: ValueKey('play-$spaceId'), spaceId: spaceId, worldIndex: 2, onSpaceChanged: _updateSpace),
      OursWorldHubPage(key: ValueKey('memories-$spaceId'), spaceId: spaceId, worldIndex: 3, onSpaceChanged: _updateSpace),
      OursWorldHubPage(key: ValueKey('together-$spaceId'), spaceId: spaceId, worldIndex: 4, onSpaceChanged: _updateSpace),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _navy,
        title: const Text('OURS', style: TextStyle(color: _gold, letterSpacing: 5)),
        centerTitle: true,
        actions: [
          OursNotificationBell(spaceId: spaceId),
          IconButton(onPressed: widget.onProfileTap,
            icon: const Icon(Icons.person_outline, color: _lavender)),
        ],
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: _purple,
        indicatorColor: _lavender.withValues(alpha: .18),
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.forum_outlined), selectedIcon: const Icon(Icons.forum), label: _oursText(context, 'مساحتنا', 'Our Space')),
          NavigationDestination(icon: const Icon(Icons.public_outlined), label: _oursText(context, 'العالم', 'Universe')),
          NavigationDestination(icon: const Icon(Icons.sports_esports_outlined), label: _oursText(context, 'اللعب', 'Play')),
          NavigationDestination(icon: const Icon(Icons.auto_awesome_outlined), label: _oursText(context, 'الذكريات', 'Memories')),
          NavigationDestination(icon: const Icon(Icons.favorite_border), label: _oursText(context, 'معًا', 'Together')),
        ],
      ),
    );
  }
}

class OursConnectHubPage extends StatefulWidget {
  final String? spaceId;
  final bool loading;
  final ValueChanged<String> onSpaceChanged;
  final ValueChanged<String> onChatTap;

  const OursConnectHubPage({
    super.key,
    required this.spaceId,
    required this.loading,
    required this.onSpaceChanged,
    required this.onChatTap,
  });

  @override
  State<OursConnectHubPage> createState() => _OursConnectHubPageState();
}

class _OursConnectHubPageState extends State<OursConnectHubPage> {
  final db = Supabase.instance.client;
  final inviteController = TextEditingController();
  Map<String, dynamic>? partner;
  String? partnerUserId;
  bool loadingPartner = false;
  bool busy = false;
  String? inviteCode;
  String? loadError;

  String get uid => db.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    loadPartner();
  }

  @override
  void didUpdateWidget(covariant OursConnectHubPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spaceId != widget.spaceId) {
      partner = null;
      partnerUserId = null;
      partnerInSpace = false;
      loadPartner();
    }
  }

  bool partnerInSpace = false;

  Future<void> loadPartner() async {
    setState(() { loadingPartner = true; loadError = null; });
    try {
      // OURS has one fixed pair. Resolve the partner account independently
      // from space membership so it is visible immediately after login.
      const pairIds = {
        'b771a6d1-3180-4f50-b81c-66924665151a': '01d9c50a-98fe-4998-ae79-c48fd5ac3fd3', // naif -> zoi
        '01d9c50a-98fe-4998-ae79-c48fd5ac3fd3': 'b771a6d1-3180-4f50-b81c-66924665151a', // zoi -> naif
      };
      final otherUserId = pairIds[uid];
      if (otherUserId == null) {
        throw Exception(_oursText(context, 'هذا الحساب ليس ضمن حسابَي OURS المعتمدين.', 'This account is not one of the two OURS accounts.'));
      }

      final profile = await db.from('duo_profiles')
          .select('username, display_name, avatar_path, bio')
          .eq('user_id', otherUserId)
          .maybeSingle();

      var connected = false;
      final space = widget.spaceId;
      if (space != null) {
        final members = await db.from('duo_members')
            .select('user_id')
            .eq('space_id', space);
        if (members.length > 2) {
          throw Exception(_oursText(context, 'تم رصد عدد أعضاء غير متوقع. تم إيقاف عرض المساحة لحماية خصوصيتكما.', 'Unexpected member count detected. The space is hidden to protect your privacy.'));
        }
        connected = members.any((m) => m['user_id'].toString() == otherUserId);
      }

      if (!mounted) return;
      setState(() {
        partner = profile;
        partnerUserId = profile == null ? null : otherUserId;
        partnerInSpace = connected;
        loadingPartner = false;
      });
    } catch (e) {
      if (mounted) setState(() { loadingPartner = false; loadError = e.toString(); });
    }
  }

  void showMessage(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> createSpace() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final result = await db.rpc('create_duo_space');
      final id = result.toString();
      if (id.isEmpty || id == 'null') throw Exception('No space id returned');
      widget.onSpaceChanged(id);
      await createInvite(showSuccess: false);
      showMessage(_oursText(context, 'تم إنشاء عالمكما الخاص', 'Your private world is ready'));
    } catch (e) {
      showMessage(_oursText(context, 'تعذر إنشاء المساحة: $e', 'Could not create your space: $e'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> createInvite({bool showSuccess = true}) async {
    try {
      final code = await db.rpc('create_duo_invite');
      if (!mounted) return;
      setState(() => inviteCode = code.toString());
      if (showSuccess) showMessage(_oursText(context, 'تم إنشاء رمز دعوة صالح لمدة 24 ساعة', 'A 24-hour invite code has been created'));
    } catch (e) {
      showMessage(_oursText(context, 'تعذر إنشاء رمز الدعوة: $e', 'Could not create invite code: $e'));
    }
  }

  Future<void> joinSpace() async {
    final code = inviteController.text.trim().toUpperCase();
    if (code.length != 8) {
      showMessage(_oursText(context, 'أدخل رمز الدعوة المكوّن من 8 خانات', 'Enter the 8-character invite code'));
      return;
    }
    if (busy) return;
    setState(() => busy = true);
    try {
      final result = await db.rpc('redeem_duo_invite', params: {'p_code': code});
      final id = result.toString();
      if (id.isEmpty || id == 'null') throw Exception('No space id returned');
      inviteController.clear();
      widget.onSpaceChanged(id);
      await loadPartner();
      showMessage(_oursText(context, 'انضممتما إلى عالمكما الخاص', 'You joined your private world'));
    } catch (e) {
      showMessage(_oursText(context, 'تعذر الانضمام: $e', 'Could not join the space: $e'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> showJoinDialog() async {
    inviteController.clear();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _purple,
        title: Text(_oursText(context, 'الانضمام إلى عالمكما', 'Join your world')),
        content: TextField(
          controller: inviteController,
          maxLength: 8,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: _oursText(context, 'رمز الدعوة', 'Invite code'),
            prefixIcon: const Icon(Icons.vpn_key_outlined),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_oursText(context, 'إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(_oursText(context, 'انضمام', 'Join'))),
        ],
      ),
    );
    if (accepted == true) await joinSpace();
  }

  @override
  void dispose() {
    inviteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading || loadingPartner) {
      return const Center(child: CircularProgressIndicator(color: _gold));
    }
    final hasPartner = partnerUserId != null;
    final connected = partnerInSpace;
    if (widget.spaceId == null) {
      final partnerAvatarPath = partner?['avatar_path']?.toString();
      final partnerAvatarUrl = partnerAvatarPath == null ? null : db.storage.from('ours-avatars').getPublicUrl(partnerAvatarPath);
      final partnerDisplayName = partner?['display_name']?.toString().trim() ?? '';
      final partnerUsername = partner?['username']?.toString() ?? '';
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (hasPartner) Card(
              color: _purple,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  CircleAvatar(radius: 30, backgroundColor: _navy,
                    backgroundImage: partnerAvatarUrl == null ? null : NetworkImage(partnerAvatarUrl),
                    child: partnerAvatarUrl == null ? const Icon(Icons.person_outline, color: _gold, size: 28) : null),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(partnerDisplayName.isNotEmpty ? partnerDisplayName : '@$partnerUsername',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    Text('@$partnerUsername', style: const TextStyle(color: _lavender)),
                    const SizedBox(height: 4),
                    Text(_oursText(context, 'حساب شريكك موجود في OURS', 'Your partner is already on OURS'),
                      style: const TextStyle(color: _gold, fontSize: 12)),
                  ])),
                  const Icon(Icons.verified_user_outlined, color: _gold),
                ]),
              ),
            ),
            const Icon(Icons.all_inclusive_rounded, color: _gold, size: 72),
            const SizedBox(height: 18),
            Text(_oursText(context, 'عالمكما يبدأ من هنا', 'Your world starts here'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(_oursText(context, 'OURS مساحة خاصة لا تضم إلا حسابيكما. أنشئ المساحة وأرسل رمز الدعوة لشريكك، أو أدخل الرمز الذي وصلك.', 'OURS is a private space for only your two accounts. Create it and share an invite with your partner, or enter the code you received.'),
                textAlign: TextAlign.center, style: const TextStyle(color: _lavender, height: 1.7)),
            const SizedBox(height: 26),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: busy ? null : createSpace,
              icon: const Icon(Icons.add_circle_outline),
              label: Text(_oursText(context, 'إنشاء عالمكما', 'Create your world')),
            )),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: busy ? null : showJoinDialog,
              icon: const Icon(Icons.vpn_key_outlined),
              label: Text(_oursText(context, 'لديّ رمز دعوة', 'I have an invite code')),
            )),
            if (busy) const Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator(color: _gold)),
          ]),
        ),
      );
    }

    final avatarPath = partner?['avatar_path']?.toString();
    final avatarUrl = avatarPath == null ? null : db.storage.from('ours-avatars').getPublicUrl(avatarPath);
    final displayName = partner?['display_name']?.toString().trim() ?? '';
    final username = partner?['username']?.toString() ?? '';
    return RefreshIndicator(
      color: _gold,
      onRefresh: loadPartner,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 36),
        children: [
          const Icon(Icons.all_inclusive_rounded, color: _gold, size: 54),
          const SizedBox(height: 12),
          Text(_oursText(context, 'عالمكما الخاص', 'Your private universe'),
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(_oursText(context, 'شخصان فقط · مساحة واحدة · ذكرياتكما معًا', 'Two people only · One space · Your memories together'),
              textAlign: TextAlign.center, style: const TextStyle(color: _lavender)),
          const SizedBox(height: 24),
          Card(
            color: _purple,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: _navy,
                  backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl),
                  child: avatarUrl == null ? const Icon(Icons.person_outline, color: _gold, size: 36) : null,
                ),
                const SizedBox(height: 12),
                Text(hasPartner ? (displayName.isNotEmpty ? displayName : username.isNotEmpty ? '@$username' : _oursText(context, 'شريكك', 'Your partner')) : _oursText(context, 'بانتظار شريكك', 'Waiting for your partner'),
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                if (hasPartner && username.isNotEmpty)
                  Text('@$username', style: const TextStyle(color: _lavender)),
                if (hasPartner && (partner?['bio']?.toString().isNotEmpty ?? false))
                  Padding(padding: const EdgeInsets.only(top: 8), child: Text(partner!['bio'].toString(),
                      textAlign: TextAlign.center, style: const TextStyle(color: _lavender, height: 1.5))),
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.lock_outline, color: _gold, size: 17),
                  const SizedBox(width: 7),
                  Text(hasPartner
                    ? _oursText(context, 'المساحة مكتملة بحسابيكما', 'Your space is complete with both accounts')
                    : _oursText(context, 'حساب واحد من أصل حسابين', 'One of two accounts connected'),
                    style: const TextStyle(color: _gold, fontSize: 12)),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          if (loadError != null)
            Card(color: _purple, child: ListTile(
              leading: const Icon(Icons.error_outline, color: _gold),
              title: Text(_oursText(context, 'تعذر تحميل بيانات الشريك', 'Could not load partner details')),
              subtitle: Text(loadError!, style: const TextStyle(color: _lavender)),
              trailing: IconButton(onPressed: loadPartner, icon: const Icon(Icons.refresh, color: _gold)),
            )),
          if (connected)
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: () => widget.onChatTap(widget.spaceId!),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(_oursText(context, 'فتح محادثتكما', 'Open your chat')),
            ))
          else ...[
            Card(color: _purple, child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Text(_oursText(context, 'رمز دعوة شريكك', 'Your partner invite code'),
                    style: const TextStyle(color: _gold, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (inviteCode != null) ...[
                  SelectableText(inviteCode!, style: const TextStyle(fontSize: 27, color: _gold, letterSpacing: 5, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => Clipboard.setData(ClipboardData(text: inviteCode!)),
                    icon: const Icon(Icons.copy),
                    label: Text(_oursText(context, 'نسخ الرمز', 'Copy code')),
                  ),
                ] else
                  Text(_oursText(context, 'أنشئ رمزًا خاصًا وشاركه مع شريكك فقط. تنتهي صلاحيته بعد 24 ساعة.', 'Create a private code and share it only with your partner. It expires after 24 hours.'),
                      textAlign: TextAlign.center, style: const TextStyle(color: _lavender, height: 1.5)),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: busy ? null : createInvite,
                  icon: const Icon(Icons.key_outlined),
                  label: Text(_oursText(context, 'إنشاء / تجديد الرمز', 'Create / renew code')),
                ),
              ]),
            )),
          ],
          const SizedBox(height: 18),
          Card(color: _purple, child: ListTile(
            leading: const Icon(Icons.shield_outlined, color: _gold),
            title: Text(_oursText(context, 'خصوصيتكما أولويتنا', 'Your privacy comes first')),
            subtitle: Text(_oursText(context, 'لا يوجد بحث عام أو قائمة أصدقاء. لا يمكن أن تضم المساحة أكثر من حسابين.', 'No public search or friend list. Your space cannot contain more than two accounts.'),
                style: const TextStyle(color: _lavender, height: 1.5)),
          )),
        ],
      ),
    );
  }
}

class OursPeopleSearchPage extends StatefulWidget {
  const OursPeopleSearchPage({super.key});
  @override
  State<OursPeopleSearchPage> createState() => _OursPeopleSearchPageState();
}

class _OursPeopleSearchPageState extends State<OursPeopleSearchPage> {
  final controller = TextEditingController();
  final db = Supabase.instance.client;
  List<Map<String, dynamic>> results = [];
  bool loading = false;
  String? searched;

  Future<void> search() async {
    final query = controller.text.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();
    if (query.length < 3) {
      setState(() { results = []; searched = query; });
      return;
    }
    setState(() { loading = true; searched = query; });
    try {
      final rows = await db.rpc('search_ours_people', params: {'p_query': query});
      if (!mounted) return;
      setState(() => results = List<Map<String, dynamic>>.from(rows));
    } catch (e) {
      if (mounted) _message(_oursText(context, 'تعذر البحث: $e', 'Search failed: $e'));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  Future<void> sendRequest(String userId) async {
    try {
      await db.from('duo_friend_requests').insert({
        'requester_id': db.auth.currentUser!.id,
        'addressee_id': userId,
      });
      _message(_oursText(context, 'تم إرسال طلب الإضافة', 'Friend request sent'));
    } on PostgrestException catch (e) {
      _message(e.code == '23505' ? _oursText(context, 'سبق إرسال طلب لهذا المستخدم', 'A request was already sent to this user') : _oursText(context, 'تعذر إرسال الطلب: ${e.message}', 'Could not send request: ${e.message}'));
    } catch (e) {
      _message(_oursText(context, 'تعذر إرسال الطلب: $e', 'Could not send request: $e'));
    }
  }

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
        child: TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => search(),
          decoration: InputDecoration(
            hintText: _oursText(context, _oursText(context, 'ابحث باسم المستخدم', 'Search by username'), 'Search by username'),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(onPressed: search, icon: const Icon(Icons.arrow_forward)),
            filled: true, fillColor: _purple,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ),
      if (loading) const LinearProgressIndicator(color: _gold),
      Expanded(
        child: searched == null
            ? Center(child: Text(_oursText(context, 'ابحث عن الأشخاص باستخدام اسم المستخدم (3 أحرف على الأقل)', 'Search people by username (at least 3 characters)'), style: const TextStyle(color: _lavender)))
            : results.isEmpty && !loading
                ? Center(child: Text(_oursText(context, 'لا توجد نتائج مطابقة', 'No matching users'), style: const TextStyle(color: _lavender)))
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final row = results[i];
                      final path = row['avatar_path']?.toString();
                      final url = path == null ? null : db.storage.from('ours-avatars').getPublicUrl(path);
                      final name = (row['display_name'] ?? '').toString().trim();
                      return Card(
                        color: _purple, margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _navy,
                            backgroundImage: url == null ? null : NetworkImage(url),
                            child: url == null ? const Icon(Icons.person, color: _gold) : null,
                          ),
                          title: Text(name.isEmpty ? '@${row['username']}' : name),
                          subtitle: Text('@${row['username']}', style: const TextStyle(color: _lavender)),
                          trailing: IconButton(
                            tooltip: _oursText(context, 'إضافة', 'Add'),
                            onPressed: () => sendRequest(row['user_id'].toString()),
                            icon: const Icon(Icons.person_add_alt_1, color: _gold),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    ]);
  }
}

class OursFriendRequestsPage extends StatefulWidget {
  const OursFriendRequestsPage({super.key});
  @override
  State<OursFriendRequestsPage> createState() => _OursFriendRequestsPageState();
}

class _OursFriendRequestsPageState extends State<OursFriendRequestsPage> {
  final db = Supabase.instance.client;
  List<Map<String, dynamic>> requests = [];
  bool loading = true;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    try {
      final rows = await db.from('duo_friend_requests')
          .select('id, requester_id, created_at')
          .eq('addressee_id', db.auth.currentUser!.id)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      if (!mounted) return;
      final list = List<Map<String, dynamic>>.from(rows);
      for (final row in list) {
        final profile = await db.from('duo_profiles')
            .select('username, display_name, avatar_path')
            .eq('user_id', row['requester_id'])
            .maybeSingle();
        row['profile'] = profile;
      }
      setState(() { requests = list; loading = false; });
    } catch (e) {
      if (mounted) setState(() => loading = false);
      if (mounted) _message(_oursText(context, _oursText(context, 'تعذر تحميل الطلبات: $e', 'Could not load requests: $e'), 'Could not load requests: $e'));
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  Future<void> respond(String id, bool accept) async {
    try {
      await db.rpc('respond_to_duo_friend_request', params: {
        'p_request_id': id,
        'p_accept': accept,
      });
      _message(accept ? _oursText(context, 'تم قبول الطلب وفتح المحادثة', 'Request accepted. Chat is ready') : _oursText(context, 'تم رفض الطلب', 'Request declined'));
      await load();
    } catch (e) { _message(_oursText(context, 'تعذر معالجة الطلب: $e', 'Could not process request: $e')); }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: _gold));
    if (requests.isEmpty) return Center(child: Text(_oursText(context, 'لا توجد طلبات إضافة حاليًا', 'No pending requests'), style: const TextStyle(color: _lavender)));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: requests.length,
      itemBuilder: (context, i) {
        final row = requests[i];
        final profile = row['profile'] as Map<String, dynamic>?;
        final username = profile?['username']?.toString() ?? _oursText(context, 'مستخدم', 'User');
        final display = profile?['display_name']?.toString().trim() ?? '';
        final path = profile?['avatar_path']?.toString();
        final url = path == null ? null : db.storage.from('ours-avatars').getPublicUrl(path);
        return Card(color: _purple, child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(children: [
            ListTile(
              leading: CircleAvatar(backgroundImage: url == null ? null : NetworkImage(url), child: url == null ? const Icon(Icons.person) : null),
              title: Text(display.isEmpty ? '@$username' : display),
              subtitle: Text('@$username', style: const TextStyle(color: _lavender)),
            ),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => respond(row['id'].toString(), false), child: Text(_oursText(context, 'رفض', 'Decline')))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton(onPressed: () => respond(row['id'].toString(), true), child: Text(_oursText(context, 'قبول وبدء المحادثة', 'Accept and chat')))),
            ]),
          ]),
        ));
      },
    );
  }
}

class OursConversationsPage extends StatefulWidget {
  const OursConversationsPage({super.key});
  @override
  State<OursConversationsPage> createState() => _OursConversationsPageState();
}

class _OursConversationsPageState extends State<OursConversationsPage> {
  final db = Supabase.instance.client;
  List<Map<String, dynamic>> conversations = [];
  bool loading = true;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    try {
      final uid = db.auth.currentUser!.id;
      final memberships = await db.from('duo_conversation_members')
          .select('conversation_id').eq('user_id', uid);
      final rows = <Map<String, dynamic>>[];
      for (final membership in memberships) {
        final id = membership['conversation_id'].toString();
        final members = await db.from('duo_conversation_members')
            .select('user_id').eq('conversation_id', id);
        final other = members.firstWhere((m) => m['user_id'] != uid, orElse: () => {'user_id': ''});
        if (other['user_id'].toString().isEmpty) continue;
        final profile = await db.from('duo_profiles')
            .select('username, display_name, avatar_path')
            .eq('user_id', other['user_id']).maybeSingle();
        final last = await db.from('duo_direct_messages')
            .select('body, message_type, created_at')
            .eq('conversation_id', id)
            .order('created_at', ascending: false).limit(1).maybeSingle();
        rows.add({
          'id': id, 'profile': profile,
          'preview': last == null ? _oursText(context, _oursText(context, 'ابدأ المحادثة الآن', 'Start chatting'), 'Start chatting') : (last['message_type'] == 'text' ? last['body'] : _oursText(context, _oursText(context, 'مرفق', 'Attachment'), 'Attachment')),
          'last_message_at': last?['created_at'],
        });
      }
      rows.sort((a,b) => (b['last_message_at'] ?? '').toString().compareTo((a['last_message_at'] ?? '').toString()));
      if (mounted) setState(() { conversations = rows; loading = false; });
    } catch (e) {
      if (mounted) setState(() => loading = false);
      if (mounted) _message(_oursText(context, 'تعذر تحميل المحادثات: $e', 'Could not load chats: $e'));
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: _gold));
    if (conversations.isEmpty) return Center(child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.forum_outlined, color: _gold, size: 58),
        SizedBox(height: 18),
        Text(_oursText(context, 'لا توجد محادثات بعد', 'No conversations yet'), style: const TextStyle(fontSize: 21)),
        SizedBox(height: 8),
        Text(_oursText(context, 'ابحث عن شريكك باسم المستخدم وأرسل طلب إضافة. بعد قبول الطلب ستظهر محادثتكما هنا.', 'Find your partner by username and send a request. Your chat will appear here after they accept.'), textAlign: TextAlign.center, style: const TextStyle(color: _lavender, height: 1.6)),
      ]),
    ));
    return RefreshIndicator(
      color: _gold, onRefresh: load,
      child: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, i) {
          final row = conversations[i];
          final profile = row['profile'] as Map<String, dynamic>?;
          final username = profile?['username']?.toString() ?? _oursText(context, 'مستخدم', 'User');
          final display = profile?['display_name']?.toString().trim() ?? '';
          final path = profile?['avatar_path']?.toString();
          final url = path == null ? null : db.storage.from('ours-avatars').getPublicUrl(path);
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            leading: CircleAvatar(radius: 26, backgroundImage: url == null ? null : NetworkImage(url), child: url == null ? const Icon(Icons.person) : null),
            title: Text(display.isEmpty ? '@$username' : display),
            subtitle: Text(row['preview'].toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _lavender)),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => OursDirectChatPage(conversationId: row['id'].toString(), partnerName: display.isEmpty ? '@$username' : display)));
              if (mounted) load();
            },
          );
        },
      ),
    );
  }
}
