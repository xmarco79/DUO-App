import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _aiNavy = Color(0xFF10101C);
const _aiPurple = Color(0xFF29213D);
const _aiLavender = Color(0xFFB9A2D5);
const _aiGold = Color(0xFFD9BC86);

class OursAiPage extends StatefulWidget {
  final String spaceId;

  const OursAiPage({super.key, required this.spaceId});

  @override
  State<OursAiPage> createState() => _OursAiPageState();
}

class _OursAiPageState extends State<OursAiPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _db = Supabase.instance.client;
  final List<Map<String, String>> _messages = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'assistant',
      'content': 'أهلًا بك في OURS AI ✨\nأنا مساعدك داخل عالمكما. اسألني أو اختر إحدى المهام بالأسفل.',
    });
  }

  Future<List<Map<String, String>>> _loadRecentContext() async {
    final rows = await _db
        .from('duo_messages')
        .select('body, sender_id, created_at')
        .eq('space_id', widget.spaceId)
        .order('created_at', ascending: false)
        .limit(25);

    final currentId = _db.auth.currentUser?.id;
    return List<Map<String, dynamic>>.from(rows)
        .reversed
        .map((row) => {
              'sender': row['sender_id'] == currentId ? 'أنا' : 'الشخص الآخر',
              'text': (row['body'] ?? '').toString(),
            })
        .toList();
  }

  Future<void> _send({String? preset, String task = 'chat', bool includeContext = false}) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _messages.add({'role': 'user', 'content': text});
      _input.clear();
    });
    _scrollToBottom();

    try {
      List<Map<String, String>> context = [];
      if (includeContext) {
        context = await _loadRecentContext();
      }

      final history = _messages
          .where((m) => m['role'] == 'user' || m['role'] == 'assistant')
          .toList();
      final payloadMessages = history.length > 12
          ? history.sublist(history.length - 12)
          : history;

      final response = await _db.functions.invoke(
        'ours-ai',
        body: {
          'space_id': widget.spaceId,
          'task': task,
          'messages': payloadMessages,
          'context': context,
        },
      );

      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data)
          : <String, dynamic>{};

      if (response.status != 200) {
        final error = data['error']?.toString() ?? 'AI_PROVIDER_ERROR';
        if (error == 'GEMINI_SETUP_REQUIRED') {
          throw Exception('مساعد OURS يحتاج إلى إعداد مفتاح Gemini المجاني على الخادم بواسطة ولي الأمر.');
        }
        if (error == 'AI_LIMIT_REACHED') {
          throw Exception('وصلنا إلى حد الاستخدام الحالي. حاول لاحقًا.');
        }
        throw Exception('تعذر الحصول على رد من OURS AI.');
      }

      final answer = data['answer']?.toString() ?? '';
      if (answer.isEmpty) throw Exception('وصل رد فارغ من المساعد.');

      if (!mounted) return;
      setState(() => _messages.add({'role': 'assistant', 'content': answer}));
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': e.toString().replaceFirst('Exception: ', ''),
        });
      });
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _quickAction(IconData icon, String title, String prompt, String task) {
    return ActionChip(
      avatar: Icon(icon, color: _aiGold, size: 18),
      label: Text(title, style: const TextStyle(color: Colors.white)),
      backgroundColor: _aiPurple,
      side: BorderSide(color: _aiGold.withOpacity(.25)),
      onPressed: _sending
          ? null
          : () => _send(preset: prompt, task: task, includeContext: true),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _aiNavy,
      appBar: AppBar(
        backgroundColor: _aiNavy,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: _aiGold),
            SizedBox(width: 9),
            Text('OURS AI', style: TextStyle(color: _aiGold, letterSpacing: 2)),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _quickAction(Icons.summarize, 'تلخيص محادثاتنا',
                      'لخّص آخر محادثاتنا بشكل مرتب، واستخرج أبرز المواضيع واللحظات المهمة دون اختلاق تفاصيل.',
                      'summary'),
                  _quickAction(Icons.lightbulb_outline, 'أفكار لنا',
                      'اقترح أنشطة وأفكارًا ممتعة ومناسبة لشخصين يمكننا إضافتها إلى وقتنا معًا.',
                      'ideas'),
                  _quickAction(Icons.collections_bookmark_outlined, 'ترتيب الذكريات',
                      'استخرج من السياق المرفق اقتراحات لعناوين وتصنيفات ذكريات، ولا تحفظ أو تغيّر أي شيء.',
                      'memories'),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 4, 18, 8),
              child: Text(
                'تُرسل رسائلك إلى Google Gemini للرد. ولا تُرسل محادثات المساحة إلا عند اختيار مهمة تستخدم سياقها. قد تستخدم Google بيانات الفئة المجانية لتحسين خدماتها؛ تجنب إرسال معلومات خاصة جدًا.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _aiLavender, fontSize: 11, height: 1.4),
              ),
            ),
            const Divider(color: Color(0x3329293D)),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final item = _messages[index];
                  final isUser = item['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 310),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(
                        color: isUser ? _aiPurple : const Color(0xFF211D30),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _aiGold.withOpacity(.22)),
                      ),
                      child: SelectableText(
                        item['content'] ?? '',
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(color: Colors.white, height: 1.5),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_sending)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(color: _aiGold, minHeight: 2),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              decoration: BoxDecoration(
                color: _aiPurple,
                border: Border(top: BorderSide(color: _aiGold.withOpacity(.2))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      textDirection: TextDirection.rtl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالتك إلى OURS AI...',
                        filled: true,
                        fillColor: _aiNavy,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : () => _send(),
                    icon: const Icon(Icons.send_rounded, color: _aiGold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
