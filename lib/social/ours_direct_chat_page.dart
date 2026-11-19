import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ours_profile_page.dart';

const _navy=Color(0xFF10101C),_gold=Color(0xFFD9BC86),_lavender=Color(0xFFB9A2D5),_bucket='ours-direct-media';
class _ChatSkin{
 final String id,ar,en;final Color bg,mine,partner,accent;
 const _ChatSkin(this.id,this.ar,this.en,this.bg,this.mine,this.partner,this.accent);
}
const _skins=[
 _ChatSkin('aurora','الشفق القطبي','Aurora',Color(0xFF091A27),Color(0xFF174A55),Color(0xFF142D3B),Color(0xFF75E0D0)),
 _ChatSkin('sunset','غروب دافئ','Sunset',Color(0xFF211329),Color(0xFF713C52),Color(0xFF38243E),Color(0xFFFFB28A)),
 _ChatSkin('sakura','حديقة ساكورا','Sakura',Color(0xFF251923),Color(0xFF75445C),Color(0xFF3E2B3A),Color(0xFFFFB9D0)),
 _ChatSkin('ocean','أعماق المحيط','Deep ocean',Color(0xFF071B30),Color(0xFF15577A),Color(0xFF12354D),Color(0xFF75D5F2)),
 _ChatSkin('forest','غابة مطيرة','Rainforest',Color(0xFF0D211D),Color(0xFF28664D),Color(0xFF1C3D32),Color(0xFFA8E6B7)),
 _ChatSkin('cosmos','فضاء نجمي','Cosmic night',Color(0xFF100F2A),Color(0xFF493A82),Color(0xFF242442),Color(0xFFC5B7FF)),
 _ChatSkin('desert','وهج الصحراء','Desert glow',Color(0xFF241B17),Color(0xFF795034),Color(0xFF443126),Color(0xFFFFD18B)),
 _ChatSkin('neon','مدينة نيون','Neon city',Color(0xFF130F25),Color(0xFF553A79),Color(0xFF2D2448),Color(0xFF8EF0FF)),
];

class _ChatAtmospherePainter extends CustomPainter {
 final _ChatSkin skin;
 const _ChatAtmospherePainter(this.skin);

 @override
 void paint(Canvas canvas, Size size) {
  final rect=Offset.zero & size;
  canvas.drawRect(rect,Paint()..shader=LinearGradient(
   begin:Alignment.topLeft,end:Alignment.bottomRight,
   colors:[skin.bg,skin.partner.withValues(alpha:.88),skin.bg],
  ).createShader(rect));
  final accent=skin.accent;
  final soft=Paint()..color=accent.withValues(alpha:.10)..style=PaintingStyle.fill;
  final line=Paint()..color=accent.withValues(alpha:.16)..style=PaintingStyle.stroke..strokeWidth=1.2;
  switch(skin.id){
   case 'aurora':
    for(var i=0;i<4;i++){
     final path=Path()..moveTo(-size.width*.1,size.height*(.20+i*.12))
      ..cubicTo(size.width*.25,size.height*(.02+i*.12),size.width*.58,size.height*(.48+i*.08),size.width*1.12,size.height*(.16+i*.13));
     canvas.drawPath(path,Paint()..color=[accent, const Color(0xFF6B8FE8),const Color(0xFF63C9B5),const Color(0xFF9D83D8)][i].withValues(alpha:.09)..style=PaintingStyle.stroke..strokeWidth=28.0+i*8.0..maskFilter=const MaskFilter.blur(BlurStyle.normal,18));
    }
    break;
   case 'sunset':
    canvas.drawCircle(Offset(size.width*.78,size.height*.16),size.width*.20,Paint()..shader=RadialGradient(colors:[accent.withValues(alpha:.34),accent.withValues(alpha:0)]).createShader(Rect.fromCircle(center:Offset(size.width*.78,size.height*.16),radius:size.width*.20)));
    for(var i=0;i<3;i++){final sunsetPath=Path()..moveTo(0,size.height*(.56+i*.10))..quadraticBezierTo(size.width*.48,size.height*(.32+i*.10),size.width,size.height*(.58+i*.10))..lineTo(size.width,size.height)..lineTo(0,size.height)..close();canvas.drawPath(sunsetPath,Paint()..color=accent.withValues(alpha:.035+i*.018));}
    break;
   case 'sakura':
    for(var i=0;i<34;i++){
     final sx=((i*83)%997)/997*size.width,sy=((i*137)%991)/991*size.height;
     canvas.save();canvas.translate(sx,sy);canvas.rotate((i%7)*.43);
     canvas.drawOval(Rect.fromCenter(center:Offset.zero,width:7.0+(i%3)*2.0,height:14.0+(i%4)*2.0),Paint()..color=accent.withValues(alpha:.13));
     canvas.restore();
    }
    break;
   case 'ocean':
    for(var i=0;i<28;i++){
     final ox=((i*97)%991)/991*size.width,oy=((i*149)%983)/983*size.height,radius=4+(i%6)*3.0;
     canvas.drawCircle(Offset(ox,oy),radius,line);
     canvas.drawCircle(Offset(ox-radius*.28,oy-radius*.3),radius*.18,soft);
    }
    break;
   case 'forest':
    for(var i=0;i<22;i++){
     final fx=((i*89)%983)/983*size.width,fy=((i*127)%977)/977*size.height;
     canvas.save();canvas.translate(fx,fy);canvas.rotate((i%8)*.38);
     final leafPath=Path()..moveTo(0,0)..quadraticBezierTo(24,-28,36,0)..quadraticBezierTo(18,28,0,0);
     canvas.drawPath(leafPath,Paint()..color=accent.withValues(alpha:.07));
     canvas.drawLine(Offset.zero,Offset(30,0),line);canvas.restore();
    }
    break;
   case 'cosmos':
    for(var i=0;i<75;i++){
     final cx=((i*73)%997)/997*size.width,cy=((i*139)%991)/991*size.height,starRadius=1+(i%3)*.65;
     canvas.drawCircle(Offset(cx,cy),starRadius,Paint()..color=accent.withValues(alpha:.18+(i%4)*.07));
    }
    canvas.drawCircle(Offset(size.width*.76,size.height*.22),size.width*.24,line);
    canvas.drawCircle(Offset(size.width*.76,size.height*.22),size.width*.31,line);
    break;
   case 'desert':
    canvas.drawCircle(Offset(size.width*.78,size.height*.19),size.width*.13,Paint()..color=accent.withValues(alpha:.12));
    for(var i=0;i<3;i++){final dunePath=Path()..moveTo(0,size.height*(.58+i*.10))..quadraticBezierTo(size.width*.42,size.height*(.40+i*.12),size.width,size.height*(.62+i*.09));canvas.drawPath(dunePath,Paint()..color=accent.withValues(alpha:.06+i*.025)..style=PaintingStyle.stroke..strokeWidth=22);}
    break;
   case 'neon':
    for(var x=0.0;x<size.width;x+=34.0){canvas.drawLine(Offset(x,0),Offset(x,size.height),line);}
    for(var y=0.0;y<size.height;y+=34.0){canvas.drawLine(Offset(0,y),Offset(size.width,y),line);}
    canvas.drawLine(Offset(size.width*.08,size.height*.72),Offset(size.width*.92,size.height*.18),Paint()..color=accent.withValues(alpha:.15)..strokeWidth=3..maskFilter=const MaskFilter.blur(BlurStyle.normal,8));
    break;
  }
 }

 @override
 bool shouldRepaint(covariant _ChatAtmospherePainter oldDelegate)=>oldDelegate.skin.id!=skin.id;
}

class OursDirectChatPage extends StatefulWidget{
 final String conversationId,partnerName,partnerId;
 final String? spaceId;
 const OursDirectChatPage({super.key,required this.conversationId,required this.partnerName,required this.partnerId,this.spaceId});
 @override State<OursDirectChatPage> createState()=>_OursDirectChatPageState();
}
class _OursDirectChatPageState extends State<OursDirectChatPage>{
 final db=Supabase.instance.client,input=TextEditingController(),scroll=ScrollController(),picker=ImagePicker();
 final Map<String,Future<String>> urls={};final List<Map<String,dynamic>> messages=[];
 final Set<String> hiddenIds={};
 Map<String,dynamic>? replyTo;
 RealtimeChannel? channel;AudioRecorder? recorder;String? recordingPath;
 bool loading=true,sending=false,recording=false,uploading=false;_ChatSkin skin=_skins.first;
 bool get ar=>Localizations.localeOf(context).languageCode=='ar';
 String t(String a,String e)=>ar?a:e;String get uid=>db.auth.currentUser!.id;
 @override void initState(){super.initState();_loadSkin();_load();_listen();}
 Future<void> _loadSkin() async{
  final p=await SharedPreferences.getInstance();final id=p.getString('ours_direct_skin_'+widget.conversationId)??'midnight';
  final found=_skins.where((s)=>s.id==id);if(mounted)setState(()=>skin=found.isEmpty?_skins.first:found.first);
 }
 Future<void> _chooseSkin() async{
  final selected=await showModalBottomSheet<_ChatSkin>(
   context:context,backgroundColor:const Color(0xFF171326),showDragHandle:true,isScrollControlled:true,
   builder:(ctx)=>SafeArea(child:Padding(
    padding:const EdgeInsets.fromLTRB(14,8,14,18),
    child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(t('اختر أجواء محادثتكما','Choose your chat atmosphere'),style:const TextStyle(color:_gold,fontSize:18,fontWeight:FontWeight.w800)),
     const SizedBox(height:5),
     Text(t('كل أجواء لها مشهدها وتفاصيلها، وليس مجرد لون مختلف.','Each atmosphere has its own scene and details, not just a different color.'),style:const TextStyle(color:_lavender,fontSize:11)),
     const SizedBox(height:14),
     GridView.builder(
      shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:_skins.length,
      gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,childAspectRatio:1.35,crossAxisSpacing:10,mainAxisSpacing:10),
      itemBuilder:(context,index){
       final item=_skins[index];final active=skin.id==item.id;
       return InkWell(
        borderRadius:BorderRadius.circular(16),onTap:()=>Navigator.pop(ctx,item),
        child:Container(
         decoration:BoxDecoration(borderRadius:BorderRadius.circular(16),border:Border.all(color:active?item.accent:item.accent.withValues(alpha:.3),width:active?2:1)),
         clipBehavior:Clip.antiAlias,
         child:Stack(children:[
          Positioned.fill(child:CustomPaint(painter:_ChatAtmospherePainter(item))),
          Positioned(left:10,right:10,bottom:10,child:Text(ar?item.ar:item.en,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:12))),
          if(active)const Positioned(top:8,right:8,child:Icon(Icons.check_circle,color:_gold,size:18)),
         ]),
        ),
       );
      },
     ),
    ]),
   )),
  );
  if(selected==null)return;setState(()=>skin=selected);final p=await SharedPreferences.getInstance();await p.setString('ours_direct_skin_'+widget.conversationId,selected.id);
 }
 Future<void> _load() async{
  try{
   final hidden=await db.from('ours_direct_message_hides').select('message_id').eq('user_id',uid);
   hiddenIds..clear()..addAll(hidden.map((r)=>r['message_id'].toString()));
   final rows=await db.from('duo_direct_messages').select().eq('conversation_id',widget.conversationId).order('created_at');
   if(!mounted)return;setState((){messages..clear()..addAll(List<Map<String,dynamic>>.from(rows).where((m)=>!hiddenIds.contains(m['id'].toString())));loading=false;});_bottom();
  }catch(e){if(mounted){setState(()=>loading=false);_show(t('تعذر تحميل المحادثة: $e','Could not load conversation: $e'));}}
 }
 void _listen(){
  channel=db.channel('ours-direct-'+widget.conversationId).onPostgresChanges(event:PostgresChangeEvent.insert,schema:'public',table:'duo_direct_messages',
   filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'conversation_id',value:widget.conversationId),callback:(p){
    final row=Map<String,dynamic>.from(p.newRecord);if(!mounted||hiddenIds.contains(row['id'].toString())||messages.any((m)=>m['id']==row['id']))return;setState(()=>messages.add(row));_bottom();
   }).subscribe();
 }
 void _bottom()=>WidgetsBinding.instance.addPostFrameCallback((_){if(scroll.hasClients)scroll.animateTo(scroll.position.maxScrollExtent,duration:const Duration(milliseconds:220),curve:Curves.easeOut);});
 void _show(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
 Future<void> _sendText() async{
  final text=input.text.trim();if(text.isEmpty||sending)return;setState(()=>sending=true);
  try{await db.from('duo_direct_messages').insert({'conversation_id':widget.conversationId,'sender_id':uid,'body':text,'message_type':'text','reply_to':replyTo?['id']});input.clear();if(mounted)setState(()=>replyTo=null);}
  catch(e){_show(t('تعذر إرسال الرسالة: $e','Could not send message: $e'));}finally{if(mounted)setState(()=>sending=false);}
 }
 String _mime(String name){
  const types={'jpg':'image/jpeg','jpeg':'image/jpeg','png':'image/png','webp':'image/webp','m4a':'audio/mp4','aac':'audio/aac','mp3':'audio/mpeg','ogg':'audio/ogg','mp4':'video/mp4','mov':'video/quicktime','pdf':'application/pdf','txt':'text/plain','csv':'text/csv','doc':'application/msword','docx':'application/vnd.openxmlformats-officedocument.wordprocessingml.document','xls':'application/vnd.ms-excel','xlsx':'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','ppt':'application/vnd.ms-powerpoint','pptx':'application/vnd.openxmlformats-officedocument.presentationml.presentation','zip':'application/zip'};
  return types[name.split('.').last.toLowerCase()]??'';
 }
 Future<void> _upload(Uint8List bytes,String name,String type,{int? maxViews}) async{
  if(bytes.isEmpty)return;if(bytes.length>20*1024*1024){_show(t('الحد الأقصى 20 ميجابايت','Maximum size is 20 MB'));return;}
  final mime=_mime(name);if(mime.isEmpty){_show(t('نوع الملف غير مدعوم','Unsupported file type'));return;}setState(()=>uploading=true);
  final safe=name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'),'_');
  final path=widget.conversationId+'/'+uid+'/'+DateTime.now().microsecondsSinceEpoch.toString()+'_'+safe;
  try{
   await db.storage.from(_bucket).uploadBinary(path,bytes,fileOptions:FileOptions(contentType:mime,upsert:false,cacheControl:'3600'));
   try{await db.from('duo_direct_messages').insert({'conversation_id':widget.conversationId,'sender_id':uid,'body':path,'message_type':type,'max_views':maxViews??1});}
   catch(_){await db.storage.from(_bucket).remove([path]);rethrow;}
  }catch(e){_show(t('تعذر رفع المرفق: $e','Could not upload attachment: $e'));}finally{if(mounted)setState(()=>uploading=false);}
 }
 Future<void> _pickImageWithMode() async{
  final mode=await showModalBottomSheet<String>(context:context,backgroundColor:const Color(0xFF29213D),showDragHandle:true,
   builder:(ctx)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
    ListTile(leading:const Icon(Icons.image_outlined,color:_gold),title:Text(t('إرسال صورة عادية','Send a normal photo')),subtitle:Text(t('تبقى الصورة ظاهرة في المحادثة','Stays visible in the chat')),onTap:()=>Navigator.pop(ctx,'normal')),
    ListTile(leading:const Icon(Icons.looks_one_outlined,color:_gold),title:Text(t('مشاهدة مرة واحدة','View once')),subtitle:Text(t('تُفتح مرة واحدة ثم تختفي','Opens once, then disappears')),onTap:()=>Navigator.pop(ctx,'once')),
    ListTile(leading:const Icon(Icons.looks_two_outlined,color:_gold),title:Text(t('مشاهدة مرتين','View twice')),subtitle:Text(t('يمكن فتحها مرتين فقط','Can be opened twice only')),onTap:()=>Navigator.pop(ctx,'twice')),
   ])));
  if(mode==null)return;
  try{
   final f=await picker.pickImage(source:ImageSource.gallery,imageQuality:86,maxWidth:1600,maxHeight:1600);if(f==null)return;
   final ext=f.name.split('.').last.toLowerCase();final name=['png','webp'].contains(ext)?f.name:'photo_'+DateTime.now().millisecondsSinceEpoch.toString()+'.jpg';
   await _upload(await f.readAsBytes(),name,mode=='normal'?'image':mode=='once'?'view_once':'view_twice',maxViews:mode=='twice'?2:1);
  }catch(e){_show(t('تعذر اختيار الصورة: $e','Could not select image: $e'));}
 }
 Future<void> _pickVideo() async{
  try{
   final f=await picker.pickVideo(source:ImageSource.gallery,maxDuration:const Duration(minutes:2));
   if(f==null)return;
   final ext=f.name.split('.').last.toLowerCase();
   if(!['mp4','mov','webm'].contains(ext)){_show(t('صيغة الفيديو غير مدعومة','Unsupported video format'));return;}
   await _upload(await f.readAsBytes(),f.name,'video');
  }catch(e){_show(t('تعذر اختيار الفيديو: $e','Could not select video: $e'));}
 }
 Future<void> _sendSticker() async{
  const stickers=['😻','😽','😺','😸','😹','😿','🙀','😾','🐱','🐈','🐈‍⬛','🐾','😼','😹💗','🥺🐱','🐱💤','🐱🎀','🐱✨','🐱🍓','🐱🫶','🐱💢','🐱🤍','🐱☕','🐱🌙'];
  final chosen=await showModalBottomSheet<String>(context:context,backgroundColor:const Color(0xFF29213D),showDragHandle:true,
   builder:(ctx)=>SafeArea(child:Padding(padding:const EdgeInsets.all(16),child:Wrap(spacing:12,runSpacing:12,children:[
    for(final sticker in stickers) InkWell(onTap:()=>Navigator.pop(ctx,sticker),child:Container(width:58,height:58,alignment:Alignment.center,decoration:BoxDecoration(color:skin.partner,borderRadius:BorderRadius.circular(16)),child:Text(sticker,style:const TextStyle(fontSize:30))))
   ]))));
  if(chosen==null)return;
  try{await db.from('duo_direct_messages').insert({'conversation_id':widget.conversationId,'sender_id':uid,'body':chosen,'message_type':'sticker'});}
  catch(e){_show(t('تعذر إرسال الملصق: $e','Could not send sticker: $e'));}
 }
 Future<void> _consumeTemporaryMedia(String messageId) async{
  try{
   final path=await db.rpc('consume_ours_temporary_media',params:{'p_message_id':messageId}) as String?;
   if(path==null||path.isEmpty){_show(t('انتهت مرات مشاهدة هذه الصورة','This photo has no views left'));await _load();return;}
   final url=await _signed(path);
   await showDialog<void>(context:context,builder:(ctx)=>Dialog(backgroundColor:Colors.black,child:Column(mainAxisSize:MainAxisSize.min,children:[
    Padding(padding:const EdgeInsets.all(10),child:Text(t('صورة مؤقتة','Temporary photo'),style:const TextStyle(color:Colors.white))),
    Flexible(child:Image.network(url,fit:BoxFit.contain)),
    TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('إغلاق','Close')))
   ])));
   final row=await db.from('duo_direct_messages').select('view_count,max_views').eq('id',messageId).maybeSingle();
   final count=(row?['view_count'] as num?)?.toInt()??1,limit=(row?['max_views'] as num?)?.toInt()??1;
   if(count>=limit){await db.storage.from(_bucket).remove([path]);}
   if(mounted)await _load();
  }catch(e){_show(t('تعذر فتح الصورة: $e','Could not open image: $e'));}
 }
 Future<void> _showAttachments() async{
  final choice=await showModalBottomSheet<String>(context:context,backgroundColor:const Color(0xFF29213D),showDragHandle:true,
   builder:(ctx)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
    ListTile(leading:Icon(Icons.image_outlined,color:skin.accent),title:Text(t('إرسال صورة','Send photo')),subtitle:Text(t('عادية أو مشاهدة مؤقتة','Normal or temporary')),onTap:()=>Navigator.pop(ctx,'image')),
    ListTile(leading:Icon(Icons.video_library_outlined,color:skin.accent),title:Text(t('مقطع فيديو','Video')),onTap:()=>Navigator.pop(ctx,'video')),
    ListTile(leading:Icon(Icons.insert_drive_file_outlined,color:skin.accent),title:Text(t('ملف','File')),onTap:()=>Navigator.pop(ctx,'file')),
    ListTile(leading:Icon(Icons.emoji_emotions_outlined,color:skin.accent),title:Text(t('ملصقات القطط','Cat stickers')),onTap:()=>Navigator.pop(ctx,'sticker')),
   ])));
  if(choice==null)return;
  switch(choice){case 'image':await _pickImageWithMode();break;case 'video':await _pickVideo();break;case 'file':await _pickFile();break;case 'sticker':await _sendSticker();break;}
 }
 Future<void> _pickFile() async{
  try{final r=await FilePicker.platform.pickFiles(withData:true);if(r==null||r.files.isEmpty)return;final f=r.files.single;
   final bytes=f.bytes??(f.path==null?null:await File(f.path!).readAsBytes());if(bytes==null)throw Exception('No file data');await _upload(bytes,f.name,'file');
  }catch(e){_show(t('تعذر اختيار الملف: $e','Could not select file: $e'));}
 }
 Future<void> _startRecording() async{
  final r=recorder??=AudioRecorder();
  try{if(!await r.hasPermission()){_show(t('اسمح باستخدام الميكروفون أولًا','Allow microphone access first'));return;}
   final d=await getTemporaryDirectory();final p=d.path+'/ours_'+DateTime.now().microsecondsSinceEpoch.toString()+'.m4a';
   await r.start(const RecordConfig(encoder:AudioEncoder.aacLc,bitRate:96000,sampleRate:44100,numChannels:1,echoCancel:true,noiseSuppress:true),path:p);
   if(mounted)setState((){recordingPath=p;recording=true;});
  }catch(e){_show(t('تعذر بدء التسجيل: $e','Could not start recording: $e'));}
 }
 Future<void> _cancelRecording() async{
  final p=recordingPath;try{await recorder?.cancel();if(p!=null&&await File(p).exists())await File(p).delete();}catch(_){}
  if(mounted)setState((){recording=false;recordingPath=null;});
 }
 Future<void> _sendRecording() async{
  final r=recorder;if(r==null||!recording)return;setState((){sending=true;recording=false;});String? p;
  try{p=await r.stop();if(p==null)throw Exception('Recording unavailable');final f=File(p);if(!await f.exists())throw Exception('Recording not found');
   await _upload(await f.readAsBytes(),'voice_'+DateTime.now().millisecondsSinceEpoch.toString()+'.m4a','audio');
  }catch(e){_show(t('تعذر إرسال التسجيل: $e','Could not send recording: $e'));}
  finally{if(p!=null&&await File(p).exists())await File(p).delete();if(mounted)setState((){sending=false;recordingPath=null;});}
 }
 Future<String> _signed(String path){
  final old=urls[path];if(old!=null)return old;final f=db.storage.from(_bucket).createSignedUrl(path,900);urls[path]=f;
  f.then((_){Future<void>.delayed(const Duration(minutes:10),(){if(identical(urls[path],f)){urls.remove(path);if(mounted)setState((){});}});},onError:(_){if(identical(urls[path],f))urls.remove(path);});return f;
 }
 Future<void> _openFile(String path) async{
  try{final url=await _signed(path);if(!await launchUrl(Uri.parse(url),mode:LaunchMode.externalApplication))_show(t('تعذر فتح الملف','Could not open file'));}
  catch(e){_show(t('تعذر فتح الملف: $e','Could not open file: $e'));}
 }
 String _time(dynamic v){final d=DateTime.tryParse(v?.toString()??'')?.toLocal();return d==null?'':DateFormat(ar?'HH:mm':'h:mm a').format(d);}
 Future<void> _callInfo(bool video) async{
  await showDialog<void>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:const Color(0xFF29213D),icon:Icon(video?Icons.videocam_outlined:Icons.call_outlined,color:_gold),
   title:Text(t('المكالمات قيد التجهيز','Calls are being prepared')),
   content:Text(t('تشغيل المكالمات يحتاج ربط خدمة اتصال آمنة وإعداد مفاتيحها على الخادم. لن نعرض اتصالًا وهميًا.','Real calls require a secure calling provider and server-side credentials. We will not simulate a fake call.')),
   actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('حسنًا','OK')))]));
 }
 Future<void> _messageActions(Map<String,dynamic> message,bool mine,String type,String body) async{
  final choice=await showModalBottomSheet<String>(context:context,backgroundColor:const Color(0xFF211D30),showDragHandle:true,builder:(ctx)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
   ListTile(leading:const Icon(Icons.reply,color:_gold),title:Text(t('رد','Reply')),onTap:()=>Navigator.pop(ctx,'reply')),
   ListTile(leading:const Icon(Icons.copy,color:_gold),title:Text(t('نسخ','Copy')),onTap:()=>Navigator.pop(ctx,'copy')),
   if(mine)ListTile(leading:const Icon(Icons.delete_forever_outlined,color:Colors.redAccent),title:Text(t('حذف لدى الجميع','Delete for everyone')),onTap:()=>Navigator.pop(ctx,'everyone')),
   ListTile(leading:const Icon(Icons.delete_outline,color:Colors.orangeAccent),title:Text(t('حذف لديك','Delete for you')),onTap:()=>Navigator.pop(ctx,'local')),
  ])));
  if(choice==null)return;final id=message['id'].toString();
  if(choice=='copy'){await Clipboard.setData(ClipboardData(text:type=='text'?body:body.split('/').last));_show(t('تم النسخ','Copied'));return;}
  if(choice=='reply'){setState(()=>replyTo=message);return;}
  try{
   if(choice=='local'){
    await db.from('ours_direct_message_hides').insert({'message_id':id,'user_id':uid});
    hiddenIds.add(id);if(mounted)setState(()=>messages.removeWhere((m)=>m['id'].toString()==id));
   }else{
    await db.from('duo_direct_messages').delete().eq('id',id).eq('sender_id',uid);
    if(['image','view_once','view_twice','video','audio','file'].contains(type)){try{await db.storage.from(_bucket).remove([body]);}catch(_){}}
    if(mounted)setState(()=>messages.removeWhere((m)=>m['id'].toString()==id));
   }
  }catch(e){_show(t('تعذر حذف الرسالة: $e','Could not delete message: $e'));}
 }
 Future<void> _searchMessages() async{
  final controller=TextEditingController();
  final query=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:const Color(0xFF211D30),title:Text(t('البحث في المحادثة','Search chat')),content:TextField(controller:controller,autofocus:true,decoration:InputDecoration(hintText:t('اكتب كلمة للبحث','Search for a word'))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('إلغاء','Cancel'))),FilledButton(onPressed:()=>Navigator.pop(ctx,controller.text.trim()),child:Text(t('بحث','Search')))]));
  controller.dispose();if(query==null||query.isEmpty)return;
  final found=messages.where((m)=>(m['message_type']=='text'||m['message_type']=='sticker')&&(m['body']??'').toString().toLowerCase().contains(query.toLowerCase())).toList();
  if(!mounted)return;
  await showModalBottomSheet<void>(context:context,isScrollControlled:true,backgroundColor:const Color(0xFF211D30),builder:(ctx)=>SafeArea(child:SizedBox(height:MediaQuery.of(ctx).size.height*.65,child:Column(children:[
   Padding(padding:const EdgeInsets.all(16),child:Text(t('نتائج البحث','Search results')+' ('+found.length.toString()+')',style:const TextStyle(color:_gold,fontWeight:FontWeight.bold))),
   Expanded(child:found.isEmpty?Center(child:Text(t('لا توجد نتائج','No results'))):ListView(children:found.map((m)=>ListTile(title:Text(m['body'].toString(),maxLines:2,overflow:TextOverflow.ellipsis),subtitle:Text(_time(m['created_at'])))).toList()))
  ]))));
 }
 Future<void> _showChatLibrary(String kind) async{
  final types=kind=='media'?['image','view_once','view_twice','video']:['file','audio'];
  final found=messages.where((m)=>types.contains(m['message_type'])).toList();
  await showModalBottomSheet<void>(context:context,isScrollControlled:true,backgroundColor:const Color(0xFF211D30),builder:(ctx)=>SafeArea(child:SizedBox(height:MediaQuery.of(ctx).size.height*.65,child:Column(children:[
   Padding(padding:const EdgeInsets.all(16),child:Text(kind=='media'?t('الوسائط المرسلة','Shared media'):t('الملفات','Files'),style:const TextStyle(color:_gold,fontWeight:FontWeight.bold))),
   Expanded(child:found.isEmpty?Center(child:Text(t('لا توجد عناصر بعد','Nothing shared yet'))):ListView(children:found.map((m)=>ListTile(leading:Icon(kind=='media'?Icons.image_outlined:Icons.insert_drive_file_outlined,color:skin.accent),title:Text((m['body']??'').toString().split('/').last,maxLines:1,overflow:TextOverflow.ellipsis),subtitle:Text(_time(m['created_at'])))).toList()))
  ]))));
 }
 Future<void> _openAi() async {
   final id = widget.spaceId;
   if (id == null || id.isEmpty) {
    _show(t('مساعد OURS متاح من داخل مساحتنا.', 'Open OURS AI from inside our space.'));
    return;
   }
   await Navigator.push(context, MaterialPageRoute(builder: (_) => OursAiPage(spaceId: id)));
  }
  @override void dispose(){input.dispose();scroll.dispose();recorder?.dispose();if(channel!=null)db.removeChannel(channel!);super.dispose();}
 @override Widget build(BuildContext context){
  final me=db.auth.currentUser!.id;
  return Scaffold(backgroundColor:skin.bg,appBar:AppBar(backgroundColor:skin.bg,centerTitle:true,
   title:InkWell(
    borderRadius:BorderRadius.circular(12),
    onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OursProfilePage(userId:widget.partnerId))),
    child:Column(mainAxisSize:MainAxisSize.min,children:[
     Text(widget.partnerName,style:const TextStyle(fontSize:16)),
     Text(t('اضغط لعرض الملف الشخصي','Tap to view profile'),style:TextStyle(color:skin.accent,fontSize:10))
    ]),
   ),
   actions:[
    IconButton(tooltip:t('الثيم','Theme'),onPressed:_chooseSkin,icon:Icon(Icons.palette_outlined,color:skin.accent)),
    PopupMenuButton<String>(tooltip:t('المزيد','More'),icon:Icon(Icons.more_vert,color:skin.accent),onSelected:(v){
     if(v=='profile')Navigator.push(context,MaterialPageRoute(builder:(_)=>OursProfilePage(userId:widget.partnerId)));
     if(v=='search')_searchMessages();if(v=='media')_showChatLibrary('media');if(v=='files')_showChatLibrary('files');
    },itemBuilder:(_)=>[
     PopupMenuItem(value:'profile',child:Text(t('الملف الشخصي','Profile'))),
     PopupMenuItem(value:'search',child:Text(t('البحث عن الرسائل','Search messages'))),
     PopupMenuItem(value:'media',child:Text(t('الوسائط المرسلة','Shared media'))),
     PopupMenuItem(value:'files',child:Text(t('الملفات','Files'))),
    ]),
    IconButton(tooltip:t('اتصال صوتي','Voice call'),onPressed:()=>_callInfo(false),icon:Icon(Icons.call_outlined,color:skin.accent)),
    IconButton(tooltip:t('اتصال مرئي','Video call'),onPressed:()=>_callInfo(true),icon:Icon(Icons.videocam_outlined,color:skin.accent))
   ]),
   body:Stack(children:[
    Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:_ChatAtmospherePainter(skin)))),
    Column(children:[
    Expanded(child:loading?Center(child:CircularProgressIndicator(color:skin.accent)):messages.isEmpty
     ?Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Icon(Icons.forum_outlined,color:skin.accent,size:52),const SizedBox(height:12),Text(t('ابدأ محادثتكما الخاصة','Start your private conversation'),style:const TextStyle(fontSize:19)),
      const SizedBox(height:7),Text(t('رسائل وصور وملفات وتسجيلات صوتية في مكان واحد.','Messages, photos, files and voice notes in one place.'),textAlign:TextAlign.center,style:TextStyle(color:skin.accent))
     ])))
     :ListView.builder(controller:scroll,padding:const EdgeInsets.all(12),itemCount:messages.length,itemBuilder:(ctx,i){
      final m=messages[i];final mine=m['sender_id']==me;final type=m['message_type']?.toString()??'text';final path=m['body']?.toString()??'';
      return GestureDetector(onLongPress:()=>_messageActions(m,mine,type,path),child:Align(alignment:mine?AlignmentDirectional.centerEnd:AlignmentDirectional.centerStart,child:Container(
       constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*.82),margin:const EdgeInsets.symmetric(vertical:5),padding:const EdgeInsets.all(10),
       decoration:BoxDecoration(color:mine?skin.mine:skin.partner,borderRadius:BorderRadius.circular(17),border:Border.all(color:skin.accent.withValues(alpha:.16))),
       child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
        if(type=='sticker')Center(child:Text(path,style:const TextStyle(fontSize:42)))
        else if(type=='view_once'||type=='view_twice')
          (m['viewed_at']!=null || ((m['view_count'] as num?)?.toInt()??0)>=((m['max_views'] as num?)?.toInt()??1))
            ?Text(t('انتهت مشاهدات الصورة','No views left'),style:TextStyle(color:skin.accent,fontSize:12))
            :mine
              ?Text(type=='view_twice'?t('أرسلت صورة لمشاهدتين','You sent a two-view photo'):t('أرسلت صورة لمرة واحدة','You sent a one-view photo'),style:TextStyle(color:skin.accent,fontSize:12))
              :FutureBuilder<String>(future:_signed(path),builder:(c,s)=>s.hasData
                ?Column(mainAxisSize:MainAxisSize.min,children:[ClipRRect(borderRadius:BorderRadius.circular(11),child:ImageFiltered(imageFilter:ImageFilter.blur(sigmaX:13,sigmaY:13),child:Image.network(s.data!,width:210,height:130,fit:BoxFit.cover))),const SizedBox(height:7),TextButton.icon(onPressed:()=>_consumeTemporaryMedia(m['id'].toString()),icon:Icon(Icons.visibility_outlined,color:skin.accent),label:Text(type=='view_twice'?t('فتح الصورة · مشاهدتان','Open photo · two views'):t('فتح الصورة · مرة واحدة','Open photo · once')))])
                :Text(t('صورة مؤقتة','Temporary photo'),style:TextStyle(color:skin.accent,fontSize:12)))
        else if(type=='video')InkWell(onTap:()=>_openFile(path),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.play_circle_fill,color:skin.accent,size:36),const SizedBox(width:8),Text(t('مقطع فيديو · تشغيل','Video · Play'))]))
        else if(type=='image')FutureBuilder<String>(future:_signed(path),builder:(c,s){
         if(s.hasError)return Text(t('تعذر تحميل الصورة','Could not load image'),style:TextStyle(color:skin.accent));
         if(!s.hasData)return SizedBox(width:190,height:125,child:Center(child:CircularProgressIndicator(color:skin.accent)));
         return GestureDetector(onTap:()=>showDialog<void>(context:context,builder:(_)=>Dialog(backgroundColor:Colors.transparent,child:InteractiveViewer(child:Image.network(s.data!,fit:BoxFit.contain)))),
          child:ClipRRect(borderRadius:BorderRadius.circular(11),child:Image.network(s.data!,width:230,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Text(t('تعذر عرض الصورة','Image unavailable')))));
        })
        else if(type=='file')InkWell(onTap:()=>_openFile(path),child:Row(mainAxisSize:MainAxisSize.min,children:[
         Icon(Icons.insert_drive_file_outlined,color:skin.accent,size:30),const SizedBox(width:8),
         Flexible(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(path.split('/').last.replaceFirst(RegExp(r'^\d+_'),''),maxLines:2,overflow:TextOverflow.ellipsis),Text(t('اضغط لفتح الملف','Tap to open file'),style:TextStyle(color:skin.accent,fontSize:10))]))
        ]))
        else if(type=='audio')_DirectAudioBubble(path:path,skin:skin,signed:_signed,ar:ar)
        else SelectableText(path,style:const TextStyle(color:Colors.white,height:1.4)),
        const SizedBox(height:4),Align(alignment:AlignmentDirectional.centerEnd,child:Text(_time(m['created_at']),style:TextStyle(color:skin.accent,fontSize:10)))
       ]))));
     })),
    SafeArea(top:false,child:Container(padding:const EdgeInsets.fromLTRB(7,8,7,10),decoration:BoxDecoration(color:skin.bg,border:Border(top:BorderSide(color:skin.accent.withValues(alpha:.2)))),
     child:recording?Row(children:[
      IconButton(onPressed:_cancelRecording,icon:const Icon(Icons.delete_outline,color:Colors.redAccent)),
      Expanded(child:Text(t('جارٍ تسجيل الرسالة الصوتية…','Recording voice message…'),textAlign:TextAlign.center,style:TextStyle(color:skin.accent))),
      IconButton(onPressed:sending?null:_sendRecording,icon:Icon(Icons.send,color:skin.accent))
     ]):Column(mainAxisSize:MainAxisSize.min,children:[
      if(replyTo!=null)Container(margin:const EdgeInsets.fromLTRB(12,0,12,6),padding:const EdgeInsets.symmetric(horizontal:12,vertical:7),decoration:BoxDecoration(color:skin.partner,borderRadius:BorderRadius.circular(12)),child:Row(children:[Icon(Icons.reply,color:skin.accent,size:18),const SizedBox(width:8),Expanded(child:Text((replyTo!['body']??'').toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:skin.accent,fontSize:12))),IconButton(onPressed:()=>setState(()=>replyTo=null),icon:const Icon(Icons.close,size:17))])),
      Row(children:[
      IconButton(onPressed:uploading||sending?null:_showAttachments,tooltip:t('إرفاق صورة أو ملف أو ملصق','Attach photo, file or sticker'),icon:uploading?SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:skin.accent)):Icon(Icons.add_circle_outline_rounded,color:skin.accent)),
      Expanded(child:TextField(controller:input,minLines:1,maxLines:5,textInputAction:TextInputAction.send,onSubmitted:(_)=>_sendText(),decoration:InputDecoration(hintText:t('اكتب رسالة…','Write a message…'),filled:true,fillColor:skin.partner,border:OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:BorderSide.none),contentPadding:const EdgeInsets.symmetric(horizontal:15,vertical:11)))),
      IconButton(onPressed:uploading||sending?null:_startRecording,icon:Icon(Icons.mic_none_rounded,color:skin.accent)),
      IconButton.filled(onPressed:sending||uploading?null:_sendText,style:IconButton.styleFrom(backgroundColor:skin.accent,foregroundColor:skin.bg),icon:sending?const SizedBox(width:17,height:17,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send_rounded))
     ])])))
   ]),
  ]));
 }
}

class OursAiPage extends StatefulWidget{
 final String spaceId;const OursAiPage({super.key,required this.spaceId});
 @override State<OursAiPage> createState()=>_OursAiPageState();
}
class _OursAiPageState extends State<OursAiPage>{
 final db=Supabase.instance.client,input=TextEditingController(),scroll=ScrollController();final messages=<Map<String,String>>[];
 bool sending=false,includeContext=false;bool get ar=>Localizations.localeOf(context).languageCode=='ar';String t(String a,String e)=>ar?a:e;
 Future<List<Map<String,String>>> _context() async{
  final rows=await db.from('duo_messages').select('body,sender_id').eq('space_id',widget.spaceId).eq('message_type','text').isFilter('deleted_at',null).order('created_at',ascending:false).limit(20);
  return List<Map<String,dynamic>>.from(rows).reversed.map((r)=>{'sender':r['sender_id']==db.auth.currentUser!.id?(ar?'أنا':'Me'):(ar?'الشريك':'Partner'),'text':r['body'].toString()}).toList();
 }
 Future<void> _send({String? preset,String task='chat'}) async{
  final text=(preset??input.text).trim();if(text.isEmpty||sending)return;setState(()=>sending=true);messages.add({'role':'user','content':text});input.clear();_persist();_bottom();
  try{
   final ctx=includeContext?await _context():<Map<String,String>>[];final history=messages.length>12?messages.sublist(messages.length-12):messages;
   final r=await db.functions.invoke('ours-ai',body:{'space_id':widget.spaceId,'task':task,'messages':history,'context':ctx});
   final data=r.data is Map?Map<String,dynamic>.from(r.data):<String,dynamic>{};
   if(r.status!=200){final e=data['error']?.toString()??'';if(e=='GEMINI_SETUP_REQUIRED')throw Exception(t('مفتاح الذكاء الاصطناعي غير مضبوط على الخادم.','AI provider key is not configured on the server.'));
    if(e=='AI_LIMIT_REACHED')throw Exception(t('وصلنا لحد الاستخدام الحالي، حاول لاحقًا.','Usage limit reached. Try later.'));if(r.status==403)throw Exception(t('لا تملك صلاحية هذه المحادثة.','Conversation access denied.'));throw Exception(t('تعذر الاتصال بمساعد OURS.','Could not reach OURS AI.'));
   }
   final answer=data['answer']?.toString()??'';if(answer.isEmpty)throw Exception('Empty response');if(mounted){messages.add({'role':'assistant','content':answer});await _persist();}_bottom();
  }catch(e){if(mounted){messages.add({'role':'assistant','content':e.toString().replaceFirst('Exception: ','')});await _persist();}_bottom();}
  finally{if(mounted)setState(()=>sending=false);}
 }
 void _bottom()=>WidgetsBinding.instance.addPostFrameCallback((_){if(scroll.hasClients)scroll.animateTo(scroll.position.maxScrollExtent,duration:const Duration(milliseconds:220),curve:Curves.easeOut);});
 @override void initState(){super.initState();_restore();}
 Future<void> _restore() async{try{final p=await SharedPreferences.getInstance();final raw=p.getString('ours_ai_history_'+db.auth.currentUser!.id);if(raw!=null){final decoded=(jsonDecode(raw) as List).map((e)=>Map<String,String>.from(e)).toList();if(mounted)setState(()=>messages.addAll(decoded));}}catch(_){} }
 Future<void> _persist() async{try{final p=await SharedPreferences.getInstance();await p.setString('ours_ai_history_'+db.auth.currentUser!.id,jsonEncode(messages.take(100).toList()));}catch(_){} }
 @override void dispose(){input.dispose();scroll.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:_navy,appBar:AppBar(backgroundColor:_navy,centerTitle:true,title:Column(mainAxisSize:MainAxisSize.min,children:[const Text('OURS AI',style:TextStyle(color:_gold,letterSpacing:2,fontWeight:FontWeight.w800)),Text(t('مساعدك الذكي','Your private assistant'),style:const TextStyle(color:_lavender,fontSize:10))])),
  body:SafeArea(child:Column(children:[
   SwitchListTile(value:includeContext,onChanged:(v)=>setState(()=>includeContext=v),activeColor:_gold,title:Text(t('السماح باستخدام سياق المحادثة','Allow chat context')),subtitle:Text(t('مغلق افتراضيًا. تُرسل آخر الرسائل النصية فقط عند تفعيله.','Off by default. Recent text messages are shared only when enabled.'),style:const TextStyle(color:_lavender,fontSize:11))),
   Wrap(spacing:7,children:[
    ActionChip(label:Text(t('أفكار لنا','Ideas for us')),onPressed:sending?null:()=>_send(preset:t('اقترح أنشطة مناسبة لشخصين.','Suggest activities for two people.'),task:'ideas')),
    ActionChip(label:Text(t('تلخيص المحادثة','Summarize chat')),onPressed:sending||!includeContext?null:()=>_send(preset:t('لخّص آخر محادثاتنا.','Summarize our recent chat.'),task:'summary')),
    ActionChip(label:Text(t('خطط وأهداف','Plans')),onPressed:sending?null:()=>_send(preset:t('ساعدني أضع خطة عملية لأهدافي مع خطوات صغيرة قابلة للتنفيذ.','Help me create a practical plan with small actionable steps.'),task:'organize')),
    ActionChip(label:Text(t('مساعدة دراسية','Study help')),onPressed:sending?null:()=>_send(preset:t('ساعدني أذاكر موضوعًا بطريقة مبسطة مع أسئلة تدريبية.','Help me study a topic simply with practice questions.'),task:'study')),
    ActionChip(label:Text(t('أفكار إبداعية','Brainstorm')),onPressed:sending?null:()=>_send(preset:t('اعطني أفكارًا إبداعية ومختلفة لمشاريع وأنشطة ممتعة.','Give me creative and unusual project and activity ideas.'),task:'brainstorm')),
    ActionChip(label:Text(t('فضفضة وكتابة','Journal')),onPressed:sending?null:()=>_send(preset:t('ساعدني أرتب أفكاري وأكتب ما أشعر به بطريقة واضحة.','Help me organize my thoughts and journal clearly.'),task:'journal'))
   ]),
   Padding(padding:const EdgeInsets.all(10),child:Text(t('قد تتم معالجة سؤالك عبر مزوّد ذكاء اصطناعي خارجي. لا تفعّل سياق المحادثة إلا إذا رغبت بإرسال الرسائل الأخيرة.','Your prompt may be processed by an external AI provider. Enable chat context only if you want recent messages shared.'),textAlign:TextAlign.center,style:const TextStyle(color:_lavender,fontSize:10))),
   const Divider(color:Color(0x3329293D)),
   Expanded(child:ListView.builder(controller:scroll,padding:const EdgeInsets.all(14),itemCount:messages.length,itemBuilder:(c,i){final m=messages[i],mine=m['role']=='user';return Align(alignment:mine?AlignmentDirectional.centerEnd:AlignmentDirectional.centerStart,child:Container(constraints:const BoxConstraints(maxWidth:320),margin:const EdgeInsets.symmetric(vertical:5),padding:const EdgeInsets.all(13),decoration:BoxDecoration(color:mine?const Color(0xFF342B4C):const Color(0xFF211D30),borderRadius:BorderRadius.circular(16)),child:SelectableText(m['content']??'',style:const TextStyle(height:1.5))));})),
   if(sending)const LinearProgressIndicator(color:_gold,minHeight:2),
   Padding(padding:const EdgeInsets.fromLTRB(10,8,10,12),child:Row(children:[
    Expanded(child:TextField(controller:input,minLines:1,maxLines:4,textInputAction:TextInputAction.send,onSubmitted:(_)=>_send(),decoration:InputDecoration(hintText:t('اسأل OURS AI…','Ask OURS AI…'),filled:true,fillColor:const Color(0xFF29213D),border:OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:BorderSide.none)))),
    IconButton(onPressed:sending?null:()=>_send(),icon:const Icon(Icons.send_rounded,color:_gold))
   ]))
  ])));
}

class _DirectAudioBubble extends StatefulWidget{
 final String path;final _ChatSkin skin;final Future<String> Function(String) signed;final bool ar;
 const _DirectAudioBubble({required this.path,required this.skin,required this.signed,required this.ar});
 @override State<_DirectAudioBubble> createState()=>_DirectAudioBubbleState();
}
class _DirectAudioBubbleState extends State<_DirectAudioBubble>{
 final player=AudioPlayer();bool loading=false;
 Future<void> _toggle() async{
  if(player.state==PlayerState.playing){await player.pause();return;}setState(()=>loading=true);
  try{await player.play(UrlSource(await widget.signed(widget.path)));}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(widget.ar?'تعذر تشغيل الصوت':'Could not play audio')));}
  finally{if(mounted)setState(()=>loading=false);}
 }
 @override void dispose(){player.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>StreamBuilder<PlayerState>(stream:player.onPlayerStateChanged,initialData:player.state,builder:(c,s){
  final playing=s.data==PlayerState.playing;return Row(mainAxisSize:MainAxisSize.min,children:[
   IconButton(onPressed:loading?null:_toggle,icon:loading?SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:widget.skin.accent)):Icon(playing?Icons.pause_circle_filled:Icons.play_circle_fill,color:widget.skin.accent,size:34)),
   Text(widget.ar?(playing?'تشغيل الصوت…':'رسالة صوتية'):(playing?'Playing…':'Voice message'),style:const TextStyle(fontSize:12))
  ]);
 });
}

class OursSelfChatPage extends StatefulWidget{
 const OursSelfChatPage({super.key});
 @override State<OursSelfChatPage> createState()=>_OursSelfChatPageState();
}
class _OursSelfChatPageState extends State<OursSelfChatPage>{
 final db=Supabase.instance.client,input=TextEditingController(),scroll=ScrollController();
 List<Map<String,dynamic>> rows=[];bool loading=true,sending=false;
 bool get ar=>Localizations.localeOf(context).languageCode=='ar';
 String t(String a,String e)=>ar?a:e;
 @override void initState(){super.initState();_load();}
 Future<void> _load()async{try{final data=await db.from('ours_self_messages').select().order('created_at');if(mounted)setState(()=>rows=List<Map<String,dynamic>>.from(data));}catch(e){_notice(t('تعذر تحميل مذكرتك: $e','Could not load your notes: $e'));}finally{if(mounted)setState(()=>loading=false);}}
 void _notice(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
 Future<void> _send()async{final text=input.text.trim();if(text.isEmpty||sending)return;setState(()=>sending=true);try{final row=await db.from('ours_self_messages').insert({'user_id':db.auth.currentUser!.id,'body':text}).select().single();if(mounted)setState(()=>rows.add(Map<String,dynamic>.from(row)));input.clear();}catch(e){_notice(t('تعذر حفظ الرسالة: $e','Could not save note: $e'));}finally{if(mounted)setState(()=>sending=false);}}
 Future<void> _togglePin(Map<String,dynamic> row)async{try{final v=!(row['pinned']==true);await db.from('ours_self_messages').update({'pinned':v}).eq('id',row['id']);if(mounted)setState(()=>row['pinned']=v);}catch(e){_notice(e.toString());}}
 Future<void> _delete(Map<String,dynamic> row)async{try{await db.from('ours_self_messages').delete().eq('id',row['id']);if(mounted)setState(()=>rows.removeWhere((r)=>r['id']==row['id']));}catch(e){_notice(e.toString());}}
 @override void dispose(){input.dispose();scroll.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(
  backgroundColor:_navy,
  appBar:AppBar(
   backgroundColor:_navy,
   centerTitle:true,
   title:Column(mainAxisSize:MainAxisSize.min,children:[
    Text(t('مراسلة نفسي','Saved messages'),style:const TextStyle(color:_gold,fontSize:16,fontWeight:FontWeight.w800)),
    Text(t('مساحة لا يراها غيرك','Private to you'),style:const TextStyle(color:_lavender,fontSize:10))
   ]),
  ),
  body:Column(children:[
   Expanded(
    child:loading
     ?const Center(child:CircularProgressIndicator(color:_gold))
     :rows.isEmpty
      ?Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[
        const Icon(Icons.bookmark_add_outlined,color:_gold,size:46),
        const SizedBox(height:12),
        Text(t('ابدأ أول رسالة لنفسك','Write your first note'),style:const TextStyle(color:Colors.white,fontSize:17,fontWeight:FontWeight.w700)),
        const SizedBox(height:6),
        Text(t('احفظ أفكارك ورسائلك المهمة هنا.','Keep ideas and important messages here.'),style:const TextStyle(color:_lavender),textAlign:TextAlign.center)
       ])))
      :ListView.builder(
       controller:scroll,
       padding:const EdgeInsets.fromLTRB(14,14,14,18),
       itemCount:rows.length,
       itemBuilder:(c,i){
        final row=rows[rows.length-1-i];
        final date=DateTime.tryParse(row['created_at']?.toString()??'')?.toLocal();
        final time=date==null?'':DateFormat(ar?'HH:mm':'h:mm a').format(date);
        return Align(
         alignment:AlignmentDirectional.centerEnd,
         child:Container(
          constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*.84),
          margin:const EdgeInsets.symmetric(vertical:5),
          padding:const EdgeInsets.fromLTRB(14,11,9,8),
          decoration:BoxDecoration(
           color:const Color(0xFF342B4C),
           borderRadius:BorderRadius.circular(18),
           border:Border.all(color:_gold.withValues(alpha:.15)),
          ),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
           SelectableText(row['body'].toString(),style:const TextStyle(color:Colors.white,height:1.5)),
           const SizedBox(height:5),
           Row(mainAxisSize:MainAxisSize.min,children:[
            if(row['pinned']==true)const Icon(Icons.push_pin_rounded,color:_gold,size:13),
            Text(time,style:const TextStyle(color:_lavender,fontSize:10)),
            const SizedBox(width:4),
            PopupMenuButton<String>(
             padding:EdgeInsets.zero,
             constraints:const BoxConstraints(minWidth:150),
             icon:const Icon(Icons.more_horiz,color:_lavender,size:18),
             onSelected:(v)=>v=='pin'?_togglePin(row):_delete(row),
             itemBuilder:(_)=>[
              PopupMenuItem(value:'pin',child:Text(t('تثبيت / إلغاء التثبيت','Pin / unpin'))),
              PopupMenuItem(value:'delete',child:Text(t('حذف الرسالة','Delete note'))),
             ],
            ),
           ]),
          ]),
         ),
        );
       },
      ),
   ),
   SafeArea(
    top:false,
    child:Container(
     padding:const EdgeInsets.fromLTRB(10,8,10,12),
     decoration:const BoxDecoration(border:Border(top:BorderSide(color:Color(0x3329293D)))),
     child:Row(children:[
      Expanded(child:TextField(
       controller:input,minLines:1,maxLines:5,textInputAction:TextInputAction.send,
       onSubmitted:(_)=>_send(),
       decoration:InputDecoration(
        hintText:t('اكتب لنفسك…','Write a note…'),
        filled:true,fillColor:const Color(0xFF211D30),
        border:OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:BorderSide.none),
        contentPadding:const EdgeInsets.symmetric(horizontal:15,vertical:12),
       ),
      )),
      const SizedBox(width:7),
      IconButton.filled(
       onPressed:sending?null:_send,
       style:IconButton.styleFrom(backgroundColor:_gold,foregroundColor:_navy),
       icon:sending?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send_rounded),
      ),
     ]),
    ),
   ),
  ]),
 );
}
