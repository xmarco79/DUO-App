import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'ours_profile_page.dart';

const _navy=Color(0xFF10101C),_gold=Color(0xFFD9BC86),_lavender=Color(0xFFB9A2D5),_bucket='ours-direct-media';
class _ChatSkin{
 final String id,ar,en;final Color bg,mine,partner,accent;
 const _ChatSkin(this.id,this.ar,this.en,this.bg,this.mine,this.partner,this.accent);
}
const _skins=[
 _ChatSkin('ours','OURS · نبض','OURS · Pulse',Color(0xFF10101C),Color(0xFF302044),Color(0xFF241B36),Color(0xFFFFD66B)),
 _ChatSkin('aurora','أورورا لايف','Aurora live',Color(0xFF081C25),Color(0xFF116C78),Color(0xFF10384A),Color(0xFF70F2D2)),
 _ChatSkin('sunset','فلامنكو','Flamenco',Color(0xFF271122),Color(0xFFB63C68),Color(0xFF56243F),Color(0xFFFFA36C)),
 _ChatSkin('sakura','بلوم','Bloom',Color(0xFF261622),Color(0xFFB64E89),Color(0xFF4B2844),Color(0xFFFFC2DE)),
 _ChatSkin('ocean','بلو لاجون','Blue lagoon',Color(0xFF061A2A),Color(0xFF167FB0),Color(0xFF123D58),Color(0xFF80E8FF)),
 _ChatSkin('forest','إميرالد','Emerald',Color(0xFF0C1E1A),Color(0xFF168B67),Color(0xFF18473A),Color(0xFF91F5B8)),
 _ChatSkin('cosmos','دريم سكيب','Dreamscape',Color(0xFF100C2A),Color(0xFF7045D8),Color(0xFF342458),Color(0xFFD6B7FF)),
 _ChatSkin('desert','صن داست','Sun dust',Color(0xFF241813),Color(0xFFB66B35),Color(0xFF4C3024),Color(0xFFFFDA87)),
 _ChatSkin('neon','سايبر بوب','Cyber pop',Color(0xFF140A22),Color(0xFF8144C7),Color(0xFF36234D),Color(0xFF7CFFF1)),
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
   case 'ours':
    for(var i=0;i<5;i++){
     final orbit=Rect.fromCenter(center:Offset(size.width*.5,size.height*.48),width:size.width*(.42+i*.10),height:size.height*(.18+i*.07));
     canvas.drawOval(orbit,line..strokeWidth=1.0+i*.25);
    }
    for(var i=0;i<36;i++){
     final x=((i*67)%997)/997*size.width,y=((i*131)%991)/991*size.height;
     canvas.drawCircle(Offset(x,y),1+(i%3)*.45,Paint()..color=accent.withValues(alpha:.12+(i%3)*.03));
    }
    break;
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
 bool loading=true,sending=false,recording=false,uploading=false;String? localPartnerName;_ChatSkin skin=_skins.first;
 bool get ar=>Localizations.localeOf(context).languageCode=='ar';
 String t(String a,String e)=>ar?a:e;String get uid=>db.auth.currentUser!.id;
 int _streakCount(){
  final days=<DateTime>{};
  for(final m in messages){final dt=DateTime.tryParse(m['created_at']?.toString()??'')?.toLocal();if(dt!=null)days.add(DateTime(dt.year,dt.month,dt.day));}
  if(days.isEmpty)return 0;
  final today=DateTime.now(),current=DateTime(today.year,today.month,today.day);
  final latest=days.reduce((a,b)=>a.isAfter(b)?a:b);
  if(latest.isBefore(current.subtract(const Duration(days:1))))return 0;
  var count=0,day=latest;
  while(days.contains(day)){count++;day=day.subtract(const Duration(days:1));}
  return count;
 }
 @override void initState(){super.initState();localPartnerName=widget.partnerName;_loadSkin();_load();_listen();}
 Future<void> _changeLocalNickname() async{
  final prefs=await SharedPreferences.getInstance();final key='ours_partner_alias_${uid}_${widget.partnerId}';
  final controller=TextEditingController(text:prefs.getString(key)??widget.partnerName);
  final value=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:skin.bg,title:Text(t('اسم الطرف الآخر عندك','Your private nickname')),content:TextField(controller:controller,maxLength:24,decoration:InputDecoration(hintText:t('اسم يظهر لك فقط','Only visible to you'))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('إلغاء','Cancel'))),TextButton(onPressed:()=>Navigator.pop(ctx,controller.text.trim()),child:Text(t('حفظ','Save')))]));
  controller.dispose();if(value==null)return;if(value.isEmpty)await prefs.remove(key);else await prefs.setString(key,value);
  if(mounted)setState(()=>localPartnerName=value.isEmpty?widget.partnerName:value);
 }
 Future<void> _loadSkin() async{
  final p=await SharedPreferences.getInstance();final id=p.getString('ours_direct_skin_'+widget.conversationId)??'ours';
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
  }catch(e){if(mounted){setState(()=>loading=false);_show(t('تعذر تحميل المحادثة. تحقق من الاتصال وحاول مجددًا.','Could not load conversation. Check your connection and try again.'));}}
 }
 void _listen(){
  final filter=PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'conversation_id',value:widget.conversationId);
  channel=db.channel('ours-direct-'+widget.conversationId)
   .onPostgresChanges(event:PostgresChangeEvent.insert,schema:'public',table:'duo_direct_messages',filter:filter,callback:(p){
    final row=Map<String,dynamic>.from(p.newRecord);if(!mounted||hiddenIds.contains(row['id'].toString())||messages.any((m)=>m['id']==row['id']))return;setState(()=>messages.add(row));_bottom();
   })
   .onPostgresChanges(event:PostgresChangeEvent.delete,schema:'public',table:'duo_direct_messages',callback:(p){
    final id=p.oldRecord['id']?.toString();if(!mounted||id==null)return;setState(()=>messages.removeWhere((m)=>m['id'].toString()==id));
   })
   .onPostgresChanges(event:PostgresChangeEvent.update,schema:'public',table:'duo_direct_messages',filter:filter,callback:(p){
    final row=Map<String,dynamic>.from(p.newRecord);if(!mounted)return;final index=messages.indexWhere((m)=>m['id'].toString()==row['id'].toString());if(index>=0)setState(()=>messages[index]=row);
   }).subscribe();
 }
 void _bottom()=>WidgetsBinding.instance.addPostFrameCallback((_){if(scroll.hasClients)scroll.animateTo(scroll.position.maxScrollExtent,duration:const Duration(milliseconds:220),curve:Curves.easeOut);});
 void _show(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
 Future<void> _sendText() async{
  final text=input.text.trim();if(text.isEmpty||sending)return;setState(()=>sending=true);
  try{await db.from('duo_direct_messages').insert({'conversation_id':widget.conversationId,'sender_id':uid,'body':text,'message_type':'text','reply_to':replyTo?['id']});input.clear();if(mounted)setState(()=>replyTo=null);}
  catch(e){_show(t('تعذر إرسال الرسالة. حاول مرة أخرى.','Could not send message. Please try again.'));}finally{if(mounted)setState(()=>sending=false);}
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
  }catch(e){_show(t('تعذر رفع المرفق. تحقق من الاتصال.','Could not upload the attachment. Check your connection.'));}finally{if(mounted)setState(()=>uploading=false);}
 }
 Future<String?> _previewMedia({required Uint8List bytes,required String name,required bool video}) async{
  final isImage=!video;String mode='normal';
  return await showDialog<String>(context:context,barrierDismissible:false,builder:(ctx)=>StatefulBuilder(builder:(ctx,setModal)=>AlertDialog(backgroundColor:skin.bg,title:Text(t('معاينة قبل الإرسال','Preview before sending')),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
   if(isImage)ClipRRect(borderRadius:BorderRadius.circular(14),child:Image.memory(bytes,height:230,fit:BoxFit.contain))
   else Container(height:170,width:260,decoration:BoxDecoration(color:skin.partner,borderRadius:BorderRadius.circular(14)),child:Icon(Icons.video_file_rounded,color:skin.accent,size:70)),
   const SizedBox(height:12),Text(name,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(color:skin.accent)),
   if(isImage)Padding(padding:const EdgeInsets.only(top:10),child:Wrap(spacing:6,children:[
    ChoiceChip(label:Text(t('عادية','Normal')),selected:mode=='normal',onSelected:(_)=>setModal(()=>mode='normal')),
    ChoiceChip(label:Text(t('مرة واحدة','Once')),selected:mode=='once',onSelected:(_)=>setModal(()=>mode='once')),
    ChoiceChip(label:Text(t('مرتين','Twice')),selected:mode=='twice',onSelected:(_)=>setModal(()=>mode='twice')),
   ])),
   const SizedBox(height:8),Text(t('لن يتم إرسال الملف حتى تضغط إرسال.','The media is not sent until you tap Send.'),style:TextStyle(color:skin.accent,fontSize:12),textAlign:TextAlign.center)
  ])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,null),child:Text(t('إلغاء','Cancel'))),FilledButton(onPressed:()=>Navigator.pop(ctx,mode),child:Text(t('إرسال','Send')))])));
 }
 Future<void> _pickImageWithMode() async{
  try{
   final f=await picker.pickImage(source:ImageSource.gallery,imageQuality:92,maxWidth:2400,maxHeight:2400);if(f==null)return;
   final bytes=await f.readAsBytes();final mode=await _previewMedia(bytes:bytes,name:f.name,video:false);if(mode==null)return;
   final ext=f.name.split('.').last.toLowerCase();final name=['png','webp'].contains(ext)?f.name:'photo_'+DateTime.now().millisecondsSinceEpoch.toString()+'.jpg';
   await _upload(bytes,name,mode=='normal'?'image':mode=='once'?'view_once':'view_twice',maxViews:mode=='twice'?2:1);
  }catch(e){_show(t('تعذر اختيار الصورة: $e','Could not select image: $e'));}
 }
 Future<bool> _previewVideoFile(String path) async{
  final controller=VideoPlayerController.file(File(path));
  try{await controller.initialize();}catch(_){await controller.dispose();return false;}
  final confirmed=await showDialog<bool>(context:context,barrierDismissible:false,builder:(ctx)=>StatefulBuilder(builder:(ctx,setModal)=>AlertDialog(backgroundColor:skin.bg,title:Text(t('معاينة الفيديو','Video preview')),content:Column(mainAxisSize:MainAxisSize.min,children:[if(controller.value.isInitialized)AspectRatio(aspectRatio:controller.value.aspectRatio,child:VideoPlayer(controller)),const SizedBox(height:10),Row(mainAxisAlignment:MainAxisAlignment.center,children:[IconButton(onPressed:()=>setModal(()=>controller.value.isPlaying?controller.pause():controller.play()),icon:Icon(controller.value.isPlaying?Icons.pause:Icons.play_arrow,color:skin.accent)),IconButton(onPressed:()=>setModal(()=>controller.seekTo(Duration.zero)),icon:Icon(Icons.replay,color:skin.accent))]),Text(t('يمكنك مشاهدة المقطع قبل إرساله.','Preview the clip before sending.'),style:TextStyle(color:skin.accent,fontSize:12),textAlign:TextAlign.center)]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:Text(t('إلغاء','Cancel'))),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:Text(t('إرسال','Send')))])));
  await controller.dispose();return confirmed==true;
 }
 Future<void> _pickVideo() async{
  try{
   final f=await picker.pickVideo(source:ImageSource.gallery,maxDuration:const Duration(minutes:2));if(f==null)return;
   final ext=f.name.split('.').last.toLowerCase();if(!['mp4','mov','webm'].contains(ext)){_show(t('صيغة الفيديو غير مدعومة','Unsupported video format'));return;}
   if(!await _previewVideoFile(f.path))return;
   await _upload(await f.readAsBytes(),f.name,'video');
  }catch(e){_show(t('تعذر اختيار الفيديو: $e','Could not select video: $e'));}
 }
 Future<void> _sendSticker() async{
  const stickers=[
   ('ours_cat_love','حب'),('ours_cat_happy','سعادة'),('ours_cat_cry','بكاء'),
   ('ours_cat_sleep','نعاس'),('ours_cat_shock','صدمة'),('ours_cat_angry','زعل'),
   ('ours_cat_wink','غمزة'),('ours_cat_blush','خجل'),('ours_cat_chef','الشيف'),
   ('ours_cat_party','احتفال'),('ours_cat_hug','حضن'),('ours_cat_cool','كشخة'),
  ];
  final chosen=await showModalBottomSheet<String>(context:context,backgroundColor:const Color(0xFF211D30),showDragHandle:true,isScrollControlled:true,
   builder:(ctx)=>SafeArea(child:SizedBox(height:MediaQuery.of(ctx).size.height*.58,child:Column(children:[
    Padding(padding:const EdgeInsets.all(14),child:Text(t('ملصقات قطط OURS','OURS Cat Stickers'),style:const TextStyle(color:_gold,fontSize:17,fontWeight:FontWeight.w800))),
    Expanded(child:GridView.builder(padding:const EdgeInsets.fromLTRB(14,0,14,16),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,childAspectRatio:.9,crossAxisSpacing:10,mainAxisSpacing:10),itemCount:stickers.length,itemBuilder:(ctx,i){
     final sticker=stickers[i];return InkWell(borderRadius:BorderRadius.circular(16),onTap:()=>Navigator.pop(ctx,sticker.$1),child:Container(decoration:BoxDecoration(color:skin.partner,borderRadius:BorderRadius.circular(16),border:Border.all(color:skin.accent.withValues(alpha:.2))),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[_OursCatSticker(stickerId:sticker.$1,size:70),const SizedBox(height:4),Text(sticker.$2,style:TextStyle(color:skin.accent,fontSize:11,fontWeight:FontWeight.w700))])));
    }))
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
    ListTile(leading:Icon(Icons.photo_library_outlined,color:skin.accent),title:Text(t('الوسائط','Media')),subtitle:Text(t('صور ومقاطع فيديو','Photos and videos')),onTap:()=>Navigator.pop(ctx,'media')),
    ListTile(leading:Icon(Icons.insert_drive_file_outlined,color:skin.accent),title:Text(t('ملف','File')),onTap:()=>Navigator.pop(ctx,'file')),
    ListTile(leading:Icon(Icons.emoji_emotions_outlined,color:skin.accent),title:Text(t('ملصقات القطط','Cat stickers')),onTap:()=>Navigator.pop(ctx,'sticker')),
   ])));
  if(choice==null)return;
  switch(choice){case 'media':await _pickMedia();break;case 'image':await _pickImageWithMode();break;case 'video':await _pickVideo();break;case 'file':await _pickFile();break;case 'sticker':await _sendSticker();break;}
 }
 Future<void> _pickMedia()async{
  final kind=await showModalBottomSheet<String>(context:context,backgroundColor:skin.bg,showDragHandle:true,builder:(ctx)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
   ListTile(leading:Icon(Icons.image_outlined,color:skin.accent),title:Text(t('صور','Photos')),onTap:()=>Navigator.pop(ctx,'image')),
   ListTile(leading:Icon(Icons.video_library_outlined,color:skin.accent),title:Text(t('مقاطع فيديو','Videos')),onTap:()=>Navigator.pop(ctx,'video')),
  ])));
  if(kind=='image')await _pickImageWithMode();else if(kind=='video')await _pickVideo();
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
 Future<void> _openImageActions(String url) async{
  if(!mounted)return;
  await showDialog<void>(context:context,builder:(ctx)=>Dialog(backgroundColor:const Color(0xFF08080C),insetPadding:const EdgeInsets.all(12),child:Column(mainAxisSize:MainAxisSize.min,children:[
   Flexible(child:InteractiveViewer(minScale:.5,maxScale:4,child:Image.network(url,fit:BoxFit.contain,errorBuilder:(_,__,___)=>Center(child:Text(t('تعذر تحميل الصورة','Image failed to load'),style:const TextStyle(color:Colors.white)))))),
   Container(padding:const EdgeInsets.fromLTRB(10,8,10,10),decoration:BoxDecoration(color:skin.partner,borderRadius:const BorderRadius.vertical(bottom:Radius.circular(16))),child:Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:[
    TextButton.icon(onPressed:()=>Navigator.pop(ctx),icon:Icon(Icons.close,color:skin.accent),label:Text(t('إغلاق','Close'))),
    TextButton.icon(onPressed:()async{Navigator.pop(ctx);await _saveImageLocally(url);},icon:Icon(Icons.download_rounded,color:skin.accent),label:Text(t('حفظ','Save'))),
    TextButton.icon(onPressed:()async{Navigator.pop(ctx);try{final bytes=await _downloadImage(url);if(!mounted)return;await showDialog<void>(context:context,builder:(_)=>_ImageMarkupDialog(bytes:bytes,skin:skin,ar:ar));}catch(_){_show(t('تعذر فتح أدوات الرسم','Could not open drawing tools'));}},icon:Icon(Icons.draw_rounded,color:skin.accent),label:Text(t('الرسم','Draw')))
   ]))
  ])));
 }
 Future<Uint8List> _downloadImage(String url)async{
  final client=HttpClient();try{final request=await client.getUrl(Uri.parse(url));final response=await request.close();if(response.statusCode<200||response.statusCode>=300)throw Exception('download');final chunks=<int>[];await for(final chunk in response)chunks.addAll(chunk);return Uint8List.fromList(chunks);}finally{client.close();}
 }
 Future<void> _saveImageLocally(String url)async{
  try{final bytes=await _downloadImage(url);final result=await FilePicker.platform.saveFile(fileName:'OURS_image_${DateTime.now().millisecondsSinceEpoch}.jpg',type:FileType.image,bytes:bytes);if(result!=null)_show(t('تم حفظ الصورة في المكان الذي اخترته','Image saved to your selected location'));}
  catch(_){_show(t('تعذر حفظ الصورة، تحقق من الاتصال أو مساحة التخزين','Could not save image. Check connection or storage'));}
 }
 Future<void> _openLibraryItem(Map<String,dynamic> message) async{
  final type=message['message_type']?.toString()??'';
  final path=message['body']?.toString()??'';
  if(type=='view_once'||type=='view_twice'){await _consumeTemporaryMedia(message['id'].toString());return;}
  if(type=='image'){
   try{final url=await _signed(path);if(!mounted)return;await _openImageActions(url);}
   catch(_){_show(t('تعذر فتح الصورة. تحقق من الاتصال.','Could not open image. Check your connection.'));}
   return;
  }
  await _openFile(path);
 }
 Future<void> _showChatLibrary(String kind) async{
  final types=kind=='media'?['image','view_once','view_twice','video']:['file','audio'];
  final found=messages.where((m)=>types.contains(m['message_type'])).toList();
  await showModalBottomSheet<void>(context:context,isScrollControlled:true,backgroundColor:const Color(0xFF211D30),builder:(ctx)=>SafeArea(child:SizedBox(height:MediaQuery.of(ctx).size.height*.65,child:Column(children:[
   Padding(padding:const EdgeInsets.all(16),child:Text(kind=='media'?t('الوسائط المرسلة','Shared media'):t('الملفات','Files'),style:const TextStyle(color:_gold,fontWeight:FontWeight.bold))),
   Expanded(child:found.isEmpty?Center(child:Text(t('لا توجد عناصر بعد','Nothing shared yet'))):ListView(children:found.map((m)=>ListTile(leading:Icon(kind=='media'?Icons.image_outlined:Icons.insert_drive_file_outlined,color:skin.accent),title:Text((m['body']??'').toString().split('/').last,maxLines:1,overflow:TextOverflow.ellipsis),subtitle:Text(_time(m['created_at'])),onTap:(){Navigator.pop(ctx);_openLibraryItem(m);})).toList()))
  ]))));
 }
   @override void dispose(){input.dispose();scroll.dispose();recorder?.dispose();if(channel!=null)db.removeChannel(channel!);super.dispose();}
 @override Widget build(BuildContext context){
  final me=db.auth.currentUser!.id;
  return Scaffold(backgroundColor:skin.bg,appBar:AppBar(backgroundColor:skin.bg,centerTitle:true,
   title:InkWell(
    borderRadius:BorderRadius.circular(12),
    onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OursProfilePage(userId:widget.partnerId))),
    child:Column(mainAxisSize:MainAxisSize.min,children:[
     Text(localPartnerName??widget.partnerName,style:const TextStyle(fontSize:16)),
     Row(mainAxisSize:MainAxisSize.min,children:[
      Text(t('اضغط لعرض الملف الشخصي','Tap to view profile'),style:TextStyle(color:skin.accent,fontSize:10)),
      if(_streakCount()>0)Padding(padding:const EdgeInsetsDirectional.only(start:6),child:Container(padding:const EdgeInsets.symmetric(horizontal:6,vertical:2),decoration:BoxDecoration(color:const Color(0xFFB85A34).withValues(alpha:.16),borderRadius:BorderRadius.circular(10)),child:Text('🔥 ${_streakCount()}',style:const TextStyle(color:Color(0xFFFFB06A),fontSize:10,fontWeight:FontWeight.w800))))
     ])
    ]),
   ),
   actions:[
    IconButton(tooltip:t('اتصال صوتي','Voice call'),onPressed:()=>_callInfo(false),icon:Icon(Icons.call_outlined,color:skin.accent)),
    IconButton(tooltip:t('اتصال مرئي','Video call'),onPressed:()=>_callInfo(true),icon:Icon(Icons.videocam_outlined,color:skin.accent)),
    IconButton(tooltip:t('تفاصيل المحادثة','Chat details'),icon:Icon(Icons.more_horiz,color:skin.accent),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>_ChatDetailsPage(partnerId:widget.partnerId,partnerName:localPartnerName??widget.partnerName,skin:skin,profile:()=>OursProfilePage(userId:widget.partnerId),nickname:_changeLocalNickname,search:_searchMessages,media:()=>_showChatLibrary('media'),files:()=>_showChatLibrary('files'),themes:_chooseSkin))))
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
       child:IntrinsicWidth(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
        if(m['reply_to']!=null && messages.any((r)=>r['id'].toString()==m['reply_to'].toString())) Container(margin:const EdgeInsets.only(bottom:7),padding:const EdgeInsets.all(7),decoration:BoxDecoration(color:skin.bg.withValues(alpha:.45),borderRadius:BorderRadius.circular(8)),child:Text(messages.firstWhere((r)=>r['id'].toString()==m['reply_to'].toString())['body'].toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(color:skin.accent,fontSize:11))),
        if(type=='sticker')Center(child:_OursCatSticker(stickerId:path,size:82))
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
         return GestureDetector(onTap:()=>_openImageActions(s.data!),
          child:ClipRRect(borderRadius:BorderRadius.circular(13),child:Stack(children:[Image.network(s.data!,width:230,height:230,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Text(t('تعذر عرض الصورة','Image unavailable'))),Positioned(bottom:8,right:8,child:Container(padding:const EdgeInsets.all(6),decoration:BoxDecoration(color:Colors.black.withValues(alpha:.58),borderRadius:BorderRadius.circular(30)),child:Icon(Icons.zoom_out_map_rounded,color:Colors.white,size:17)))])));
        })
        else if(type=='file')InkWell(onTap:()=>_openFile(path),child:Row(mainAxisSize:MainAxisSize.min,children:[
         Icon(Icons.insert_drive_file_outlined,color:skin.accent,size:30),const SizedBox(width:8),
         Flexible(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(path.split('/').last.replaceFirst(RegExp(r'^\d+_'),''),maxLines:2,overflow:TextOverflow.ellipsis),Text(t('اضغط لفتح الملف','Tap to open file'),style:TextStyle(color:skin.accent,fontSize:10))]))
        ]))
        else if(type=='audio')_DirectAudioBubble(path:path,skin:skin,signed:_signed,ar:ar)
        else SelectableText(path,style:const TextStyle(color:Colors.white,height:1.4)),
        const SizedBox(height:4),Align(alignment:AlignmentDirectional.centerEnd,child:Text(_time(m['created_at']),style:TextStyle(color:skin.accent,fontSize:10)))
       ])))));
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
   Expanded(child:ListView.builder(controller:scroll,padding:const EdgeInsets.all(14),itemCount:messages.length,itemBuilder:(c,i){final m=messages[i],mine=m['role']=='user';return Align(alignment:mine?AlignmentDirectional.centerEnd:AlignmentDirectional.centerStart,child:IntrinsicWidth(child:Container(constraints:const BoxConstraints(maxWidth:320),margin:const EdgeInsets.symmetric(vertical:5),padding:const EdgeInsets.all(13),decoration:BoxDecoration(gradient:LinearGradient(colors:mine?[const Color(0xFF6D42A8),const Color(0xFF39275D)]:[const Color(0xFF332345),const Color(0xFF21182F)]),borderRadius:BorderRadius.circular(16)),child:SelectableText(m['content']??'',style:const TextStyle(height:1.5)))));})),
   if(sending)const LinearProgressIndicator(color:_gold,minHeight:2),
   Padding(padding:const EdgeInsets.fromLTRB(10,8,10,12),child:Row(children:[
    Expanded(child:TextField(controller:input,minLines:1,maxLines:4,textInputAction:TextInputAction.send,onSubmitted:(_)=>_send(),decoration:InputDecoration(hintText:t('اسأل OURS AI…','Ask OURS AI…'),filled:true,fillColor:const Color(0xFF29213D),border:OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:BorderSide.none)))),
    IconButton(onPressed:sending?null:()=>_send(),icon:const Icon(Icons.send_rounded,color:_gold))
   ]))
  ])));
}

class _OursCatSticker extends StatelessWidget{
 final String stickerId;final double size;
 const _OursCatSticker({required this.stickerId,this.size=76});
 @override Widget build(BuildContext context)=>CustomPaint(size:Size.square(size),painter:_OursCatStickerPainter(stickerId));
}

class _OursCatStickerPainter extends CustomPainter{
 final String id;
 const _OursCatStickerPainter(this.id);
 @override void paint(Canvas canvas,Size size){
  final w=size.width,h=size.height;
  final fill=Paint()..color=id.contains('cool')?const Color(0xFFB9D9E8):id.contains('chef')?const Color(0xFFFFE2B5):const Color(0xFFFFD8E5);
  final edge=Paint()..color=Colors.white..style=PaintingStyle.stroke..strokeWidth=4..strokeJoin=StrokeJoin.round;
  final earLeft=Path()..moveTo(w*.20,h*.43)..lineTo(w*.23,h*.08)..quadraticBezierTo(w*.45,h*.12,w*.47,h*.34)..close();
  final earRight=Path()..moveTo(w*.53,h*.34)..quadraticBezierTo(w*.58,h*.12,w*.80,h*.08)..lineTo(w*.82,h*.43)..close();
  canvas.drawPath(earLeft,fill);canvas.drawPath(earLeft,edge);canvas.drawPath(earRight,fill);canvas.drawPath(earRight,edge);
  final head=Rect.fromCenter(center:Offset(w*.5,h*.52),width:w*.68,height:h*.64);
  canvas.drawOval(head,fill);canvas.drawOval(head,edge);
  final pink=Paint()..color=const Color(0xFFF29AB5);
  canvas.drawCircle(Offset(w*.31,h*.27),w*.055,pink);canvas.drawCircle(Offset(w*.69,h*.27),w*.055,pink);
  final eye=Paint()..color=const Color(0xFF33283B);
  if(id.contains('sleep')) {
   final p=Paint()..color=const Color(0xFF33283B)..style=PaintingStyle.stroke..strokeWidth=2.5..strokeCap=StrokeCap.round;
   canvas.drawArc(Rect.fromCenter(center:Offset(w*.38,h*.48),width:w*.14,height:h*.08),0,math.pi,false,p);
   canvas.drawArc(Rect.fromCenter(center:Offset(w*.62,h*.48),width:w*.14,height:h*.08),0,math.pi,false,p);
  }else{
   canvas.drawCircle(Offset(w*.38,h*.47),w*.035,eye);
   canvas.drawCircle(Offset(w*.62,h*.47),w*.035,eye);
   if(id.contains('wink')){canvas.drawLine(Offset(w*.55,h*.45),Offset(w*.69,h*.46),Paint()..color=const Color(0xFF33283B)..strokeWidth=2.5..strokeCap=StrokeCap.round);}
  }
  final nose=Path()..moveTo(w*.47,h*.56)..quadraticBezierTo(w*.5,h*.52,w*.53,h*.56)..quadraticBezierTo(w*.5,h*.60,w*.47,h*.56);
  canvas.drawPath(nose,Paint()..color=const Color(0xFFB96B86));
  final mouth=Paint()..color=const Color(0xFF5B3A4A)..style=PaintingStyle.stroke..strokeWidth=2..strokeCap=StrokeCap.round;
  if(id.contains('shock')){canvas.drawCircle(Offset(w*.5,h*.65),w*.045,mouth..style=PaintingStyle.stroke);}
  else{final smile=Path()..moveTo(w*.5,h*.59)..quadraticBezierTo(w*.43,h*.69,w*.37,h*.63)..moveTo(w*.5,h*.59)..quadraticBezierTo(w*.57,h*.69,w*.63,h*.63);canvas.drawPath(smile,mouth);}
  final blush=Paint()..color=const Color(0xFFF39CB5).withValues(alpha:.72);
  canvas.drawOval(Rect.fromCenter(center:Offset(w*.29,h*.60),width:w*.12,height:h*.06),blush);
  canvas.drawOval(Rect.fromCenter(center:Offset(w*.71,h*.60),width:w*.12,height:h*.06),blush);
  final whisker=Paint()..color=const Color(0xFF9B7483)..strokeWidth=1.4..strokeCap=StrokeCap.round;
  for(var i=0;i<2;i++){
   final y=h*(.58+i*.07);
   canvas.drawLine(Offset(w*.19,y),Offset(w*.34,y+(i==0?-.025:.025)*h),whisker);
   canvas.drawLine(Offset(w*.66,y+(i==0?-.025:.025)*h),Offset(w*.81,y),whisker);
  }
  if(id.contains('love')||id.contains('party')||id.contains('hug')){
   final heart=Path()..moveTo(w*.76,h*.16)..cubicTo(w*.68,h*.08,w*.58,h*.17,w*.76,h*.31)..cubicTo(w*.94,h*.17,w*.84,h*.08,w*.76,h*.16)..close();
   canvas.drawPath(heart,Paint()..color=id.contains('party')?const Color(0xFFFFC857):const Color(0xFFFF668C));
  }
  if(id.contains('cry')){
   final tear=Paint()..color=const Color(0xFF75C9F3);
   canvas.drawOval(Rect.fromCenter(center:Offset(w*.36,h*.56),width:w*.045,height:h*.11),tear);
   canvas.drawOval(Rect.fromCenter(center:Offset(w*.64,h*.56),width:w*.045,height:h*.11),tear);
  }
  if(id.contains('angry')){canvas.drawLine(Offset(w*.31,h*.39),Offset(w*.44,h*.43),eye..strokeWidth=2.5);canvas.drawLine(Offset(w*.56,h*.43),Offset(w*.69,h*.39),eye..strokeWidth=2.5);}
  if(id.contains('chef')){final hat=Paint()..color=Colors.white;canvas.drawOval(Rect.fromLTWH(w*.31,h*.02,w*.38,h*.14),hat);canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w*.35,h*.10,w*.30,h*.10),const Radius.circular(5)),hat);}
 }
 @override bool shouldRepaint(covariant _OursCatStickerPainter old)=>old.id!=id;
}

class _DirectAudioBubble extends StatefulWidget{
 final String path;final _ChatSkin skin;final Future<String> Function(String) signed;final bool ar;
 const _DirectAudioBubble({required this.path,required this.skin,required this.signed,required this.ar});
 @override State<_DirectAudioBubble> createState()=>_DirectAudioBubbleState();
}
class _DirectAudioBubbleState extends State<_DirectAudioBubble>{
 final player=AudioPlayer();bool loading=false;
 String _time(Duration d)=>'${d.inMinutes.toString().padLeft(2,'0')}:${(d.inSeconds%60).toString().padLeft(2,'0')}';
 Future<void> _toggle() async{
  if(player.state==PlayerState.playing){await player.pause();return;}setState(()=>loading=true);
  try{await player.play(UrlSource(await widget.signed(widget.path)));}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(widget.ar?'تعذر تشغيل الصوت، تحقق من الاتصال':'Audio could not play. Check your connection')));}
  finally{if(mounted)setState(()=>loading=false);}
 }
 @override void dispose(){player.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>StreamBuilder<PlayerState>(stream:player.onPlayerStateChanged,initialData:player.state,builder:(c,state){
  final playing=state.data==PlayerState.playing;return Container(width:250,padding:const EdgeInsets.symmetric(vertical:3),child:Row(mainAxisSize:MainAxisSize.min,children:[
   IconButton(onPressed:loading?null:_toggle,padding:EdgeInsets.zero,constraints:const BoxConstraints.tightFor(width:42,height:42),icon:loading?SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2,color:widget.skin.accent)):Icon(playing?Icons.pause_circle_filled:Icons.play_circle_fill,color:widget.skin.accent,size:36)),
   Expanded(child:StreamBuilder<Duration>(stream:player.onDurationChanged,initialData:Duration.zero,builder:(c,durationSnap){
    final duration=durationSnap.data??Duration.zero;return StreamBuilder<Duration>(stream:player.onPositionChanged,initialData:Duration.zero,builder:(c,posSnap){
     final position=posSnap.data??Duration.zero;final progress=duration.inMilliseconds==0?0.0:(position.inMilliseconds/duration.inMilliseconds).clamp(0.0,1.0);
     return Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
      LayoutBuilder(builder:(ctx,limits)=>GestureDetector(onTapDown:(e){final x=(e.localPosition.dx/limits.maxWidth).clamp(0.0,1.0);if(duration>Duration.zero)player.seek(Duration(milliseconds:(duration.inMilliseconds*x).round()));},child:SizedBox(width:limits.maxWidth,height:26,child:CustomPaint(painter:_VoiceWavePainter(widget.skin.accent,progress))))),
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(_time(position),style:TextStyle(color:widget.skin.accent,fontSize:10)),Text(_time(duration),style:TextStyle(color:widget.skin.accent.withValues(alpha:.65),fontSize:10))])
     ]);
    });
   })),
  ]));
 });
}
class _VoiceWavePainter extends CustomPainter{
 final Color accent;final double progress;const _VoiceWavePainter(this.accent,this.progress);
 @override void paint(Canvas canvas,Size size){const count=36;const gap=2.2;final barWidth=(size.width-gap*(count-1))/count;for(var i=0;i<count;i++){final value=(math.sin(i*.67).abs()*.48+math.cos(i*.23).abs()*.38+(i%7)*.025).clamp(.13,.95);final h=size.height*value;final rect=Rect.fromLTWH(i*(barWidth+gap), (size.height-h)/2,barWidth,h);canvas.drawRRect(RRect.fromRectAndRadius(rect,Radius.circular(barWidth)),Paint()..color=i/count<progress?accent:accent.withValues(alpha:.35));}}
 @override bool shouldRepaint(covariant _VoiceWavePainter old)=>old.progress!=progress||old.accent!=accent;
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
 Future<void> _load()async{try{final data=await db.from('ours_self_messages').select().order('created_at');if(mounted)setState(()=>rows=List<Map<String,dynamic>>.from(data));}catch(e){_notice(t('تعذر تحميل الرسائل المحفوظة. تحقق من الاتصال.','Could not load saved messages. Check your connection.'));}finally{if(mounted)setState(()=>loading=false);}}
 Future<void> _noteActions(Map<String,dynamic> row)async{
  final choice=await showModalBottomSheet<String>(context:context,backgroundColor:_navy,showDragHandle:true,builder:(ctx)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
   ListTile(leading:const Icon(Icons.push_pin_outlined,color:_gold),title:Text(t('تثبيت / إلغاء التثبيت','Pin / unpin')),onTap:()=>Navigator.pop(ctx,'pin')),
   ListTile(leading:const Icon(Icons.delete_outline_rounded,color:Colors.redAccent),title:Text(t('حذف الرسالة','Delete note')),onTap:()=>Navigator.pop(ctx,'delete'))
  ])));
  if(choice=='pin')await _togglePin(row);if(choice=='delete')await _delete(row);
 }
 void _notice(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
 Future<void> _send()async{final text=input.text.trim();if(text.isEmpty||sending)return;setState(()=>sending=true);try{final row=await db.from('ours_self_messages').insert({'user_id':db.auth.currentUser!.id,'body':text}).select().single();if(mounted)setState(()=>rows.add(Map<String,dynamic>.from(row)));input.clear();}catch(e){_notice(t('تعذر حفظ الرسالة. حاول مجددًا.','Could not save note. Try again.'));}finally{if(mounted)setState(()=>sending=false);}}
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
         return Align(alignment:AlignmentDirectional.centerEnd,child:GestureDetector(onLongPress:()=>_noteActions(row),child:Container(
          constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*.84),margin:const EdgeInsets.symmetric(vertical:5),padding:const EdgeInsets.fromLTRB(14,11,14,8),
          decoration:BoxDecoration(color:const Color(0xFF342B4C),borderRadius:BorderRadius.circular(18),border:Border.all(color:_gold.withValues(alpha:.15))),
          child:IntrinsicWidth(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
           SelectableText(row['body'].toString(),style:const TextStyle(color:Colors.white,height:1.5)),
           const SizedBox(height:5),
           Row(mainAxisSize:MainAxisSize.min,children:[if(row['pinned']==true)const Icon(Icons.push_pin_rounded,color:_gold,size:13),Text(time,style:const TextStyle(color:_lavender,fontSize:10))]),
          ])),
         )));
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


Future<ui.Image> _decodeUiImage(Uint8List bytes){final completer=Completer<ui.Image>();ui.decodeImageFromList(bytes,completer.complete);return completer.future;}
class _ImageMarkupDialog extends StatefulWidget{
 final Uint8List bytes;final _ChatSkin skin;final bool ar;
 const _ImageMarkupDialog({required this.bytes,required this.skin,required this.ar});
 @override State<_ImageMarkupDialog> createState()=>_ImageMarkupDialogState();
}
class _ImageMarkupDialogState extends State<_ImageMarkupDialog>{
 final List<_MarkupStroke> strokes=[];List<Offset> current=[];Color color=const Color(0xFFFFD66B);bool saving=false;late final Future<ui.Image> decodedFuture;
 @override void initState(){super.initState();decodedFuture=_decodeUiImage(widget.bytes);}
 String t(String a,String e)=>widget.ar?a:e;
 Future<void> _save()async{
  if(saving)return;setState(()=>saving=true);
  try{
   final decoded=await _decodeUiImage(widget.bytes);final recorder=ui.PictureRecorder();final canvas=Canvas(recorder);
   canvas.drawImage(decoded,Offset.zero,Paint());
   final sx=decoded.width.toDouble(),sy=decoded.height.toDouble();
   final all=[...strokes,if(current.length>1)_MarkupStroke(List<Offset>.from(current),color)];
   for(final stroke in all){if(stroke.points.length<2)continue;final path=Path()..moveTo(stroke.points.first.dx*sx,stroke.points.first.dy*sy);for(final p in stroke.points.skip(1))path.lineTo(p.dx*sx,p.dy*sy);canvas.drawPath(path,Paint()..color=stroke.color..strokeWidth=math.max(5.0,decoded.width/180.0)..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round..style=PaintingStyle.stroke);}
   final image=await recorder.endRecording().toImage(decoded.width,decoded.height);final data=await image.toByteData(format:ui.ImageByteFormat.png);if(data==null)throw Exception('encode');
   final output=data.buffer.asUint8List();final saved=await FilePicker.platform.saveFile(fileName:'OURS_drawing_${DateTime.now().millisecondsSinceEpoch}.png',type:FileType.image,bytes:output);if(saved==null)return;
   if(mounted){Navigator.pop(context);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(t('تم حفظ الرسم في المكان الذي اخترته','Drawing saved to your selected location'))));}
  }catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(t('تعذر حفظ الرسم','Could not save drawing'))));}
  finally{if(mounted)setState(()=>saving=false);}
 }
 @override Widget build(BuildContext context)=>Dialog(backgroundColor:widget.skin.bg,insetPadding:const EdgeInsets.all(8),child:SafeArea(child:Column(mainAxisSize:MainAxisSize.max,children:[
  Padding(padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),child:Row(children:[Icon(Icons.draw_rounded,color:widget.skin.accent),const SizedBox(width:8),Expanded(child:Text(t('مرسم الصورة','Image studio'),style:TextStyle(color:widget.skin.accent,fontWeight:FontWeight.w800))),IconButton(onPressed:()=>setState(()=>strokes.clear()),tooltip:t('مسح الرسم','Clear'),icon:Icon(Icons.delete_outline,color:widget.skin.accent)),IconButton(onPressed:()=>setState(()=>strokes.isNotEmpty?strokes.removeLast():null),tooltip:t('تراجع','Undo'),icon:Icon(Icons.undo,color:widget.skin.accent))])),
  Expanded(child:Center(child:LayoutBuilder(builder:(ctx,box){return FutureBuilder<ui.Image>(future:decodedFuture, builder:(ctx,s){if(!s.hasData)return const CircularProgressIndicator();final img=s.data!;final ratio=img.width/img.height;final w=math.min<double>(box.maxWidth,box.maxHeight*ratio);final h=w/ratio;return SizedBox(width:w,height:h,child:Stack(fit:StackFit.expand,children:[Image.memory(widget.bytes,fit:BoxFit.fill),CustomPaint(painter:_MarkupPainter([...strokes,if(current.length>1)_MarkupStroke(current,color)])),GestureDetector(behavior:HitTestBehavior.translucent,onPanStart:(e)=>setState(()=>current=[Offset(e.localPosition.dx/w,e.localPosition.dy/h)]),onPanUpdate:(e)=>setState(()=>current.add(Offset((e.localPosition.dx/w).clamp(0,1),(e.localPosition.dy/h).clamp(0,1)))),onPanEnd:(_){if(current.length>1)strokes.add(_MarkupStroke(List<Offset>.from(current),color));current.clear();setState((){});})]));});}))),
  Padding(padding:const EdgeInsets.all(10),child:Row(children:[for(final c in [const Color(0xFFFFD66B),const Color(0xFFFF5C8A),const Color(0xFF7CFFF1),Colors.white,const Color(0xFF8B72FF)])IconButton(onPressed:()=>setState(()=>color=c),icon:Icon(Icons.circle,color:c,size:24)),const Spacer(),FilledButton.icon(onPressed:saving?null:_save,icon:saving?const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.save_alt),label:Text(t('حفظ الرسم','Save drawing')))]))
 ])));
}
class _MarkupStroke{final List<Offset> points;final Color color;const _MarkupStroke(this.points,this.color);}
class _MarkupPainter extends CustomPainter{
 final List<_MarkupStroke> strokes;const _MarkupPainter(this.strokes);
 @override void paint(Canvas canvas,Size size){for(final stroke in strokes){if(stroke.points.length<2)continue;final path=Path()..moveTo(stroke.points.first.dx*size.width,stroke.points.first.dy*size.height);for(final p in stroke.points.skip(1))path.lineTo(p.dx*size,p.dy*size);canvas.drawPath(path,Paint()..color=stroke.color..strokeWidth=4..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round..style=PaintingStyle.stroke);}}
 @override bool shouldRepaint(covariant _MarkupPainter old)=>old.strokes!=strokes;
}
class _ChatDetailsPage extends StatelessWidget{
 final String partnerId,partnerName;final _ChatSkin skin;final Widget Function() profile;final VoidCallback nickname,search,media,files;final Future<void> Function() themes;
 const _ChatDetailsPage({required this.partnerId,required this.partnerName,required this.skin,required this.profile,required this.nickname,required this.search,required this.media,required this.files,required this.themes});
 @override Widget build(BuildContext context){final ar=Localizations.localeOf(context).languageCode=='ar';String t(String a,String e)=>ar?a:e;
 Widget section(String title)=>Padding(padding:const EdgeInsets.fromLTRB(5,20,5,9),child:Text(title,style:TextStyle(color:skin.accent,fontSize:12,fontWeight:FontWeight.w800,letterSpacing:.4)));
 Widget tile(IconData icon,String title,String subtitle,VoidCallback action)=>_ChatDetailTile(icon:icon,title:title,subtitle:subtitle,accent:skin.accent,onTap:action);
 return Scaffold(backgroundColor:skin.bg,appBar:AppBar(backgroundColor:skin.bg,title:Text(t('تفاصيل المحادثة','Chat details')),centerTitle:true),body:ListView(padding:const EdgeInsets.fromLTRB(16,12,16,28),children:[
  Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[skin.mine,skin.partner,skin.bg]),borderRadius:BorderRadius.circular(26),border:Border.all(color:skin.accent.withValues(alpha:.3))),child:Column(children:[
   Container(width:86,height:86,decoration:BoxDecoration(shape:BoxShape.circle,color:skin.accent.withValues(alpha:.14),border:Border.all(color:skin.accent.withValues(alpha:.6),width:2)),child:Icon(Icons.person_rounded,color:skin.accent,size:44)),
   const SizedBox(height:12),Text(partnerName,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:21)),Text(t('مساحتكما الخاصة','Your private space'),style:TextStyle(color:skin.accent,fontSize:11)),
   const SizedBox(height:14),FilledButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>profile())),icon:const Icon(Icons.person_outline_rounded),label:Text(t('الملف الشخصي','Profile')),style:FilledButton.styleFrom(backgroundColor:skin.accent,foregroundColor:skin.bg))
  ])),
  section(t('المحتوى المشترك','Shared content')),
  Row(children:[Expanded(child:_ChatDetailTile(icon:Icons.photo_library_rounded,title:t('الوسائط','Media'),subtitle:t('صور ومقاطع','Photos & videos'),accent:skin.accent,onTap:media)),const SizedBox(width:10),Expanded(child:_ChatDetailTile(icon:Icons.folder_rounded,title:t('الملفات','Files'),subtitle:t('ملفات ومرفقات','Files & attachments'),accent:skin.accent,onTap:files))]),
  section(t('إدارة المحادثة','Conversation')),
  tile(Icons.search_rounded,t('البحث في الرسائل','Search messages'),t('اعثر على رسالة بسرعة','Find a message quickly'),search),
  tile(Icons.person_pin_rounded,t('اسم خاص للطرف الآخر','Private nickname'),t('اسم يظهر في جهازك فقط','Only on your device'),nickname),
  tile(Icons.palette_rounded,t('أجواء المحادثة','Chat atmosphere'),t('ثيمات حية وألوان مميزة','Vibrant themes and colors'),()=>themes()),
 ]));
 }
}
class _ChatDetailTile extends StatelessWidget{
 final IconData icon;final String title,subtitle;final Color accent;final VoidCallback onTap;
 const _ChatDetailTile({required this.icon,required this.title,required this.subtitle,required this.accent,required this.onTap});
 @override Widget build(BuildContext c)=>InkWell(onTap:onTap,borderRadius:BorderRadius.circular(17),child:Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.symmetric(horizontal:14,vertical:13),decoration:BoxDecoration(color:const Color(0xFF211D30),borderRadius:BorderRadius.circular(17),border:Border.all(color:accent.withValues(alpha:.15))),child:Row(children:[Container(width:38,height:38,decoration:BoxDecoration(color:accent.withValues(alpha:.12),borderRadius:BorderRadius.circular(12)),child:Icon(icon,color:accent,size:21)),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800)),const SizedBox(height:3),Text(subtitle,style:TextStyle(color:accent.withValues(alpha:.8),fontSize:11))])),Icon(Icons.chevron_right_rounded,color:accent.withValues(alpha:.6))])));}

