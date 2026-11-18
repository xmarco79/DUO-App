import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ours_direct_chat_page.dart';
import 'ours_profile_page.dart';
import 'ours_music_page.dart';
import '../notifications/ours_notifications.dart';

const _p=Color(0xFF29213D), _l=Color(0xFFB9A2D5), _g=Color(0xFFD9BC86);
String _t(BuildContext c,String a,String e)=>Localizations.localeOf(c).languageCode=='ar'?a:e;

class OursSocialHomePage extends StatefulWidget {
 final VoidCallback onProfileTap; final ValueChanged<String> onChatTap;
 const OursSocialHomePage({super.key,required this.onProfileTap,required this.onChatTap});
 @override State<OursSocialHomePage> createState()=>_OursSocialHomePageState();
}
class _OursSocialHomePageState extends State<OursSocialHomePage>{
 final db=Supabase.instance.client; int tab=0; String? spaceId,error,conversationId,partnerId,partnerName; bool loading=true;
 @override void initState(){super.initState();_load();}
 Future<void> _load() async {try{
  final raw=await db.rpc('ensure_ours_pair_space'); final m=Map<String,dynamic>.from(raw as Map);
  final me=db.auth.currentUser!.id;
  final ownMembership=await db.from('duo_conversation_members').select('conversation_id').eq('user_id',me).limit(1).maybeSingle();
  String? foundConversation,foundPartner,foundName;
  if(ownMembership!=null){
   foundConversation=ownMembership['conversation_id'].toString();
   final members=await db.from('duo_conversation_members').select('user_id').eq('conversation_id',foundConversation);
   final others=members.where((row)=>row['user_id'].toString()!=me).toList();
   if(others.isNotEmpty){
    foundPartner=others.first['user_id'].toString();
    final profile=await db.from('duo_profiles').select('username,display_name').eq('user_id',foundPartner).maybeSingle();
    final display=profile?['display_name']?.toString().trim()??'';
    foundName=display.isNotEmpty?display:(profile?['username']?.toString()??'zoi');
   }
  }
  if(mounted)setState(() { spaceId=m['space_id'].toString(); conversationId=foundConversation; partnerId=foundPartner; partnerName=foundName; loading=false; });
 }catch(e){if(mounted)setState(() { error=e.toString(); loading=false; });}}
 void _openChat(){
  if(conversationId!=null&&partnerId!=null){
   Navigator.push(context,MaterialPageRoute(builder:(_)=>OursDirectChatPage(conversationId:conversationId!,partnerId:partnerId!,partnerName:partnerName??'OURS',spaceId:spaceId)));
  }else if(spaceId!=null){widget.onChatTap(spaceId!);}
 }
 @override Widget build(BuildContext context){
  final labels=[_t(context,'مساحتنا','Space'),_t(context,'مرسمنا','Studio'),_t(context,'المشاهدة','Watch'),_t(context,'موسيقانا','Music'),_t(context,'التقرير','Report')];
  final icons=[Icons.forum_outlined,Icons.brush_outlined,Icons.live_tv_outlined,Icons.music_note_outlined,Icons.insights_outlined];
  return Scaffold(appBar:AppBar(title:const Text('OURS',style:TextStyle(color:_g,letterSpacing:5)),actions:[if(spaceId!=null) OursNotificationBell(spaceId:spaceId,onOpenMessage:_openChat),IconButton(onPressed:widget.onProfileTap,icon:const Icon(Icons.tune,color:_l))]),
   body:loading?const Center(child:CircularProgressIndicator(color:_g)):error!=null?Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(_t(context,'تعذر تجهيز مساحتنا','Could not load space')),Text(error!,style:const TextStyle(color:_l)),TextButton(onPressed:()=>setState(() { loading=true; error=null; _load(); }),child:Text(_t(context,'إعادة المحاولة','Retry')))])):
   IndexedStack(index:tab,children:[
    _SpaceView(partnerName:partnerName??'zoi',onChat:_openChat,onPartnerProfile:partnerId==null?null:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OursProfilePage(userId:partnerId!))),onSelf:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const OursSelfChatPage())),onAi:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OursAiPage(spaceId:spaceId!)))),
    _StudioView(spaceId:spaceId!),
    _WatchView(spaceId:spaceId!),
    const OursMusicPage(),
    const _ReportView(),
   ]),
   bottomNavigationBar:NavigationBar(backgroundColor:_p,selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:List.generate(5,(i)=>NavigationDestination(icon:Icon(icons[i]),label:labels[i]))));
 }
}
class _SpaceView extends StatelessWidget{
 final String partnerName;
 final VoidCallback onChat,onSelf,onAi;
 final VoidCallback? onPartnerProfile;
 const _SpaceView({required this.partnerName,required this.onChat,required this.onSelf,required this.onAi,this.onPartnerProfile});
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.fromLTRB(18,18,18,26),children:[
  Container(
   padding:const EdgeInsets.all(22),
   decoration:BoxDecoration(
    gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF302544),Color(0xFF171725),Color(0xFF17323A)]),
    borderRadius:BorderRadius.circular(26),
    border:Border.all(color:_g.withValues(alpha:.32)),
    boxShadow:[BoxShadow(color:_g.withValues(alpha:.07),blurRadius:26,spreadRadius:1)],
   ),
   child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[const Icon(Icons.all_inclusive_rounded,color:_g,size:30),const Spacer(),Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:Colors.white.withValues(alpha:.07),borderRadius:BorderRadius.circular(20)),child:Text(_t(c,'مساحة خاصة','PRIVATE SPACE'),style:const TextStyle(color:_l,fontSize:9,letterSpacing:1.1)))]),
    const SizedBox(height:18),
    Text(_t(c,'عالمكما يبدأ هنا','YOUR WORLD, TOGETHER'),style:const TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.w800)),
    const SizedBox(height:6),
    Text(_t(c,'مكان واحد يجمع محادثاتكما وأفكاركما ولحظاتكما.','One place for your conversations, ideas and moments.'),style:const TextStyle(color:_l,height:1.6,fontSize:12)),
    const SizedBox(height:18),
    Row(children:[
     Expanded(child:FilledButton.icon(onPressed:onChat,icon:const Icon(Icons.chat_bubble_outline_rounded),label:Text(_t(c,'افتح المحادثة','Open chat')))),
     if(onPartnerProfile!=null) ...[const SizedBox(width:8),IconButton.filledTonal(onPressed:onPartnerProfile,tooltip:_t(c,'ملف $partnerName','View $partnerName profile'),icon:const Icon(Icons.account_circle_outlined))]
    ])
   ]),
  ),
  const SizedBox(height:24),
  Text(_t(c,'محادثاتك','YOUR CONVERSATIONS'),style:const TextStyle(color:_g,fontSize:12,fontWeight:FontWeight.w800,letterSpacing:1.5)),
  const SizedBox(height:10),
  _conversationTile(c,icon:Icons.person_outline_rounded,title:partnerName,subtitle:_t(c,'محادثتك الخاصة مع الطرف الآخر','Your private conversation with your partner'),accent:const Color(0xFF8DD9CF),onTap:onChat,onAvatarTap:onPartnerProfile),
  _conversationTile(c,icon:Icons.bookmark_outline_rounded,title:_t(c,'مراسلة نفسي','Saved messages'),subtitle:_t(c,'مساحة خاصة للملاحظات والرسائل المحفوظة','A private place for notes and saved messages'),accent:const Color(0xFFE6C28B),onTap:onSelf),
  _conversationTile(c,icon:Icons.auto_awesome_rounded,title:'OURS AI',subtitle:_t(c,'مساعدك الذكي داخل عالمك','Your AI companion inside OURS'),accent:const Color(0xFFC3A5F3),onTap:onAi),
 ]);
}
Widget _conversationTile(BuildContext c,{required IconData icon,required String title,required String subtitle,required Color accent,required VoidCallback onTap,VoidCallback? onAvatarTap})=>Container(
 margin:const EdgeInsets.only(bottom:10),
 decoration:BoxDecoration(color:_p.withValues(alpha:.82),borderRadius:BorderRadius.circular(19),border:Border.all(color:accent.withValues(alpha:.18))),
 child:ListTile(
  contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:7),
  leading:InkWell(onTap:onAvatarTap,borderRadius:BorderRadius.circular(30),child:CircleAvatar(backgroundColor:accent.withValues(alpha:.14),child:Icon(icon,color:accent))),
  title:Text(title,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700,fontSize:14)),
  subtitle:Text(subtitle,style:const TextStyle(color:_l,fontSize:11,height:1.4)),
  trailing:const Icon(Icons.chevron_right_rounded,color:_l),
  onTap:onTap,
 ),
);

class _StudioView extends StatefulWidget{final String spaceId;const _StudioView({required this.spaceId});@override State<_StudioView> createState()=>_StudioState();}
class _StudioState extends State<_StudioView> {
  final db = Supabase.instance.client;
  String scope = 'personal';
  List<Map<String, dynamic>> rows = [];
  bool loading = true;
  Color color = _l;
  double strokeWidth = 4;
  bool erasing = false;
  bool marker = false;
  bool showGrid = true;
  double opacity = 1.0;
  static const Color canvasBackground = Color(0xFF171522);
  List<Offset> points = [];
  final List<Map<String, dynamic>> redoStack = [];
  final TransformationController zoomController = TransformationController();
  Size canvasSize = Size.zero;
  RealtimeChannel? channel;

  @override
  void initState() {
    super.initState();
    _load();
    channel = db
        .channel('ours-studio-live-${widget.spaceId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ours_canvas_strokes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'space_id',
            value: widget.spaceId,
          ),
          callback: (_) => _load(),
        )
      ..subscribe();
  }

  Future<void> _load() async {
    try {
      var query = db
          .from('ours_canvas_strokes')
          .select()
          .eq('space_id', widget.spaceId);
      query = scope == 'personal'
          ? query.eq('owner_id', db.auth.currentUser!.id)
          : query.eq('scope', 'shared');
      final result = await query.order('created_at');
      if (mounted) {
        setState(() {
          rows = List<Map<String, dynamic>>.from(result);
          loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => loading = false);
        _message(error.toString());
      }
    }
  }

  Offset _normalized(Offset point) {
    if (canvasSize.width <= 0 || canvasSize.height <= 0) return point;
    return Offset(
      (point.dx / canvasSize.width).clamp(0.0, 1.0).toDouble(),
      (point.dy / canvasSize.height).clamp(0.0, 1.0).toDouble(),
    );
  }

  Future<void> _save() async {
    if (points.isEmpty) {
      setState(() => points = []);
      return;
    }
    try {
      await db.from('ours_canvas_strokes').insert({
        'space_id': widget.spaceId,
        'owner_id': db.auth.currentUser!.id,
        'scope': scope,
        'points': points.map((point) => {'x': point.dx, 'y': point.dy}).toList(),
        'color': erasing ? canvasBackground.toARGB32() : color.withValues(alpha: marker ? opacity * 0.42 : opacity).toARGB32(),
        'stroke_width': erasing ? 28 : marker ? strokeWidth * 2.2 : strokeWidth,
      });
      if (mounted) setState(() { points = []; redoStack.clear(); });
      await _load();
    } catch (error) {
      if (mounted) setState(() => points = []);
      _message(error.toString());
    }
  }

  Future<void> _undoLastStroke() async {
    try {
      var query = db.from('ours_canvas_strokes').select()
          .eq('space_id', widget.spaceId).eq('scope', scope);
      query = query.eq('owner_id', db.auth.currentUser!.id);
      final last = await query.order('created_at', ascending: false).limit(1).maybeSingle();
      if (last == null) return;
      await db.from('ours_canvas_strokes').delete().eq('id', last['id']);
      if (mounted) setState(() => redoStack.add(Map<String, dynamic>.from(last)));
      await _load();
    } catch (error) {
      _message(error.toString());
    }
  }

  Future<void> _redoLastStroke() async {
    if (redoStack.isEmpty) return;
    final stroke = redoStack.removeLast();
    try {
      await db.from('ours_canvas_strokes').insert({
        'space_id': widget.spaceId,
        'owner_id': db.auth.currentUser!.id,
        'scope': scope,
        'points': stroke['points'],
        'color': stroke['color'],
        'stroke_width': stroke['stroke_width'],
      });
      await _load();
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) setState(() => redoStack.add(stroke));
      _message(error.toString());
    }
  }

  void _resetZoom() {
    zoomController.value = Matrix4.identity();
  }

  Future<void> _clearBoard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _p,
        title: Text(_t(context, 'مسح اللوحة؟', 'Clear canvas?')),
        content: Text(_t(
          context,
          scope == 'personal' ? 'سيتم حذف رسومات مرسمك الشخصي.' : 'سيتم حذف رسوماتك أنت فقط من اللوحة المشتركة، وستبقى رسومات الطرف الآخر.',
          scope == 'personal' ? 'This removes the drawings in your personal studio.' : 'This removes only your drawings from the shared canvas. The other person’s drawings stay.',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(_t(context, 'إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(_t(context, 'مسح', 'Clear'))),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      var query = db.from('ours_canvas_strokes').delete().eq('space_id', widget.spaceId).eq('scope', scope);
      query = query.eq('owner_id', db.auth.currentUser!.id);
      await query;
      if (mounted) setState(() { points = []; redoStack.clear(); });
      await _load();
    } catch (error) {
      _message(error.toString());
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  @override
  void dispose() {
    zoomController.dispose();
    if (channel != null) db.removeChannel(channel!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'personal',
                label: Text(_t(context, 'مرسمي', 'My studio')),
              ),
              ButtonSegment(
                value: 'shared',
                label: Text(_t(context, 'مرسمنا المشترك', 'Shared studio')),
              ),
            ],
            selected: {scope},
            onSelectionChanged: (values) {
              setState(() {
                scope = values.first;
                loading = true;
                points = [];
                redoStack.clear();
              });
              _load();
            },
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final selectedColor in [_l, _g, Colors.white, const Color(0xFFFF6B6B), const Color(0xFFFF9F43), const Color(0xFFFFD166), const Color(0xFF9BE564), const Color(0xFF36D6A8), const Color(0xFF45C4E8), const Color(0xFF5B8DEF), const Color(0xFF9B7BFF), const Color(0xFFE879F9), const Color(0xFFFF8FC7), const Color(0xFFB7C5D3), const Color(0xFF8D6E63), const Color(0xFF222222)])
                IconButton(
                  tooltip: selectedColor.toString(),
                  onPressed: () => setState(() { color = selectedColor; erasing = false; }),
                  icon: Icon(Icons.circle, color: selectedColor, size: color == selectedColor && !erasing ? 27 : 22),
                ),
              IconButton(
                tooltip: _t(context, 'الممحاة', 'Eraser'),
                onPressed: () => setState(() => erasing = !erasing),
                color: erasing ? _g : _l,
                icon: const Icon(Icons.auto_fix_high_rounded),
              ),
              IconButton(
                tooltip: _t(context, 'قلم تظليل', 'Marker brush'),
                onPressed: () => setState(() { marker = !marker; erasing = false; }),
                color: marker ? _g : _l,
                icon: const Icon(Icons.brush_rounded),
              ),
              IconButton(
                tooltip: _t(context, 'إظهار شبكة اللوحة', 'Toggle canvas grid'),
                onPressed: () => setState(() => showGrid = !showGrid),
                color: showGrid ? _g : _l,
                icon: const Icon(Icons.grid_4x4_rounded),
              ),
              IconButton(
                tooltip: _t(context, 'تراجع عن آخر خط', 'Undo last stroke'),
                onPressed: rows.isEmpty ? null : _undoLastStroke,
                icon: const Icon(Icons.undo_rounded, color: _l),
              ),
              IconButton(
                tooltip: _t(context, 'إعادة الخط', 'Redo stroke'),
                onPressed: redoStack.isEmpty ? null : _redoLastStroke,
                icon: const Icon(Icons.redo_rounded, color: _l),
              ),
              IconButton(
                tooltip: _t(context, 'إعادة ضبط التكبير', 'Reset zoom'),
                onPressed: _resetZoom,
                icon: const Icon(Icons.zoom_out_map_rounded, color: _l),
              ),
              IconButton(
                tooltip: _t(context, 'مسح اللوحة', 'Clear canvas'),
                onPressed: rows.isEmpty ? null : _clearBoard,
                icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(_t(context, 'سُمك القلم', 'Brush size'),
                  style: const TextStyle(color: _l, fontSize: 12)),
              Expanded(
                child: Slider(
                  min: 1,
                  max: 32,
                  divisions: 31,
                  value: strokeWidth,
                  onChanged: (value) => setState(() => strokeWidth = value),
                ),
              ),
              Text(strokeWidth.toStringAsFixed(0),
                  style: const TextStyle(color: _g, fontSize: 12)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text(_t(context, 'شفافية', 'Opacity'), style: const TextStyle(color: _l, fontSize: 12)),
            Expanded(child: Slider(min: 0.1, max: 1, divisions: 9, value: opacity, onChanged: (value) => setState(() => opacity = value))),
            Text('${(opacity * 100).round()}%', style: const TextStyle(color: _g, fontSize: 11)),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                return Container(
                  decoration: BoxDecoration(
                    color: canvasBackground,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : InteractiveViewer(
                          transformationController: zoomController,
                          minScale: 0.8,
                          maxScale: 3.5,
                          panEnabled: false,
                          scaleEnabled: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (details) => setState(
                              () => points = [_normalized(details.localPosition)],
                            ),
                            onPanUpdate: (details) => setState(
                              () => points.add(_normalized(details.localPosition)),
                            ),
                            onPanEnd: (_) => _save(),
                            child: CustomPaint(
                              painter: _CanvasPainter(rows, points, color.withValues(alpha: marker ? opacity * 0.42 : opacity), marker ? strokeWidth * 2.2 : strokeWidth, showGrid),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            _t(
              context,
              'لكل حساب مرسمه الخاص، ويمكنكما الرسم على لوحة مشتركة. تُحفظ الإحداثيات بشكل متناسب لتظهر بصورة صحيحة على مختلف الشاشات.',
              'Each account has a private studio and both can draw on a shared canvas. Strokes use normalized coordinates across screen sizes.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _l, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<Map<String, dynamic>> rows;
  final List<Offset> active;
  final Color activeColor;
  final double activeWidth;
  final bool showGrid;

  _CanvasPainter(this.rows, this.active, this.activeColor, this.activeWidth, this.showGrid);

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) {
      final gridPaint = Paint()..color = _l.withValues(alpha: .075)..strokeWidth = .6;
      const step = 28.0;
      for (double x = step; x < size.width; x += step) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = step; y < size.height; y += step) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }
    for (final row in rows) {
      final raw = row['points'];
      if (raw is! List) continue;
      final points = raw.whereType<Map>().map((point) {
        return Offset(
          (point['x'] as num).toDouble(),
          (point['y'] as num).toDouble(),
        );
      }).toList();
      final normalized = points.every(
        (point) => point.dx >= 0 && point.dx <= 1 && point.dy >= 0 && point.dy <= 1,
      );
      final displayPoints = normalized
          ? points.map((point) => Offset(point.dx * size.width, point.dy * size.height)).toList()
          : points;
      final strokeColor = Color(
        (row['color'] as num?)?.toInt() ?? _l.value,
      );
      final width = (row['stroke_width'] as num?)?.toDouble() ?? 4;
      _draw(canvas, displayPoints, strokeColor, width);
    }
    _draw(
      canvas,
      active.map((point) => Offset(point.dx * size.width, point.dy * size.height)).toList(),
      activeColor,
      activeWidth,
    );
  }

  void _draw(Canvas canvas, List<Offset> points, Color color, double width) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (points.length == 1) {
      canvas.drawCircle(points.first, width / 2, paint..style = PaintingStyle.fill);
      return;
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length - 1; i++) {
      final midpoint = Offset((points[i].dx + points[i + 1].dx) / 2, (points[i].dy + points[i + 1].dy) / 2);
      path.quadraticBezierTo(points[i].dx, points[i].dy, midpoint.dx, midpoint.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) =>
      oldDelegate.rows != rows || oldDelegate.active != active ||
      oldDelegate.activeColor != activeColor || oldDelegate.activeWidth != activeWidth ||
      oldDelegate.showGrid != showGrid;
}

class _WatchView extends StatefulWidget{final String spaceId;const _WatchView({required this.spaceId});@override State<_WatchView> createState()=>_WatchState();}
class _WatchState extends State<_WatchView> {
  final db = Supabase.instance.client;
  final title = TextEditingController();
  final url = TextEditingController();
  Map<String, dynamic>? session;
  bool busy = false;
  RealtimeChannel? channel;

  int get _positionMs => (session?['position_ms'] as num?)?.toInt() ?? 0;
  bool get _isPlaying => session?['is_playing'] == true;

  @override
  void initState() {
    super.initState();
    _load();
    channel = db
        .channel('ours-watch-live-${widget.spaceId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'ours_watch_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'space_id',
            value: widget.spaceId,
          ),
          callback: (_) => _load(),
        )
      ..subscribe();
  }

  Future<void> _load() async {
    try {
      final result = await db
          .from('ours_watch_sessions')
          .select()
          .eq('space_id', widget.spaceId)
          .eq('status', 'active')
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (mounted) setState(() => session = result);
    } catch (error) {
      _message(error.toString());
    }
  }

  Future<void> _start() async {
    final uri = Uri.tryParse(url.text.trim());
    if (title.text.trim().isEmpty ||
        uri == null ||
        !uri.hasAuthority ||
        !['http', 'https'].contains(uri.scheme)) {
      _message(_t(context, 'أدخل اسمًا ورابطًا صالحًا', 'Enter a title and valid URL'));
      return;
    }

    setState(() => busy = true);
    try {
      await db
          .from('ours_watch_sessions')
          .update({'status': 'ended', 'is_playing': false})
          .eq('space_id', widget.spaceId)
          .eq('status', 'active');
      final created = await db
          .from('ours_watch_sessions')
          .insert({
            'space_id': widget.spaceId,
            'created_by': db.auth.currentUser!.id,
            'title': title.text.trim(),
            'source_url': uri.toString(),
            'status': 'active',
            'position_ms': 0,
            'is_playing': false,
          })
          .select()
          .single();
      if (mounted) setState(() => session = Map<String, dynamic>.from(created));
    } catch (error) {
      await _load();
      if (error.toString().contains('23505')) {
        _message(_t(context, 'بدأت جلسة مشاهدة أخرى بالفعل.', 'A watch session is already active.'));
      } else {
        _message(error.toString());
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _updateSession({
    int? positionMs,
    bool? isPlaying,
    String? status,
  }) async {
    final current = session;
    if (current == null || busy) return;
    setState(() => busy = true);
    try {
      final updated = await db
          .from('ours_watch_sessions')
          .update({
            if (positionMs != null) 'position_ms': positionMs,
            if (isPlaying != null) 'is_playing': isPlaying,
            if (status != null) 'status': status,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', current['id'])
          .eq('status', 'active')
          .select()
          .maybeSingle();
      if (mounted) {
        setState(() => session = status == 'ended' || updated == null ? null : Map<String, dynamic>.from(updated));
      }
    } catch (error) {
      _message(error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _formatPosition(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }

  Future<void> _openSource() async {
    final uri = Uri.tryParse(session?['source_url']?.toString() ?? '');
    if (uri == null) return;
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) _message(_t(context, 'تعذر فتح الرابط', 'Could not open the link'));
    } catch (error) {
      _message(error.toString());
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = session;
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _Header(
          icon: Icons.live_tv,
          title: _t(context, 'مشاهدة معًا', 'Watch together'),
          subtitle: _t(context, 'جلسة مشتركة بين الحسابين', 'One shared session for both accounts'),
        ),
        if (current == null) ...[
          const SizedBox(height: 16),
          TextField(
            controller: title,
            decoration: InputDecoration(labelText: _t(context, 'اسم المحتوى', 'Title')),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: url,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: _t(context, 'رابط مصدر مرخّص', 'Licensed source URL'),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: busy ? null : _start,
            child: Text(_t(context, 'بدء جلسة', 'Start session')),
          ),
        ] else ...[
          const SizedBox(height: 16),
          Card(
            color: _p,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    current['title'].toString(),
                    style: const TextStyle(color: _g, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _t(context, 'جلسة نشطة للحسابين', 'Shared session is active'),
                    style: const TextStyle(color: _l),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      _formatPosition(_positionMs),
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: _t(context, 'رجوع 10 ثوانٍ', 'Back 10 seconds'),
                        onPressed: busy
                            ? null
                            : () => _updateSession(positionMs: (_positionMs - 10000).clamp(0, 1 << 62)),
                        icon: const Icon(Icons.replay_10, color: _g, size: 32),
                      ),
                      IconButton.filled(
                        tooltip: _isPlaying ? _t(context, 'إيقاف مؤقت', 'Pause') : _t(context, 'تشغيل', 'Play'),
                        onPressed: busy ? null : () => _updateSession(isPlaying: !_isPlaying),
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      ),
                      IconButton(
                        tooltip: _t(context, 'تقديم 10 ثوانٍ', 'Forward 10 seconds'),
                        onPressed: busy
                            ? null
                            : () => _updateSession(positionMs: _positionMs + 10000),
                        icon: const Icon(Icons.forward_10, color: _g, size: 32),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: busy ? null : _openSource,
                      icon: const Icon(Icons.open_in_new),
                      label: Text(_t(context, 'فتح مصدر المشاهدة', 'Open viewing source')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : () => _updateSession(status: 'ended', isPlaying: false),
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: Text(_t(context, 'إنهاء الجلسة', 'End session')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            _t(
              context,
              'حالة الجلسة وموضع التشغيل وأوامر التقديم والإيقاف تتزامن بين الحسابين. تشغيل الفيديو نفسه يتم عبر المصدر الخارجي؛ التشغيل المدمج والتحكم المباشر بالمشغل يحتاجان تكاملًا مرخّصًا مع مزود المحتوى.',
              'Session state, shared position and play/pause/seek commands sync between both accounts. Video playback opens through the external provider; embedded playback and direct player control require a licensed provider integration.',
            ),
            style: const TextStyle(color: _l, fontSize: 11, height: 1.6),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    title.dispose();
    url.dispose();
    if (channel != null) db.removeChannel(channel!);
    super.dispose();
  }
}

class _ReportView extends StatefulWidget{const _ReportView();@override State<_ReportView> createState()=>_ReportState();}
class _ReportState extends State<_ReportView>{final db=Supabase.instance.client;Map<String,dynamic>? data;bool loading=true;String? error;
 @override void initState(){super.initState();_load();}
 Future<void> _load()async{try{final r=await db.rpc('generate_ours_weekly_report');if(mounted)setState(() { data=Map<String,dynamic>.from(r as Map); loading=false; });}catch(e){if(mounted)setState(() { error=e.toString(); loading=false; });}}
 Widget _card(BuildContext c,String name,Map<String,dynamic> stats){final labels={'messages':_t(c,'الرسائل','Messages'),'media':_t(c,'الوسائط','Media'),'drawings':_t(c,'الرسومات','Drawings'),'watch_sessions':_t(c,'جلسات المشاهدة','Watch sessions')};return Card(color:_p,child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(name,style:const TextStyle(color:_g,fontWeight:FontWeight.bold,fontSize:17)),const SizedBox(height:10),for(final entry in labels.entries)Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(entry.value,style:const TextStyle(color:_l)),Text((stats[entry.key]??0).toString(),style:const TextStyle(fontWeight:FontWeight.bold))]))])));}
 @override Widget build(BuildContext c){if(loading)return const Center(child:CircularProgressIndicator());if(error!=null)return Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(_t(c,'التقرير يحتاج تحديث قاعدة البيانات','Report requires database migration'),style:const TextStyle(color:_l)),TextButton(onPressed:()=>setState(() { loading=true; error=null; _load(); }),child:Text(_t(c,'إعادة المحاولة','Retry')))]));final n=Map<String,dynamic>.from(data!['naif'] as Map? ?? {}),z=Map<String,dynamic>.from(data!['zoi'] as Map? ?? {}),s=Map<String,dynamic>.from(data!['shared'] as Map? ?? {});return ListView(padding:const EdgeInsets.all(18),children:[const _Header(icon:Icons.insights,title:'تقرير OURS',subtitle:'ملخص الأسبوع المكتمل للحسابين'),if(data?['week_start']!=null)Padding(padding:const EdgeInsets.only(top:8,bottom:12),child:Text(data!['week_start'].toString()+' — '+data!['week_end'].toString(),textAlign:TextAlign.center,style:const TextStyle(color:_l))),_card(c,'naif',n),_card(c,'zoi',z),_card(c,_t(c,'النشاط المشترك','Shared activity'),s),Text(_t(c,'يُحدّث التقرير عند فتح هذه الصفحة. يظهر التقرير نفسه للحسابين بعد إنشائه.','The report refreshes when this page is opened. Both accounts see the same report.'),style:const TextStyle(color:_l,fontSize:11))]);}
}

class _Header extends StatelessWidget{final IconData icon;final String title,subtitle;const _Header({required this.icon,required this.title,required this.subtitle});@override Widget build(BuildContext c)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:_p,borderRadius:BorderRadius.circular(18)),child:Row(children:[Icon(icon,color:_g,size:30),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Text(subtitle,style:const TextStyle(color:_l,fontSize:12))]))]));}
