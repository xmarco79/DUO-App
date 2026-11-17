import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _albumGold = Color(0xFFD9BC86);
const _albumPurple = Color(0xFF29213D);
const _albumLavender = Color(0xFFB9A2D5);
String _albumText(BuildContext context, String ar, String en) => Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

class OursAlbumsPage extends StatefulWidget {
  final String spaceId;
  const OursAlbumsPage({super.key, required this.spaceId});

  @override
  State<OursAlbumsPage> createState() => _OursAlbumsPageState();
}

class _OursAlbumsPageState extends State<OursAlbumsPage> {
  final db = Supabase.instance.client;
  final picker = ImagePicker();
  List<Map<String, dynamic>> albums = [];
  bool loading = true;
  bool busy = false;
  RealtimeChannel? channel;

  @override
  void initState() {
    super.initState();
    loadAlbums();
    channel = db.channel('ours-albums-${widget.spaceId}')
      .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'duo_albums',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'space_id', value: widget.spaceId),
        callback: (_) => loadAlbums())
      .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'duo_album_media',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'space_id', value: widget.spaceId),
        callback: (_) => loadAlbums())
      ..subscribe();
  }

  Future<void> loadAlbums() async {
    try {
      final rows = await db.from('duo_albums').select().eq('space_id', widget.spaceId).order('created_at', ascending: false);
      if (!mounted) return;
      setState(() { albums = List<Map<String, dynamic>>.from(rows); loading = false; });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> createAlbum() async {
    final title = TextEditingController();
    final description = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: _albumPurple,
      title: Text(_albumText(context, 'ألبوم جديد', 'New album')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, maxLength: 100, decoration: const InputDecoration(labelText: _albumText(context, 'اسم الألبوم', 'Album name'))),
        TextField(controller: description, maxLines: 2, decoration: const InputDecoration(labelText: _albumText(context, 'وصف اختياري', 'Optional description'))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_albumText(context, 'إلغاء', 'Cancel'))),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(_albumText(context, 'إنشاء', 'Create'))),
      ],
    ));
    if (ok != true || title.text.trim().isEmpty) { title.dispose(); description.dispose(); return; }
    setState(() => busy = true);
    try {
      await db.from('duo_albums').insert({
        'space_id': widget.spaceId,
        'created_by': db.auth.currentUser!.id,
        'title': title.text.trim(),
        'description': description.text.trim(),
      });
      await loadAlbums();
    } catch (e) {
      _message(_albumText(context, 'تعذر إنشاء الألبوم: $e', 'Could not create album: $e'));
    } finally {
      title.dispose(); description.dispose();
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> addPhoto(String albumId) async {
    if (busy) return;
    try {
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 2200);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty || bytes.length > 15 * 1024 * 1024) {
        _message('الصورة فارغة أو تتجاوز 15 ميجابايت'); return;
      }
      final ext = picked.name.contains('.') ? picked.name.split('.').last.toLowerCase() : 'jpg';
      const allowed = {'jpg','jpeg','png','webp'};
      if (!allowed.contains(ext)) { _message('الصيغة غير مدعومة'); return; }
      final mime = switch(ext) {'png'=>'image/png','webp'=>'image/webp',_=>'image/jpeg'};
      final userId = db.auth.currentUser!.id;
      final path = '${widget.spaceId}/$userId/albums/$albumId/${DateTime.now().microsecondsSinceEpoch}.$ext';
      setState(() => busy = true);
      await db.storage.from('duo-private').uploadBinary(path, bytes,
        fileOptions: FileOptions(contentType: mime, cacheControl: '3600', upsert: false));
      try {
        await db.from('duo_album_media').insert({
          'album_id': albumId, 'space_id': widget.spaceId,
          'uploaded_by': userId, 'storage_path': path, 'media_type': 'image',
        });
      } catch (_) {
        await db.storage.from('duo-private').remove([path]);
        rethrow;
      }
      await loadAlbums();
    } catch (e) {
      _message('تعذر رفع الصورة: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _message(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    if (channel != null) db.removeChannel(channel!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_albumText(context, 'ألبومات OURS', 'OURS albums'))),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: busy ? null : createAlbum,
      backgroundColor: _albumGold,
      foregroundColor: Colors.black,
      icon: const Icon(Icons.add_photo_alternate_outlined),
      label: const Text('ألبوم جديد'),
    ),
    body: loading ? const Center(child: CircularProgressIndicator(color: _albumGold))
      : albums.isEmpty ? const Center(child: Text('أنشئا أول ألبوم لذكرياتكما', style: TextStyle(color: _albumLavender)))
      : ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
        itemCount: albums.length,
        itemBuilder: (ctx, i) {
          final album = albums[i];
          return Card(color: _albumPurple, child: ListTile(
            leading: const CircleAvatar(backgroundColor: _albumGold, child: Icon(Icons.photo_album_outlined, color: Colors.black)),
            title: Text(album['title']?.toString() ?? 'ألبوم'),
            subtitle: Text(album['description']?.toString() ?? '', style: const TextStyle(color: _albumLavender)),
            trailing: const Icon(Icons.arrow_forward_ios, color: _albumGold, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
              OursAlbumDetailPage(spaceId: widget.spaceId, album: album))),
          ));
        },
      ),
  );
}

class OursAlbumDetailPage extends StatefulWidget {
  final String spaceId;
  final Map<String, dynamic> album;
  const OursAlbumDetailPage({super.key, required this.spaceId, required this.album});
  @override
  State<OursAlbumDetailPage> createState() => _OursAlbumDetailPageState();
}

class _OursAlbumDetailPageState extends State<OursAlbumDetailPage> {
  final db = Supabase.instance.client;
  List<Map<String, dynamic>> media = [];
  bool loading = true;
  RealtimeChannel? channel;

  @override
  void initState() {
    super.initState();
    load();
    channel = db.channel('ours-album-media-${widget.album['id']}')
      .onPostgresChanges(event: PostgresChangeEvent.all, schema: 'public', table: 'duo_album_media',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'album_id', value: widget.album['id']),
        callback: (_) => load())..subscribe();
  }

  Future<void> load() async {
    try {
      final rows = await db.from('duo_album_media').select().eq('album_id', widget.album['id']).order('created_at', ascending: false);
      if (!mounted) return;
      setState(() { media = List<Map<String, dynamic>>.from(rows); loading = false; });
    } catch (_) { if (mounted) setState(() => loading = false); }
  }

  Future<String> signed(String path) => db.storage.from('duo-private').createSignedUrl(path, 900);

  @override
  void dispose() { if (channel != null) db.removeChannel(channel!); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.album['title']?.toString() ?? 'الألبوم')),
    body: loading ? const Center(child: CircularProgressIndicator(color: _albumGold))
      : media.isEmpty ? const Center(child: Text('لا توجد صور في هذا الألبوم بعد'))
      : GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: media.length,
        itemBuilder: (ctx, i) => FutureBuilder<String>(
          future: signed(media[i]['storage_path'].toString()),
          builder: (ctx, snap) => GestureDetector(
            onTap: snap.hasData ? () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
              Scaffold(backgroundColor: Colors.black, appBar: AppBar(), body: Center(child: InteractiveViewer(child: Image.network(snap.data!, fit: BoxFit.contain)))))) : null,
            child: ClipRRect(borderRadius: BorderRadius.circular(12), child: snap.hasData
              ? Image.network(snap.data!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image))
              : const ColoredBox(color: _albumPurple, child: Center(child: CircularProgressIndicator(color: _albumGold)))),
          ),
        ),
      ),
  );
}
