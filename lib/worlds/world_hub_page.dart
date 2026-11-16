import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

const _navy = Color(0xFF10101C);
const _purple = Color(0xFF29213D);
const _lavender = Color(0xFFB9A2D5);
const _gold = Color(0xFFD9BC86);

class OursWorldHubPage extends StatefulWidget {
  const OursWorldHubPage({
    super.key,
    required this.spaceId,
    required this.worldIndex,
  });

  final String? spaceId;
  final int worldIndex;

  @override
  State<OursWorldHubPage> createState() => _OursWorldHubPageState();
}

class _OursWorldHubPageState extends State<OursWorldHubPage> {
  bool loading = false;
  String? error;
  String? selectedKind;
  List<Map<String, dynamic>> items = [];
  final AudioRecorder voiceRecorder = AudioRecorder();
  final AudioPlayer voicePlayer = AudioPlayer();
  bool recordingVoice = false;
  String? activeVoicePath;
  String? playingVoicePath;

  SupabaseClient get db => Supabase.instance.client;
  bool get canSync => widget.spaceId != null && db.auth.currentUser != null;

  static const worlds = [
    ('Connect', 'تواصلا وشاركا تفاصيل يومكما', Icons.forum_rounded, 'connect'),
    ('Universe', 'ابنيا عالمكما الخاص وزيّناه', Icons.public_rounded, 'universe'),
    ('Play', 'أسئلة وألعاب وتحديات خفيفة', Icons.sports_esports_rounded, 'play'),
    ('Memories', 'اجمعا اللحظات والرسائل التي لا تُنسى', Icons.auto_awesome_rounded, 'memories'),
    ('Together', 'خططا للأشياء التي تريدان فعلها معًا', Icons.favorite_rounded, 'together'),
  ];

  static const features = [
    [
      ('Little Notes', 'ملاحظات مشتركة', Icons.sticky_note_2_outlined),
      ('Voice Diary', 'يوميات صوتية', Icons.mic_none_rounded),
      ('Our List', 'قائمة مشتركة', Icons.checklist_rounded),
      ('Our Radio', 'رسائل صوتية قصيرة', Icons.radio_rounded),
      ('I’m Here', 'إشارة لطيفة بأنك موجود', Icons.waving_hand_outlined),
    ],
    [
      ('Our Little Planet', 'الكوكب المشترك', Icons.language_rounded),
      ('Our Garden', 'حديقة تنمو مع نشاطكما', Icons.local_florist_outlined),
      ('Themes & Symbols', 'الثيمات والرموز', Icons.palette_outlined),
      ('Constellation', 'نجوم من ذكرياتكما', Icons.stars_rounded),
      ('Our Aquarium', 'حوضكما الافتراضي', Icons.water_outlined),
    ],
    [
      ('Question of the Day', 'سؤال اليوم', Icons.help_outline_rounded),
      ('This or That', 'هذا أم ذاك؟', Icons.compare_arrows_rounded),
      ('Who Knows Who?', 'من يعرف الآخر أكثر؟', Icons.psychology_alt_outlined),
      ('Spin Together', 'عجلة الاختيارات', Icons.casino_outlined),
      ('Our Votes', 'تصويت مشترك', Icons.how_to_vote_outlined),
      ('Mini Missions', 'مهام بسيطة وآمنة', Icons.task_alt_rounded),
    ],
    [
      ('Our Memories', 'خط زمني للحظاتكما', Icons.photo_library_outlined),
      ('Time Capsule', 'رسائل للمستقبل', Icons.inventory_2_outlined),
      ('Our Scrapbook', 'ألبوم القصاصات', Icons.collections_bookmark_outlined),
      ('Open When', 'رسائل لمناسبات محددة', Icons.mail_outline_rounded),
      ('The Archive', 'أرشيف الذكريات', Icons.archive_outlined),
      ('Our Wrapped', 'ملخص شهري', Icons.auto_graph_rounded),
    ],
    [
      ('Bucket List', 'أشياء نريد تجربتها', Icons.checklist_rounded),
      ('Our Calendar', 'مواعيد ومناسبات', Icons.calendar_month_outlined),
      ('Our Goals', 'أهداف مشتركة', Icons.flag_outlined),
      ('Places to Go', 'أماكن نريد زيارتها', Icons.place_outlined),
      ('Focus Together', 'جلسة تركيز مشتركة', Icons.timer_outlined),
      ('Future Predictions', 'توقعات نفتحها لاحقًا', Icons.auto_awesome_outlined),
    ],
  ];

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  @override
  void didUpdateWidget(covariant OursWorldHubPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.worldIndex != widget.worldIndex ||
        oldWidget.spaceId != widget.spaceId) {
      selectedKind = null;
      loadItems();
    }
  }

  Future<void> loadItems() async {
    if (!canSync) {
      if (mounted) setState(() {
        items = [];
        loading = false;
        error = null;
      });
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      var query = db.from('duo_world_items').select()
          .eq('space_id', widget.spaceId!)
          .eq('world', worlds[widget.worldIndex].$4);
      if (selectedKind != null) query = query.eq('kind', selectedKind!);
      final result = await query.order('is_pinned', ascending: false)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        items = List<Map<String, dynamic>>.from(result);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object e) {
    final value = e.toString();
    if (value.contains('SocketException') || value.contains('Failed host lookup')) {
      return 'تعذر الاتصال بالإنترنت. تحقق من الشبكة ثم أعد المحاولة.';
    }
    if (value.contains('PGRST') || value.contains('duo_world_items')) {
      return 'ميزة التخزين لم تجهز بعد. حدّث التطبيق أو راجع إعداد قاعدة البيانات.';
    }
    return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
  }

  Future<void> recordVoiceEntry(String title, String content) async {
    if (!canSync) {
      _snack('تسجيل اليوميات الصوتية يتطلب تسجيل الدخول إلى مساحة مشتركة.');
      return;
    }
    try {
      if (!recordingVoice) {
        final permitted = await voiceRecorder.hasPermission();
        if (!permitted) {
          _snack('اسمح باستخدام الميكروفون لتسجيل اليوميات الصوتية.');
          return;
        }
        final dir = await getTemporaryDirectory();
        activeVoicePath = '${dir.path}/ours_voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
        await voiceRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 96000,
            sampleRate: 44100,
            numChannels: 1,
            echoCancel: true,
            noiseSuppress: true,
          ),
          path: activeVoicePath!,
        );
        if (mounted) setState(() => recordingVoice = true);
        return;
      }
      final path = await voiceRecorder.stop();
      if (mounted) setState(() => recordingVoice = false);
      if (path == null) return;
      final file = File(path);
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length > 15 * 1024 * 1024) {
        _snack('التسجيل فارغ أو يتجاوز الحد المسموح (15 MB).');
        return;
      }
      final userId = db.auth.currentUser!.id;
      final storagePath = '${widget.spaceId}/$userId/voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
      await db.storage.from('duo-private').uploadBinary(
        storagePath,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'audio/mp4',
          cacheControl: '3600',
          upsert: false,
        ),
      );
      try {
        await createItem('Voice Diary', title.trim().isEmpty ? 'يوميات صوتية' : title,
          content, payload: {'audio_path': storagePath, 'audio_mime': 'audio/mp4'});
      } catch (_) {
        await db.storage.from('duo-private').remove([storagePath]);
        rethrow;
      }
      await file.delete();
      _snack('تم حفظ التسجيل الصوتي في يومياتكما');
    } catch (e) {
      if (mounted) {
        setState(() => recordingVoice = false);
        _snack(_friendlyError(e));
      }
    }
  }

  Future<void> playVoice(String path) async {
    try {
      if (playingVoicePath == path && voicePlayer.state == PlayerState.playing) {
        await voicePlayer.pause();
        return;
      }
      final url = await db.storage.from('duo-private').createSignedUrl(path, 900);
      if (mounted) setState(() => playingVoicePath = path);
      await voicePlayer.play(UrlSource(url));
    } catch (e) {
      _snack('تعذر تشغيل التسجيل الصوتي. تحقق من الاتصال والصلاحيات.');
    }
  }

  Future<void> createItem(String kind, String title, String content, {Map<String, dynamic> payload = const {}, DateTime? dueAt}) async {
    if (!canSync) {
      _snack('هذه معاينة فقط. سجّل الدخول وأنشئ مساحة لحفظ بياناتكما.');
      return;
    }
    try {
      await db.from('duo_world_items').insert({
        'space_id': widget.spaceId,
        'created_by': db.auth.currentUser!.id,
        'world': worlds[widget.worldIndex].$4,
        'kind': kind,
        'title': title.trim(),
        'content': content.trim(),
        'payload': payload,
        'due_at': dueAt?.toUtc().toIso8601String(),
      });
      if (!mounted) return;
      _snack('تم الحفظ في مساحتكما');
      await loadItems();
    } catch (e) {
      _snack(_friendlyError(e));
    }
  }

  Future<void> voteOnItem(Map<String, dynamic> item, int optionIndex) async {
    if (!canSync) return;
    try {
      final payload = Map<String, dynamic>.from(item['payload'] is Map ? item['payload'] : {});
      final votes = Map<String, dynamic>.from(payload['votes'] is Map ? payload['votes'] : {});
      votes[db.auth.currentUser!.id] = optionIndex;
      payload['votes'] = votes;
      await db.from('duo_world_items').update({
        'payload': payload,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', item['id']).eq('space_id', widget.spaceId!);
      await loadItems();
    } catch (e) {
      _snack(_friendlyError(e));
    }
  }

  Future<void> toggleTask(Map<String, dynamic> item, int taskIndex, bool done) async {
    try {
      final payload = Map<String, dynamic>.from(item['payload'] is Map ? item['payload'] : {});
      final tasks = List<Map<String, dynamic>>.from(
        (payload['tasks'] is List ? payload['tasks'] as List : const [])
            .map((v) => Map<String, dynamic>.from(v as Map)),
      );
      if (taskIndex < 0 || taskIndex >= tasks.length) return;
      tasks[taskIndex]['done'] = done;
      payload['tasks'] = tasks;
      await db.from('duo_world_items').update({
        'payload': payload,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', item['id']).eq('space_id', widget.spaceId!);
      await loadItems();
    } catch (e) {
      _snack(_friendlyError(e));
    }
  }

  Future<void> togglePin(Map<String, dynamic> item) async {
    try {
      await db.from('duo_world_items').update({
        'is_pinned': !(item['is_pinned'] == true),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', item['id']).eq('space_id', widget.spaceId!);
      await loadItems();
    } catch (e) {
      _snack(_friendlyError(e));
    }
  }

  Future<void> deleteItem(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    final confirm = prefs.getBool('ours_confirm_delete') ?? true;
    if (confirm && mounted) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _purple,
          title: const Text('تأكيد الحذف'),
          content: const Text('هل تريد حذف هذا العنصر من المساحة المشتركة؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
          ],
        ),
      );
      if (accepted != true) return;
    }
    try {
      await db.from('duo_world_items').delete()
          .eq('id', item['id']).eq('space_id', widget.spaceId!);
      await loadItems();
    } catch (e) {
      _snack(_friendlyError(e));
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _showEditor(String kind) async {
    final title = TextEditingController();
    final body = TextEditingController();
    final options = TextEditingController();
    DateTime? dueDate;
    final feature = features[widget.worldIndex]
        .firstWhere((entry) => entry.$1 == kind);
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _purple,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(22, 22, 22,
            MediaQuery.of(context).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: StatefulBuilder(
          builder: (context, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Icon(feature.$3, color: _gold),
                const SizedBox(width: 10),
                Expanded(child: Text(feature.$1,
                    style: const TextStyle(fontSize: 20, color: _gold))),
              ]),
              const SizedBox(height: 8),
              Text(feature.$2, style: const TextStyle(color: _lavender)),
              const SizedBox(height: 18),
              TextField(controller: title, maxLength: 140,
                decoration: const InputDecoration(
                  labelText: 'العنوان', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: body, minLines: 3, maxLines: 7,
                maxLength: 10000,
                decoration: const InputDecoration(
                  labelText: 'اكتب التفاصيل هنا', border: OutlineInputBorder())),
              if (kind == 'Voice Diary')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: FilledButton.icon(
                    onPressed: () => recordVoiceEntry(title.text, body.text),
                    icon: Icon(recordingVoice ? Icons.stop_circle_outlined : Icons.mic_none_rounded),
                    label: Text(recordingVoice ? 'إيقاف التسجيل وحفظه' : 'بدء تسجيل صوتي'),
                    style: FilledButton.styleFrom(
                      backgroundColor: recordingVoice ? Colors.red.shade800 : _gold,
                      foregroundColor: recordingVoice ? Colors.white : _navy,
                    ),
                  ),
                ),
              if (kind == 'Our Votes' || kind == 'This or That' || kind == 'Our List' || kind == 'Mini Missions' || kind == 'Bucket List')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(
                    controller: options,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: (kind == 'Our List' || kind == 'Mini Missions' || kind == 'Bucket List') ? 'المهام (كل مهمة في سطر)' : 'الخيارات (كل خيار في سطر)',
                      hintText: 'الخيار الأول\nالخيار الثاني',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              if (worlds[widget.worldIndex].$4 == 'together' || worlds[widget.worldIndex].$4 == 'memories')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        builder: (context, child) => Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: _gold, surface: _purple, onSurface: Colors.white),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) setSheetState(() => dueDate = picked);
                    },
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(dueDate == null
                        ? (worlds[widget.worldIndex].$4 == 'memories' ? 'تحديد تاريخ فتح الذكرى' : 'تحديد تاريخ (اختياري)')
                        : 'التاريخ: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (title.text.trim().isNotEmpty) Navigator.pop(context, true);
                },
                child: const Text('حفظ'),
              ),
            ],
          ),
        ),
        ),
      ),
    );
    if (result == true && title.text.trim().isNotEmpty) {
      final lines = options.text.split('\n').map((v) => v.trim())
          .where((v) => v.isNotEmpty).take(30).toList();
      final isTaskList = kind == 'Our List' || kind == 'Mini Missions' || kind == 'Bucket List';
      final payload = isTaskList
          ? {'tasks': lines.map((v) => {'title': v, 'done': false}).toList()}
          : lines.length >= 2 ? {'options': lines.take(6).toList(), 'votes': <String, dynamic>{}} : {};
      await createItem(kind, title.text, body.text, payload: payload, dueAt: dueDate);
    }
    title.dispose();
    body.dispose();
    options.dispose();
  }

  @override
  void dispose() {
    if (recordingVoice) {
      voiceRecorder.stop();
    }
    voiceRecorder.dispose();
    voicePlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final world = worlds[widget.worldIndex];
    final worldFeatures = features[widget.worldIndex];
    return Scaffold(
      backgroundColor: _navy,
      floatingActionButton: canSync
          ? FloatingActionButton(
              backgroundColor: _gold,
              foregroundColor: _navy,
              onPressed: () => _showEditor(worldFeatures.first.$1),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: loadItems,
        color: _gold,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('YOUR PRIVATE UNIVERSE',
                        style: TextStyle(color: _gold, letterSpacing: 3, fontSize: 10)),
                    const SizedBox(height: 16),
                    Row(children: [
                      Icon(world.$3, color: _gold, size: 34),
                      const SizedBox(width: 12),
                      Text(world.$1, style: const TextStyle(
                          color: _gold, fontSize: 29, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 8),
                    Text(world.$2, style: const TextStyle(color: _lavender)),
                    const SizedBox(height: 20),
                    if (!canSync)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _purple,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _lavender.withOpacity(.2)),
                        ),
                        child: const Row(children: [
                          Icon(Icons.visibility_outlined, color: _gold),
                          SizedBox(width: 10),
                          Expanded(child: Text(
                            'وضع المعاينة: يمكنك استكشاف الميزات، لكن الحفظ يتطلب حسابًا ومساحة مشتركة.',
                            style: TextStyle(color: _lavender, height: 1.5))),
                        ]),
                      ),
                    const SizedBox(height: 18),
                    const Text('الميزات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: worldFeatures.map((feature) {
                    final active = selectedKind == feature.$1;
                    return ActionChip(
                      avatar: Icon(feature.$3, size: 17, color: active ? _navy : _gold),
                      label: Text(feature.$1),
                      backgroundColor: active ? _gold : _purple,
                      labelStyle: TextStyle(color: active ? _navy : Colors.white),
                      onPressed: () {
                        setState(() => selectedKind = active ? null : feature.$1);
                        loadItems();
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      const Expanded(child: Text('مساحتكما المشتركة',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600))),
                      IconButton(onPressed: loadItems,
                          icon: const Icon(Icons.refresh, color: _lavender)),
                    ]),
                    if (loading)
                      const Padding(padding: EdgeInsets.all(30),
                          child: Center(child: CircularProgressIndicator(color: _gold)))
                    else if (error != null)
                      Card(color: _purple, child: ListTile(
                        leading: const Icon(Icons.error_outline, color: _gold),
                        title: Text(error!),
                        trailing: TextButton(onPressed: loadItems, child: const Text('إعادة'))))
                    else if (items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(color: _purple,
                          borderRadius: BorderRadius.circular(18)),
                        child: const Column(children: [
                          Icon(Icons.auto_awesome_outlined, color: _gold, size: 32),
                          SizedBox(height: 10),
                          Text('لا توجد إضافات بعد', style: TextStyle(fontSize: 17)),
                          SizedBox(height: 6),
                          Text('اختارا ميزة وابدآ بإضافة أول ذكرى أو فكرة أو ملاحظة.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _lavender, height: 1.5)),
                        ]),
                      )
                    else
                      ...items.map((item) {
                        final payload = Map<String, dynamic>.from(
                            item['payload'] is Map ? item['payload'] : {});
                        final choices = List<String>.from(payload['options'] is List
                            ? payload['options'] : const []);
                        final votes = Map<String, dynamic>.from(
                            payload['votes'] is Map ? payload['votes'] : {});
                        final tasks = List<Map<String, dynamic>>.from(
                          (payload['tasks'] is List ? payload['tasks'] as List : const [])
                              .map((v) => Map<String, dynamic>.from(v as Map)),
                        );
                        final myVote = votes[db.auth.currentUser?.id];
                        final audioPath = payload['audio_path']?.toString();
                        return Card(
                          color: _purple,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(children: [
                                  Icon(item['is_pinned'] == true
                                      ? Icons.push_pin : Icons.notes_rounded, color: _gold),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(item['title']?.toString() ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.w600))),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'pin') togglePin(item);
                                      if (value == 'delete') deleteItem(item);
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(value: 'pin', child: Text('تثبيت / إلغاء التثبيت')),
                                      PopupMenuItem(value: 'delete', child: Text('حذف')),
                                    ],
                                  ),
                                ]),
                                if (audioPath != null && audioPath.isNotEmpty)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: FilledButton.tonalIcon(
                                      onPressed: () => playVoice(audioPath),
                                      icon: Icon(
                                        playingVoicePath == audioPath && voicePlayer.state == PlayerState.playing
                                            ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      ),
                                      label: const Text('تشغيل التسجيل الصوتي'),
                                    ),
                                  ),
                                if (item['due_at'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(children: [
                                      const Icon(Icons.event, size: 15, color: _gold),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${isTimeCapsule ? 'تُفتح الذكرى' : 'الموعد'}: ${DateFormat('dd/MM/yyyy').format(unlockAt ?? DateTime.parse(item['due_at'].toString()).toLocal())}',
                                        style: const TextStyle(color: _gold, fontSize: 12),
                                      ),
                                    ]),
                                  ),
                                final unlockAt = item['due_at'] == null
                                    ? null : DateTime.tryParse(item['due_at'].toString())?.toLocal();
                                final isTimeCapsule = item['kind'] == 'Time Capsule';
                                final isLockedCapsule = isTimeCapsule &&
                                    unlockAt != null && unlockAt.isAfter(DateTime.now());
                                if (isLockedCapsule)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(children: [
                                      const Icon(Icons.lock_clock, color: _gold, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(
                                        'رسالة مغلقة حتى ${DateFormat('dd/MM/yyyy').format(unlockAt)}',
                                        style: const TextStyle(color: _gold),
                                      )),
                                    ]),
                                  ),
                                if (!isLockedCapsule && (item['content']?.toString() ?? '').isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6, bottom: 8),
                                    child: Text(item['content'].toString(),
                                      style: const TextStyle(color: _lavender, height: 1.4)),
                                  ),
                                if (tasks.isNotEmpty) ...[
                                  const Divider(color: _lavender),
                                  ...List.generate(tasks.length, (index) => CheckboxListTile(
                                    value: tasks[index]['done'] == true,
                                    onChanged: canSync ? (value) => toggleTask(item, index, value == true) : null,
                                    activeColor: _gold,
                                    checkColor: _navy,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(tasks[index]['title']?.toString() ?? '',
                                      style: TextStyle(
                                        color: _lavender,
                                        decoration: tasks[index]['done'] == true
                                            ? TextDecoration.lineThrough : TextDecoration.none,
                                      )),
                                  )),
                                  Text('${tasks.where((task) => task['done'] == true).length} / ${tasks.length} مكتملة',
                                    style: const TextStyle(color: _lavender, fontSize: 12)),
                                ],
                                if (choices.isNotEmpty) ...[
                                  const Divider(color: _lavender),
                                  ...List.generate(choices.length, (index) {
                                    final count = votes.values.where((v) => v == index).length;
                                    final selected = myVote == index;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: OutlinedButton(
                                        onPressed: canSync ? () => voteOnItem(item, index) : null,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: selected ? _gold : Colors.white,
                                          side: BorderSide(color: selected ? _gold : _lavender.withOpacity(.3)),
                                        ),
                                        child: Row(children: [
                                          Expanded(child: Text(choices[index])),
                                          Text('$count'),
                                          if (selected) const Padding(
                                            padding: EdgeInsets.only(left: 6),
                                            child: Icon(Icons.check_circle, size: 17, color: _gold)),
                                        ]),
                                      ),
                                    );
                                  }),
                                  Text('عدد الأصوات: ${votes.length}',
                                      style: const TextStyle(color: _lavender, fontSize: 12)),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 14),
                    ...worldFeatures.map((feature) => OutlinedButton.icon(
                      onPressed: () => _showEditor(feature.$1),
                      icon: Icon(feature.$3, size: 18),
                      label: Text('إضافة إلى ${feature.$1}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _lavender,
                        side: BorderSide(color: _lavender.withOpacity(.25)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
