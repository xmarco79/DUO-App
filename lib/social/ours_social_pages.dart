import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        destinations: const [
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'المحادثات'),
          NavigationDestination(icon: Icon(Icons.search), label: 'البحث'),
          NavigationDestination(icon: Icon(Icons.person_add_alt_1_outlined), label: 'الطلبات'),
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
    if (query.length < 2) {
      setState(() { results = []; searched = query; });
      return;
    }
    setState(() { loading = true; searched = query; });
    try {
      final rows = await db.from('duo_profiles')
          .select('user_id, username, display_name, avatar_path')
          .ilike('username', '%$query%')
          .neq('user_id', db.auth.currentUser!.id)
          .limit(30);
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
      _message('تم إرسال طلب الإضافة');
    } on PostgrestException catch (e) {
      _message(e.code == '23505' ? 'سبق إرسال طلب لهذا المستخدم' : 'تعذر إرسال الطلب: ${e.message}');
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
            hintText: 'ابحث باسم المستخدم',
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
            ? const Center(child: Text('ابحث عن الأشخاص باستخدام اسم المستخدم', style: TextStyle(color: _lavender)))
            : results.isEmpty && !loading
                ? const Center(child: Text('لا توجد نتائج مطابقة', style: TextStyle(color: _lavender)))
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
                            tooltip: 'إضافة',
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
      if (mounted) _message('تعذر تحميل الطلبات: $e');
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  Future<void> respond(String id, bool accept) async {
    try {
      await db.rpc('respond_to_duo_friend_request', params: {
        'p_request_id': id,
        'p_accept': accept,
      });
      _message(accept ? 'تم قبول الطلب وفتح المحادثة' : 'تم رفض الطلب');
      await load();
    } catch (e) { _message('تعذر معالجة الطلب: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: _gold));
    if (requests.isEmpty) return const Center(child: Text('لا توجد طلبات إضافة حاليًا', style: TextStyle(color: _lavender)));
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
              Expanded(child: OutlinedButton(onPressed: () => respond(row['id'].toString(), false), child: const Text('رفض'))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton(onPressed: () => respond(row['id'].toString(), true), child: const Text('قبول وبدء المحادثة'))),
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
          'preview': last == null ? 'ابدأ المحادثة الآن' : (last['message_type'] == 'text' ? last['body'] : 'مرفق'),
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
        Text('لا توجد محادثات بعد', style: TextStyle(fontSize: 21)),
        SizedBox(height: 8),
        Text('ابحث عن شخص وأرسل له طلب إضافة. بعد قبول الطلب ستظهر محادثتكما هنا.', textAlign: TextAlign.center, style: TextStyle(color: _lavender, height: 1.6)),
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

class OursDirectChatPage extends StatefulWidget {
  final String conversationId;
  final String partnerName;
  const OursDirectChatPage({super.key, required this.conversationId, required this.partnerName});
  @override
  State<OursDirectChatPage> createState() => _OursDirectChatPageState();
}

class _OursDirectChatPageState extends State<OursDirectChatPage> {
  final db = Supabase.instance.client;
  final controller = TextEditingController();
  final scroll = ScrollController();
  List<Map<String, dynamic>> messages = [];
  RealtimeChannel? channel;
  bool loading = true, sending = false;

  @override
  void initState() { super.initState(); load(); listen(); }

  Future<void> load() async {
    try {
      final rows = await db.from('duo_direct_messages').select()
          .eq('conversation_id', widget.conversationId).order('created_at');
      if (mounted) setState(() { messages = List<Map<String, dynamic>>.from(rows); loading = false; });
      _toBottom();
    } catch (e) {
      if (mounted) setState(() => loading = false);
      if (mounted) _message('تعذر تحميل الرسائل: $e');
    }
  }

  void listen() {
    channel = db.channel('ours-direct-${widget.conversationId}')
      .onPostgresChanges(event: PostgresChangeEvent.insert, schema: 'public', table: 'duo_direct_messages',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'conversation_id', value: widget.conversationId),
        callback: (payload) {
          final row = Map<String, dynamic>.from(payload.newRecord);
          if (!mounted || messages.any((m) => m['id'] == row['id'])) return;
          setState(() => messages.add(row));
          _toBottom();
        }).subscribe();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) scroll.animateTo(scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    });
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  Future<void> send() async {
    final text = controller.text.trim();
    if (text.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await db.from('duo_direct_messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': db.auth.currentUser!.id,
        'body': text,
        'message_type': 'text',
      });
      controller.clear();
    } catch (e) { _message('تعذر إرسال الرسالة: $e'); }
    finally { if (mounted) setState(() => sending = false); }
  }

  @override
  void dispose() {
    controller.dispose(); scroll.dispose();
    if (channel != null) db.removeChannel(channel!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = db.auth.currentUser!.id;
    return Scaffold(
      appBar: AppBar(backgroundColor: _navy, title: Text(widget.partnerName, style: const TextStyle(fontSize: 17))),
      body: Column(children: [
        Expanded(child: loading ? const Center(child: CircularProgressIndicator(color: _gold)) : ListView.builder(
          controller: scroll, padding: const EdgeInsets.all(14), itemCount: messages.length,
          itemBuilder: (context, i) {
            final row = messages[i]; final mine = row['sender_id'] == uid;
            return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft, child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: mine ? _purple : const Color(0xFF211B30), borderRadius: BorderRadius.circular(16)),
              child: Text(row['body'].toString(), style: const TextStyle(height: 1.4)),
            ));
          },
        )),
        SafeArea(top: false, child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(children: [
            Expanded(child: TextField(controller: controller, minLines: 1, maxLines: 5, textInputAction: TextInputAction.send, onSubmitted: (_) => send(),
              decoration: InputDecoration(hintText: 'اكتب رسالة...', filled: true, fillColor: _purple, border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)))),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: sending ? null : send, icon: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send), color: _navy, style: IconButton.styleFrom(backgroundColor: _gold)),
          ]),
        )),
      ]),
    );
  }
}
