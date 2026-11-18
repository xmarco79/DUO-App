import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ours_direct_chat_page.dart';
import '../notifications/ours_notifications.dart';

const _p=Color(0xFF29213D), _l=Color(0xFFB9A2D5), _g=Color(0xFFD9BC86);
String _t(BuildContext c,String a,String e)=>Localizations.localeOf(c).languageCode=='ar'?a:e;

class OursSocialHomePage extends StatefulWidget {
 final VoidCallback onProfileTap; final ValueChanged<String> onChatTap;
 const OursSocialHomePage({super.key,required this.onProfileTap,required this.onChatTap});
 @override State<OursSocialHomePage> createState()=>_OursSocialHomePageState();
}
class _OursSocialHomePageState extends State<OursSocialHomePage>{
 final db=Supabase.instance.client; int tab=0; String? spaceId,conversationId,error; bool loading=true;
 @override void initState(){super.initState();_load();channel=db.channel('ours-studio-live-'+widget.spaceId).onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'ours_canvas_strokes',filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'space_id',value:widget.spaceId),callback:(_)=>_load())..subscribe();}
 Future<void> _load() async {try{
  final raw=await db.rpc('ensure_ours_pair_space'); final m=Map<String,dynamic>.from(raw as Map);
  if(mounted)setState(() { spaceId=m['space_id'].toString(); conversationId=m['conversation_id'].toString(); loading=false; });
 }catch(e){if(mounted)setState(() { error=e.toString(); loading=false; });}}
 @override Widget build(BuildContext context){
  final labels=[_t(context,'مساحتنا','Space'),_t(context,'مرسمنا','Studio'),_t(context,'المشاهدة','Watch'),_t(context,'موسيقانا','Music'),_t(context,'التقرير','Report')];
  final icons=[Icons.forum_outlined,Icons.brush_outlined,Icons.live_tv_outlined,Icons.music_note_outlined,Icons.insights_outlined];
  return Scaffold(appBar:AppBar(title:const Text('OURS',style:TextStyle(color:_g,letterSpacing:5)),actions:[if(spaceId!=null) OursNotificationBell(spaceId:spaceId,onOpenMessage:()=>widget.onChatTap(spaceId!)),IconButton(onPressed:widget.onProfileTap,icon:const Icon(Icons.tune,color:_l))]),
   body:loading?const Center(child:CircularProgressIndicator(color:_g)):error!=null?Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(_t(context,'تعذر تجهيز مساحتنا','Could not load space')),Text(error!,style:const TextStyle(color:_l)),TextButton(onPressed:()=>setState(() { loading=true; error=null; _load(); }),child:Text(_t(context,'إعادة المحاولة','Retry')))])):
   IndexedStack(index:tab,children:[
    _SpaceView(onChat:()=>widget.onChatTap(spaceId!),onSelf:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const OursSelfChatPage())),onAi:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OursAiPage(conversationId:conversationId!)))),
    _StudioView(spaceId:spaceId!),
    _WatchView(spaceId:spaceId!),
    const _SpotifyView(),
    const _ReportView(),
   ]),
   bottomNavigationBar:NavigationBar(backgroundColor:_p,selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:List.generate(5,(i)=>NavigationDestination(icon:Icon(icons[i]),label:labels[i]))));
 }
}
class _SpaceView extends StatelessWidget{
 final VoidCallback onChat,onSelf,onAi;
 const _SpaceView({required this.onChat,required this.onSelf,required this.onAi});
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(18),children:[
  Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:_p,borderRadius:BorderRadius.circular(22),border:Border.all(color:_g.withValues(alpha:.25))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(Icons.all_inclusive,color:_g,size:34),const SizedBox(height:12),Text(_t(c,'مساحتنا','OUR SPACE'),style:const TextStyle(color:_g,fontSize:24,fontWeight:FontWeight.bold)),Text(_t(c,'مساحة دائمة وخاصة بين naif و zoi.','A permanent private space for naif and zoi.'),style:const TextStyle(color:_l)),const SizedBox(height:16),FilledButton.icon(onPressed:onChat,icon:const Icon(Icons.chat),label:Text(_t(c,'افتح محادثتنا','Open our chat')))])),
  const SizedBox(height:16),_tile(c,Icons.bookmark_border,_t(c,'مراسلة نفسي','Private notes'),_t(c,'ملاحظات خاصة بحسابك','Notes only you can see'),onSelf),
  _tile(c,Icons.auto_awesome,'OURS AI',_t(c,'مساعدك الذكي','Your AI assistant'),onAi),
 ]);
}
Widget _tile(BuildContext c,IconData i,String title,String sub,VoidCallback tap)=>Card(color:_p,child:ListTile(leading:Icon(i,color:_g),title:Text(title),subtitle:Text(sub,style:const TextStyle(color:_l)),trailing:const Icon(Icons.chevron_right,color:_l),onTap:tap));

class _StudioView extends StatefulWidget{final String spaceId;const _StudioView({required this.spaceId});@override State<_StudioView> createState()=>_StudioState();}
class _StudioState extends State<_StudioView>{
 final db=Supabase.instance.client;String scope='personal';List<Map<String,dynamic>> rows=[];bool loading=true;Color color=_l;List<Offset> points=[];RealtimeChannel? channel;
 @override void initState(){super.initState();_load();channel=db.channel('ours-watch-live-'+widget.spaceId).onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'ours_watch_sessions',filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'space_id',value:widget.spaceId),callback:(_)=>_load())..subscribe();}
 Future<void> _load()async{try{var q=db.from('ours_canvas_strokes').select().eq('space_id',widget.spaceId);q=scope=='personal'?q.eq('owner_id',db.auth.currentUser!.id):q.eq('scope','shared');final r=await q.order('created_at');if(mounted)setState(() { rows=List<Map<String,dynamic>>.from(r); loading=false; });}catch(_){if(mounted)setState(()=>loading=false);}}
 Future<void> _save()async{if(points.length<2)return;try{await db.from('ours_canvas_strokes').insert({'space_id':widget.spaceId,'owner_id':scope=='personal'?db.auth.currentUser!.id:null,'scope':scope,'points':points.map((p)=>{'x':p.dx,'y':p.dy}).toList(),'color':color.value,'stroke_width':4});points=[];_load();}catch(e){_msg(e.toString());}}
 void _msg(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
 @override void dispose(){if(channel!=null)db.removeChannel(channel!);super.dispose();}
 @override Widget build(BuildContext c)=>Column(children:[
  Padding(padding:const EdgeInsets.all(12),child:SegmentedButton<String>(segments:[ButtonSegment(value:'personal',label:Text(_t(c,'مرسمي','My studio'))),ButtonSegment(value:'shared',label:Text(_t(c,'مرسمنا المشترك','Shared studio')))],selected:{scope},onSelectionChanged:(v)=>setState(() { scope=v.first; loading=true; _load(); }))),
  Row(mainAxisAlignment:MainAxisAlignment.center,children:[for(final x in [_l,_g,Colors.white,Colors.redAccent,Colors.lightBlueAccent])IconButton(onPressed:()=>setState(()=>color=x),icon:Icon(Icons.circle,color:x))]),
  Expanded(child:Padding(padding:const EdgeInsets.all(10),child:Container(decoration:BoxDecoration(color:const Color(0xFF171522),borderRadius:BorderRadius.circular(18)),child:loading?const Center(child:CircularProgressIndicator()):GestureDetector(onPanStart:(d)=>setState(()=>points=[d.localPosition]),onPanUpdate:(d)=>setState(()=>points.add(d.localPosition)),onPanEnd:(_)=>_save(),child:CustomPaint(painter:_CanvasPainter(rows,points,color),child:const SizedBox.expand()))))),
  Padding(padding:const EdgeInsets.all(8),child:Text(_t(c,'المرسم الشخصي خاص بك، والمشترك ظاهر للحسابين.','Personal canvas is private; shared canvas is visible to both.'),style:const TextStyle(color:_l,fontSize:11)))
 ]);
}
class _CanvasPainter extends CustomPainter{
 final List<Map<String,dynamic>> rows;final List<Offset> active;final Color color;_CanvasPainter(this.rows,this.active,this.color);
 @override void paint(Canvas c,Size s){for(final r in rows){final raw=r['points'];if(raw is! List)continue;final pts=raw.whereType<Map>().map((p)=>Offset((p['x'] as num).toDouble(),(p['y'] as num).toDouble())).toList();_draw(c,pts,Color((r['color'] as num?)?.toInt()??_l.value));}_draw(c,active,color);}
 void _draw(Canvas c,List<Offset> pts,Color col){if(pts.length<2)return;final p=Paint()..color=col..strokeWidth=4..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;final path=Path()..moveTo(pts.first.dx,pts.first.dy);for(final x in pts.skip(1)){path.lineTo(x.dx,x.dy);}c.drawPath(path,p);}
 @override bool shouldRepaint(covariant _CanvasPainter old)=>true;
}

class _WatchView extends StatefulWidget{final String spaceId;const _WatchView({required this.spaceId});@override State<_WatchView> createState()=>_WatchState();}
class _WatchState extends State<_WatchView>{
 final db=Supabase.instance.client;final title=TextEditingController(),url=TextEditingController();Map<String,dynamic>? session;bool busy=false;RealtimeChannel? channel;
 @override void initState(){super.initState();_load();}
 Future<void> _load()async{try{final r=await db.from('ours_watch_sessions').select().eq('space_id',widget.spaceId).eq('status','active').order('updated_at',ascending:false).limit(1).maybeSingle();if(mounted)setState(()=>session=r);}catch(_){}}
 Future<void> _start()async{final uri=Uri.tryParse(url.text.trim());if(title.text.trim().isEmpty||uri==null||!['http','https'].contains(uri.scheme)){_msg(_t(context,'أدخل اسمًا ورابطًا صالحًا','Enter a title and valid URL'));return;}setState(()=>busy=true);try{await db.from('ours_watch_sessions').update({'status':'ended'}).eq('space_id',widget.spaceId).eq('status','active');await db.from('ours_watch_sessions').insert({'space_id':widget.spaceId,'created_by':db.auth.currentUser!.id,'title':title.text.trim(),'source_url':uri.toString(),'status':'active','position_ms':0,'is_playing':false});await _load();}catch(e){_msg(e.toString());}finally{if(mounted)setState(()=>busy=false);}}
 void _msg(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(18),children:[
  const _Header(icon:Icons.live_tv,title:'مشاهدة معًا',subtitle:'جلسة مشاهدة مشتركة'),
  if(session==null)...[const SizedBox(height:16),TextField(controller:title,decoration:InputDecoration(labelText:_t(c,'اسم المحتوى','Title'))),const SizedBox(height:10),TextField(controller:url,decoration:InputDecoration(labelText:_t(c,'رابط مصدر مرخّص','Licensed source URL'))),const SizedBox(height:12),FilledButton(onPressed:busy?null:_start,child:Text(_t(c,'بدء جلسة','Start session')))]
  else Card(color:_p,child:ListTile(title:Text(session!['title'].toString()),subtitle:Text(_t(c,'الجلسة نشطة. يمكن فتح المصدر الخارجي.','Session active. Open the external source.'),style:const TextStyle(color:_l)),trailing:IconButton(onPressed:()async{final u=Uri.tryParse(session!['source_url'].toString());if(u!=null)await launchUrl(u,mode:LaunchMode.externalApplication);},icon:const Icon(Icons.open_in_new,color:_g)))),
  const SizedBox(height:14),Text(_t(c,'تنبيه: هذه النسخة لا تدّعي تشغيل فيديو مدمج أو مزامنة موضع التشغيل الفعلي. ذلك يتطلب SDK وترخيصًا من مزود المحتوى.','This build does not claim embedded playback or real playback-position sync; these require a licensed provider SDK.'),style:const TextStyle(color:_l,fontSize:11))
 ]);
 @override void dispose(){title.dispose();url.dispose();if(channel!=null)db.removeChannel(channel!);super.dispose();}
}
class _SpotifyView extends StatefulWidget{const _SpotifyView();@override State<_SpotifyView> createState()=>_SpotifyState();}
class _SpotifyState extends State<_SpotifyView>{final q=TextEditingController();Future<void> _search()async{if(q.text.trim().isEmpty)return;final u=Uri.https('open.spotify.com','/search/'+Uri.encodeComponent(q.text.trim()));await launchUrl(u,mode:LaunchMode.externalApplication);}
 @override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(18),children:[const _Header(icon:Icons.headphones,title:'موسيقانا',subtitle:'Spotify · عربي وأجنبي'),const SizedBox(height:16),TextField(controller:q,onSubmitted:(_)=>_search(),decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:_t(c,'ابحث عن أغنية أو فنان','Search songs or artists'))),const SizedBox(height:12),FilledButton.icon(onPressed:_search,icon:const Icon(Icons.open_in_new),label:Text(_t(c,'البحث في Spotify','Search Spotify'))),const SizedBox(height:12),Text(_t(c,'التشغيل الكامل داخل OURS يتطلب Spotify Developer Client ID وOAuth وصلاحيات تشغيل معتمدة. لم يتم تفعيل التشغيل المدمج بعد.','Full in-app playback requires Spotify Developer Client ID, OAuth and approved playback permissions. Embedded playback is not enabled yet.'),style:const TextStyle(color:_l,fontSize:11))]);
 @override void dispose(){q.dispose();super.dispose();}
}
class _ReportView extends StatefulWidget{const _ReportView();@override State<_ReportView> createState()=>_ReportState();}
class _ReportState extends State<_ReportView>{final db=Supabase.instance.client;Map<String,dynamic>? data;bool loading=true;String? error;
 @override void initState(){super.initState();_load();}
 Future<void> _load()async{try{final r=await db.rpc('generate_ours_weekly_report');if(mounted)setState(() { data=Map<String,dynamic>.from(r as Map); loading=false; });}catch(e){if(mounted)setState(() { error=e.toString(); loading=false; });}}
 @override Widget build(BuildContext c){if(loading)return const Center(child:CircularProgressIndicator());if(error!=null)return Center(child:Text(_t(c,'التقرير يحتاج تحديث قاعدة البيانات','Report requires database migration')+'\n'+error!,style:const TextStyle(color:_l)));return ListView(padding:const EdgeInsets.all(18),children:[const _Header(icon:Icons.insights,title:'تقرير OURS',subtitle:'ملخص أسبوعي للحسابين'),for(final key in ['naif','zoi','shared'])Card(color:_p,child:ListTile(title:Text(key=='shared'?_t(c,'نشاطكما المشترك','Shared activity'):key),subtitle:Text((data![key]??{}).toString(),style:const TextStyle(color:_l))))]);}
}
class _Header extends StatelessWidget{final IconData icon;final String title,subtitle;const _Header({required this.icon,required this.title,required this.subtitle});@override Widget build(BuildContext c)=>Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:_p,borderRadius:BorderRadius.circular(18)),child:Row(children:[Icon(icon,color:_g,size:30),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:20,fontWeight:FontWeight.bold)),Text(subtitle,style:const TextStyle(color:_l,fontSize:12))]))]));}
