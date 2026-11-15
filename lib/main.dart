
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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
      home: Supabase.instance.client.auth.currentSession == null
          ? const LoginPage()
          : const HomePage(),
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

      if (response.status < 200 || response.status >= 300) {
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
  bool loading = true;
  String? inviteCode;
  String? spaceId;

  final codeController = TextEditingController();

  SupabaseClient get db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    loadExistingSpace();
  }

  Future<void> loadExistingSpace() async {
    try {
      final userId = db.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => loading = false);
        return;
      }

      final membership = await db
          .from('duo_members')
          .select('space_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        spaceId = membership?['space_id']?.toString();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      message('تعذر استرجاع مساحتك: $e');
    }
  }

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
      if (!mounted) return;
      setState(() => spaceId = createdSpace.toString());

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
            tooltip: 'الملف الشخصي والإعدادات',
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileSettingsPage(),
                ),
              );
            },
          ),
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
                  Icons.all_inclusive_rounded,
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

  bool loading = true;
  bool sending = false;
  bool uploadingImage = false;
  bool uploadingFile = false;
  final ImagePicker imagePicker = ImagePicker();
  final Map<String, Future<String>> signedImageUrls = {};
  final Map<String, String> participantNames = {};
  String partnerName = 'مساحتكما الخاصة';

  RealtimeChannel? channel;

  String get currentUserId => db.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    loadMessages();
    loadParticipantNames();
    listenToMessages();
  }

  Future<void> loadParticipantNames() async {
    try {
      final members = await db
          .from('duo_members')
          .select('user_id')
          .eq('space_id', widget.spaceId);

      final ids = members
          .map((row) => row['user_id'].toString())
          .toList();

      if (ids.isEmpty) return;

      final profiles = await db
          .from('duo_profiles')
          .select('user_id, username, display_name')
          .inFilter('user_id', ids);

      final names = <String, String>{};
      for (final profile in profiles) {
        final id = profile['user_id'].toString();
        final displayName = profile['display_name']?.toString().trim() ?? '';
        final username = profile['username']?.toString() ?? '';
        names[id] = displayName.isNotEmpty ? displayName : username;
      }

      if (!mounted) return;
      setState(() {
        participantNames
          ..clear()
          ..addAll(names);
        final otherIds = ids.where((id) => id != currentUserId).toList();
        if (otherIds.isNotEmpty) {
          partnerName = names[otherIds.first] ?? 'الشريك';
        }
      });
    } catch (e) {
      debugPrint('Could not load chat participant names: $e');
    }
  }

  void showImagePreview(String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: navy,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('تعذر تحميل الصورة'),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close, color: gold),
              ),
            ),
          ],
        ),
      ),
    );
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


  Future<void> sendImage() async {
    if (uploadingImage || sending) return;

    try {
      final picked = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1920,
      );
      if (picked == null || !mounted) return;

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        showMessage('الصورة المحددة فارغة');
        return;
      }
      if (bytes.length > 15 * 1024 * 1024) {
        showMessage('حجم الصورة كبير. اختر صورة أقل من 15 ميجابايت');
        return;
      }

      setState(() => uploadingImage = true);

      final originalName = picked.name;
      final extension = originalName.contains('.')
          ? originalName.split('.').last.toLowerCase()
          : 'jpg';
      const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif'};
      if (!allowedExtensions.contains(extension)) {
        showMessage('صيغة الصورة غير مدعومة. استخدم JPG أو PNG أو WEBP أو GIF');
        return;
      }
      final safeExtension = extension;
      final contentType = switch (safeExtension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };

      final storagePath =
          '${widget.spaceId}/$currentUserId/'
          '${DateTime.now().microsecondsSinceEpoch}.$safeExtension';

      await db.storage.from('duo-private').uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          cacheControl: '3600',
          upsert: false,
        ),
      );

      try {
        await db.from('duo_messages').insert({
          'space_id': widget.spaceId,
          'sender_id': currentUserId,
          'body': storagePath,
          'message_type': 'image',
        });
      } catch (_) {
        await db.storage.from('duo-private').remove([storagePath]);
        rethrow;
      }

      if (mounted) showMessage('تم إرسال الصورة');
    } catch (e) {
      if (mounted) showMessage('تعذر إرسال الصورة: $e');
    } finally {
      if (mounted) setState(() => uploadingImage = false);
    }
  }

  Future<void> sendFile() async {
    if (uploadingFile || uploadingImage || sending) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'csv', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'zip'],
        withData: true,
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) { showMessage('تعذر قراءة الملف المحدد'); return; }
      if (bytes.length > 20 * 1024 * 1024) { showMessage('حجم الملف يتجاوز الحد المسموح (20 ميجابايت)'); return; }
      setState(() => uploadingFile = true);
      final extension = (file.extension ?? '').toLowerCase();
      final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_').replaceAll('..', '_');
      final storagePath = '${widget.spaceId}/$currentUserId/${DateTime.now().microsecondsSinceEpoch}_$safeName';
      await db.storage.from('duo-private').uploadBinary(storagePath, bytes, fileOptions: FileOptions(contentType: _fileMimeType(extension), cacheControl: '3600', upsert: false));
      try {
        await db.from('duo_messages').insert({'space_id': widget.spaceId, 'sender_id': currentUserId, 'body': storagePath, 'message_type': 'file'});
      } catch (_) { await db.storage.from('duo-private').remove([storagePath]); rethrow; }
      if (mounted) showMessage('تم إرسال الملف');
    } catch (e) { if (mounted) showMessage('تعذر إرسال الملف: $e'); }
    finally { if (mounted) setState(() => uploadingFile = false); }
  }

  String _fileMimeType(String extension) {
    const types = {'pdf':'application/pdf','txt':'text/plain','csv':'text/csv','doc':'application/msword','docx':'application/vnd.openxmlformats-officedocument.wordprocessingml.document','xls':'application/vnd.ms-excel','xlsx':'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','ppt':'application/vnd.ms-powerpoint','pptx':'application/vnd.openxmlformats-officedocument.presentationml.presentation','zip':'application/zip'};
    return types[extension] ?? 'application/octet-stream';
  }

  Future<void> openSharedFile(String path) async {
    try {
      final url = await db.storage.from('duo-private').createSignedUrl(path, 900);
      final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!opened && mounted) showMessage('تعذر فتح الملف');
    } catch (e) { if (mounted) showMessage('تعذر فتح الملف: $e'); }
  }
  Future<String> signedImageUrl(String path) {
    return signedImageUrls.putIfAbsent(
      path,
      () => db.storage.from('duo-private').createSignedUrl(path, 900),
    );
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

  String _formatMessageTime(dynamic value) {
    if (value == null) return '';
    try {
      final date = DateTime.parse(value.toString()).toLocal();
      return DateFormat('h:mm a').format(date);
    } catch (_) {
      return '';
    }
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
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'OURS',
              style: TextStyle(
                color: gold,
                letterSpacing: 5,
              ),
            ),
            Text(
              partnerName,
              style: const TextStyle(
                color: lavender,
                fontSize: 11,
                letterSpacing: 0,
              ),
            ),
          ],
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isMe)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        participantNames[item['sender_id']?.toString()] ?? 'الشريك',
                                        style: const TextStyle(
                                          color: gold,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  if (item['message_type'] == 'file')
                                    InkWell(
                                      onTap: () => openSharedFile(item['body']?.toString() ?? ''),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                                        const Icon(Icons.insert_drive_file_outlined, color: gold, size: 30),
                                        const SizedBox(width: 10),
                                        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text((item['body']?.toString() ?? '').split('/').last.replaceFirst(RegExp(r'^\d+_'), ''), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 3),
                                          const Text('اضغط لفتح الملف', style: TextStyle(color: lavender, fontSize: 11)),
                                        ])),
                                      ]),
                                    )
                                  else if (item['message_type'] == 'image')
                                    FutureBuilder<String>(
                                      future: signedImageUrl(
                                        item['body']?.toString() ?? '',
                                      ),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasError) {
                                          return const Text(
                                            'تعذر تحميل الصورة',
                                            style: TextStyle(color: lavender),
                                          );
                                        }
                                        if (!snapshot.hasData) {
                                          return const SizedBox(
                                            width: 190,
                                            height: 150,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                color: gold,
                                              ),
                                            ),
                                          );
                                        }
                                        return GestureDetector(
                                          onTap: () => showImagePreview(snapshot.data!),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              snapshot.data!,
                                              width: 220,
                                              fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const SizedBox(
                                              width: 190,
                                              height: 100,
                                              child: Center(
                                                child: Text(
                                                  'تعذر عرض الصورة',
                                                  style: TextStyle(color: lavender),
                                                ),
                                              ),
                                            ),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  else
                                    Text(
                                      item['body']?.toString() ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      _formatMessageTime(item['created_at']),
                                      style: const TextStyle(
                                        color: lavender,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
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
                  tooltip: 'إرسال ملف',
                  onPressed: uploadingFile || uploadingImage || sending ? null : sendFile,
                  icon: uploadingFile ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: gold, strokeWidth: 2)) : const Icon(Icons.attach_file, color: gold),
                ),
                IconButton(
                  tooltip: 'إرسال صورة',
                  onPressed: uploadingImage || uploadingFile || sending ? null : sendImage,
                  icon: uploadingImage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: gold,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.image_outlined, color: gold),
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


// ==================== PROFILE & SETTINGS ====================

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final displayNameController = TextEditingController();
  SupabaseClient get db => Supabase.instance.client;

  String username = '';
  String email = '';
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final user = db.auth.currentUser;
      if (user == null) throw Exception('انتهت جلسة تسجيل الدخول');

      email = user.email ?? '';
      final profile = await db
          .from('duo_profiles')
          .select('username, display_name')
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;
      username = profile?['username']?.toString() ?? '';
      displayNameController.text =
          profile?['display_name']?.toString() ?? '';
      setState(() => loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      showMessage('تعذر تحميل الملف الشخصي: $e');
    }
  }

  void showMessage(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  Future<void> saveProfile() async {
    final value = displayNameController.text.trim();
    if (value.length > 30) {
      showMessage('الاسم الظاهر يجب ألا يتجاوز 30 حرفًا');
      return;
    }

    final userId = db.auth.currentUser?.id;
    if (userId == null) {
      showMessage('انتهت جلسة تسجيل الدخول');
      return;
    }

    setState(() => saving = true);
    try {
      await db
          .from('duo_profiles')
          .update({'display_name': value.isEmpty ? null : value})
          .eq('user_id', userId);

      if (!mounted) return;
      showMessage('تم حفظ الاسم الظاهر');
    } catch (e) {
      showMessage('تعذر حفظ التغييرات: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> signOut() async {
    try {
      await db.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      showMessage('تعذر تسجيل الخروج: $e');
    }
  }

  Widget settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      color: purple,
      child: ListTile(
        leading: Icon(icon, color: gold),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: lavender),
        ),
      ),
    );
  }

  @override
  void dispose() {
    displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الملف الشخصي والإعدادات',
          style: TextStyle(color: gold, fontSize: 18),
        ),
        backgroundColor: navy,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: gold))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 12),
                const CircleAvatar(
                  radius: 42,
                  backgroundColor: purple,
                  child: Icon(Icons.person_rounded, color: gold, size: 42),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    username.isEmpty ? 'حساب OURS' : '@$username',
                    style: const TextStyle(
                      color: lavender,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'معلومات الحساب',
                  style: TextStyle(color: gold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: displayNameController,
                  maxLength: 30,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الظاهر',
                    hintText: 'كيف تريد أن يظهر اسمك؟',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم',
                    prefixIcon: Icon(Icons.alternate_email),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(username.isEmpty ? '—' : username),
                ),
                const SizedBox(height: 14),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'البريد المرتبط بالحساب',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(email.isEmpty ? 'غير متاح' : email),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: saving ? null : saveProfile,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: navy,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('حفظ التغييرات'),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'الإعدادات والخصوصية',
                  style: TextStyle(color: gold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                settingsTile(
                  icon: Icons.lock_outline,
                  title: 'مساحتك الخاصة',
                  subtitle: 'المحادثة والملفات مخصصة لأعضاء مساحتك فقط',
                ),
                settingsTile(
                  icon: Icons.people_outline,
                  title: 'عدد الأعضاء',
                  subtitle: 'كل مساحة في OURS مخصصة لشخصين فقط',
                ),
                settingsTile(
                  icon: Icons.info_outline,
                  title: 'حول OURS',
                  subtitle: 'YOUR PRIVATE UNIVERSE · الإصدار 1.0.0',
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل الخروج'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: gold,
                    side: const BorderSide(color: gold),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ],
            ),
    );
  }
}
