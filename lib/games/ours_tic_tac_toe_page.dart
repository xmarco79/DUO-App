import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _tttGold = Color(0xFFD9BC86);
const _tttPurple = Color(0xFF29213D);
const _tttLavender = Color(0xFFB9A2D5);
String _tttText(BuildContext context, String ar, String en) => Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

class OursTicTacToePage extends StatefulWidget {
  final String spaceId;
  const OursTicTacToePage({super.key, required this.spaceId});
  @override
  State<OursTicTacToePage> createState() => _OursTicTacToePageState();
}

class _OursTicTacToePageState extends State<OursTicTacToePage> {
  final db = Supabase.instance.client;
  Map<String,dynamic>? game;
  bool loading = true;
  bool busy = false;
  RealtimeChannel? channel;
  String get userId => db.auth.currentUser!.id;
  List<String> get board {
    final raw = (game?['state'] as Map?)?['board'];
    if (raw is List && raw.length == 9) return raw.map((v) => v?.toString() ?? '').toList();
    return List.filled(9, '');
  }

  @override
  void initState() {
    super.initState();
    loadGame();
    channel = db.channel('ours-ttt-${widget.spaceId}')
      .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'duo_game_sessions',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'space_id', value: widget.spaceId),
        callback: (_) => loadGame())..subscribe();
  }

  Future<void> loadGame() async {
    try {
      final row = await db.from('duo_game_sessions').select()
        .eq('space_id', widget.spaceId).eq('game_type','tic_tac_toe')
        .order('created_at', ascending: false).limit(1).maybeSingle();
      if (!mounted) return;
      setState(() { game = row; loading = false; });
    } catch (_) { if (mounted) setState(() => loading = false); }
  }

  Future<void> newGame() async {
    setState(() => busy = true);
    try {
      final row = await db.from('duo_game_sessions').insert({
        'space_id': widget.spaceId, 'game_type': 'tic_tac_toe',
        'created_by': userId, 'current_turn_user_id': userId,
        'status': 'waiting',
        'state': {'board': List.filled(9, ''), 'winner_mark': null},
        'turn_number': 0,
      }).select().single();
      if (mounted) setState(() => game = Map<String,dynamic>.from(row));
    } catch (e) { _message(_tttText(context, 'تعذر بدء اللعبة: $e', 'Could not start game: $e')); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> play(int cell) async {
    final current = game;
    if (current == null || busy || current['status'] == 'completed' || current['current_turn_user_id'] != userId) return;
    if (board[cell].isNotEmpty) return;
    setState(() => busy = true);
    try {
      final result = await db.rpc('ours_make_ttt_move', params: {'p_session_id': current['id'], 'p_cell': cell});
      if (mounted) setState(() => game = Map<String,dynamic>.from(result as Map));
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
      await loadGame();
    } finally { if (mounted) setState(() => busy = false); }
  }

  void _message(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  void dispose() { if (channel != null) db.removeChannel(channel!); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final current = game;
    final completed = current?['status'] == 'completed';
    final myTurn = current != null && current['current_turn_user_id'] == userId && !completed;
    final winnerId = current?['winner_user_id']?.toString();
    final winnerMark = (current?['state'] as Map?)?['winner_mark']?.toString();
    final message = current == null ? _tttText(context, 'ابدأ مباراة جديدة بينكما', 'Start a new match together')
      : completed ? (winnerId == null ? _tttText(context, 'تعادل! مباراة جميلة', 'A draw! Nice match') : winnerId == userId ? _tttText(context, 'فزت بالجولة!', 'You won the round!') : _tttText(context, 'فاز الطرف الآخر بالجولة', 'Your partner won the round'))
      : myTurn ? _tttText(context, 'دورك الآن', 'Your turn') : _tttText(context, 'بانتظار حركة الطرف الآخر', 'Waiting for your partner');
    return Scaffold(
      appBar: AppBar(title: Text(_tttText(context, 'XO · لعبة لشخصين', 'XO · Two-player game'))),
      body: loading ? const Center(child: CircularProgressIndicator(color: _tttGold))
        : SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.grid_3x3_rounded, color: _tttGold, size: 48),
            const SizedBox(height: 14),
            Text(message, style: const TextStyle(fontSize: 19, color: _tttLavender), textAlign: TextAlign.center),
            if (current != null) ...[
              const SizedBox(height: 8),
              Text(_tttText(context, 'أنت تلعب ${current['created_by'] == userId ? 'X' : 'O'}', 'You are ${current['created_by'] == userId ? 'X' : 'O'}'), style: const TextStyle(color: _tttGold)),
              const SizedBox(height: 24),
              AspectRatio(aspectRatio: 1, child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(), itemCount: 9,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 9, mainAxisSpacing: 9),
                itemBuilder: (ctx, i) => InkWell(
                  onTap: myTurn && board[i].isEmpty && !busy ? () => play(i) : null,
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(color: _tttPurple, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: board[i].isEmpty ? _tttGold.withOpacity(.35) : _tttGold, width: board[i].isEmpty ? 1 : 2)),
                    child: Center(child: AnimatedScale(
                      scale: board[i].isEmpty ? 0.7 : 1, duration: const Duration(milliseconds: 180),
                      child: Text(board[i], style: TextStyle(fontSize: 54, fontWeight: FontWeight.bold,
                        color: board[i] == 'X' ? _tttGold : _tttLavender)),
                    )),
                  ),
                ),
              )),
              const SizedBox(height: 12),
              Text(_tttText(context, 'الحركات: ${current['turn_number'] ?? 0} / 9', 'Moves: ${current['turn_number'] ?? 0} / 9'), style: const TextStyle(color: _tttLavender)),
              if (winnerMark != null) Text(_tttText(context, 'الفائز: $winnerMark', 'Winner: $winnerMark'), style: const TextStyle(color: _tttGold, fontSize: 18)),
            ],
            const SizedBox(height: 28),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: busy ? null : newGame, icon: const Icon(Icons.refresh),
              label: Text(current == null ? _tttText(context, 'ابدأ اللعب', 'Start game') : _tttText(context, 'مباراة جديدة', 'New game')),
            )),
          ],
        )),
    );
  }
}
