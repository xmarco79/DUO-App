import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const _navy=Color(0xFF10101C),_gold=Color(0xFFD9BC86),_lavender=Color(0xFFB9A2D5),_bucket='ours-direct-media';
class _ChatSkin{
 final String id,ar,en;final Color bg,mine,partner,accent;
 const _ChatSkin(this.id,this.ar,this.en,this.bg,this.mine,this.partner,this.accent);
}
const _skins=[
 _ChatSkin('midnight','ليلي','Midnight',Color(0xFF10101C),Color(0xFF342B4C),Color(0xFF211D30),_gold),
 _ChatSkin('ocean','المحيط','Ocean',Color(0xFF0B1B2A),Color(0xFF174A66),Color(0xFF173244),Color(0xFF75C8D8)),
 _ChatSkin('rose','وردي هادئ','Soft rose',Color(0xFF24151F),Color(0xFF63364D),Color(0xFF382331),Color(0xFFF0AFC4)),
 _ChatSkin('forest','الغابة','Forest',Color(0xFF101F1A),Color(0xFF285342),Color(0xFF1D332B),Color(0xFF9CC9A8)),
];

class OursDirectChatPage extends StatefulWidget{
 final String conversationId,partnerName;
 final String? spaceId;
 const OursDirectChatPage({super.key,required this.conversationId,required this.partnerName,this.spaceId});
 @override State<OursDirectChatPage> createState()=>_OursDirectChatPageState();
}
class _OursDirectChatPageState extends State<OursDirectChatPage>{
 final db=Supabase.instance.client,input=TextEditingController(),scroll=ScrollController(),picker=ImagePicker();
 final Map<String,Future<String>> urls={};final List<Map<String,dynamic>> messages=[];
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
  final selected=await showModalBottomSheet<_ChatSkin>(context:context,backgroundColor:const Color(0xFF29213D),showDragHandle:true,
   builder:(ctx)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
    Padding(padding:const EdgeInsets.all(12),child:Text(t('مظهر المحادثة','Chat appearance'),style:const TextStyle(color:_gold,fontSize:18))),
    for(final s in _skins) ListTile(
     leading:Container(width:42,height:30,decoration:BoxDecoration(color:s.bg,borderRadius:BorderRadius.circular(8),border:Border.all(color:s.accent)),child:Align(alignment:Alignment.centerRight,child:Container(width:19,height:10,margin:const EdgeInsets.all(4),decoration:BoxDecoration(color:s.mine,borderRadius:BorderRadius.circular(8))))),
     title:Text(ar?s.ar:s.en),trailing:skin.id==s.id?const Icon(Icons.check_circle,color:_gold):null,onTap:()=>Navigator.pop(ctx,s))
   ])));
  if(selected==null)return;setState(()=>skin=selected);final p=await SharedPreferences.getInstance();await p.setString('ours_direct_skin_'+widget.conversationId,selected.id);
 }
 Future<void> _load() async{
  try{final rows=await db.from('duo_direct_messages').select().eq('conversation_id',widget.conversationId).order('created_at');
   if(!mounted)return;setState((){messages..clear()..addAll(List<Map<String,dynamic>>.from(rows));loading=false;});_bottom();
  }catch(e){if(mounted){setState(()=>loading=false);_show(t('تعذر تحميل المحادثة: $e','Could not load conversation: $e'));}}
 }
 void _listen(){
  channel=db.channel('ours-direct-'+widget.conversationId).onPostgresChanges(event:PostgresChangeEvent.insert,schema:'public',table:'duo_direct_messages',
   filter:PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'conversation_id',value:widget.conversationId),callback:(p){
    final row=Map<String,dynamic>.from(p.newRecord);if(!mounted||messages.any((m)=>m['id']==row['id']))return;setState(()=>messages.add(row));_bottom();
   }).subscribe();
 }
 void _bottom()=>WidgetsBinding.instance.addPostFrameCallback((_){if(scroll.hasClients)scroll.animateTo(scroll.position.maxScrollExtent,duration:const Duration(milliseconds:220),curve:Curves.easeOut);});
 void _show(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
 Future<void> _sendText() async{
  final text=input.text.trim();if(text.isEmpty||sending)return;setState(()=>sending=true);
  try{await db.from('duo_direct_messages').insert({'conversation_id':widget.conversationId,'sender_id':uid,'body':text,'message_type':'text'});input.clear();}
  catch(e){_show(t('تعذر إرسال الرسالة: $e','Could not send message: $e'));}finally{if(mounted)setState(()=>sending=false);}
 }
 String _mime(String name){
  const types={'jpg':'image/jpeg','jpeg':'image/jpeg','png':'image/png','webp':'image/webp','m4a':'audio/mp4','aac':'audio/aac','mp3':'audio/mpeg','ogg':'audio/ogg','mp4':'video/mp4','mov':'video/quicktime','pdf':'application/pdf','txt':'text/plain','csv':'text/csv','doc':'application/msword','docx':'application/vnd.openxmlformats-officedocument.wordprocessingml.document','xls':'application/vnd.ms-excel','xlsx':'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','ppt':'application/vnd.ms-powerpoint','pptx':'application/vnd.openxmlformats-officedocument.presentationml.presentation','zip':'application/zip'};
  return types[name.split('.').last.toLowerCase()]??'';
 }
 Future<void> _upload(Uint8List bytes,String name,String type) async{
  if(bytes.isEmpty)return;if(bytes.length>20*1024*1024){_show(t('الحد الأقصى 20 ميجابايت','Maximum size is 20 MB'));return;}
  final mime=_mime(name);if(mime.isEmpty){_show(t('نوع الملف غير مدعوم','Unsupported file type'));return;}setState(()=>uploading=true);
  final safe=name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'),'_');
  final path=widget.conversationId+'/'+uid+'/'+DateTime.now().microsecondsSinceEpoch.toString()+'_'+safe;
  try{
   await db.storage.from(_bucket).uploadBinary(path,bytes,fileOptions:FileOptions(contentType:mime,upsert:false,cacheControl:'3600'));
   try{await db.from('duo_direct_messages').insert({'conversation_id':widget.conversationId,'sender_id':uid,'body':path,'message_type':type});}
   catch(_){await db.storage.from(_bucket).remove([path]);rethrow;}
  }catch(e){_show(t('تعذر رفع المرفق: $e','Could not upload attachment: $e'));}finally{if(mounted)setState(()=>uploading=false);}
 }
 Future<void> _pickImage({bool viewOnce=false}) async{
  try{final f=await picker.pickImage(source:ImageSource.gallery,imageQuality:86,maxWidth:1600,maxHeight:1600);if(f==null)return;
   final ext=f.name.split('.').last.toLowerCase();final name=['png','webp'].contains(ext)?f.name:'photo_'+DateTime.now().millisecondsSinceEpoch.toString()+'.jpg';
   await _upload(await f.readAsBytes(),name,viewOnce?'view_once':'image');
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
  const stickers=['❤️','🥰','😂','😍','😘','🤍','✨','🌙','🫶','🥹','🎉','🌸','🐱','🧸','💌','🔥'];
  final chosen=await showModalBottomSheet<String>(context:context,backgroundColor:const Color(0xFF29213D),showDragHandle:true,
   builder:(ctx)=>SafeArea(child:Padding(padding:const EdgeInsets.all(16),child:Wrap(spacing:12,runSpacing:12,children:[
    for(final sticker in stickers) InkWell(onTap:()=>Navigator.pop(ctx,sticker),child:Container(width:58,height:58,alignment:Alignment.center,decoration:BoxDecoration(color:skin.partner,borderRadius:BorderRadius.circular(16)),child:Text(sticker,style:const TextStyle(fontSize:30))))
   ]))));
  if(chosen==null)return;
  try{await db.from('duo_direct_messages').insert({'conversation_id':widget.conversationId,'sender_id':uid,'body':chosen,'message_type':'sticker'});}
  catch(e){_show(t('تعذر إرسال الملصق: $e','Could not send sticker: $e'));}
 }
 Future<void> _consumeViewOnce(String messageId) async{
  try{
   final path=await db.rpc('consume_ours_view_once',params:{'p_message_id':messageId}) as String?;
   if(path==null||path.isEmpty){_show(t('تم فتح هذه الصورة مسبقًا','This photo has already been viewed'));return;}
   final url=await _signed(path);
   await showDialog<void>(context:context,builder:(ctx)=>Dialog(backgroundColor:Colors.black,child:Column(mainAxisSize:MainAxisSize.min,children:[
    Padding(padding:const EdgeInsets.all(10),child:Text(t('عرض لمرة واحدة','View once'),style:const TextStyle(color:Colors.white))),
    Flexible(child:Image.network(url,fit:BoxFit.contain)),
    TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('إغلاق','Close')))
   ])));
   await db.storage.from(_bucket).remove([path]);
   if(mounted)setState(()=>messages.firstWhere((m)=>m['id']==messageId)['body']='[viewed]');
  }catch(e){_show(t('تعذر فتح الصورة: $e','Could not open one-time photo: $e'));}
 }
 Future<void> _showAttachments() async{
  final choice=await showModalBottomSheet<String>(context:context,backgroundColor:const Color(0xFF29213D),showDragHandle:true,
   builder:(ctx)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
    ListTile(leading:Icon(Icons.image_outlined,color:skin.accent),title:Text(t('صورة','Photo')),onTap:()=>Navigator.pop(ctx,'image')),
    ListTile(leading:Icon(Icons.timer_outlined,color:skin.accent),title:Text(t('صورة لمرة واحدة','View-once photo')),onTap:()=>Navigator.pop(ctx,'once')),
    ListTile(leading:Icon(Icons.video_library_outlined,color:skin.accent),title:Text(t('مقطع فيديو','Video')),onTap:()=>Navigator.pop(ctx,'video')),
    ListTile(leading:Icon(Icons.insert_drive_file_outlined,color:skin.accent),title:Text(t('ملف','File')),onTap:()=>Navigator.pop(ctx,'file')),
    ListTile(leading:Icon(Icons.emoji_emotions_outlined,color:skin.accent),title:Text(t('ملصق','Sticker')),onTap:()=>Navigator.pop(ctx,'sticker')),
   ])));
  if(choice==null)return;
  switch(choice){case 'image':await _pickImage();break;case 'once':await _pickImage(viewOnce:true);break;case 'video':await _pickVideo();break;case 'file':await _pickFile();break;case 'sticker':await _sendSticker();break;}
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
   title:Column(mainAxisSize:MainAxisSize.min,children:[Text(widget.partnerName,style:const TextStyle(fontSize:16)),Text(t('محادثة خاصة بينكما','Private conversation'),style:TextStyle(color:skin.accent,fontSize:10))]),
   actions:[
    IconButton(tooltip:t('الثيم','Theme'),onPressed:_chooseSkin,icon:Icon(Icons.palette_outlined,color:skin.accent)),
    IconButton(tooltip:t('راسل نفسك','Message yourself'),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const OursSelfChatPage())),icon:Icon(Icons.bookmark_border_rounded,color:skin.accent)),
    if(widget.spaceId!=null) IconButton(tooltip:'OURS AI',onPressed:_openAi,icon:Icon(Icons.auto_awesome_outlined,color:skin.accent)),
    IconButton(tooltip:t('اتصال صوتي','Voice call'),onPressed:()=>_callInfo(false),icon:Icon(Icons.call_outlined,color:skin.accent)),
    IconButton(tooltip:t('اتصال مرئي','Video call'),onPressed:()=>_callInfo(true),icon:Icon(Icons.videocam_outlined,color:skin.accent))
   ]),
   body:Column(children:[
    Expanded(child:loading?Center(child:CircularProgressIndicator(color:skin.accent)):messages.isEmpty
     ?Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Icon(Icons.forum_outlined,color:skin.accent,size:52),const SizedBox(height:12),Text(t('ابدأ محادثتكما الخاصة','Start your private conversation'),style:const TextStyle(fontSize:19)),
      const SizedBox(height:7),Text(t('رسائل وصور وملفات وتسجيلات صوتية في مكان واحد.','Messages, photos, files and voice notes in one place.'),textAlign:TextAlign.center,style:TextStyle(color:skin.accent))
     ])))
     :ListView.builder(controller:scroll,padding:const EdgeInsets.all(12),itemCount:messages.length,itemBuilder:(ctx,i){
      final m=messages[i];final mine=m['sender_id']==me;final type=m['message_type']?.toString()??'text';final path=m['body']?.toString()??'';
      return Align(alignment:mine?AlignmentDirectional.centerEnd:AlignmentDirectional.centerStart,child:Container(
       constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*.82),margin:const EdgeInsets.symmetric(vertical:5),padding:const EdgeInsets.all(10),
       decoration:BoxDecoration(color:mine?skin.mine:skin.partner,borderRadius:BorderRadius.circular(17),border:Border.all(color:skin.accent.withValues(alpha:.16))),
       child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
        if(type=='sticker')Center(child:Text(path,style:const TextStyle(fontSize:42)))
        else if(type=='view_once')m['viewed_at']!=null
          ?Text(t('تم فتح الصورة لمرة واحدة','One-time photo viewed'),style:TextStyle(color:skin.accent,fontSize:12))
          :mine
            ?Text(t('أرسلت صورة لمرة واحدة','You sent a view-once photo'),style:TextStyle(color:skin.accent,fontSize:12))
            :TextButton.icon(onPressed:()=>_consumeViewOnce(m['id'].toString()),icon:Icon(Icons.visibility_outlined,color:skin.accent),label:Text(t('عرض الصورة مرة واحدة','View photo once')))
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
       ])));
     })),
    SafeArea(top:false,child:Container(padding:const EdgeInsets.fromLTRB(7,8,7,10),decoration:BoxDecoration(color:skin.bg,border:Border(top:BorderSide(color:skin.accent.withValues(alpha:.2)))),
     child:recording?Row(children:[
      IconButton(onPressed:_cancelRecording,icon:const Icon(Icons.delete_outline,color:Colors.redAccent)),
      Expanded(child:Text(t('جارٍ تسجيل الرسالة الصوتية…','Recording voice message…'),textAlign:TextAlign.center,style:TextStyle(color:skin.accent))),
      IconButton(onPressed:sending?null:_sendRecording,icon:Icon(Icons.send,color:skin.accent))
     ]):Row(children:[
      IconButton(onPressed:uploading||sending?null:_showAttachments,tooltip:t('المرفقات والملصقات','Attachments and stickers'),icon:uploading?SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:skin.accent)):Icon(Icons.add_circle_outline_rounded,color:skin.accent)),
      Expanded(child:TextField(controller:input,minLines:1,maxLines:5,textInputAction:TextInputAction.send,onSubmitted:(_)=>_sendText(),
       decoration:InputDecoration(hintText:t('اكتب رسالة…','Write a message…'),filled:true,fillColor:skin.partner,border:OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:BorderSide.none),contentPadding:const EdgeInsets.symmetric(horizontal:15,vertical:11)))),
      IconButton(onPressed:uploading||sending?null:_startRecording,icon:Icon(Icons.mic_none_rounded,color:skin.accent)),
      IconButton.filled(onPressed:sending||uploading?null:_sendText,style:IconButton.styleFrom(backgroundColor:skin.accent,foregroundColor:skin.bg),icon:sending?const SizedBox(width:17,height:17,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send_rounded))
     ])))
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
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:_navy,appBar:AppBar(backgroundColor:_navy,title:const Text('OURS AI',style:TextStyle(color:_gold,letterSpacing:2)),centerTitle:true),
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
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:_navy,appBar:AppBar(title:Text(t('مساحتي الخاصة','My private space'))),
 body:Column(children:[
  Padding(padding:const EdgeInsets.all(12),child:Text(t('اكتب أفكارك، خططك، تذكيراتك وأشياءك المهمة. لا يراها غيرك.','Save ideas, plans, reminders and important notes. Only you can see them.'),style:const TextStyle(color:_lavender))),
  Expanded(child:loading?const Center(child:CircularProgressIndicator(color:_gold)):rows.isEmpty?Center(child:Text(t('مساحتك لك وحدك. ابدأ بتدوين أول فكرة.','Your space is yours. Save your first thought.'),style:const TextStyle(color:_lavender))):ListView.builder(controller:scroll,padding:const EdgeInsets.all(12),itemCount:rows.length,itemBuilder:(c,i){final row=rows[rows.length-1-i];return Card(color:const Color(0xFF29213D),child:ListTile(title:SelectableText(row['body'].toString()),subtitle:Text(DateFormat('yyyy/MM/dd · HH:mm').format(DateTime.parse(row['created_at']).toLocal()),style:const TextStyle(color:_lavender,fontSize:11)),leading:row['pinned']==true?const Icon(Icons.push_pin,color:_gold):const Icon(Icons.sticky_note_2_outlined,color:_lavender),trailing:PopupMenuButton<String>(onSelected:(v)=>v=='pin'?_togglePin(row):_delete(row),itemBuilder:(_)=>[PopupMenuItem(value:'pin',child:Text(t('تثبيت / إلغاء التثبيت','Pin / unpin'))),PopupMenuItem(value:'delete',child:Text(t('حذف','Delete')))])));})),
  SafeArea(top:false,child:Padding(padding:const EdgeInsets.all(10),child:Row(children:[Expanded(child:TextField(controller:input,minLines:1,maxLines:4,decoration:InputDecoration(hintText:t('اكتب لنفسك…','Write a note…'),filled:true,fillColor:const Color(0xFF29213D),border:OutlineInputBorder(borderRadius:BorderRadius.circular(20),borderSide:BorderSide.none)),onSubmitted:(_)=>_send())),IconButton(onPressed:sending?null:_send,icon:const Icon(Icons.send_rounded,color:_gold))])))
 ]));
}
