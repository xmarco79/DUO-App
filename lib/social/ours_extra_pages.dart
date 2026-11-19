import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

const _xpNavy=Color(0xFF10101C),_xpPurple=Color(0xFF29213D),_xpGold=Color(0xFFD9BC86),_xpLav=Color(0xFFB9A2D5);
String _xpText(BuildContext c,String ar,String en)=>Localizations.localeOf(c).languageCode=='ar'?ar:en;

class OursReportPage extends StatefulWidget{
 final String? spaceId;const OursReportPage({super.key,this.spaceId});
 @override State<OursReportPage> createState()=>_OursReportPageState();
}
class _OursReportPageState extends State<OursReportPage>{
 final db=Supabase.instance.client;bool loading=true;String? error;
 int total=0,media=0,audio=0,files=0,stickers=0,activeDays=0,streak=0,longest=0,worldItems=0;List<int> week=List.filled(7,0);
 @override void initState(){super.initState();_load();}
 Future<void> _load()async{
  setState(()=>loading=true);error=null;
  try{
   final uid=db.auth.currentUser?.id;if(uid==null)throw Exception('Authentication required');
   final member=await db.from('duo_conversation_members').select('conversation_id').eq('user_id',uid).limit(1);
   if(member.isNotEmpty){
    final cid=member.first['conversation_id'].toString();final rows=await db.from('duo_direct_messages').select('message_type,created_at').eq('conversation_id',cid);
    final days=<String>{};final counts=List<int>.filled(7,0);final now=DateTime.now();int med=0,au=0,fi=0,st=0;
    for(final r in rows){final type=r['message_type']?.toString()??'text';if(['image','video','view_once','view_twice'].contains(type))med++;if(type=='audio')au++;if(type=='file')fi++;if(type=='sticker')st++;
     final d=DateTime.tryParse(r['created_at']?.toString()??'')?.toLocal();if(d!=null){days.add(d.year.toString()+'-'+d.month.toString()+'-'+d.day.toString());final diff=DateTime(now.year,now.month,now.day).difference(DateTime(d.year,d.month,d.day)).inDays;if(diff>=0&&diff<7)counts[6-diff]++;}}
    total=rows.length;media=med;audio=au;files=fi;stickers=st;activeDays=days.length;week=counts;
    try{final s=await db.from('duo_direct_streaks').select('current_days,longest_days').eq('conversation_id',cid).maybeSingle();streak=(s?['current_days'] as num?)?.toInt()??0;longest=(s?['longest_days'] as num?)?.toInt()??0;}catch(_){}
   }
   if(widget.spaceId!=null){try{worldItems=(await db.from('duo_world_items').select('id').eq('space_id',widget.spaceId!)).length;}catch(_){worldItems=0;}}
  }catch(e){error=e.toString();}
  if(mounted)setState(()=>loading=false);
 }
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:_xpNavy,appBar:AppBar(backgroundColor:_xpNavy,title:Text(_xpText(context,'تقرير OURS','OURS report')),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh,color:_xpGold))]),body:loading?const Center(child:CircularProgressIndicator(color:_xpGold)):error!=null?Center(child:Text(error!,style:const TextStyle(color:_xpLav))):RefreshIndicator(color:_xpGold,onRefresh:_load,child:ListView(padding:const EdgeInsets.all(16),children:[
  Text(_xpText(context,'ملخص نشاطكما','Activity summary'),style:const TextStyle(color:_xpGold,fontSize:18,fontWeight:FontWeight.bold)),const SizedBox(height:10),
  GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:2,mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:1.55,children:[
   _card(_xpText(context,'الرسائل','Messages'),total,Icons.chat_bubble_outline),_card(_xpText(context,'السلسلة الحالية','Current streak'),streak,Icons.local_fire_department),
   _card(_xpText(context,'أطول سلسلة','Longest streak'),longest,Icons.emoji_events_outlined),_card(_xpText(context,'أيام النشاط','Active days'),activeDays,Icons.calendar_today),
   _card(_xpText(context,'الوسائط','Media'),media,Icons.photo_library_outlined),_card(_xpText(context,'ملفات وصوت','Files & audio'),files+audio,Icons.folder_outlined),
   _card(_xpText(context,'ملصقات','Stickers'),stickers,Icons.emoji_emotions_outlined),_card(_xpText(context,'عناصر العالم','World items'),worldItems,Icons.public_outlined),
  ]),
  const SizedBox(height:18),Text(_xpText(context,'نشاط آخر 7 أيام','Last 7 days'),style:const TextStyle(color:_xpGold,fontSize:16)),const SizedBox(height:10),
  Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:_xpPurple,borderRadius:BorderRadius.circular(16)),child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[for(int i=0;i<week.length;i++)Expanded(child:Column(children:[Text(week[i].toString(),style:const TextStyle(color:Colors.white,fontSize:11)),const SizedBox(height:5),Container(height:12+(week[i]*8).clamp(0,88),margin:const EdgeInsets.symmetric(horizontal:3),decoration:BoxDecoration(color:_xpLav,borderRadius:BorderRadius.circular(8))),const SizedBox(height:5),Text((i+1).toString(),style:const TextStyle(color:_xpGold,fontSize:10))]))])),
  const SizedBox(height:10),Text(_xpText(context,'التقرير يعرض أعداد النشاط فقط ولا يقرأ محتوى الرسائل.','This report shows activity counts only, not message contents.'),style:const TextStyle(color:_xpLav,fontSize:12))
 ])));
 Widget _card(String label,int value,IconData icon)=>Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:_xpPurple,borderRadius:BorderRadius.circular(16)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Icon(icon,color:_xpGold),Text(value.toString(),style:const TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.bold)),Text(label,style:const TextStyle(color:_xpLav,fontSize:11),maxLines:2,overflow:TextOverflow.ellipsis)]));
}

class OursDrawingStudioPage extends StatefulWidget{
 final String? spaceId;const OursDrawingStudioPage({super.key,this.spaceId});
 @override State<OursDrawingStudioPage> createState()=>_OursDrawingStudioPageState();
}
class _OursDrawingStudioPageState extends State<OursDrawingStudioPage>{
 bool shared=false,loading=false;List<Map<String,dynamic>> sessions=[];final db=Supabase.instance.client;
 @override void initState(){super.initState();if(widget.spaceId!=null)_load();}
 Future<void> _load()async{setState(()=>loading=true);try{sessions=List<Map<String,dynamic>>.from(await db.from('duo_studio_sessions').select('id,title').eq('space_id',widget.spaceId!).order('created_at',ascending:false));}catch(_){sessions=[];}if(mounted)setState(()=>loading=false);}
 Future<void> _create()async{final c=TextEditingController();final title=await showDialog<String>(context:context,builder:(d)=>AlertDialog(backgroundColor:_xpPurple,title:Text(_xpText(context,'مرسم مشترك','Shared studio')),content:TextField(controller:c,decoration:InputDecoration(hintText:_xpText(context,'اسم المرسم','Studio title'))),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:Text(_xpText(context,'إلغاء','Cancel'))),FilledButton(onPressed:()=>Navigator.pop(d,c.text.trim()),child:Text(_xpText(context,'إنشاء','Create'))]));c.dispose();if(title==null||title.isEmpty)return;try{final r=await db.from('duo_studio_sessions').insert({'space_id':widget.spaceId,'created_by':db.auth.currentUser!.id,'title':title}).select('id,title').single();if(mounted)Navigator.push(context,MaterialPageRoute(builder:(_)=>OursSharedStudioPage(sessionId:r['id'].toString(),title:r['title'].toString())));await _load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Create error: $e')));}}
 Future<void> _savePrivate(Uint8List bytes)async{try{final root=await getApplicationDocumentsDirectory();final folder=Directory(root.path+'/ours_drawings');if(!await folder.exists())await folder.create(recursive:true);final f=File(folder.path+'/drawing_'+DateTime.now().millisecondsSinceEpoch.toString()+'.png');await f.writeAsBytes(bytes);if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(_xpText(context,'حُفظ الرسم في ملفات التطبيق','Saved to app files'))));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Save error: $e')));}}
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:_xpNavy,appBar:AppBar(backgroundColor:_xpNavy,title:Text(_xpText(context,'مرسمنا','Our studio')),bottom:PreferredSize(preferredSize:const Size.fromHeight(45),child:Padding(padding:const EdgeInsets.all(8),child:SegmentedButton<bool>(segments:[ButtonSegment(value:false,label:Text(_xpText(context,'مرسمي الخاص','Private')),icon:const Icon(Icons.person_outline)),ButtonSegment(value:true,label:Text(_xpText(context,'مشترك','Shared')),icon:const Icon(Icons.people_outline))],selected:{shared},onSelectionChanged:(v)=>setState(()=>shared=v.first))))),body:shared?_shared():_private());
 Widget _private()=>_StudioCanvas(onSave:_savePrivate);
 Widget _shared(){if(widget.spaceId==null)return Center(child:Text(_xpText(context,'المساحة المشتركة غير جاهزة','Shared space not available'),style:const TextStyle(color:_xpLav)));if(loading)return const Center(child:CircularProgressIndicator(color:_xpGold));return Column(children:[Padding(padding:const EdgeInsets.all(10),child:FilledButton.icon(onPressed:_create,icon:const Icon(Icons.add),label:Text(_xpText(context,'إنشاء مرسم','Create studio')))),Expanded(child:sessions.isEmpty?Center(child:Text(_xpText(context,'لا توجد مراسم بعد','No studios yet'),style:const TextStyle(color:_xpLav))):ListView.builder(itemCount:sessions.length,itemBuilder:(c,i){final s=sessions[i];return Card(color:_xpPurple,child:ListTile(leading:const Icon(Icons.brush,color:_xpGold),title:Text(s['title'].toString(),style:const TextStyle(color:Colors.white)),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OursSharedStudioPage(sessionId:s['id'].toString(),title:s['title'].toString()))));}))]);}
}
class OursSharedStudioPage extends StatefulWidget{
 final String sessionId,title;const OursSharedStudioPage({super.key,required this.sessionId,required this.title});
 @override State<OursSharedStudioPage> createState()=>_OursSharedStudioPageState();
}
class _OursSharedStudioPageState extends State<OursSharedStudioPage>{
 final db=Supabase.instance.client;List<Map<String,dynamic>> strokes=[];RealtimeChannel? channel;bool loading=true;
 @override void initState(){super.initState();_load();_subscribe();}
 Future<void> _load()async{try{strokes=List<Map<String,dynamic>>.from(await db.from('duo_studio_strokes').select('stroke').eq('session_id',widget.sessionId).order('created_at'));}catch(_){}if(mounted)setState(()=>loading=false);}
 void _subscribe(){channel=db.channel('studio-'+widget.sessionId).onPostgresChanges(event:PostgresChangeEvent.insert,schema:'public',table:'duo_studio_strokes',filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'session_id',value:widget.sessionId),callback:(p){if(p.newRecord['user_id']==db.auth.currentUser?.id)return;if(mounted)setState(()=>strokes.add({'stroke':p.newRecord['stroke']}));}).subscribe();}
 Future<void> _sync(Map<String,dynamic> stroke)async{try{await db.from('duo_studio_strokes').insert({'session_id':widget.sessionId,'user_id':db.auth.currentUser!.id,'stroke':stroke});}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Sync failed: $e')));}}
 @override void dispose(){if(channel!=null)db.removeChannel(channel!);super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:_xpNavy,appBar:AppBar(backgroundColor:_xpNavy,title:Text(widget.title)),body:loading?const Center(child:CircularProgressIndicator(color:_xpGold)):_StudioCanvas(initial:strokes.map((r)=>Map<String,dynamic>.from(r['stroke'] as Map)).toList(),onStroke:_sync,showSave:false));
}
class _Stroke{final int color;final double width;final List<Offset> points;_Stroke(this.color,this.width,this.points);}
class _StudioCanvas extends StatefulWidget{
 final List<Map<String,dynamic>> initial;final Future<void> Function(Uint8List)? onSave;final Future<void> Function(Map<String,dynamic>)? onStroke;final bool showSave;
 const _StudioCanvas({this.initial=const[],this.onSave,this.onStroke,this.showSave=true});
 @override State<_StudioCanvas> createState()=>_StudioCanvasState();
}
class _StudioCanvasState extends State<_StudioCanvas>{
 final boundary=GlobalKey();final canvasKey=GlobalKey();List<_Stroke> strokes=[];_Stroke? active;Color color=Colors.deepPurple;double width=4;
 @override void initState(){super.initState();strokes=widget.initial.map((j)=>_Stroke((j['color'] as num).toInt(),(j['width'] as num).toDouble(),(j['points'] as List).map((p)=>Offset((p['x'] as num).toDouble(),(p['y'] as num).toDouble())).toList())).toList();}
 Map<String,dynamic> _serialize(_Stroke s)=>{'color':s.color,'width':s.width,'points':s.points.map((p)=>{'x':p.dx,'y':p.dy}).toList()};
 Size _size(){final box=canvasKey.currentContext?.findRenderObject() as RenderBox?;return box?.size??const Size(1,1);}
 void _start(Offset p){final size=_size();active=_Stroke(color.value,width,[Offset(p.dx/size.width,p.dy/size.height)]);setState(()=>strokes.add(active!));}
 void _move(Offset p){if(active==null)return;final size=_size();active!.points.add(Offset(p.dx/size.width,p.dy/size.height));setState((){});}
 Future<void> _finish()async{final s=active;active=null;if(s!=null&&widget.onStroke!=null)await widget.onStroke!(_serialize(s));}
 Future<void> _save()async{try{final r=boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;if(r==null)return;final img=await r.toImage(pixelRatio:2);final data=await img.toByteData(format:ui.ImageByteFormat.png);img.dispose();if(data!=null&&widget.onSave!=null)await widget.onSave!(data.buffer.asUint8List(data.offsetInBytes,data.lengthInBytes));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Export failed: $e')));}}
 @override Widget build(BuildContext context)=>Column(children:[Expanded(child:Padding(padding:const EdgeInsets.all(12),child:RepaintBoundary(key:boundary,child:Container(key:canvasKey,color:Colors.white,child:GestureDetector(onPanStart:(d)=>_start(d.localPosition),onPanUpdate:(d)=>_move(d.localPosition),onPanEnd:(_)=>_finish(),child:CustomPaint(painter:_StrokePainter(strokes),size:Size.infinite))))),Row(children:[for(final c in [Colors.deepPurple,Colors.pink,Colors.red,Colors.orange,Colors.amber,Colors.green,Colors.blue,Colors.black,Colors.white])IconButton(onPressed:()=>setState(()=>color=c),icon:Icon(Icons.circle,color:c,size:18)),IconButton(onPressed:strokes.isEmpty?null:()=>setState(()=>strokes.removeLast()),icon:const Icon(Icons.undo,color:_xpGold)),if(widget.showSave)IconButton(onPressed:_save,icon:const Icon(Icons.save_outlined,color:_xpGold))])]);
}
class _StrokePainter extends CustomPainter{
 final List<_Stroke> strokes;_StrokePainter(this.strokes);
 @override void paint(Canvas canvas,Size size){canvas.drawRect(Offset.zero&size,Paint()..color=Colors.white);for(final s in strokes){if(s.points.length<2)continue;final p=Paint()..color=Color(s.color)..strokeWidth=s.width..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round;final path=Path()..moveTo(s.points.first.dx*size.width,s.points.first.dy*size.height);for(final q in s.points.skip(1))path.lineTo(q.dx*size.width,q.dy*size.height);canvas.drawPath(path,p);}}
 @override bool shouldRepaint(covariant _StrokePainter old)=>old.strokes!=strokes;
}

class OursWatchTogetherPage extends StatefulWidget{
 final String? spaceId;const OursWatchTogetherPage({super.key,this.spaceId});
 @override State<OursWatchTogetherPage> createState()=>_OursWatchTogetherPageState();
}
class _OursWatchTogetherPageState extends State<OursWatchTogetherPage>{
 final db=Supabase.instance.client;List<Map<String,dynamic>> rooms=[];bool loading=false;RealtimeChannel? channel;
 @override void initState(){super.initState();_load();_subscribe();}
 Future<void> _load()async{if(widget.spaceId==null)return;setState(()=>loading=true);try{rooms=List<Map<String,dynamic>>.from(await db.from('duo_watch_rooms').select('id,title,video_url').eq('space_id',widget.spaceId!).order('created_at',ascending:false));}catch(_){}if(mounted)setState(()=>loading=false);}
 void _subscribe(){if(widget.spaceId==null)return;channel=db.channel('watchlist-'+widget.spaceId).onPostgresChanges(event:PostgresChangeEvent.all,schema:'public',table:'duo_watch_rooms',filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'space_id',value:widget.spaceId),callback:(_)=>_load()).subscribe();}
 Future<void> _create()async{final title=TextEditingController(),url=TextEditingController();final ok=await showDialog<bool>(context:context,builder:(d)=>AlertDialog(backgroundColor:_xpPurple,title:Text(_xpText(context,'جلسة مشاهدة','Watch room')),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:title,decoration:InputDecoration(hintText:_xpText(context,'اسم الجلسة','Title'))),TextField(controller:url,keyboardType:TextInputType.url,decoration:const InputDecoration(hintText:'HTTPS direct video URL'))]),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:Text(_xpText(context,'إلغاء','Cancel'))),FilledButton(onPressed:()=>Navigator.pop(d,true),child:Text(_xpText(context,'إنشاء','Create'))]));if(ok!=true){title.dispose();url.dispose();return;}final uri=Uri.tryParse(url.text.trim());if(uri==null||uri.scheme!='https'||!(uri.path.toLowerCase().endsWith('.mp4')||uri.path.toLowerCase().endsWith('.m3u8'))){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(_xpText(context,'الرابط يجب أن يكون HTTPS مباشرًا لفيديو MP4 أو HLS.','Use a direct HTTPS MP4 or HLS URL.'))));title.dispose();url.dispose();return;}try{final r=await db.from('duo_watch_rooms').insert({'space_id':widget.spaceId,'created_by':db.auth.currentUser!.id,'updated_by':db.auth.currentUser!.id,'title':title.text.trim().isEmpty?'Watch together':title.text.trim(),'video_url':url.text.trim()}).select('id,title,video_url').single();if(mounted)Navigator.push(context,MaterialPageRoute(builder:(_)=>OursWatchRoomPage(room:r)));await _load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Room failed: $e')));}title.dispose();url.dispose();}
 @override void dispose(){if(channel!=null)db.removeChannel(channel!);super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:_xpNavy,appBar:AppBar(backgroundColor:_xpNavy,title:Text(_xpText(context,'المشاهدة معًا','Watch together')),actions:[IconButton(onPressed:_load,icon:const Icon(Icons.refresh,color:_xpGold))]),body:widget.spaceId==null?Center(child:Text(_xpText(context,'المساحة المشتركة غير جاهزة','Shared space not ready'),style:const TextStyle(color:_xpLav))):loading?const Center(child:CircularProgressIndicator(color:_xpGold)):Column(children:[Padding(padding:const EdgeInsets.all(12),child:FilledButton.icon(onPressed:_create,icon:const Icon(Icons.add),label:Text(_xpText(context,'إنشاء جلسة','Create room')))),Expanded(child:rooms.isEmpty?Center(child:Text(_xpText(context,'لا توجد جلسات بعد','No rooms yet'),style:const TextStyle(color:_xpLav))):ListView.builder(itemCount:rooms.length,itemBuilder:(c,i){final r=rooms[i];return Card(color:_xpPurple,child:ListTile(leading:const Icon(Icons.movie,color:_xpGold),title:Text(r['title'].toString(),style:const TextStyle(color:Colors.white)),subtitle:Text(r['video_url'].toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:_xpLav)),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OursWatchRoomPage(room:r))));}))]));
}
class OursWatchRoomPage extends StatefulWidget{
 final Map<String,dynamic> room;const OursWatchRoomPage({super.key,required this.room});
 @override State<OursWatchRoomPage> createState()=>_OursWatchRoomPageState();
}
class _OursWatchRoomPageState extends State<OursWatchRoomPage>{
 final db=Supabase.instance.client;VideoPlayerController? player;RealtimeChannel? channel;bool loading=true;String? error;
 @override void initState(){super.initState();_init();}
 Future<void> _init()async{try{player=VideoPlayerController.networkUrl(Uri.parse(widget.room['video_url'].toString()));await player!.initialize();player!.addListener(_changed);if(mounted)setState(()=>loading=false);_subscribe();}catch(e){if(mounted)setState(()=>error=e.toString());}}
 void _changed(){if(mounted)setState((){});}
 void _subscribe(){channel=db.channel('watchroom-'+widget.room['id'].toString()).onPostgresChanges(event:PostgresChangeEvent.update,schema:'public',table:'duo_watch_rooms',filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'id',value:widget.room['id']),callback:(p){if(p.newRecord['updated_by']==db.auth.currentUser?.id)return;_remote(p.newRecord);}).subscribe();}
 Future<void> _remote(Map<String,dynamic> r)async{final p=player;if(p==null||!p.value.isInitialized)return;final target=Duration(milliseconds:(r['position_ms'] as num?)?.toInt()??0);if((p.value.position.inMilliseconds-target.inMilliseconds).abs()>2000)await p.seekTo(target);if(r['playing']==true&&!p.value.isPlaying)await p.play();if(r['playing']!=true&&p.value.isPlaying)await p.pause();}
 Future<void> _publish()async{final p=player;if(p==null)return;try{await db.from('duo_watch_rooms').update({'position_ms':p.value.position.inMilliseconds,'playing':p.value.isPlaying,'updated_by':db.auth.currentUser!.id,'updated_at':DateTime.now().toUtc().toIso8601String()}).eq('id',widget.room['id']);}catch(_){}}
 Future<void> _toggle()async{final p=player;if(p==null)return;if(p.value.isPlaying)await p.pause();else await p.play();await _publish();}
 Future<void> _seek(double value)async{await player?.seekTo(Duration(milliseconds:value.round()));await _publish();}
 @override void dispose(){if(channel!=null)db.removeChannel(channel!);player?.removeListener(_changed);player?.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:_xpNavy,appBar:AppBar(backgroundColor:_xpNavy,title:Text(widget.room['title'].toString())),body:loading?const Center(child:CircularProgressIndicator(color:_xpGold)):error!=null?Center(child:Text(error!,style:const TextStyle(color:_xpLav))):Column(children:[AspectRatio(aspectRatio:player!.value.aspectRatio,child:VideoPlayer(player!)),Row(children:[IconButton(onPressed:_toggle,icon:Icon(player!.value.isPlaying?Icons.pause:Icons.play_arrow,color:_xpGold,size:30)),Expanded(child:Slider(value:player!.value.position.inMilliseconds.toDouble().clamp(0,player!.value.duration.inMilliseconds.toDouble().clamp(1,999999999)).toDouble(),max:player!.value.duration.inMilliseconds.toDouble().clamp(1,999999999).toDouble(),activeColor:_xpGold,onChanged:_seek)),Text(_time(player!.value.position),style:const TextStyle(color:_xpLav))]),Padding(padding:const EdgeInsets.all(12),child:Text(_xpText(context,'يتم مزامنة التشغيل والتوقف والموقع الزمني. استخدم رابطًا مباشرًا.','Playback, pause and seek are synced. A direct video URL is required.'),style:const TextStyle(color:_xpLav,fontSize:12))]));
 String _time(Duration d)=>d.inMinutes.toString().padLeft(2,'0')+':'+(d.inSeconds%60).toString().padLeft(2,'0');
}
