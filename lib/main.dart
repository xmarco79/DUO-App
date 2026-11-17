import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_page.dart';

// ==================== COLORS ====================

const navy = Color(0xFF10101C);
const purple = Color(0xFF29213D);
const lavender = Color(0xFFB9A2D5);
const gold = Color(0xFFD9BC86);

// ==================== MAIN ====================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://sthlcrgwpzqhxtpevqwg.supabase.co',
    publishableKey: 'sb_publishable_xUgF7Wh8fE4wMpuZSrROwA_DNdPJKGM',
  );

  runApp(const OursApp());
}

// ==================== APP ====================

class OursApp extends StatelessWidget {
  const OursApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OURS',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: navy,
        colorScheme: const ColorScheme.dark(
          primary: gold,
          secondary: lavender,
          surface: purple,
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// ==================== LOGIN PAGE ====================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();

  bool loading = false;
  bool creatingAccount = false;

  SupabaseClient get db => Supabase.instance.client;

  void showMessage(String value) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  Future<void> login() async {
    final user = username.text.trim().toLowerCase();

    if (user.isEmpty || password.text.isEmpty) {
      showMessage('أدخل اسم المستخدم وكلمة المرور');
      return;
    }

    setState(() => loading = true);

    try {
      final response = await db.functions.invoke(
        'duo-username-login',
        body: {
          'username': user,
          'password': password.text,
        },
      );

      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data)
          : <String, dynamic>{};

      if (response.status != 200) {
        throw Exception(data['error'] ?? 'تعذر تسجيل الدخول');
      }

      final refreshToken = data['refresh_token'];

      if (refreshToken == null) {
        throw Exception('لم يتم استلام بيانات الجلسة');
      }

      await db.auth.setSession(refreshToken);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    } catch (e) {
      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> register() async {
    final user = username.text.trim().toLowerCase();
    final pass = password.text;
    final confirm = confirmPassword.text;

    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(user)) {
      showMessage(
        'اسم المستخدم يجب أن يكون من 3 إلى 20 حرفًا، '
        'ويحتوي على أحرف إنجليزية أو أرقام أو _ فقط',
      );
      return;
    }

    if (pass.length < 8) {
      showMessage('كلمة المرور يجب أن تكون 8 أحرف على الأقل');
      return;
    }

    if (pass != confirm) {
      showMessage('كلمتا المرور غير متطابقتين');
      return;
    }

    setState(() => loading = true);

    try {
      final response = await db.functions.invoke(
        'duo-username-register',
        body: {
          'username': user,
          'password': pass,
        },
      );

      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data)
          : <String, dynamic>{};

      if (response.status != 200) {
        throw Exception(data['error'] ?? 'تعذر إنشاء الحساب');
      }

      final loginResponse = await db.functions.invoke(
        'duo-username-login',
        body: {
          'username': user,
          'password': pass,
        },
      );

      final loginData = loginResponse.data is Map
          ? Map<String, dynamic>.from(loginResponse.data)
          : <String, dynamic>{};

      if (loginResponse.status != 200) {
        throw Exception(
          loginData['error'] ?? 'تم إنشاء الحساب، تعذر تسجيل الدخول',
        );
      }

      final refreshToken = loginData['refresh_token'];

      if (refreshToken == null) {
        throw Exception('لم يتم استلام بيانات الجلسة');
      }

      await db.auth.setSession(refreshToken);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    } catch (e) {
      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                const Icon(
                  Icons.all_inclusive,
                  size: 76,
                  color: gold,
                ),
                const SizedBox(height: 18),
                const Text(
                  'OURS',
                  style: TextStyle(
                    color: gold,
                    fontSize: 46,
                    letterSpacing: 12,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const Text(
                  'YOUR PRIVATE UNIVERSE',
                  style: TextStyle(
                    color: lavender,
                    letterSpacing: 3,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 50),
                Text(
                  creatingAccount ? 'أنشئ حسابك' : 'مرحبًا بعودتك',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: username,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم',
                    hintText: 'مثال: ours_user',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                if (creatingAccount) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      prefixIcon: Icon(Icons.lock_reset),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'اسم المستخدم: أحرف إنجليزية وأرقام و _ فقط',
                    style: TextStyle(
                      color: lavender,
                      fontSize: 12,
                    ),
                  ),
                  const Text(
                    'كلمة المرور: 8 أحرف على الأقل',
                    style: TextStyle(
                      color: lavender,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: loading
                        ? null
                        : creatingAccount
                            ? register
                            : login,
                    child: loading
                        ? const CircularProgressIndicator(
                            color: navy,
                          )
                        : Text(
                            creatingAccount
                                ? 'إنشاء الحساب'
                                : 'تسجيل الدخول',
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          setState(() {
                            creatingAccount = !creatingAccount;
                            password.clear();
                            confirmPassword.clear();
                          });
                        },
                  child: Text(
                    creatingAccount
                        ? 'لديك حساب بالفعل؟ تسجيل الدخول'
                        : 'ليس لديك حساب؟ إنشاء حساب جديد',
                    style: const TextStyle(color: lavender),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'A WORLD OF TWO',
                  style: TextStyle(
                    color: lavender,
                    letterSpacing: 3,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== HOME PAGE ====================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = false;
  String? inviteCode;
  String? spaceId;

  final codeController = TextEditingController();

  SupabaseClient get db => Supabase.instance.client;

  void message(String value) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  Future<void> createSpace() async {
    setState(() => loading = true);

    try {
      final createdSpace = await db.rpc('create_duo_space');
      final code = await db.rpc('create_duo_invite');

      if (!mounted) return;

      setState(() {
        spaceId = createdSpace.toString();
        inviteCode = code.toString();
      });
    } catch (e) {
      message('تعذر إنشاء المساحة: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> joinSpace() async {
    final code = codeController.text.trim();

    if (code.length != 8) {
      message('أدخل رمز الدعوة المكوّن من 8 خانات');
      return;
    }

    setState(() => loading = true);

    try {
      final joinedSpace = await db.rpc(
        'redeem_duo_invite',
        params: {'p_code': code},
      );

      if (!mounted) return;

      setState(() {
        spaceId = joinedSpace.toString();
        inviteCode = null;
      });

      codeController.clear();
      message('تم الانضمام إلى المساحة بنجاح');
    } catch (e) {
      message('تعذر الانضمام: $e');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void openChat() {
    if (spaceId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(spaceId: spaceId!),
      ),
    );
  }

  void showJoinDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: purple,
        title: const Text('الانضمام إلى مساحة'),
        content: TextField(
          controller: codeController,
          maxLength: 8,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'رمز الدعوة',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: loading
                ? null
                : () {
                    Navigator.pop(dialogContext);
                    joinSpace();
                  },
            child: const Text('انضمام'),
          ),
        ],
      ),
    );
  }

  Widget actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Card(
      color: purple,
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: Icon(
          icon,
          color: gold,
          size: 32,
        ),
        title: Text(title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            subtitle,
            style: const TextStyle(color: lavender),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: gold,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'OURS',
          style: TextStyle(
            color: gold,
            letterSpacing: 5,
          ),
        ),
        centerTitle: true,
        backgroundColor: navy,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await db.auth.signOut();

                if (!mounted) return;

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(),
                  ),
                );
              } catch (e) {
                message('تعذر تسجيل الخروج: $e');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.nights_stay,
                  color: gold,
                  size: 65,
                ),
                const SizedBox(height: 20),
                const Text(
                  'عالمك الخاص يبدأ هنا',
                  style: TextStyle(fontSize: 25),
                ),
                const SizedBox(height: 10),
                const Text(
                  'مساحة تجمع شخصين فقط',
                  style: TextStyle(color: lavender),
                ),
                const SizedBox(height: 45),
                actionCard(
                  icon: Icons.add_circle_outline,
                  title: 'إنشاء مساحة جديدة',
                  subtitle: 'أنشئ عالمك الخاص وأرسل رمز الدعوة',
                  onTap: loading ? null : createSpace,
                ),
                const SizedBox(height: 18),
                actionCard(
                  icon: Icons.vpn_key_outlined,
                  title: 'الانضمام إلى مساحة',
                  subtitle: 'أدخل رمز الدعوة الذي وصلك',
                  onTap: loading ? null : showJoinDialog,
                ),
                if (loading) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(color: gold),
                ],
                if (inviteCode != null) ...[
                  const SizedBox(height: 30),
                  const Text('رمز الدعوة الخاص بك'),
                  const SizedBox(height: 12),
                  SelectableText(
                    inviteCode!,
                    style: const TextStyle(
                      fontSize: 30,
                      color: gold,
                      letterSpacing: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'شاركه مع الشخص الذي تريد دعوته',
                    style: TextStyle(color: lavender),
                  ),
                ],
                if (spaceId != null) ...[
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: FilledButton.icon(
                      onPressed: openChat,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text(
                        'فتح المحادثة',
                        style: TextStyle(fontSize: 17),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  actionCard(
                    icon: Icons.auto_awesome,
                    title: 'OURS AI',
                    subtitle: 'مساعد ذكي للمحادثة وتلخيص الذكريات واقتراح الأفكار',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OursAiPage(spaceId: spaceId!),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== CHAT PAGE ====================

class ChatPage extends StatefulWidget {
  final String spaceId;

  const ChatPage({
    super.key,
    required this.spaceId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageController =
      TextEditingController();

  final ScrollController scrollController = ScrollController();

  SupabaseClient get db => Supabase.instance.client;

  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> stickerShelf = [];
  final Map<String, Future<String>> signedStickerUrls = {};
  final ImagePicker imagePicker = ImagePicker();

  bool loading = true;
  bool sending = false;

  RealtimeChannel? channel;

  String get currentUserId => db.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    loadMessages();
    loadStickerShelf();
    listenToMessages();
  }

  Future<void> loadMessages() async {
    try {
      final result = await db
          .from('duo_messages')
          .select()
          .eq('space_id', widget.spaceId)
          .order('created_at', ascending: true);

      if (!mounted) return;

      setState(() {
        messages = List<Map<String, dynamic>>.from(result);
        loading = false;
      });

      scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      showMessage('تعذر تحميل الرسائل: $e');
    }
  }

  void listenToMessages() {
    channel = db
        .channel('ours-chat-${widget.spaceId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'duo_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'space_id',
            value: widget.spaceId,
          ),
          callback: (payload) {
            final newMessage =
                Map<String, dynamic>.from(payload.newRecord);

            if (!mounted) return;

            final alreadyExists = messages.any(
              (item) => item['id'] == newMessage['id'],
            );

            if (!alreadyExists) {
              setState(() {
                messages.add(newMessage);
              });

              scrollToBottom();
            }
          },
        )
        .subscribe();
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty || sending) return;

    setState(() => sending = true);

    try {
      await db.from('duo_messages').insert({
        'space_id': widget.spaceId,
        'sender_id': currentUserId,
        'body': text,
        'message_type': 'text',
      });

      if (!mounted) return;

      messageController.clear();
    } catch (e) {
      showMessage('تعذر إرسال الرسالة: $e');
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }


  Future<void> loadStickerShelf() async {
    try {
      final rows = await db
          .from('duo_stickers')
          .select()
          .eq('space_id', widget.spaceId)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() => stickerShelf = List<Map<String, dynamic>>.from(rows));
    } catch (e) {
      showMessage('تعذر تحميل الملصقات: $e');
    }
  }

  Future<void> createTextSticker() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: purple,
        title: const Text('إنشاء ملصق نصّي'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(
            hintText: 'اكتب عبارة قصيرة أو إيموجي',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty) return;

    try {
      final row = await db.from('duo_stickers').insert({
        'space_id': widget.spaceId,
        'created_by': currentUserId,
        'sticker_type': 'text',
        'content': value.trim(),
      }).select().single();
      if (!mounted) return;
      setState(() => stickerShelf.insert(0, Map<String, dynamic>.from(row)));
      await _sendSticker(Map<String, dynamic>.from(row));
    } catch (e) {
      showMessage('تعذر إنشاء الملصق: $e');
    }
  }

  Future<void> createImageSticker() async {
    try {
      final image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      final extension = image.name.toLowerCase().split('.').last;
      final safeExtension = ['png', 'jpg', 'jpeg', 'webp'].contains(extension)
          ? extension
          : 'jpg';
      final contentType = safeExtension == 'png'
          ? 'image/png'
          : safeExtension == 'webp'
              ? 'image/webp'
              : 'image/jpeg';
      final id = const Uuid().v4();
      final path = '${widget.spaceId}/$id.$safeExtension';

      await db.storage.from('ours-stickers').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: false,
        ),
      );

      final row = await db.from('duo_stickers').insert({
        'space_id': widget.spaceId,
        'created_by': currentUserId,
        'sticker_type': 'image',
        'content': '',
        'storage_path': path,
      }).select().single();

      if (!mounted) return;
      final sticker = Map<String, dynamic>.from(row);
      setState(() => stickerShelf.insert(0, sticker));
      await _sendSticker(sticker);
    } catch (e) {
      showMessage('تعذر إنشاء ملصق من الصورة: $e');
    }
  }

  Future<void> _sendSticker(Map<String, dynamic> sticker) async {
    try {
      final payload = {
        'id': sticker['id'],
        'sticker_type': sticker['sticker_type'],
        'content': sticker['content'] ?? '',
        'storage_path': sticker['storage_path'],
      };
      await db.from('duo_messages').insert({
        'space_id': widget.spaceId,
        'sender_id': currentUserId,
        'body': jsonEncode(payload),
        'message_type': 'sticker',
      });
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      showMessage('تعذر إرسال الملصق: $e');
    }
  }

  Future<String> _getStickerUrl(String path) {
    return signedStickerUrls.putIfAbsent(
      path,
      () => db.storage.from('ours-stickers').createSignedUrl(path, 3600),
    );
  }

  Widget _buildStickerMessage(Map<String, dynamic> item) {
    try {
      final data = jsonDecode(item['body']?.toString() ?? '{}') as Map<String, dynamic>;
      if (data['sticker_type'] == 'text') {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF382D4B),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: gold.withOpacity(.55), width: 1.3),
          ),
          child: Text(
            data['content']?.toString() ?? '',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }
      final path = data['storage_path']?.toString() ?? '';
      if (path.isEmpty || !path.startsWith('${widget.spaceId}/')) {
        return const Text('ملصق غير متاح');
      }
      return FutureBuilder<String>(
        future: _getStickerUrl(path),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox(
              width: 100,
              height: 100,
              child: Center(child: CircularProgressIndicator(color: gold)),
            );
          }
          return Image.network(
            snapshot.data!,
            width: 150,
            height: 150,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Text('تعذر عرض الملصق'),
          );
        },
      );
    } catch (_) {
      return const Text('ملصق غير صالح');
    }
  }

  Future<void> openStickerPicker() async {
    await loadStickerShelf();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: navy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * .62,
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: lavender.withOpacity(.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'ملصقاتنا',
                        style: TextStyle(color: gold, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      tooltip: 'إنشاء ملصق نصي',
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        createTextSticker();
                      },
                      icon: const Icon(Icons.text_fields, color: gold),
                    ),
                    IconButton(
                      tooltip: 'إنشاء ملصق من صورة',
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        createImageSticker();
                      },
                      icon: const Icon(Icons.add_photo_alternate_outlined, color: gold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: stickerShelf.isEmpty
                      ? const Center(
                          child: Text(
                            'ما عندكم ملصقات بعد\nأنشئوا أول ملصق لكم',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: lavender, height: 1.7),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: stickerShelf.length,
                          itemBuilder: (context, index) {
                            final sticker = stickerShelf[index];
                            final isText = sticker['sticker_type'] == 'text';
                            return InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _sendSticker(sticker),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: purple,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: gold.withOpacity(.25)),
                                ),
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(8),
                                child: isText
                                    ? Text(
                                        sticker['content']?.toString() ?? '',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 21),
                                      )
                                    : FutureBuilder<String>(
                                        future: _getStickerUrl(sticker['storage_path'].toString()),
                                        builder: (context, snapshot) => snapshot.hasData
                                            ? Image.network(snapshot.data!, fit: BoxFit.contain)
                                            : const Icon(Icons.image_outlined, color: lavender, size: 32),
                                      ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'الملصقات التي تنشئها تظهر لكما داخل هذه المساحة فقط',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: lavender, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void showMessage(String value) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();

    if (channel != null) {
      db.removeChannel(channel!);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'OURS',
          style: TextStyle(
            color: gold,
            letterSpacing: 5,
          ),
        ),
        centerTitle: true,
        backgroundColor: navy,
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: gold),
                  )
                : messages.isEmpty
                    ? const Center(
                        child: Text(
                          'بداية عالمكما الخاص',
                          style: TextStyle(
                            color: lavender,
                            fontSize: 18,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final item = messages[index];
                          final isMe =
                              item['sender_id'] == currentUserId;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(
                                maxWidth: 280,
                              ),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? purple
                                    : const Color(0xFF211D30),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: gold.withOpacity(0.25),
                                ),
                              ),
                              child: item['message_type'] == 'sticker'
                                  ? _buildStickerMessage(item)
                                  : Text(
                                      item['body']?.toString() ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
            decoration: BoxDecoration(
              color: purple,
              border: Border(
                top: BorderSide(
                  color: gold.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'الملصقات',
                  onPressed: openStickerPicker,
                  icon: const Icon(Icons.emoji_emotions_outlined, color: gold, size: 27),
                ),
                Expanded(
                  child: TextField(
                    controller: messageController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالتك...',
                      filled: true,
                      fillColor: navy,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: sending ? null : sendMessage,
                  icon: sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: gold,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: gold,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
