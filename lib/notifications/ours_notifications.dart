import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _oursGold = Color(0xFFD9BC86);
const _oursPurple = Color(0xFF29213D);
const _oursLavender = Color(0xFFB9A2D5);

class OursNotificationBell extends StatefulWidget {
  final String? spaceId;
  const OursNotificationBell({super.key, required this.spaceId});

  @override
  State<OursNotificationBell> createState() => _OursNotificationBellState();
}

class _OursNotificationBellState extends State<OursNotificationBell> {
  final db = Supabase.instance.client;
  RealtimeChannel? channel;
  int unread = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
    _subscribe();
  }

  Future<void> _loadCount() async {
    final userId = db.auth.currentUser?.id;
    if (userId == null || widget.spaceId == null) return;
    try {
      final rows = await db.from('duo_notifications')
          .select('id')
          .eq('user_id', userId)
          .isFilter('read_at', null);
      if (mounted) setState(() => unread = rows.length);
    } catch (_) {
      // Preview builds and older schemas can safely omit the notification badge.
    }
  }

  void _subscribe() {
    final userId = db.auth.currentUser?.id;
    if (userId == null || widget.spaceId == null) return;
    channel = db.channel('ours-notifications-$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'duo_notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          if (!mounted) return;
          setState(() => unread += 1);
        },
      )
      ..subscribe();
  }

  @override
  void didUpdateWidget(covariant OursNotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spaceId != widget.spaceId) {
      if (channel != null) db.removeChannel(channel!);
      channel = null;
      _loadCount();
      _subscribe();
    }
  }

  @override
  void dispose() {
    if (channel != null) db.removeChannel(channel!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.spaceId == null) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'الإشعارات',
      onPressed: () async {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => OursNotificationsPage(spaceId: widget.spaceId!),
        ));
        _loadCount();
      },
      icon: Stack(clipBehavior: Clip.none, children: [
        const Icon(Icons.notifications_none_rounded),
        if (unread > 0)
          Positioned(
            right: -5,
            top: -5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
              child: Text(unread > 99 ? '99+' : '$unread',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
      ]),
    );
  }
}

class OursNotificationsPage extends StatefulWidget {
  final String spaceId;
  const OursNotificationsPage({super.key, required this.spaceId});

  @override
  State<OursNotificationsPage> createState() => _OursNotificationsPageState();
}

class _OursNotificationsPageState extends State<OursNotificationsPage> {
  final db = Supabase.instance.client;
  List<Map<String, dynamic>> notifications = [];
  bool loading = true;
  String? error;
  RealtimeChannel? channel;

  @override
  void initState() {
    super.initState();
    _load();
    final userId = db.auth.currentUser?.id;
    if (userId != null) {
      channel = db.channel('ours-notification-list-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'duo_notifications',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
          callback: (_) => _load(),
        )..subscribe();
    }
  }

  Future<void> _load() async {
    final userId = db.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final rows = await db.from('duo_notifications')
        .select()
        .eq('user_id', userId)
        .eq('space_id', widget.spaceId)
        .order('created_at', ascending: false)
        .limit(100);
      if (!mounted) return;
      setState(() {
        notifications = List<Map<String, dynamic>>.from(rows);
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = 'تعذر تحميل الإشعارات'; });
    }
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    if (item['read_at'] != null) return;
    try {
      await db.from('duo_notifications').update({
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', item['id']);
      if (!mounted) return;
      setState(() {
        final index = notifications.indexWhere((row) => row['id'] == item['id']);
        if (index >= 0) notifications[index]['read_at'] = DateTime.now().toIso8601String();
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    final userId = db.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await db.from('duo_notifications').update({
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('user_id', userId).eq('space_id', widget.spaceId).isFilter('read_at', null);
      if (!mounted) return;
      setState(() {
        for (final row in notifications) {
          row['read_at'] ??= DateTime.now().toIso8601String();
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    if (channel != null) db.removeChannel(channel!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending = notifications.where((n) => n['read_at'] == null).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          if (pending > 0)
            TextButton(onPressed: _markAllRead, child: const Text('قراءة الكل')),
        ],
      ),
      body: loading
        ? const Center(child: CircularProgressIndicator(color: _oursGold))
        : error != null
          ? Center(child: Text(error!))
          : notifications.isEmpty
            ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.notifications_off_outlined, color: _oursLavender, size: 42),
                SizedBox(height: 10),
                Text('لا توجد إشعارات حتى الآن'),
              ]))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    final isUnread = item['read_at'] == null;
                    return Card(
                      color: _oursPurple,
                      child: ListTile(
                        onTap: () => _markRead(item),
                        leading: CircleAvatar(
                          backgroundColor: _oursGold.withOpacity(.15),
                          child: Icon(
                            item['notification_type'] == 'message'
                              ? Icons.chat_bubble_outline
                              : item['notification_type'] == 'game'
                                ? Icons.sports_esports
                                : Icons.auto_awesome,
                            color: _oursGold,
                          ),
                        ),
                        title: Text(item['title']?.toString() ?? 'إشعار'),
                        subtitle: Text(item['body']?.toString() ?? '',
                          style: const TextStyle(color: _oursLavender)),
                        trailing: isUnread
                          ? const Icon(Icons.circle, size: 9, color: _oursGold)
                          : null,
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
