import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ours_direct_chat_page.dart';

String _oursText(BuildContext context, String ar, String en) =>
    Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

const _navy = Color(0xFF10101C);
const _purple = Color(0xFF29213D);
const _lavender = Color(0xFFB9A2D5);
const _gold = Color(0xFFD9BC86);

class OursSocialHomePage extends StatefulWidget {
  final VoidCallback onProfileTap;
  const OursSocialHomePage({super.key, required this.onProfileTap});

  @override
  State<OursSocialHomePage> createState() => _OursSocialHomePageState();
}

class _OursSocialHomePageState extends State<OursSocialHomePage> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      const OursConversationsPage(),
      const OursPeopleSearchPage(),
      const OursFriendRequestsPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _navy,
        title: const Text('OURS', style: TextStyle(color: _gold, letterSpacing: 5)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: widget.onProfileTap, icon: const Icon(Icons.person_outline, color: _lavender)),
        ],
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        backgroundColor: _purple,
        indicatorColor: _lavender.withValues(alpha: .18),
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: _oursText(context, 'المحادثات', 'Chats')),
          NavigationDestination(icon: Icon(Icons.search), label: _oursText(context, 'البحث', 'Search')),
          NavigationDestination(icon: Icon(Icons.person_add_alt_1_outlined), label: _oursText(context, 'الطلبات', 'Requests')),
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
      if (mounted) _message('تعذر البحث: $e');
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
      _message(e.code == '23505' ? _oursText(context, 'سبق إرسال طلب لهذا المستخدم', 'A request was already sent to this user') : 'تعذر إرسال الطلب: ${e.message}');
    } catch (e) {
      _message('تعذر إرسال الطلب: $e');
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
            hintText: _oursText(context, 'ابحث باسم المستخدم', 'Search by username'),
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
      if (mounted) _message(_oursText(context, 'تعذر تحميل الطلبات: $e', 'Could not load requests: $e'));
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
    } catch (e) { _message('تعذر معالجة الطلب: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: _gold));
    if (requests.isEmpty) return const Center(child: Text(_oursText(context, 'لا توجد طلبات إضافة حاليًا', 'No pending requests'), style: TextStyle(color: _lavender)));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: requests.length,
      itemBuilder: (context, i) {
        final row = requests[i];
        final profile = row['profile'] as Map<String, dynamic>?;
        final username = profile?['username']?.toString() ?? 'مستخدم';
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
          'preview': last == null ? _oursText(context, 'ابدأ المحادثة الآن', 'Start chatting') : (last['message_type'] == 'text' ? last['body'] : _oursText(context, 'مرفق', 'Attachment')),
          'last_message_at': last?['created_at'],
        });
      }
      rows.sort((a,b) => (b['last_message_at'] ?? '').toString().compareTo((a['last_message_at'] ?? '').toString()));
      if (mounted) setState(() { conversations = rows; loading = false; });
    } catch (e) {
      if (mounted) setState(() => loading = false);
      if (mounted) _message('تعذر تحميل المحادثات: $e');
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: _gold));
    if (conversations.isEmpty) return Center(child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
        Icon(Icons.forum_outlined, color: _gold, size: 58),
        SizedBox(height: 18),
        Text(_oursText(context, 'لا توجد محادثات بعد', 'No conversations yet'), style: TextStyle(fontSize: 21)),
        SizedBox(height: 8),
        Text(_oursText(context, 'ابحث عن شريكك باسم المستخدم وأرسل طلب إضافة. بعد قبول الطلب ستظهر محادثتكما هنا.', 'Find your partner by username and send a request. Your chat will appear here after they accept.'), textAlign: TextAlign.center, style: TextStyle(color: _lavender, height: 1.6)),
      ]),
    ));
    return RefreshIndicator(
      color: _gold, onRefresh: load,
      child: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, i) {
          final row = conversations[i];
          final profile = row['profile'] as Map<String, dynamic>?;
          final username = profile?['username']?.toString() ?? 'مستخدم';
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
