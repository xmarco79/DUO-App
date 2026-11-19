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
 _ChatSkin('signature','OURS Signature','OURS Signature',Color(0xFF10101C),Color(0xFF342B4C),Color(0xFF211D30),_gold),
 _ChatSkin('midnight','ليلي','Midnight',Color(0xFF080D1A),Color(0xFF283B62),Color(0xFF17243C),Color(0xFF8DAFFF)),
 _ChatSkin('ocean','المحيط','Ocean',Color(0xFF0B1B2A),Color(0xFF174A66),Color(0xFF173244),Color(0xFF75C8D8)),
 _ChatSkin('rose','وردي هادئ','Soft rose',Color(0xFF24151F),Color(0xFF63364D),Color(0xFF382331),Color(0xFFF0AFC4)),
 _ChatSkin('forest','الغابة','Forest',Color(0xFF101F1A),Color(0xFF285342),Color(0xFF1D332B),Color(0xFF9CC9A8)),
 _ChatSkin('aurora','الشفق','Aurora',Color(0xFF101323),Color(0xFF433D72),Color(0xFF252D49),Color(0xFF88E4C4)),
 _ChatSkin('cafe','دفء القهوة','Warm Café',Color(0xFF211A16),Color(0xFF5A4030),Color(0xFF3B2B22),Color(0xFFE1B98B)),
 _ChatSkin('crimson','قرمزي','Crimson',Color(0xFF1C1016),Color(0xFF682B40),Color(0xFF38202B),Color(0xFFFF8098)),
 _ChatSkin('lavender','لافندر','Lavender Dream',Color(0xFF1A1628),Color(0xFF57446D),Color(0xFF30263F),Color(0xFFC9B2F1)),
 _ChatSkin('monochrome','أحادي','Monochrome',Color(0xFF111111),Color(0xFF414141),Color(0xFF252525),Color(0xFFE5E5E5)),
];

class OursDirectChatPage extends StatefulWidget{
 final String conversationId,partnerName;
 const OursDirectChatPage({super.key,required this.conversationId,required this.partnerName});
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
  final selected=await showModalBottomSheet<_ChatSkin>(context:context,backgroundColor:const Color(0xFF171523),showDragHandle:true,isScrollControlled:true,
   builder:(ctx)=>SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(14,8,14,18),child:Column(mainAxisSize:MainAxisSize.min,children:[
    Text(t('ثيمات OURS','OURS themes'),style:const TextStyle(color:_gold,fontSize:19,fontWeight:FontWeight.w700)),
    const SizedBox(height:5),Text(t('اختر هوية محادثتك','Choose your conversation style'),style:TextStyle(color:_lavender.withValues(alpha:.8))),
    const SizedBox(height:12),Flexible(child:ListView(shrinkWrap:true,children:[for(final s in _skins)
     Card(color:s.bg,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16),side:BorderSide(color:s.id==skin.id?s.accent:Colors.white12,width:s.id==skin.id?1.5:1)),
      child:ListTile(
       leading:Container(width:48,height:34,decoration:BoxDecoration(color:s.bg,borderRadius:BorderRadius.circular(10),border:Border.all(color:s.accent.withValues(alpha:.8))),child:Stack(children:[Align(alignment:Alignment.centerLeft,child:Container(width:22,height:12,margin:const EdgeInsets.all(4),decoration:BoxDecoration(color:s.partner,borderRadius:BorderRadius.circular(6)))),Align(alignment:Alignment.centerRight,child:Container(width:22,height:12,margin:const EdgeInsets.all(4),decoration:BoxDecoration(color:s.mine,borderRadius:BorderRadius.circular(6))))])),
       title:Text(ar?s.ar:s.en,style:const TextStyle(color:Colors.white)),subtitle:Text(s.id=='signature'?t('الثيم الرسمي لهوية OURS','OURS official signature theme'):t('ثيم محادثة','Conversation theme'),style:TextStyle(color:s.accent,fontSize:11)),
       trailing:skin.id==s.id?Icon(Icons.check_circle,color:s.accent):null,onTap:()=>Navigator.pop(ctx,s)))]))
   ]))));
  if(selected==null)return;setState(()=>skin=selected);final p=await SharedPreferences.getInstance();await p.setString('ours_direct_skin_'+widget.conversationId,selected.id);
 }
 Future<void> _openDetails() async{
  await Navigator.push(context,MaterialPageRoute(builder:(_)=>OursConversationDetailsPage(conversationId:widget.conversationId,partnerName:widget.partnerName)));
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
  const types={'jpg':'image/jpeg','jpeg':'image/jpeg','png':'image/png','webp':'image/webp','mp4':'video/mp4','m4a':'audio/mp4','aac':'audio/aac','mp3':'audio/mpeg','ogg':'audio/ogg','webm':'audio/webm','pdf':'application/pdf','txt':'text/plain','csv':'text/csv','doc':'application/msword','docx':'application/vnd.openxmlformats-officedocument.wordprocessingml.document','xls':'application/vnd.ms-excel','xlsx':'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','ppt':'application/vnd.ms-powerpoint','pptx':'application/vnd.openxmlformats-officedocument.presentationml.presentation','zip':'application/zip'};
  return types[name.split('.').last.toLowerCase()]??'';
 }
 Future<void> _upload(Uint8List bytes,String name,String type,{String viewMode='normal'}) async{
  if(bytes.isEmpty)return;if(bytes.length>20*1024*1024){_show(t('الحد الأقصى 20 ميجابايت','Maximum size is 20 MB'));return;}
  final mime=_mime(name);if(mime.isEmpty){_show(t('نوع الملف غير مدعوم','Unsupported file type'));return;}setState(()=>uploading=true);
  final safe=name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'),'_');
  final path=widget.conversationId+'/'+uid+'/'+DateTime.now().microsecondsSinceEpoch.toString()+'_'+safe;
  try{
   await db.storage.from(_bucket).uploadBinary(path,bytes,fileOptions:FileOptions(contentType:mime,upsert:false,cacheControl:'3600'));
   try{await db.from('duo_direct_messages').insert({'conversation_id':widget.conversationId,'sender_id':uid,'body':path,'message_type':viewMode=='once'?'view_once':viewMode=='twice'?'view_twice':type,'max_views':viewMode=='twice'?2:1,'view_count':0});}
   catch(_){await db.storage.from(_bucket).remove([path]);rethrow;}
  }catch(e){_show(t('تعذر رفع المرفق: $e','Could not upload attachment: $e'));}finally{if(mounted)setState(()=>uploading=false);}
 }
 Future<void> _pickImage({ImageSource source=ImageSource.gallery}) async{
  try{final f=await picker.pickImage(source:source,imageQuality:92,maxWidth:2200,maxHeight:2200);if(f==null)return;
   final ext=f.name.split('.').last.toLowerCase();final name=['png','webp'].contains(ext)?f.name:'photo_'+DateTime.now().millisecondsSinceEpoch.toString()+'.jpg';
   final bytes=await f.readAsBytes();final draft=await Navigator.push<_MediaDraft>(context,MaterialPageRoute(builder:(_)=>OursMediaPreviewPage(bytes:bytes,name:name,kind:'image',accent:skin.accent)));
   if(draft==null)return;await _upload(draft.bytes,draft.name,'image',viewMode:draft.viewMode);
  }catch(e){_show(t('تعذر اختيار الصورة: $e','Could not select image: $e'));}
 }
 Future<void> _pickVideo({ImageSource source=ImageSource.gallery}) async{
  try{final f=await picker.pickVideo(source:source,maxDuration:const Duration(minutes:5));if(f==null)return;
   if(f.name.split('.').last.toLowerCase()!='mp4'){_show(t('اختر فيديو بصيغة MP4 حاليًا.','Please choose an MP4 video for now.'));return;}
   final bytes=await f.readAsBytes();final draft=await Navigator.push<_MediaDraft>(context,MaterialPageRoute(builder:(_)=>OursMediaPreviewPage(bytes:bytes,name:f.name,kind:'video',accent:skin.accent)));
   if(draft==null)return;await _upload(draft.bytes,draft.name,'video',viewMode:draft.viewMode);
  }catch(e){_show(t('تعذر اختيار الفيديو: $e','Could not select video: $e'));}
 }
 Future<void> _chooseMedia() async{
  final choice=await showModalBottomSheet<String>(context:context,backgroundColor:const Color(0xFF29213D),showDragHandle:true,builder:(c)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
   ListTile(leading:Icon(Icons.photo_outlined,color:skin.accent),title:Text(t('صورة من المعرض','Photo from gallery')),onTap:()=>Navigator.pop(c,'photo')),
   ListTile(leading:Icon(Icons.videocam_outlined,color:skin.accent),title:Text(t('فيديو من المعرض','Video from gallery')),onTap:()=>Navigator.pop(c,'video')),
   ListTile(leading:Icon(Icons.camera_alt_outlined,color:skin.accent),title:Text(t('التقاط صورة','Take a photo')),onTap:()=>Navigator.pop(c,'camera')),
   ListTile(leading:Icon(Icons.video_camera_back_outlined,color:skin.accent),title:Text(t('تسجيل فيديو','Record video')),onTap:()=>Navigator.pop(c,'record'))
  ])));
  if(choice=='photo')await _pickImage();else if(choice=='video')await _pickVideo();else if(choice=='camera')await _pickImage(source:ImageSource.camera);else if(choice=='record')await _pickVideo(source:ImageSource.camera);
 }
 Future<void> _chooseAttachment() async{
  final choice=await showModalBottomSheet<String>(context:context,backgroundColor:const Color(0xFF29213D),showDragHandle:true,builder:(c)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
   ListTile(leading:Icon(Icons.folder_open,color:skin.accent),title:Text(t('ملف أو مستند','File or document')),onTap:()=>Navigator.pop(c,'file')),
   ListTile(leading:Icon(Icons.photo_library_outlined,color:skin.accent),title:Text(t('وسائط: صورة أو فيديو','Media: photo or video')),onTap:()=>Navigator.pop(c,'media')),
  ])));
  if(choice=='file')await _pickFile();if(choice=='media')await _chooseMedia();
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
 String _absoluteStorageRpcUrl(dynamic result){
  final value=result?.toString()??'';if(value.isEmpty||value.startsWith('http'))return value;
  final origin=Uri.parse(db.storage.from(_bucket).getPublicUrl('ours-url-base')).origin;
  final path=value.startsWith('/storage/v1')?value:'/storage/v1'+(value.startsWith('/')?value:'/'+value);
  return origin+path;
 }
 Future<void> _openLimitedMedia(Map<String,dynamic> m) async{
  try{
   final result=await db.rpc('ours_consume_limited_media',params:{'p_message_id':m['id']});
   final url=_absoluteStorageRpcUrl(result);if(url.isEmpty){_show(t('انتهت المشاهدات المسموحة','Allowed views have been used'));return;}
   final p=(m['view_once_storage_path']??m['body']??'').toString();final isVideo=p.toLowerCase().endsWith('.mp4');
   if(isVideo){await launchUrl(Uri.parse(url),mode:LaunchMode.externalApplication);}
   else if(mounted){await showDialog<void>(context:context,builder:(_)=>Dialog(backgroundColor:Colors.transparent,child:InteractiveViewer(child:Image.network(url,fit:BoxFit.contain))));}
   final idx=messages.indexWhere((x)=>x['id']==m['id']);if(idx>=0&&mounted)setState(()=>messages[idx]['view_count']=((messages[idx]['view_count']??0) as num).toInt()+1);
  }catch(e){_show(t('تعذر فتح الوسائط المحدودة: $e','Unable to open limited media: $e'));}
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
 Future<void> _openAi() async{await Navigator.push(context,MaterialPageRoute(builder:(_)=>OursAiPage(conversationId:widget.conversationId)));}
 @override void dispose(){input.dispose();scroll.dispose();recorder?.dispose();if(channel!=null)db.removeChannel(channel!);super.dispose();}
 @override Widget build(BuildContext context){
  final me=db.auth.currentUser!.id;
  return Scaffold(backgroundColor:skin.bg,appBar:AppBar(backgroundColor:skin.bg,centerTitle:true,
   title:Column(mainAxisSize:MainAxisSize.min,children:[Text(widget.partnerName,style:const TextStyle(fontSize:16)),Text(t('محادثة خاصة بينكما','Private conversation'),style:TextStyle(color:skin.accent,fontSize:10))]),
   actions:[
    IconButton(tooltip:t('الثيم','Theme'),onPressed:_chooseSkin,icon:Icon(Icons.palette_outlined,color:skin.accent)),
    IconButton(tooltip:'OURS AI',onPressed:_openAi,icon:Icon(Icons.auto_awesome_outlined,color:skin.accent)),
    IconButton(tooltip:t('اتصال صوتي','Voice call'),onPressed:()=>_callInfo(false),icon:Icon(Icons.call_outlined,color:skin.accent)),
    IconButton(tooltip:t('اتصال مرئي','Video call'),onPressed:()=>_callInfo(true),icon:Icon(Icons.videocam_outlined,color:skin.accent)),
    IconButton(tooltip:t('معلومات المحادثة','Conversation details'),onPressed:_openDetails,icon:Icon(Icons.more_horiz_rounded,color:skin.accent))
   ]),
   body:Column(children:[
    Expanded(child:loading?Center(child:CircularProgressIndicator(color:skin.accent)):messages.isEmpty
     ?Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Icon(Icons.forum_outlined,color:skin.accent,size:52),const SizedBox(height:12),Text(t('ابدأ محادثتكما الخاصة','Start your private conversation'),style:const TextStyle(fontSize:19)),
      const SizedBox(height:7),Text(t('رسائل وصور وملفات وتسجيلات صوتية في مكان واحد.','Messages, photos, files and voice notes in one place.'),textAlign:TextAlign.center,style:TextStyle(color:skin.accent))
     ])))
     :ListView.builder(controller:scroll,padding:const EdgeInsets.all(12),itemCount:messages.length,itemBuilder:(ctx,i){
      final m=messages[i];final mine=m['sender_id']==me;final type=m['message_type']?.toString()??'text';final path=(m['body']=='[viewed]'?m['view_once_storage_path']:m['body'])?.toString()??'';
      return Align(alignment:mine?AlignmentDirectional.centerEnd:AlignmentDirectional.centerStart,child:Container(
       constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*.82),margin:const EdgeInsets.symmetric(vertical:5),padding:const EdgeInsets.all(10),
       decoration:BoxDecoration(color:mine?skin.mine:skin.partner,borderRadius:BorderRadius.circular(17),border:Border.all(color:skin.accent.withValues(alpha:.16))),
       child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
        if(type=='view_once'||type=='view_twice')InkWell(onTap:()=>_openLimitedMedia(m),child:Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:10),decoration:BoxDecoration(color:skin.bg.withValues(alpha:.45),borderRadius:BorderRadius.circular(13)),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(path.toLowerCase().endsWith('.mp4')?Icons.movie_outlined:Icons.visibility_outlined,color:skin.accent,size:28),const SizedBox(width:8),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(type=='view_once'?t('وسائط لمرة واحدة','View once'):t('وسائط لمرتين','View twice'),style:TextStyle(color:skin.accent,fontWeight:FontWeight.w600)),Text((m['view_count']??0).toString()+'/'+(m['max_views']??1).toString(),style:TextStyle(color:skin.accent,fontSize:10))])])))
        else if(type=='view_once'||type=='view_twice')InkWell(onTap:()=>_openLimitedMedia(m),child:Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:10),decoration:BoxDecoration(color:skin.bg.withValues(alpha:.45),borderRadius:BorderRadius.circular(13)),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(path.toLowerCase().endsWith('.mp4')?Icons.movie_outlined:Icons.visibility_outlined,color:skin.accent,size:28),const SizedBox(width:8),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(type=='view_once'?t('وسائط لمرة واحدة','View once'):t('وسائط لمرتين','View twice'),style:TextStyle(color:skin.accent,fontWeight:FontWeight.w600)),Text((m['view_count']??0).toString()+'/'+(m['max_views']??1).toString(),style:TextStyle(color:skin.accent,fontSize:10))])])))
        else if(type=='image')FutureBuilder<String>(future:_signed(path),builder:(c,s){
         if(s.hasError)return Text(t('تعذر تحميل الصورة','Could not load image'),style:TextStyle(color:skin.accent));
         if(!s.hasData)return SizedBox(width:190,height:125,child:Center(child:CircularProgressIndicator(color:skin.accent)));
         return GestureDetector(onTap:()=>showDialog<void>(context:context,builder:(_)=>Dialog(backgroundColor:Colors.transparent,child:InteractiveViewer(child:Image.network(s.data!,fit:BoxFit.contain)))),
          child:ClipRRect(borderRadius:BorderRadius.circular(11),child:Image.network(s.data!,width:230,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Text(t('تعذر عرض الصورة','Image unavailable')))));
        })
        else if(type=='video')InkWell(onTap:()=>_openFile(path),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.movie_outlined,color:skin.accent,size:30),const SizedBox(width:8),Text(t('مقطع فيديو','Video'))]))
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
      IconButton(onPressed:uploading||sending?null:_chooseAttachment,icon:uploading?SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:skin.accent)):Icon(Icons.add_circle_outline_rounded,color:skin.accent)),
      Expanded(child:TextField(controller:input,minLines:1,maxLines:5,textInputAction:TextInputAction.send,onSubmitted:(_)=>_sendText(),
       decoration:InputDecoration(hintText:t('اكتب رسالة…','Write a message…'),filled:true,fillColor:skin.partner,border:OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:BorderSide.none),contentPadding:const EdgeInsets.symmetric(horizontal:15,vertical:11)))),
      IconButton(onPressed:uploading||sending?null:_startRecording,icon:Icon(Icons.mic_none_rounded,color:skin.accent)),
      IconButton.filled(onPressed:sending||uploading?null:_sendText,style:IconButton.styleFrom(backgroundColor:skin.accent,foregroundColor:skin.bg),icon:sending?const SizedBox(width:17,height:17,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send_rounded))
     ])))
   ]));
 }
}

class _MediaDraft{final Uint8List bytes;final String name,kind,viewMode;const _MediaDraft({required this.bytes,required this.name,required this.kind,required this.viewMode});}
class OursMediaPreviewPage extends StatefulWidget{
 final Uint8List bytes;final String name,kind;final Color accent;
 const OursMediaPreviewPage({super.key,required this.bytes,required this.name,required this.kind,required this.accent});
 @override State<OursMediaPreviewPage> createState()=>_OursMediaPreviewPageState();
}
class _OursMediaPreviewPageState extends State<OursMediaPreviewPage>{
 String viewMode='normal';bool hd=true;
 bool get ar=>Localizations.localeOf(context).languageCode=='ar';String t(String a,String e)=>ar?a:e;
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:const Color(0xFF10101C),appBar:AppBar(backgroundColor:const Color(0xFF10101C),title:Text(t('معاينة قبل الإرسال','Preview before sending')),actions:[IconButton(onPressed:()=>setState(()=>hd=!hd),tooltip:'HD',icon:Icon(Icons.high_quality,color:hd?widget.accent:Colors.white54))]),
 body:SafeArea(child:Column(children:[
  Expanded(child:Center(child:Padding(padding:const EdgeInsets.all(16),child:widget.kind=='image'?ClipRRect(borderRadius:BorderRadius.circular(20),child:Image.memory(widget.bytes,fit:BoxFit.contain)):Container(width:280,height:300,decoration:BoxDecoration(color:const Color(0xFF211D30),borderRadius:BorderRadius.circular(22),border:Border.all(color:widget.accent.withValues(alpha:.4))),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.movie_outlined,size:72,color:widget.accent),const SizedBox(height:12),Padding(padding:const EdgeInsets.all(12),child:Text(widget.name,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white)))]))))),
  Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:Row(children:[Text(t('المشاهدة','Viewing'),style:TextStyle(color:widget.accent,fontWeight:FontWeight.w600)),const Spacer(),Text('HD '+(hd?t('مفعّل','on'):t('غير مفعّل','off')),style:TextStyle(color:widget.accent,fontSize:12))])),
  Padding(padding:const EdgeInsets.all(12),child:Wrap(spacing:8,runSpacing:8,children:[_modeChip('normal',t('عادي','Normal')),_modeChip('once',t('لمرة واحدة','Once')),_modeChip('twice',t('لمرتين','Twice'))])),
  Padding(padding:const EdgeInsets.fromLTRB(16,4,16,14),child:Row(children:[Expanded(child:OutlinedButton(onPressed:()=>Navigator.pop(context),child:Text(t('إلغاء','Cancel')))),const SizedBox(width:12),Expanded(child:FilledButton.icon(onPressed:()=>Navigator.pop(context,_MediaDraft(bytes:widget.bytes,name:widget.name,kind:widget.kind,viewMode:viewMode)),icon:const Icon(Icons.send_rounded),label:Text(t('إرسال','Send'))))]))
 ])));
 Widget _modeChip(String value,String label)=>ChoiceChip(label:Text(label),selected:viewMode==value,selectedColor:widget.accent.withValues(alpha:.25),backgroundColor:const Color(0xFF29213D),labelStyle:TextStyle(color:viewMode==value?widget.accent:Colors.white),onSelected:(_)=>setState(()=>viewMode=value));
}
class OursConversationDetailsPage extends StatefulWidget{
 final String conversationId,partnerName;const OursConversationDetailsPage({super.key,required this.conversationId,required this.partnerName});
 @override State<OursConversationDetailsPage> createState()=>_OursConversationDetailsPageState();
}
class _OursConversationDetailsPageState extends State<OursConversationDetailsPage> with SingleTickerProviderStateMixin{
 final db=Supabase.instance.client;late TabController tabs;late Future<List<Map<String,dynamic>>> future;
 bool get ar=>Localizations.localeOf(context).languageCode=='ar';String t(String a,String e)=>ar?a:e;
 @override void initState(){super.initState();tabs=TabController(length:3,vsync:this);future=_load();}
 Future<List<Map<String,dynamic>>> _load()async{final r=await db.from('duo_direct_messages').select('id,body,message_type,created_at,sender_id,view_once_storage_path,max_views,view_count').eq('conversation_id',widget.conversationId).order('created_at',ascending:false);return List<Map<String,dynamic>>.from(r);}
 Future<String> _signed(String path)=>db.storage.from(_bucket).createSignedUrl(path,300);
 Future<void> _open(Map<String,dynamic> m)async{final path=(m['body']=='[viewed]'?m['view_once_storage_path']:m['body'])?.toString()??'';try{final limited=m['message_type']=='view_once'||m['message_type']=='view_twice';final result=limited?await db.rpc('ours_consume_limited_media',params:{'p_message_id':m['id']}):await _signed(path);final url=limited?_absoluteStorageRpcUrl(result):result?.toString()??'';if(url.isEmpty)throw Exception('View limit reached');await launchUrl(Uri.parse(url),mode:LaunchMode.externalApplication);}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(t('تعذر فتح العنصر أو انتهت المشاهدات','Unable to open item or view limit reached'))));}}
 bool _isVideo(String p)=>p.toLowerCase().endsWith('.mp4')||p.toLowerCase().endsWith('.mov');
 @override void dispose(){tabs.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:_navy,appBar:AppBar(backgroundColor:_navy,title:Text(t('معلومات المحادثة','Conversation info')),bottom:TabBar(controller:tabs,indicatorColor:_gold,labelColor:_gold,unselectedLabelColor:_lavender,tabs:[Tab(text:t('الوسائط','Media')),Tab(text:t('الملفات','Files')),Tab(text:t('الصوتيات','Audio'))])),
 body:FutureBuilder<List<Map<String,dynamic>>>(future:future,builder:(c,s){if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator(color:_gold));if(s.hasError)return Center(child:Text(t('تعذر تحميل المحتوى','Could not load items')));final rows=s.data??[];
 final media=rows.where((m)=>m['message_type']=='image'||m['message_type']=='video'||m['message_type']=='view_once'||m['message_type']=='view_twice').toList();final files=rows.where((m)=>m['message_type']=='file').toList();final audio=rows.where((m)=>m['message_type']=='audio').toList();
 return Column(children:[Padding(padding:const EdgeInsets.fromLTRB(16,18,16,14),child:Column(children:[CircleAvatar(radius:36,backgroundColor:const Color(0xFF29213D),child:Icon(Icons.person_rounded,color:_gold,size:38)),const SizedBox(height:10),Text(widget.partnerName,style:const TextStyle(fontSize:19,fontWeight:FontWeight.w700)),Text(t('محادثة خاصة','Private chat'),style:TextStyle(color:_lavender,fontSize:12))])),Expanded(child:TabBarView(controller:tabs,children:[_list(media,t('لا توجد وسائط بعد','No media yet'),Icons.photo_library_outlined),_list(files,t('لا توجد ملفات','No files'),Icons.folder_outlined),_list(audio,t('لا توجد صوتيات','No audio'),Icons.mic_none_rounded)]))]);
 }),
 );
 Widget _list(List<Map<String,dynamic>> rows,String empty,IconData icon)=>rows.isEmpty?Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,color:_lavender,size:45),const SizedBox(height:8),Text(empty,style:TextStyle(color:_lavender))])):ListView.builder(padding:const EdgeInsets.all(12),itemCount:rows.length,itemBuilder:(c,i){final m=rows[i];final p=m['body']?.toString()??'';final type=m['message_type'];final video=type=='video'||((type=='view_once'||type=='view_twice')&&_isVideo((m['view_once_storage_path']??p).toString()));return Card(color:const Color(0xFF211D30),child:ListTile(leading:Icon(type=='image'||type=='view_once'||type=='view_twice'?Icons.image_outlined:video?Icons.movie_outlined:type=='audio'?Icons.audiotrack:Icons.insert_drive_file_outlined,color:_gold),title:Text(video?t('مقطع فيديو','Video'):p.split('/').last.replaceFirst(RegExp(r'^\d+_'),''),maxLines:1,overflow:TextOverflow.ellipsis),subtitle:Text(DateFormat(ar?'d MMM yyyy':'MMM d, yyyy').format(DateTime.tryParse(m['created_at']?.toString()??'')?.toLocal()??DateTime.now()),style:const TextStyle(color:_lavender,fontSize:11)),onTap:()=>_open(m)));});
}
class OursAiPage extends StatefulWidget{
 final String conversationId;const OursAiPage({super.key,required this.conversationId});
 @override State<OursAiPage> createState()=>_OursAiPageState();
}
class _OursAiPageState extends State<OursAiPage>{
 final db=Supabase.instance.client,input=TextEditingController(),scroll=ScrollController();final messages=<Map<String,String>>[];
 bool sending=false,includeContext=false;bool get ar=>Localizations.localeOf(context).languageCode=='ar';String t(String a,String e)=>ar?a:e;
 Future<List<Map<String,String>>> _context() async{
  final rows=await db.from('duo_direct_messages').select('body,sender_id').eq('conversation_id',widget.conversationId).eq('message_type','text').order('created_at',ascending:false).limit(20);
  return List<Map<String,dynamic>>.from(rows).reversed.map((r)=>{'sender':r['sender_id']==db.auth.currentUser!.id?(ar?'أنا':'Me'):(ar?'الشريك':'Partner'),'text':r['body'].toString()}).toList();
 }
 Future<void> _send({String? preset,String task='chat'}) async{
  final text=(preset??input.text).trim();if(text.isEmpty||sending)return;setState(()=>sending=true);messages.add({'role':'user','content':text});input.clear();_bottom();
  try{
   final ctx=includeContext?await _context():<Map<String,String>>[];final history=messages.length>12?messages.sublist(messages.length-12):messages;
   final r=await db.functions.invoke('ours-ai',body:{'conversation_id':widget.conversationId,'task':task,'messages':history,'context':ctx});
   final data=r.data is Map?Map<String,dynamic>.from(r.data):<String,dynamic>{};
   if(r.status!=200){final e=data['error']?.toString()??'';if(e=='GEMINI_SETUP_REQUIRED')throw Exception(t('مفتاح الذكاء الاصطناعي غير مضبوط على الخادم.','AI provider key is not configured on the server.'));
    if(e=='AI_LIMIT_REACHED')throw Exception(t('وصلنا لحد الاستخدام الحالي، حاول لاحقًا.','Usage limit reached. Try later.'));if(r.status==403)throw Exception(t('لا تملك صلاحية هذه المحادثة.','Conversation access denied.'));throw Exception(t('تعذر الاتصال بمساعد OURS.','Could not reach OURS AI.'));
   }
   final answer=data['answer']?.toString()??'';if(answer.isEmpty)throw Exception('Empty response');if(mounted)messages.add({'role':'assistant','content':answer});_bottom();
  }catch(e){if(mounted)messages.add({'role':'assistant','content':e.toString().replaceFirst('Exception: ','')});_bottom();}
  finally{if(mounted)setState(()=>sending=false);}
 }
 void _bottom()=>WidgetsBinding.instance.addPostFrameCallback((_){if(scroll.hasClients)scroll.animateTo(scroll.position.maxScrollExtent,duration:const Duration(milliseconds:220),curve:Curves.easeOut);});
 @override void dispose(){input.dispose();scroll.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:_navy,appBar:AppBar(backgroundColor:_navy,title:const Text('OURS AI',style:TextStyle(color:_gold,letterSpacing:2)),centerTitle:true),
  body:SafeArea(child:Column(children:[
   SwitchListTile(value:includeContext,onChanged:(v)=>setState(()=>includeContext=v),activeColor:_gold,title:Text(t('السماح باستخدام سياق المحادثة','Allow chat context')),subtitle:Text(t('مغلق افتراضيًا. تُرسل آخر الرسائل النصية فقط عند تفعيله.','Off by default. Recent text messages are shared only when enabled.'),style:const TextStyle(color:_lavender,fontSize:11))),
   Wrap(spacing:7,children:[
    ActionChip(label:Text(t('أفكار لنا','Ideas for us')),onPressed:sending?null:()=>_send(preset:t('اقترح أنشطة مناسبة لشخصين.','Suggest activities for two people.'),task:'ideas')),
    ActionChip(label:Text(t('تلخيص المحادثة','Summarize chat')),onPressed:sending||!includeContext?null:()=>_send(preset:t('لخّص آخر محادثاتنا.','Summarize our recent chat.'),task:'summary'))
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
