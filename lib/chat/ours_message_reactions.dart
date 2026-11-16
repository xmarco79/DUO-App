import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _reactionGold = Color(0xFFD9BC86);
const _reactionPurple = Color(0xFF29213D);
const _quickReactions = ['❤️','😂','🥰','👍','✨','😮'];

class OursMessageReactions extends StatefulWidget {
  final String messageId;
  final String spaceId;
  const OursMessageReactions({super.key, required this.messageId, required this.spaceId});
  @override
  State<OursMessageReactions> createState() => _OursMessageReactionsState();
}

class _OursMessageReactionsState extends State<OursMessageReactions> {
  final db = Supabase.instance.client;
  List<Map<String, dynamic>> rows = [];
  RealtimeChannel? channel;

  @override
  void initState() {
    super.initState();
    load();
    channel = db.channel('ours-reactions-${widget.messageId}')
      .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'duo_message_reactions',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'message_id', value: widget.messageId),
        callback: (_) => load())..subscribe();
  }

  Future<void> load() async {
    try {
      final result = await db.from('duo_message_reactions').select('id,user_id,emoji')
        .eq('message_id', widget.messageId);
      if (mounted) setState(() => rows = List<Map<String, dynamic>>.from(result));
    } catch (_) {}
  }

  Future<void> toggle(String emoji) async {
    final userId = db.auth.currentUser?.id;
    if (userId == null) return;
    final existing = rows.where((r) => r['user_id'] == userId && r['emoji'] == emoji).toList();
    try {
      if (existing.isNotEmpty) {
        await db.from('duo_message_reactions').delete().eq('id', existing.first['id']);
      } else {
        await db.from('duo_message_reactions').insert({
          'message_id': widget.messageId, 'space_id': widget.spaceId,
          'user_id': userId, 'emoji': emoji,
        });
      }
      await load();
    } catch (_) {}
  }

  @override
  void dispose() { if (channel != null) db.removeChannel(channel!); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final userId = db.auth.currentUser?.id;
    final counts = <String,int>{};
    for (final row in rows) {
      final emoji = row['emoji'].toString();
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    return Wrap(spacing: 4, runSpacing: 2, children: [
      for (final emoji in _quickReactions)
        if (counts.containsKey(emoji))
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => toggle(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: rows.any((r) => r['emoji'] == emoji && r['user_id'] == userId)
                  ? _reactionGold.withOpacity(.24) : _reactionPurple,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _reactionGold.withOpacity(.45)),
              ),
              child: Text('$emoji ${counts[emoji]}', style: const TextStyle(fontSize: 12)),
            ),
          ),
      PopupMenuButton<String>(
        tooltip: 'إضافة تفاعل',
        padding: EdgeInsets.zero,
        onSelected: toggle,
        itemBuilder: (_) => _quickReactions.map((e) => PopupMenuItem(value: e, child: Text(e))).toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(color: _reactionPurple, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.add_reaction_outlined, size: 17, color: _reactionGold),
        ),
      ),
    ]);
  }
}
