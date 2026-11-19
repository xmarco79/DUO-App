import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ours_direct_chat_page.dart';
import 'ours_profile_page.dart';
import 'ours_music_page.dart';
import '../notifications/ours_notifications.dart';

const _p=Color(0xFF29213D), _l=Color(0xFFB9A2D5), _g=Color(0xFFD9BC86), _gold=_g, _navy=Color(0xFF10101C), _lavender=_l;
String _t(BuildContext c,String a,String e)=>Localizations.localeOf(c).languageCode=='ar'?a:e;

class OursSocialHomePage extends StatefulWidget {
 final VoidCallback onProfileTap; final ValueChanged<String> onChatTap;
 const OursSocialHomePage({super.key,required this.onProfileTap,required this.onChatTap});
 @override State<OursSocialHomePage> createState()=>_OursSocialHomePageState();
}
class _OursSocialHomePageState extends State<OursSocialHomePage>{
 final db=Supabase.instance.client; int tab=0; String? spaceId,error,conversationId,partnerId,partnerName,partnerAlias,partnerAvatarUrl; bool loading=true;
 @override void initState(){super.initState();_load();}
 Future<void> _load() async {try{
  final raw=await db.rpc('ensure_ours_pair_space'); final m=Map<String,dynamic>.from(raw as Map);
  final me=db.auth.currentUser!.id;
  String? foundConversation=m['conversation_id']?.toString(),foundPartner,foundName,foundAvatar;
  if(foundConversation!=null&&foundConversation.isNotEmpty){
   final members=await db.from('duo_conversation_members').select('user_id').eq('conversation_id',foundConversation);
   final others=members.where((row)=>row['user_id'].toString()!=me).toList();
   if(others.isNotEmpty){
    foundPartner=others.first['user_id'].toString();
    final profile=await db.from('duo_profiles').select('username,display_name,avatar_path').eq('user_id',foundPartner).maybeSingle();
    final display=profile?['display_name']?.toString().trim()??'';
    foundName=display.isNotEmpty?display:(profile?['username']?.toString()??'zoi');
    final avatar=profile?['avatar_path']?.toString();
    if(avatar!=null&&avatar.isNotEmpty){try{foundAvatar=db.storage.from('ours-avatars').getPublicUrl(avatar);}catch(_){}}
   }
  }
  final prefs=await SharedPreferences.getInstance();
  final alias=foundPartner==null?null:prefs.getString('ours_partner_alias_${me}_$foundPartner');
  if(mounted)setState(() { spaceId=m['space_id'].toString(); conversationId=foundConversation; partnerId=foundPartner; partnerName=foundName; partnerAlias=alias; partnerAvatarUrl=foundAvatar; loading=false; });
 }catch(e){if(mounted)setState(() { error=e.toString(); loading=false; });}}
 String get _partnerLabel=>partnerAlias?.trim().isNotEmpty==true?partnerAlias!.trim():(partnerName??'zoi');
 Future<void> _editPartnerAlias() async{
  if(partnerId==null)return;
  final controller=TextEditingController(text:partnerAlias??'');
  final value=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:_p,title:Text(_t(context,'تخصيص اسم الطرف الآخر','Set a nickname')),content:TextField(controller:controller,maxLength:24,autofocus:true,decoration:InputDecoration(hintText:_t(context,'اسم يظهر لك فقط','Only visible to you'))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(_t(context,'إلغاء','Cancel'))),TextButton(onPressed:()=>Navigator.pop(ctx,controller.text.trim()),child:Text(_t(context,'حفظ','Save')))]));
  controller.dispose();if(value==null)return;
  final prefs=await SharedPreferences.getInstance();final key='ours_partner_alias_${db.auth.currentUser!.id}_$partnerId';
  if(value.isEmpty)await prefs.remove(key);else await prefs.setString(key,value);
  if(mounted)setState(()=>partnerAlias=value.isEmpty?null:value);
 }
 void _openChat(){
  if(conversationId!=null&&partnerId!=null){
   Navigator.push(context,MaterialPageRoute(builder:(_)=>OursDirectChatPage(conversationId:conversationId!,partnerId:partnerId!,partnerName:_partnerLabel,spaceId:spaceId)));
  }else if(spaceId!=null){widget.onChatTap(spaceId!);}
 }
 @override Widget build(BuildContext context){
  final labels=[_t(context,'مساحتنا','Space'),_t(context,'مرسمنا','Studio'),_t(context,'المشاهدة','Watch'),_t(context,'موسيقانا','Music'),_t(context,'التقرير','Report')];
  final icons=[Icons.forum_outlined,Icons.brush_outlined,Icons.live_tv_outlined,Icons.music_note_outlined,Icons.insights_outlined];
  return Scaffold(appBar:AppBar(title:const Text('OURS',style:TextStyle(color:_g,letterSpacing:5)),actions:[if(spaceId!=null) OursNotificationBell(spaceId:spaceId,onOpenMessage:_openChat),IconButton(onPressed:widget.onProfileTap,icon:const Icon(Icons.tune,color:_l))]),
   body:loading?const Center(child:CircularProgressIndicator(color:_g)):error!=null?Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(_t(context,'تعذر تجهيز مساحتنا','Could not load space')),Text(error!,style:const TextStyle(color:_l)),TextButton(onPressed:()=>setState(() { loading=true; error=null; _load(); }),child:Text(_t(context,'إعادة المحاولة','Retry')))])):
   IndexedStack(index:tab,children:[
    _SpaceView(partnerName:_partnerLabel,username:partnerName??'zoi',avatarUrl:partnerAvatarUrl,onChat:_openChat,onPartnerProfile:partnerId==null?null:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OursProfilePage(userId:partnerId!))),onEditAlias:_editPartnerAlias,onSelf:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const OursSelfChatPage())),onAi:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OursAiPage(spaceId:spaceId!)))),
    _StudioView(spaceId:spaceId!),
    _WatchView(spaceId:spaceId!,active:tab==2),
    const OursMusicPage(),
    const _ReportView(),
   ]),
   bottomNavigationBar:NavigationBar(backgroundColor:_p,selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:List.generate(5,(i)=>NavigationDestination(icon:Icon(icons[i]),label:labels[i]))));
 }
}
class _SpaceView extends StatelessWidget{
 final String partnerName,username;final String? avatarUrl;
 final VoidCallback onChat,onSelf,onAi,onEditAlias;
 final VoidCallback? onPartnerProfile;
 const _SpaceView({required this.partnerName,required this.username,this.avatarUrl,required this.onChat,required this.onSelf,required this.onAi,required this.onEditAlias,this.onPartnerProfile});
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.fromLTRB(18,18,18,26),children:[
  InkWell(onTap:onPartnerProfile,borderRadius:BorderRadius.circular(25),child:Container(
   padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF3A2C50),Color(0xFF171725),Color(0xFF18343A)]),borderRadius:BorderRadius.circular(25),border:Border.all(color:_g.withValues(alpha:.35)),boxShadow:[BoxShadow(color:_g.withValues(alpha:.08),blurRadius:24)]),
   child:Row(children:[
    Container(width:66,height:66,decoration:BoxDecoration(shape:BoxShape.circle,gradient:LinearGradient(colors:[_g.withValues(alpha:.35),_l.withValues(alpha:.2)]),border:Border.all(color:_g,width:1.4)),child:avatarUrl==null?const Icon(Icons.person_rounded,color:Colors.white,size:34):ClipOval(child:Image.network(avatarUrl,fit:BoxFit.cover,width:66,height:66,errorBuilder:(_,__,___)=>const Icon(Icons.person_rounded,color:Colors.white,size:34)))),
    const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(partnerName,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:19),maxLines:1,overflow:TextOverflow.ellipsis),
     const SizedBox(height:3),Text('@$username',style:const TextStyle(color:_l,fontSize:12)),
     const SizedBox(height:8),Text(_t(c,'مساحتكما الخاصة','Your private space'),style:const TextStyle(color:_g,fontSize:11,letterSpacing:.3))
    ])),
    Column(children:[IconButton(tooltip:_t(c,'تخصيص الاسم عندك فقط','Set your private nickname'),onPressed:onEditAlias,icon:const Icon(Icons.edit_rounded,color:_g)),IconButton(tooltip:_t(c,'فتح المحادثة','Open chat'),onPressed:onChat,icon:const Icon(Icons.chat_bubble_outline_rounded,color:_l))])
   ])
  )),
  const SizedBox(height:24),Text(_t(c,'مساحاتك','YOUR SPACES'),style:const TextStyle(color:_g,fontSize:12,fontWeight:FontWeight.w800,letterSpacing:1.5)),
  const SizedBox(height:10),
  _conversationTile(c,icon:Icons.bookmark_outline_rounded,title:_t(c,'مراسلة نفسي','Saved messages'),subtitle:_t(c,'ملاحظاتك ورسائلك المحفوظة — خاصة بك','Your private notes and saved messages'),accent:const Color(0xFFE6C28B),onTap:onSelf),
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
  bool studioOpened = false;
  String canvasPreset = 'midnight';
  String toolMode = 'pen';
  Offset? gestureStart;
  Color color = _l;
  double strokeWidth = 4;
  bool erasing = false;
  bool marker = false;
  bool showGrid = true;
  double opacity = 1.0;
  Color canvasBackground = const Color(0xFF171522);
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

  List<Offset> _shapePoints(Offset start,Offset end){
    if(toolMode=='line'){
      return List.generate(28,(i){final t=i/27;return Offset(start.dx+(end.dx-start.dx)*t,start.dy+(end.dy-start.dy)*t);});
    }
    final left=math.min(start.dx,end.dx),right=math.max(start.dx,end.dx);
    final top=math.min(start.dy,end.dy),bottom=math.max(start.dy,end.dy);
    if(toolMode=='circle'){
      final center=Offset((left+right)/2,(top+bottom)/2),rx=(right-left)/2,ry=(bottom-top)/2;
      return List.generate(72,(i){final a=2*math.pi*i/71;return Offset(center.dx+rx*math.cos(a),center.dy+ry*math.sin(a));});
    }
    final corners=[Offset(left,top),Offset(right,top),Offset(right,bottom),Offset(left,bottom),Offset(left,top)];
    final result=<Offset>[];
    for(var edge=0;edge<4;edge++){
      final a=corners[edge],b=corners[edge+1];
      for(var i=0;i<14;i++){final t=i/14;result.add(Offset(a.dx+(b.dx-a.dx)*t,a.dy+(b.dy-a.dy)*t));}
    }
    result.add(corners.last);
    return result;
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

  Widget _studioLobby(BuildContext context) {
    final presets=<(String,String,Color,bool)>[
      ('midnight','ليل بنفسجي',const Color(0xFF171522),true),
      ('paper','ورق عاجي',const Color(0xFFF2EBDD),true),
      ('grid','شبكة هادئة',const Color(0xFF202838),true),
      ('canvas','لوحة فاتحة',const Color(0xFFFAFAF7),false),
    ];
    return ListView(padding:const EdgeInsets.all(18),children:[
      Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(gradient:const LinearGradient(colors:[Color(0xFF34294B),Color(0xFF171725),Color(0xFF18343A)]),borderRadius:BorderRadius.circular(24),border:Border.all(color:_gold.withValues(alpha:.3))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Icon(Icons.draw_rounded,color:_gold,size:34),const SizedBox(height:14),
        Text(_t(context,'مرسم OURS','OURS Studio'),style:const TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.w800)),
        const SizedBox(height:6),Text(_t(context,'اختر نوع المرسم وأجواء اللوحة قبل البدء، ثم استخدم أدوات الرسم والتظليل والممحاة والتراجع والتكبير.','Choose your studio and canvas mood before drawing, then use brushes, marker, eraser, undo and zoom.'),style:const TextStyle(color:_lavender,height:1.6)),
      ])),
      const SizedBox(height:20),Text(_t(context,'اختر مساحة العمل','Choose your workspace'),style:const TextStyle(color:_gold,fontWeight:FontWeight.bold,fontSize:16)),
      const SizedBox(height:10),GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:2.15,crossAxisSpacing:9,mainAxisSpacing:9,children:[_StudioChoice(icon:Icons.person_outline_rounded,title:_t(context,'مرسمي الخاص','Personal studio'),subtitle:_t(context,'لوحاتك وحدك','Only you'),selected:scope=='personal',onTap:()=>setState(()=>scope='personal')),_StudioChoice(icon:Icons.people_alt_outlined,title:_t(context,'مرسمنا المشترك','Shared studio'),subtitle:_t(context,'ارسم مع الطرف الآخر','Draw together'),selected:scope=='shared',onTap:()=>setState(()=>scope='shared'))]),
      const SizedBox(height:18),Text(_t(context,'اختر خلفية البداية','Choose a canvas preset'),style:const TextStyle(color:_gold,fontWeight:FontWeight.bold)),
      const SizedBox(height:10),GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,childAspectRatio:1.65,crossAxisSpacing:10,mainAxisSpacing:10,children:presets.map((p)=>InkWell(onTap:(){setState((){canvasPreset=p.$1;canvasBackground=p.$3;showGrid=p.$4;});},borderRadius:BorderRadius.circular(14),child:Container(decoration:BoxDecoration(color:p.$3,borderRadius:BorderRadius.circular(14),border:Border.all(color:canvasPreset==p.$1?_gold:_lavender.withValues(alpha:.3),width:canvasPreset==p.$1?2:1)),child:Stack(children:[if(p.$4)Positioned.fill(child:CustomPaint(painter:_StudioPreviewGrid())),Align(alignment:Alignment.bottomLeft,child:Padding(padding:const EdgeInsets.all(10),child:Text(p.$2,style:TextStyle(color:p.$1=='paper'||p.$1=='canvas'?const Color(0xFF29213D):Colors.white,fontWeight:FontWeight.bold)))),if(canvasPreset==p.$1)const Positioned(top:7,right:7,child:Icon(Icons.check_circle,color:_gold))])))).toList()),
      const SizedBox(height:18),Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:_p.withValues(alpha:.65),borderRadius:BorderRadius.circular(16),border:Border.all(color:_l.withValues(alpha:.2))),child:Wrap(spacing:12,runSpacing:10,children:[_StudioFeature(Icons.gesture_rounded,_t(context,'رسم حر','Freehand')),_StudioFeature(Icons.shape_line_rounded,_t(context,'أشكال هندسية','Shapes')),_StudioFeature(Icons.brush_rounded,_t(context,'فرش وتظليل','Brushes')),_StudioFeature(Icons.undo_rounded,_t(context,'تراجع وإعادة','Undo / redo')),_StudioFeature(Icons.zoom_in_rounded,_t(context,'تكبير اللوحة','Canvas zoom'))])),
      const SizedBox(height:18),FilledButton.icon(onPressed:(){setState(()=>studioOpened=true);_load();},icon:const Icon(Icons.add_rounded),label:Text(_t(context,'إنشاء لوحة وبدء الرسم','Create canvas and start drawing')),style:FilledButton.styleFrom(backgroundColor:_gold,foregroundColor:_navy,padding:const EdgeInsets.symmetric(vertical:15))),
      const SizedBox(height:8),OutlinedButton.icon(onPressed:(){setState(()=>studioOpened=true);_load();},icon:const Icon(Icons.folder_open_outlined),label:Text(_t(context,'فتح أعمالي المحفوظة','Open saved work'))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (!studioOpened) return _studioLobby(context);
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
        Padding(padding:const EdgeInsets.fromLTRB(12,4,12,0),child:Wrap(spacing:8,children:[
          ChoiceChip(label:Text(_t(context,'قلم','Pen')),selected:toolMode=='pen',onSelected:(_){setState((){toolMode='pen';erasing=false;marker=false;});}),
          ChoiceChip(label:Text(_t(context,'تظليل','Marker')),selected:toolMode=='marker',onSelected:(_){setState((){toolMode='marker';erasing=false;marker=true;});}),
          ChoiceChip(label:Text(_t(context,'ممحاة','Eraser')),selected:toolMode=='eraser',onSelected:(_){setState((){toolMode='eraser';erasing=true;marker=false;});}),
          ChoiceChip(label:Text(_t(context,'خط مستقيم','Line')),selected:toolMode=='line',onSelected:(_){setState((){toolMode='line';erasing=false;marker=false;});}),
          ChoiceChip(label:Text(_t(context,'مستطيل','Rectangle')),selected:toolMode=='rectangle',onSelected:(_){setState((){toolMode='rectangle';erasing=false;marker=false;});}),
          ChoiceChip(label:Text(_t(context,'دائرة','Circle')),selected:toolMode=='circle',onSelected:(_){setState((){toolMode='circle';erasing=false;marker=false;});}),
        ])),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final selectedColor in [_l, _g, Colors.white, const Color(0xFFFF6B6B), const Color(0xFFFF9F43), const Color(0xFFFFD166), const Color(0xFF9BE564), const Color(0xFF36D6A8), const Color(0xFF45C4E8), const Color(0xFF5B8DEF), const Color(0xFF9B7BFF), const Color(0xFFE879F9), const Color(0xFFFF8FC7), const Color(0xFFB7C5D3), const Color(0xFF8D6E63), const Color(0xFF222222)])
                IconButton(
                  tooltip: selectedColor.toString(),
                  onPressed: () => setState(() { color = selectedColor; erasing = false; marker = false; toolMode = 'pen'; }),
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
                            onPanStart: (details) {
                              final p=_normalized(details.localPosition);
                              setState((){gestureStart=p;points=[p];});
                            },
                            onPanUpdate: (details) {
                              final p=_normalized(details.localPosition);
                              setState((){
                                if(['line','rectangle','circle'].contains(toolMode)&&gestureStart!=null){points=_shapePoints(gestureStart!,p);}
                                else{points.add(p);}
                              });
                            },
                            onPanEnd: (_) {gestureStart=null;_save();},
                            child: CustomPaint(
                              painter: _CanvasPainter(rows, points, erasing ? canvasBackground : color.withValues(alpha: marker ? opacity * 0.42 : opacity), erasing ? 28 : marker ? strokeWidth * 2.2 : strokeWidth, showGrid),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
        ),
        TextButton.icon(onPressed:()=>setState(()=>studioOpened=false),icon:const Icon(Icons.dashboard_outlined,color:_gold),label:Text(_t(context,'العودة لاختيار المرسم','Back to studio selection'))),
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

class _StudioChoice extends StatelessWidget{
 final IconData icon;final String title,subtitle;final bool selected;final VoidCallback onTap;
 const _StudioChoice({required this.icon,required this.title,required this.subtitle,required this.selected,required this.onTap});
 @override Widget build(BuildContext c)=>InkWell(onTap:onTap,borderRadius:BorderRadius.circular(14),child:Container(padding:const EdgeInsets.all(11),decoration:BoxDecoration(color:_p,borderRadius:BorderRadius.circular(14),border:Border.all(color:selected?_g:_l.withValues(alpha:.22),width:selected?1.6:1)),child:Row(children:[Icon(icon,color:selected?_g:_l,size:22),const SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[Text(title,style:const TextStyle(color:Colors.white,fontSize:11,fontWeight:FontWeight.bold)),Text(subtitle,style:const TextStyle(color:_l,fontSize:9))])),if(selected)const Icon(Icons.check_circle,color:_g,size:17)])));
}
class _StudioFeature extends StatelessWidget{final IconData icon;final String title;const _StudioFeature(this.icon,this.title);@override Widget build(BuildContext c)=>Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,color:_g,size:16),const SizedBox(width:5),Text(title,style:const TextStyle(color:_l,fontSize:10))]);}
class _StudioPreviewGrid extends CustomPainter {
  @override
  void paint(Canvas canvas,Size size){
    final paint=Paint()..color=const Color(0xFFB9A2D5).withValues(alpha:.18)..strokeWidth=.7;
    for(double x=0;x<size.width;x+=18){canvas.drawLine(Offset(x,0),Offset(x,size.height),paint);}
    for(double y=0;y<size.height;y+=18){canvas.drawLine(Offset(0,y),Offset(size.width,y),paint);}
  }
  @override
  bool shouldRepaint(covariant _StudioPreviewGrid oldDelegate)=>false;
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

class _WatchView extends StatefulWidget{final String spaceId;final bool active;const _WatchView({required this.spaceId,required this.active});@override State<_WatchView> createState()=>_WatchState();}
class _WatchState extends State<_WatchView> {
  final db = Supabase.instance.client;
  final title = TextEditingController();
  final url = TextEditingController();
  Map<String, dynamic>? session;
  bool busy = false;
  RealtimeChannel? channel;
  VideoPlayerController? player;
  Timer? syncTimer;
  String? loadedSource, playerError;
  bool playerLoading = false;

  int get _positionMs => (session?['position_ms'] as num?)?.toInt() ?? 0;
  bool get _isPlaying => session?['is_playing'] == true;

  @override
  void didUpdateWidget(covariant _WatchView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active && session != null) {
      _ensurePlayer(session!);
    } else if (oldWidget.active && !widget.active && player?.value.isPlaying == true) {
      player!.pause();
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
    syncTimer = Timer.periodic(const Duration(seconds: 4), (_) => _syncPlaybackPosition());
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
      if (!mounted) return;
      setState(() => session = result);
      if (result == null) {
        loadedSource = null;
        final old = player;
        player = null;
        if (old != null) await old.dispose();
      } else if (widget.active) {
        await _ensurePlayer(Map<String, dynamic>.from(result));
      }
    } catch (error) {
      _message(error.toString());
    }
  }

  bool _isDirectVideoUrl(Uri uri) {
    final path = uri.path.toLowerCase();
    return path.endsWith('.mp4') || path.endsWith('.m3u8') || path.endsWith('.webm');
  }

  Future<void> _ensurePlayer(Map<String, dynamic> current) async {
    final source = current['source_url']?.toString() ?? '';
    final uri = Uri.tryParse(source);
    if (uri == null || !_isDirectVideoUrl(uri)) {
      playerError = _t(context, 'هذا المصدر لا يوفّر رابط فيديو مباشرًا مدعومًا داخل التطبيق. استخدم رابط MP4 أو HLS مباشرًا.', 'This source does not provide a supported direct video stream. Use a direct MP4 or HLS link.');
      if (mounted) setState(() => playerLoading = false);
      return;
    }
    if (loadedSource == source && player?.value.isInitialized == true) {
      await _applyRemoteState(current);
      return;
    }
    final old = player;
    player = null;
    loadedSource = source;
    playerError = null;
    if (mounted) setState(() => playerLoading = true);
    if (old != null) await old.dispose();
    final controller = VideoPlayerController.networkUrl(uri);
    player = controller;
    try {
      await controller.initialize();
      await controller.setLooping(false);
      await _applyRemoteState(current);
      if (mounted && identical(player, controller)) {
        setState(() => playerLoading = false);
      }
    } catch (error) {
      if (mounted && identical(player, controller)) {
        setState(() {
          playerLoading = false;
          playerError = _t(context, 'تعذر تشغيل الفيديو داخل OURS. تحقق من صلاحية الرابط ودعم صيغة الفيديو.', 'Could not play this video inside OURS. Check the URL and supported video format.');
        });
      }
    }
  }

  Future<void> _applyRemoteState(Map<String, dynamic> current) async {
    final controller = player;
    if (controller == null || !controller.value.isInitialized) return;
    final target = Duration(milliseconds: (current['position_ms'] as num?)?.toInt() ?? 0);
    final actual = controller.value.position;
    if ((actual - target).inMilliseconds.abs() > 1800) {
      await controller.seekTo(target);
    }
    if (current['is_playing'] == true) {
      if (!controller.value.isPlaying) await controller.play();
    } else if (controller.value.isPlaying) {
      await controller.pause();
    }
  }

  Future<void> _syncPlaybackPosition() async {
    final current = session;
    final controller = player;
    if (!widget.active || current == null || controller == null || !controller.value.isInitialized ||
        current['is_playing'] != true ||
        current['created_by']?.toString() != db.auth.currentUser?.id ||
        !controller.value.isPlaying) return;
    try {
      await db.from('ours_watch_sessions').update({
        'position_ms': controller.value.position.inMilliseconds,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', current['id']).eq('status', 'active');
    } catch (_) {
      // A missed heartbeat is recovered by the next realtime update.
    }
  }

  Future<void> _seekBy(int deltaMs) async {
    final controller = player;
    if (controller == null || !controller.value.isInitialized) return;
    final target = (controller.value.position.inMilliseconds + deltaMs).clamp(0, controller.value.duration.inMilliseconds);
    await _updateSession(positionMs: target);
  }

  Future<void> _start() async {
    final uri = Uri.tryParse(url.text.trim());
    if (title.text.trim().isEmpty ||
        uri == null ||
        !uri.hasAuthority ||
        !['http', 'https'].contains(uri.scheme) ||
        !_isDirectVideoUrl(uri)) {
      _message(_t(context, 'أدخل اسمًا ورابط فيديو مباشرًا بصيغة MP4 أو HLS أو WebM.', 'Enter a title and a direct MP4, HLS or WebM video URL.'));
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
      await _ensurePlayer(Map<String, dynamic>.from(created));
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
        if (status == 'ended' || updated == null) {
          final old = player;
          player = null;
          loadedSource = null;
          if (old != null) await old.dispose();
        } else {
          await _applyRemoteState(Map<String, dynamic>.from(updated));
        }
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
              labelText: _t(context, 'رابط فيديو مباشر (MP4 / HLS / WebM)', 'Direct video URL (MP4 / HLS / WebM)'),
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
                  if (playerLoading)
                    const AspectRatio(aspectRatio: 16 / 9, child: Center(child: CircularProgressIndicator(color: _g)))
                  else if (playerError != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16)),
                      child: Column(children: [
                        const Icon(Icons.video_library_outlined, color: _g, size: 38),
                        const SizedBox(height: 10),
                        Text(playerError!, textAlign: TextAlign.center, style: const TextStyle(color: _l, height: 1.5)),
                      ]),
                    )
                  else if (player?.value.isInitialized == true)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(children: [
                        AspectRatio(aspectRatio: player!.value.aspectRatio, child: VideoPlayer(player!)),
                        ValueListenableBuilder<VideoPlayerValue>(
                          valueListenable: player!,
                          builder: (context, value, _) {
                            final duration = value.duration.inMilliseconds;
                            if (duration <= 0) return const LinearProgressIndicator(minHeight: 3, color: _g);
                            final position = value.position.inMilliseconds.clamp(0, duration).toDouble();
                            return Slider(
                              min: 0,
                              max: duration.toDouble(),
                              value: position,
                              activeColor: _g,
                              inactiveColor: Colors.white24,
                              onChanged: (next) => player!.seekTo(Duration(milliseconds: next.round())),
                              onChangeEnd: (next) => _updateSession(positionMs: next.round()),
                            );
                          },
                        ),
                      ]),
                    )
                  else
                    const AspectRatio(aspectRatio: 16 / 9, child: Center(child: Icon(Icons.play_circle_outline, color: _g, size: 56))),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: _t(context, 'رجوع 10 ثوانٍ', 'Back 10 seconds'),
                        onPressed: busy ? null : () => _seekBy(-10000),
                        icon: const Icon(Icons.replay_10, color: _g, size: 32),
                      ),
                      IconButton.filled(
                        tooltip: _isPlaying ? _t(context, 'إيقاف مؤقت', 'Pause') : _t(context, 'تشغيل', 'Play'),
                        onPressed: busy || player?.value.isInitialized != true ? null : () => _updateSession(isPlaying: !_isPlaying),
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      ),
                      IconButton(
                        tooltip: _t(context, 'تقديم 10 ثوانٍ', 'Forward 10 seconds'),
                        onPressed: busy ? null : () => _seekBy(10000),
                        icon: const Icon(Icons.forward_10, color: _g, size: 32),
                      ),
                    ],
                  ),
                  Center(child: Text(
                    _formatPosition(player?.value.isInitialized == true ? player!.value.position.inMilliseconds : _positionMs),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  )),
                  const SizedBox(height: 8),
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
              'الفيديو يعمل داخل OURS مباشرة عند استخدام رابط ملف فيديو مباشر مدعوم. تتزامن أوامر التشغيل والإيقاف والتقديم وموضع المشاهدة بين الحسابين؛ الروابط التي تفتح صفحات منصات خارجية غير مدعومة كمشغل مضمّن.',
              'Video plays directly inside OURS when using a supported direct video stream. Play, pause, seek and playback position sync between both accounts; external platform webpages are not supported as embedded streams.',
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
    syncTimer?.cancel();
    player?.dispose();
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
