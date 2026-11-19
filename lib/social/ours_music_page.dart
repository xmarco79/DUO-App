import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _mn = Color(0xFF10101C);
const _mp = Color(0xFF29213D);
const _mg = Color(0xFFD9BC86);
const _ml = Color(0xFFB9A2D5);

class OursMusicPage extends StatefulWidget {
  const OursMusicPage({super.key});
  @override
  State<OursMusicPage> createState() => _OursMusicPageState();
}

class _OursMusicPageState extends State<OursMusicPage> {
  final AudioPlayer player = AudioPlayer();
  final TextEditingController search = TextEditingController();
  final List<Map<String, dynamic>> tracks = [];
  final List<Map<String, dynamic>> playlists = [];

  int current = -1;
  bool loading = true, busy = false, shuffle = false, repeatAll = false, repeatOne = false;
  String view = 'all';
  String? activePlaylist;
  Duration position = Duration.zero, duration = Duration.zero;

  bool get ar => Localizations.localeOf(context).languageCode == 'ar';
  String t(String a, String e) => ar ? a : e;
  Map<String, dynamic>? get selected =>
      current >= 0 && current < tracks.length ? tracks[current] : null;
  bool get playing => player.state == PlayerState.playing;

  @override
  void initState() {
    super.initState();
    _restore();
    player.onPositionChanged.listen((value) {
      if (mounted) setState(() => position = value);
    });
    player.onDurationChanged.listen((value) {
      if (mounted) setState(() => duration = value);
    });
    player.onPlayerStateChanged.listen((_) {
      if (mounted) setState(() {});
    });
    player.onPlayerComplete.listen((_) {
      if (!mounted || tracks.isEmpty) return;
      if (repeatOne && selected != null) {
        player.seek(Duration.zero);
        player.resume();
      } else if (current < tracks.length - 1 || repeatAll || shuffle) {
        _next();
      } else {
        setState(() => position = Duration.zero);
      }
    });
  }

  Future<Directory> _musicDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/ours_music');
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawTracks = prefs.getString('ours_local_music_v2') ??
          prefs.getString('ours_local_music_v1');
      if (rawTracks != null) {
        final restored = (jsonDecode(rawTracks) as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .where((item) => File(item['path']?.toString() ?? '').existsSync())
            .toList();
        for (final track in restored) {
          track.putIfAbsent('id', () => DateTime.now().microsecondsSinceEpoch.toString());
          track.putIfAbsent('artist', () => '');
          track.putIfAbsent('album', () => '');
          track.putIfAbsent('genre', () => 'غير مصنف');
          track.putIfAbsent('favorite', () => false);
        }
        tracks.addAll(restored);
      }
      final rawPlaylists = prefs.getString('ours_music_playlists_v1');
      if (rawPlaylists != null) {
        playlists.addAll((jsonDecode(rawPlaylists) as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item)));
      }
    } catch (error) {
      debugPrint('OURS music restore failed: $error');
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ours_local_music_v2', jsonEncode(tracks));
    await prefs.setString('ours_music_playlists_v1', jsonEncode(playlists));
  }

  Future<void> _addTracks() async {
    if (busy) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
        withData: false,
      );
      if (result == null || !mounted) return;
      setState(() => busy = true);
      final directory = await _musicDirectory();
      int added = 0;
      for (final file in result.files) {
        final sourcePath = file.path;
        if (sourcePath == null) continue;
        final source = File(sourcePath);
        if (!await source.exists()) continue;
        final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._ -]'), '_');
        final target = File('${directory.path}/${DateTime.now().microsecondsSinceEpoch}_$safeName');
        await source.copy(target.path);
        tracks.add({
          'id': DateTime.now().microsecondsSinceEpoch.toString(),
          'name': file.name.replaceFirst(RegExp(r'\.[^.]+$'), ''),
          'path': target.path,
          'artist': '',
          'album': '',
          'genre': 'غير مصنف',
          'favorite': false,
        });
        added++;
      }
      await _persist();
      if (mounted) {
        setState(() {
          if (current < 0 && tracks.isNotEmpty) current = 0;
        });
        _notice(added > 0
            ? t('أُضيف $added مقطعًا إلى المكتبة', 'Added $added tracks to your library')
            : t('تعذرت قراءة الملفات المحددة', 'Could not read the selected files'));
      }
    } catch (error) {
      _notice(t('تعذرت إضافة الموسيقى: $error', 'Could not import music: $error'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _play(int index) async {
    if (index < 0 || index >= tracks.length || busy) return;
    setState(() => busy = true);
    try {
      await player.stop();
      setState(() {
        current = index;
        position = Duration.zero;
        duration = Duration.zero;
      });
      await player.play(DeviceFileSource(tracks[index]['path'].toString()));
    } catch (error) {
      _notice(t('تعذر تشغيل المقطع: $error', 'Could not play track: $error'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _togglePlayback() async {
    if (selected == null) {
      if (tracks.isNotEmpty) await _play(0);
      return;
    }
    try {
      if (playing) {
        await player.pause();
      } else if (player.state == PlayerState.paused) {
        await player.resume();
      } else {
        await _play(current);
      }
    } catch (error) {
      _notice(error.toString());
    }
  }

  Future<void> _next() async {
    if (tracks.isEmpty) return;
    final nextIndex = shuffle && tracks.length > 1
        ? (Random().nextInt(tracks.length - 1) + (current + 1)) % tracks.length
        : current + 1;
    if (nextIndex >= tracks.length && !repeatAll) {
      await player.stop();
      if (mounted) setState(() => position = Duration.zero);
      return;
    }
    await _play(nextIndex % tracks.length);
  }

  Future<void> _previous() async {
    if (tracks.isEmpty) return;
    if (position > const Duration(seconds: 3)) {
      await player.seek(Duration.zero);
      return;
    }
    await _play((current - 1 + tracks.length) % tracks.length);
  }

  Future<void> _toggleFavorite(int index) async {
    tracks[index]['favorite'] = !(tracks[index]['favorite'] == true);
    setState(() {});
    await _persist();
  }

  Future<void> _createPlaylist() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _mp,
        title: Text(t('قائمة تشغيل جديدة', 'New playlist')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 36,
          decoration: InputDecoration(hintText: t('اسم القائمة', 'Playlist name')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t('إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: Text(t('إنشاء', 'Create'))),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    playlists.add({
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'name': name,
      'track_ids': <String>[],
    });
    setState(() => activePlaylist = playlists.last['id'].toString());
    await _persist();
  }

  Future<void> _addToPlaylist(int index) async {
    if (playlists.isEmpty) {
      await _createPlaylist();
      if (playlists.isEmpty) return;
    }
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _mp,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(12), child: Text(t('أضف إلى قائمة تشغيل', 'Add to playlist'), style: const TextStyle(color: _mg, fontWeight: FontWeight.bold))),
          for (final playlist in playlists)
            ListTile(
              leading: const Icon(Icons.queue_music_rounded, color: _mg),
              title: Text(playlist['name'].toString()),
              onTap: () => Navigator.pop(sheetContext, playlist['id'].toString()),
            ),
        ]),
      ),
    );
    if (chosen == null) return;
    final playlist = playlists.firstWhere((item) => item['id'].toString() == chosen);
    final ids = List<String>.from(playlist['track_ids'] ?? []);
    final id = tracks[index]['id'].toString();
    if (!ids.contains(id)) ids.add(id);
    playlist['track_ids'] = ids;
    await _persist();
    _notice(t('تمت إضافة المقطع إلى القائمة', 'Added to playlist'));
  }

  Future<void> _editTrack(int index) async {
    final track = tracks[index];
    final name = TextEditingController(text: track['name']?.toString() ?? '');
    final artist = TextEditingController(text: track['artist']?.toString() ?? '');
    final album = TextEditingController(text: track['album']?.toString() ?? '');
    final genre = TextEditingController(text: track['genre']?.toString() ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _mp,
        title: Text(t('تفاصيل المقطع', 'Track details')),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: InputDecoration(labelText: t('اسم المقطع', 'Track title'))),
          TextField(controller: artist, decoration: InputDecoration(labelText: t('الفنان', 'Artist'))),
          TextField(controller: album, decoration: InputDecoration(labelText: t('الألبوم', 'Album'))),
          TextField(controller: genre, decoration: InputDecoration(labelText: t('التصنيف', 'Genre'))),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t('إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(t('حفظ', 'Save'))),
        ],
      ),
    );
    if (saved == true) {
      track['name'] = name.text.trim().isEmpty ? track['name'] : name.text.trim();
      track['artist'] = artist.text.trim();
      track['album'] = album.text.trim();
      track['genre'] = genre.text.trim().isEmpty ? 'غير مصنف' : genre.text.trim();
      setState(() {});
      await _persist();
    }
    name.dispose();
    artist.dispose();
    album.dispose();
    genre.dispose();
  }

  Future<void> _removeTrack(int index) async {
    final track = tracks[index];
    if (index == current) await player.stop();
    final file = File(track['path'].toString());
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
    final id = track['id'].toString();
    tracks.removeAt(index);
    for (final playlist in playlists) {
      final ids = List<String>.from(playlist['track_ids'] ?? []);
      ids.remove(id);
      playlist['track_ids'] = ids;
    }
    setState(() {
      if (tracks.isEmpty) {
        current = -1;
      } else if (index < current) {
        current--;
      } else if (index == current) {
        current = index.clamp(0, tracks.length - 1).toInt();
        position = Duration.zero;
      }
    });
    await _persist();
  }

  List<MapEntry<int, Map<String, dynamic>>> _visibleTracks() {
    final query = search.text.trim().toLowerCase();
    final ids = activePlaylist == null
        ? null
        : List<String>.from(playlists.firstWhere(
            (item) => item['id'].toString() == activePlaylist,
            orElse: () => <String, dynamic>{'track_ids': <String>[]},
          )['track_ids'] ?? []);
    return tracks.asMap().entries.where((entry) {
      final track = entry.value;
      final searchable = [
        track['name'], track['artist'], track['album'], track['genre'],
      ].join(' ').toString().toLowerCase();
      if (query.isNotEmpty && !searchable.contains(query)) return false;
      if (view == 'favorites' && track['favorite'] != true) return false;
      if (ids != null && !ids.contains(track['id'].toString())) return false;
      return true;
    }).toList();
  }

  void _notice(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatTime(Duration value) =>
      '${value.inMinutes.remainder(60).toString().padLeft(2, '0')}:${value.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    search.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleTracks();
    final maxDuration = duration.inMilliseconds > 0 ? duration.inMilliseconds : 1;
    final currentPosition = position.inMilliseconds.clamp(0, maxDuration);
    return Scaffold(
      backgroundColor: _mn,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF59417B), Color(0xFF25213F), Color(0xFF102B3B)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: _mg.withValues(alpha: .28)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.graphic_eq_rounded, color: _mg, size: 32),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(t('موسيقانا', 'OUR MUSIC'), style: const TextStyle(color: _mg, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        Text(t('مكتبتكما الصوتية', 'Your private music space'), style: const TextStyle(color: _ml, fontSize: 11)),
                      ])),
                      IconButton.filledTonal(
                        onPressed: busy ? null : _addTracks,
                        tooltip: t('استيراد الموسيقى', 'Import music'),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ]),
                    const SizedBox(height: 17),
                    Text(t('كل ما تحب سماعه، في مكان واحد', 'Everything you love, in one place'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Text(t('نظّم مقاطعك، أنشئ قوائمك، واستمع دون مغادرة OURS.',
                        'Organize your tracks, create playlists and listen without leaving OURS.'),
                      style: const TextStyle(color: _ml, fontSize: 12, height: 1.5)),
                    const SizedBox(height: 13),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _statChip(Icons.library_music_outlined, '${tracks.length} ${t('مقطع', 'tracks')}'),
                      _statChip(Icons.favorite_rounded, '${tracks.where((e) => e['favorite'] == true).length} ${t('مفضلة', 'favorites')}'),
                      _statChip(Icons.queue_music_rounded, '${playlists.length} ${t('قائمة', 'playlists')}'),
                    ]),
                  ]),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _nowPlayingCard(maxDuration, currentPosition),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
                child: Row(children: [
                  Expanded(child: Text(t('مكتبتك', 'YOUR LIBRARY'), style: const TextStyle(color: _mg, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
                  TextButton.icon(onPressed: _createPlaylist, icon: const Icon(Icons.create_new_folder_outlined, size: 18), label: Text(t('قائمة جديدة', 'New playlist'))),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterChip('all', t('كل المقاطع', 'All tracks'), Icons.library_music_outlined),
                    const SizedBox(width: 8),
                    _filterChip('favorites', t('المفضلة', 'Favorites'), Icons.favorite_border_rounded),
                    for (final playlist in playlists) ...[
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(Icons.queue_music_rounded, color: _mg, size: 17),
                        label: Text(playlist['name'].toString()),
                        backgroundColor: activePlaylist == playlist['id'].toString() ? _mg.withValues(alpha: .18) : _mp,
                        side: BorderSide(color: activePlaylist == playlist['id'].toString() ? _mg : Colors.transparent),
                        labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
                        onPressed: () => setState(() {
                          activePlaylist = activePlaylist == playlist['id'].toString() ? null : playlist['id'].toString();
                          view = 'all';
                        }),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                child: TextField(
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: t('ابحث بالاسم أو الفنان أو الألبوم', 'Search title, artist or album'),
                    filled: true,
                    fillColor: _mp,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ),
            if (loading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: _mg)))
            else if (visible.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.album_outlined, color: _ml.withValues(alpha: .8), size: 54),
                    const SizedBox(height: 12),
                    Text(tracks.isEmpty ? t('مكتبتك تنتظر أول مقطع', 'Your library is waiting for its first track') : t('لا توجد نتائج هنا', 'Nothing found here'),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 7),
                    Text(t('أضف ملفات صوتية تملك حق استخدامها، ثم رتّبها في قوائمك.',
                        'Import audio files you have the right to use, then organize them into playlists.'),
                      textAlign: TextAlign.center, style: const TextStyle(color: _ml, fontSize: 12)),
                    const SizedBox(height: 14),
                    FilledButton.icon(onPressed: busy ? null : _addTracks, icon: const Icon(Icons.library_add_rounded), label: Text(t('إضافة مقاطع', 'Add tracks'))),
                  ]),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 100),
                sliver: SliverList.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 5),
                  itemBuilder: (context, index) {
                    final entry = visible[index];
                    final trackIndex = entry.key;
                    final track = entry.value;
                    final active = trackIndex == current;
                    return Container(
                      decoration: BoxDecoration(
                        color: active ? _mg.withValues(alpha: .12) : _mp.withValues(alpha: .72),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: active ? _mg.withValues(alpha: .5) : Colors.transparent),
                      ),
                      child: ListTile(
                        onTap: () => _play(trackIndex),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                        leading: Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: active ? const [Color(0xFF9B79C9), Color(0xFF315B72)] : const [Color(0xFF4C3B67), Color(0xFF20394B)]),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(active && playing ? Icons.equalizer_rounded : Icons.music_note_rounded, color: _mg),
                        ),
                        title: Text(track['name']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: active ? _mg : Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                        subtitle: Text([
                          if ((track['artist']?.toString() ?? '').isNotEmpty) track['artist'],
                          if ((track['album']?.toString() ?? '').isNotEmpty) track['album'],
                          if ((track['artist']?.toString() ?? '').isEmpty && (track['album']?.toString() ?? '').isEmpty) t('أكمل بيانات المقطع', 'Add track details'),
                        ].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ml, fontSize: 10)),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _toggleFavorite(trackIndex),
                            icon: Icon(track['favorite'] == true ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: track['favorite'] == true ? const Color(0xFFFF829F) : _ml, size: 20),
                          ),
                          PopupMenuButton<String>(
                            color: _mp,
                            onSelected: (value) {
                              if (value == 'edit') _editTrack(trackIndex);
                              if (value == 'playlist') _addToPlaylist(trackIndex);
                              if (value == 'remove') _removeTrack(trackIndex);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(value: 'edit', child: Text(t('تعديل التفاصيل', 'Edit details'))),
                              PopupMenuItem(value: 'playlist', child: Text(t('إضافة إلى قائمة', 'Add to playlist'))),
                              PopupMenuItem(value: 'remove', child: Text(t('إزالة من المكتبة', 'Remove from library'))),
                            ],
                          ),
                        ]),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .08), borderRadius: BorderRadius.circular(30)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: _mg, size: 14), const SizedBox(width: 6),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _filterChip(String value, String label, IconData icon) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 8),
    child: ChoiceChip(
      selected: view == value && activePlaylist == null,
      onSelected: (_) => setState(() { view = value; activePlaylist = null; }),
      avatar: Icon(icon, size: 16, color: _mg),
      label: Text(label),
      selectedColor: _mg.withValues(alpha: .2),
      backgroundColor: _mp,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
      side: BorderSide(color: view == value && activePlaylist == null ? _mg : Colors.transparent),
    ),
  );

  Widget _nowPlayingCard(int maxDuration, int currentPosition) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF29213D), Color(0xFF142B3A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _mg.withValues(alpha: .2)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 62, height: 62,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8B6BB3), Color(0xFF2F6374)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.album_rounded, color: Colors.white, size: 38),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t('يعمل الآن', 'NOW PLAYING'), style: const TextStyle(color: _mg, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
            const SizedBox(height: 4),
            Text(selected?['name']?.toString() ?? t('اختر مقطعًا من مكتبتك', 'Choose a track from your library'),
              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            Text(selected?['artist']?.toString().isNotEmpty == true ? selected!['artist'].toString() : t('OURS PLAYER', 'OURS PLAYER'),
              style: const TextStyle(color: _ml, fontSize: 10)),
          ])),
          IconButton(onPressed: selected == null ? null : () => _toggleFavorite(current),
            icon: Icon(selected?['favorite'] == true ? Icons.favorite : Icons.favorite_border, color: const Color(0xFFFF91AC))),
        ]),
        Slider(
          value: currentPosition.toDouble(),
          max: maxDuration.toDouble(),
          activeColor: _mg,
          inactiveColor: _ml.withValues(alpha: .2),
          onChanged: selected == null ? null : (value) => setState(() => position = Duration(milliseconds: value.round())),
          onChangeEnd: selected == null ? null : (value) => player.seek(Duration(milliseconds: value.round())),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_formatTime(position), style: const TextStyle(color: _ml, fontSize: 10)),
          Text(_formatTime(duration), style: const TextStyle(color: _ml, fontSize: 10)),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(onPressed: tracks.isEmpty ? null : () => setState(() => shuffle = !shuffle),
            color: shuffle ? _mg : _ml, icon: const Icon(Icons.shuffle_rounded)),
          IconButton(onPressed: tracks.isEmpty ? null : _previous, iconSize: 29, icon: const Icon(Icons.skip_previous_rounded)),
          SizedBox(
            width: 54, height: 54,
            child: FilledButton(
              onPressed: busy || tracks.isEmpty ? null : _togglePlayback,
              style: FilledButton.styleFrom(backgroundColor: _mg, foregroundColor: _mn, shape: const CircleBorder(), padding: EdgeInsets.zero),
              child: busy ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30),
            ),
          ),
          IconButton(onPressed: tracks.isEmpty ? null : _next, iconSize: 29, icon: const Icon(Icons.skip_next_rounded)),
          IconButton(onPressed: tracks.isEmpty ? null : () => setState(() { repeatOne = !repeatOne; if (repeatOne) repeatAll = false; }),
            color: repeatOne ? _mg : _ml, icon: const Icon(Icons.repeat_one_rounded)),
          IconButton(onPressed: tracks.isEmpty ? null : () => setState(() { repeatAll = !repeatAll; if (repeatAll) repeatOne = false; }),
            color: repeatAll ? _mg : _ml, icon: const Icon(Icons.repeat_rounded)),
        ]),
      ]),
    );
  }
}
