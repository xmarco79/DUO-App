import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../worlds/world_hub_page.dart';
import '../games/ours_tic_tac_toe_page.dart';

const _oursGold = Color(0xFFD9BC86);
const _oursPurple = Color(0xFF29213D);
const _oursLavender = Color(0xFFB9A2D5);
String _notificationText(BuildContext context, String ar, String en) => Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

class OursNotificationBell extends StatefulWidget {
  final String? spaceId;
  final VoidCallback? onOpenMessage;
  const OursNotificationBell({super.key, required this.spaceId, this.onOpenMessage});

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
          .eq('space_id', widget.spaceId!)
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
      tooltip: _notificationText(context, 'الإشعارات', 'Notifications'),
      onPressed: () async {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => OursNotificationsPage(
            spaceId: widget.spaceId!,
            onOpenMessage: widget.onOpenMessage,
          ),
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
  final VoidCallback? onOpenMessage;
  const OursNotificationsPage({super.key, required this.spaceId, this.onOpenMessage});

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
      setState(() {
        loading = false;
        error = _notificationText(context, 'تعذر تحميل الإشعارات. تحقق من اتصالك وحاول مجددًا.', 'Could not load notifications. Check your connection and try again.');
      });
    }
  }

  Future<void> _openNotification(Map<String, dynamic> item) async {
    await _markRead(item);
    if (!mounted) return;
    final type = item['notification_type']?.toString();
    if (type == 'message') {
      widget.onOpenMessage?.call();
      return;
    }
    if (type == 'world_item') {
      final data = item['data'] is Map
          ? Map<String, dynamic>.from(item['data'] as Map)
          : <String, dynamic>{};
      final entityId = data['entity_id']?.toString();
      if (entityId == null || entityId.isEmpty) return;
      try {
        final row = await db.from('duo_world_items')
            .select('world')
            .eq('id', entityId)
            .eq('space_id', widget.spaceId)
            .maybeSingle();
        if (!mounted || row == null) return;
        const indexes = {
          'connect': 0, 'universe': 1, 'play': 2, 'memories': 3, 'together': 4,
        };
        final index = indexes[row['world']?.toString()];
        if (index == null) return;
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => OursWorldHubPage(spaceId: widget.spaceId, worldIndex: index),
        ));
      } catch (_) {
        if (mounted) _showMessage(_notificationText(context, 'تعذر فتح العنصر المرتبط.', 'Could not open the related item.'));
      }
      return;
    }
    if (type == 'game') {
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => OursTicTacToePage(spaceId: widget.spaceId),
      ));
    }
  }

  void _showMessage(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
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
    } catch (_) {
      _showMessage(_notificationText(context, 'تعذر تحديث الإشعار.', 'Could not update notification.'));
    }
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
    } catch (_) {
      _showMessage(_notificationText(context, 'تعذر تحديث الإشععارات.', 'Could not update notifications.'));
    }
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
        title: Text(_notificationText(context, 'الإشعارات', 'Notifications')),
        actions: [
          if (pending > 0)
            TextButton(onPressed: _markAllRead, child: Text(_notificationText(context, 'قراءة الكل', 'Mark all as read'))),
        ],
      ),
      body: loading
        ? const Center(child: CircularProgressIndicator(color: _oursGold))
        : error != null
          ? Center(child: Text(error!))
          : notifications.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.notifications_off_outlined, color: _oursLavender, size: 42),
                const SizedBox(height: 10),
                Text(_notificationText(context, 'لا توجد إشعارات حتى الآن', 'No notifications yet')),
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
                        onTap: () => _openNotification(item),
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
