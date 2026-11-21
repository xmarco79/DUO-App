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
import 'package:image/image.dart' as img;
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
 _ChatSkin('rose','روز كوارتر','Rose quartz',Color(0xFF25101F),Color(0xFFB95380),Color(0xFF5D2E4D),Color(0xFFFFC7DA)),
 _ChatSkin('mint','مينت بريز','Mint breeze',Color(0xFF0B1F20),Color(0xFF218B7C),Color(0xFF184B4B),Color(0xFF9AF0D6)),
 _ChatSkin('glacier','آيس بلو','Ice blue',Color(0xFF0A1729),Color(0xFF3973B5),Color(0xFF1C3A5C),Color(0xFFA6D7FF)),
 _ChatSkin('ember','إمبر','Ember',Color(0xFF24110C),Color(0xFFB9502C),Color(0xFF63301E),Color(0xFFFFC078)),
 _ChatSkin('mono','مونوكروم','Monochrome',Color(0xFF111216),Color(0xFF4C505B),Color(0xFF282B32),Color(0xFFE3E5EA)),
 _ChatSkin('lavender','لافندر دريم','Lavender dream',Color(0xFF1C1530),Color(0xFF7857B7),Color(0xFF382A57),Color(0xFFC8B4FF)),
 _ChatSkin('candy','كاندي','Candy',Color(0xFF240F2B),Color(0xFFB44FA2),Color(0xFF532C67),Color(0xFFFFB6E7)),
];


Uint8List _processOursImage(Uint8List bytes,{required int filter,required int ratio,required double offsetX,required double offsetY,required bool hd}){
 final source=img.decodeImage(bytes);
 if(source==null)throw Exception('Unsupported image');
 const ratios=<double?>[null,1,4/5,16/9];
 final targetRatio=ratios[ratio];
 var cropW=source.width,cropH=source.height;
 if(targetRatio!=null){
  if(source.width/source.height>targetRatio){cropW=(source.height*targetRatio).round().clamp(1,source.width).toInt();}
  else{cropH=(source.width/targetRatio).round().clamp(1,source.height).toInt();}
 }
 final left=((source.width-cropW)*offsetX).round().clamp(0,source.width-cropW).toInt();
 final top=((source.height-cropH)*offsetY).round().clamp(0,source.height-cropH).toInt();
 final output=img.Image(width:cropW,height:cropH,numChannels:3);
 const profiles=<List<double>>[
  [1,1,0,0],[1.12,1.08,0,3],[.82,1.12,8,2],[1.18,1.10,-5,0],
  [.0,1.12,0,5],[1.25,1.05,4,4],[.92,1.18,-7,-3],[1.08,.92,12,5],
  [1.35,1.12,0,-4],[.72,1.06,5,7],[1.10,1.22,-3,-5],[.88,1.02,15,8],
 ];
 final profile=profiles[filter.clamp(0,profiles.length-1).toInt()];
 for(var y=0;y<cropH;y++){
  for(var x=0;x<cropW;x++){
   final p=source.getPixel(left+x,top+y);
   final r=p.r.toDouble(),g=p.g.toDouble(),b=p.b.toDouble();
   final luminance=.299*r+.587*g+.114*b;
   double transform(double value)=>((luminance+(value-luminance)*profile[0]-127.5)*profile[1]+127.5+profile[3]).clamp(0,255);
   final nr=(transform(r)+profile[2]).clamp(0,255).round();
   final ng=transform(g).clamp(0,255).round();
   final nb=(transform(b)-profile[2]).clamp(0,255).round();
   output.setPixelRgb(x,y,nr,ng,nb);
  }
 }
 return Uint8List.fromList(img.encodeJpg(output,quality:hd?98:86));
}

String _oursDate(DateTime date,bool arabic,{bool withYear=true}){
 const months=['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
 if(arabic)return '${date.day} ${months[date.month-1]}${withYear?' ${date.year}':''}';
 return DateFormat(withYear?'MMM d, y':'MMM d').format(date);
}

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
   case 'rose':
    for(var i=0;i<9;i++){final x=size.width*((i*113)%997)/997,y=size.height*((i*191)%991)/991;canvas.drawCircle(Offset(x,y),18+(i%3)*9,Paint()..color=accent.withValues(alpha:.035));}
    for(var i=0;i<4;i++){canvas.drawOval(Rect.fromCenter(center:Offset(size.width*.72,size.height*.24),width:size.width*(.22+i*.08),height:size.height*(.09+i*.05)),line);}
    break;
   case 'mint':
    for(var i=0;i<14;i++){final x=size.width*((i*67)%997)/997,y=size.height*((i*131)%991)/991;canvas.save();canvas.translate(x,y);canvas.rotate((i%5)*.45);canvas.drawOval(Rect.fromCenter(center:Offset.zero,width:12+(i%3)*5,height:30+(i%4)*6),soft);canvas.restore();}
    break;
   case 'glacier':
    for(var i=0;i<6;i++){final path=Path()..moveTo(0,size.height*(.18+i*.13))..cubicTo(size.width*.25,size.height*(.02+i*.13),size.width*.7,size.height*(.34+i*.08),size.width,size.height*(.14+i*.12));canvas.drawPath(path,line);}
    break;
   case 'ember':
    for(var i=0;i<6;i++){canvas.drawCircle(Offset(size.width*.78,size.height*.23),size.width*(.08+i*.055),Paint()..color=accent.withValues(alpha:.045)..style=PaintingStyle.stroke..strokeWidth=2);}
    break;
   case 'mono':
    for(var x=0.0;x<size.width;x+=38.0){canvas.drawLine(Offset(x,0),Offset(x,size.height),line);}
    for(var y=0.0;y<size.height;y+=38.0){canvas.drawLine(Offset(0,y),Offset(size.width,y),line);}
    break;
   case 'lavender':
    for(var i=0;i<7;i++){canvas.drawOval(Rect.fromCenter(center:Offset(size.width*.34,size.height*.44),width:size.width*(.25+i*.09),height:size.height*(.12+i*.06)),line);}
    break;
   case 'candy':
    for(var i=0;i<7;i++){final x=size.width*((i*139)%997)/997,y=size.height*((i*83)%991)/991;canvas.drawCircle(Offset(x,y),20+(i%3)*12,soft);}
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
 RealtimeChannel? channel,liveChannel;AudioRecorder? recorder;String? recordingPath;
 Timer? typingTimer;bool typingSent=false,partnerOnline=false,partnerTyping=false;DateTime? partnerLastSeen;String? highlightedMessageId;
 bool loading=true,sending=false,recording=false,uploading=false,downloading=false;double? downloadProgress;String? localPartnerName,wallpaperPath;double wallpaperOpacity=.22,wallpaperDim=.34,wallpaperBlur=0;_ChatSkin skin=_skins.first;
 bool get ar=>Localizations.localeOf(context).languageCode=='ar';
 String t(String a,String e)=>ar?a:e;String get uid=>db.auth.currentUser!.id;
 int _streakCount(){
  final participantsByDay=<DateTime,Set<String>>{};
  for(final message in messages){
   final body=(message['body']??'').toString().trim();
   final type=(message['message_type']??'text').toString();
   final sender=message['sender_id']?.toString()??'';
   final date=DateTime.tryParse(message['created_at']?.toString()??'')?.toLocal();
   if(date==null||sender.isEmpty||body.isEmpty||!const ['text','image','video','audio','file','sticker','view_once','view_twice'].contains(type))continue;
   final day=DateTime(date.year,date.month,date.day);
   participantsByDay.putIfAbsent(day,()=>{}).add(sender);
  }
  final activeDays=participantsByDay.entries.where((entry)=>entry.value.length>=2).map((entry)=>entry.key).toSet();
  if(activeDays.isEmpty)return 0;
  final today=DateTime.now(),current=DateTime(today.year,today.month,today.day);
  final latest=activeDays.reduce((a,b)=>a.isAfter(b)?a:b);
  if(latest.isBefore(current.subtract(const Duration(days:1))))return 0;
  var count=0,day=latest;
  while(activeDays.contains(day)){count++;day=day.subtract(const Duration(days:1));}
  return count>=3?count:0;
 }
 int _streakStage(){
  final count=_streakCount();
  if(count>=100)return 6;if(count>=60)return 5;if(count>=30)return 4;
  if(count>=14)return 3;if(count>=7)return 2;if(count>=3)return 1;return 0;
 }
 String _streakStageName(){
  switch(_streakStage()){
   case 6:return t('أسطورة OURS','OURS Legend');
   case 5:return t('أفق مشترك','Shared Horizon');
   case 4:return t('مدار ثابت','Steady Orbit');
   case 3:return t('وهج متنامٍ','Growing Glow');
   case 2:return t('نبض متواصل','Steady Pulse');
   case 1:return t('بداية الحكاية','The Beginning');
   default:return '';
  }
 }
 @override void initState(){super.initState();localPartnerName=widget.partnerName;_loadSkin();_load();_listen();_startLiveStatus();}
 Future<void> _changeLocalNickname() async{
  final prefs=await SharedPreferences.getInstance();final key='ours_partner_alias_${uid}_${widget.partnerId}';
  final controller=TextEditingController(text:prefs.getString(key)??widget.partnerName);
  final value=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:skin.bg,title:Text(t('اسم الطرف الآخر عندك','Your private nickname')),content:TextField(controller:controller,maxLength:24,decoration:InputDecoration(hintText:t('اسم يظهر لك فقط','Only visible to you'))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('إلغاء','Cancel'))),TextButton(onPressed:()=>Navigator.pop(ctx,controller.text.trim()),child:Text(t('حفظ','Save')))]));
  controller.dispose();if(value==null)return;if(value.isEmpty)await prefs.remove(key);else await prefs.setString(key,value);
  if(mounted)setState(()=>localPartnerName=value.isEmpty?widget.partnerName:value);
 }
 Future<void> _loadSkin() async{
  final p=await SharedPreferences.getInstance();final id=p.getString('ours_direct_skin_'+widget.conversationId)??'ours';
  final found=_skins.where((s)=>s.id==id);
  final savedWallpaper=p.getString('ours_direct_wallpaper_'+widget.conversationId);
  final savedOpacity=p.getDouble('ours_direct_wallpaper_opacity_'+widget.conversationId)??.22;
  final savedDim=p.getDouble('ours_direct_wallpaper_dim_'+widget.conversationId)??.34;
  final savedBlur=p.getDouble('ours_direct_wallpaper_blur_'+widget.conversationId)??0;
  if(mounted)setState((){skin=found.isEmpty?_skins.first:found.first;wallpaperPath=savedWallpaper;wallpaperOpacity=savedOpacity.clamp(.08,.85).toDouble();wallpaperDim=savedDim.clamp(0,.75).toDouble();wallpaperBlur=savedBlur.clamp(0,12).toDouble();});
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
          Positioned(left:10,top:10,child:Container(width:50,height:15,decoration:BoxDecoration(color:item.mine,borderRadius:BorderRadius.circular(9)))),
          Positioned(right:10,top:30,child:Container(width:62,height:15,decoration:BoxDecoration(color:item.partner,borderRadius:BorderRadius.circular(9),border:Border.all(color:item.accent.withValues(alpha:.45))))),
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
 Future<void> _startLiveStatus() async{
  try{
   await db.rpc('touch_ours_presence');
   await _loadPartnerLastSeen();
   final liveTopic=widget.spaceId!=null?'duo-space:${widget.spaceId}:live':'ours-direct:${widget.conversationId}:live';
   liveChannel=db.channel(liveTopic,opts:const RealtimeChannelConfig(private:true));
   liveChannel!
    .onPresenceSync((_){
     final state=liveChannel?.presenceState()??<SinglePresenceState>[];
     final online=state.any((client)=>client.presences.any((presence)=>presence.payload['user_id']?.toString()==widget.partnerId));
     if(mounted)setState(()=>partnerOnline=online);
     if(!online)_loadPartnerLastSeen();
    })
    .onBroadcast(event:'typing',callback:(payload){
     final raw=payload['payload']??payload;
     final data=raw is Map?Map<String,dynamic>.from(raw):<String,dynamic>{};
     if(data['user_id']?.toString()==widget.partnerId&&mounted)setState(()=>partnerTyping=data['typing']==true);
    })
    .subscribe((status,error)async{
     if(status==RealtimeSubscribeStatus.subscribed){
      await liveChannel?.track({'user_id':uid,'online_at':DateTime.now().toIso8601String()});
      await db.rpc('touch_ours_presence');
     }
    });
  }catch(_){}
 }
 Future<void> _loadPartnerLastSeen() async{
  try{
   final profile=await db.from('duo_profiles').select('last_seen_at').eq('user_id',widget.partnerId).maybeSingle();
   final seen=DateTime.tryParse(profile?['last_seen_at']?.toString()??'')?.toLocal();
   if(mounted)setState(()=>partnerLastSeen=seen);
  }catch(_){}
 }
 void _handleTyping(String value){
  final live=liveChannel;if(live==null)return;
  if(value.trim().isNotEmpty&&!typingSent){
   typingSent=true;
   unawaited(live.sendBroadcastMessage(event:'typing',payload:{'user_id':uid,'typing':true}).then<void>((_){}));
  }
  typingTimer?.cancel();
  typingTimer=Timer(const Duration(milliseconds:1300),(){
   typingSent=false;
   unawaited(live.sendBroadcastMessage(event:'typing',payload:{'user_id':uid,'typing':false}).then<void>((_){}));
  });
 }
 String _readReceipt(dynamic value){
  final raw=value?.toString();
  if(raw==null||raw.isEmpty)return t('تم الإرسال','Sent');
  final seen=DateTime.tryParse(raw)?.toLocal();
  if(seen==null)return t('تمت المشاهدة','Seen');
  final minutes=DateTime.now().difference(seen).inMinutes;
  if(minutes<=0)return t('مقروءة الآن','Seen just now');
  if(minutes==1)return t('مقروءة منذ دقيقة','Seen 1 minute ago');
  if(minutes<60)return t('مقروءة منذ ${minutes} دقيقة','Seen ${minutes} minutes ago');
  final hours=minutes~/60;
  if(hours==1)return t('مقروءة منذ ساعة','Seen 1 hour ago');
  if(hours<24)return t('مقروءة منذ ${hours} ساعة','Seen ${hours} hours ago');
  return t('تمت المشاهدة ${_oursDate(seen,true,withYear:false)}','Seen ${_oursDate(seen,false,withYear:false)}');
 }
 String _presenceLabel(){
  if(partnerTyping)return t('يكتب الآن…','Typing…');
  if(partnerOnline)return t('متصل الآن','Online now');
  if(partnerLastSeen==null)return t('غير متصل','Offline');
  final now=DateTime.now(),seen=partnerLastSeen!;
  final elapsed=now.difference(seen);
  if(elapsed.inMinutes<1)return t('آخر ظهور للتو','Last seen just now');
  if(elapsed.inMinutes<60)return t('آخر ظهور منذ ${elapsed.inMinutes} دقيقة','Last seen ${elapsed.inMinutes}m ago');
  if(elapsed.inHours<24)return t('آخر ظهور منذ ${elapsed.inHours} ساعة','Last seen ${elapsed.inHours}h ago');
  return t('آخر ظهور ${_oursDate(seen,true,withYear:false)}','Last seen ${_oursDate(seen,false,withYear:false)}');
 }
 Future<void> _chooseWallpaper() async{
  var opacity=wallpaperOpacity,dim=wallpaperDim,blur=wallpaperBlur;
  final action=await showModalBottomSheet<String>(context:context,isScrollControlled:true,backgroundColor:const Color(0xFF171326),showDragHandle:true,builder:(ctx)=>StatefulBuilder(builder:(ctx,setModal)=>SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(18,8,18,20),child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
   Row(children:[Icon(Icons.wallpaper_rounded,color:skin.accent,size:23),const SizedBox(width:9),Text(t('استوديو خلفية المحادثة','Chat wallpaper studio'),style:const TextStyle(color:_gold,fontSize:18,fontWeight:FontWeight.w900))]),
   const SizedBox(height:6),Text(t('خصص الصورة ووازنها مع ألوان الثيم دون أن تطغى على الرسائل.','Fine-tune the image and balance it with your theme without overpowering messages.'),style:const TextStyle(color:_lavender,fontSize:12,height:1.5)),
   const SizedBox(height:14),
   Container(height:104,width:double.infinity,clipBehavior:Clip.antiAlias,decoration:BoxDecoration(borderRadius:BorderRadius.circular(17),border:Border.all(color:skin.accent.withValues(alpha:.3))),child:Stack(fit:StackFit.expand,children:[
    CustomPaint(painter:_ChatAtmospherePainter(skin)),
    if(wallpaperPath!=null)Opacity(opacity:opacity,child:Image.file(File(wallpaperPath!),fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox.shrink())),
    ColoredBox(color:skin.bg.withValues(alpha:dim)),
    Align(alignment:Alignment.centerRight,child:Container(margin:const EdgeInsets.all(10),padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),decoration:BoxDecoration(color:skin.mine,borderRadius:BorderRadius.circular(14)),child:Text(t('معاينة الرسائل','Message preview'),style:const TextStyle(color:Colors.white,fontSize:12))))
   ])),
   const SizedBox(height:12),
   _wallpaperSliderLabel(t('وضوح الصورة','Image visibility'),opacity),
   Slider(value:opacity.clamp(.08,.85),min:.08,max:.85,onChanged:(v)=>setModal(()=>opacity=v),activeColor:skin.accent),
   _wallpaperSliderLabel(t('تعتيم متناسق مع الثيم','Theme blending'),dim),
   Slider(value:dim.clamp(0,.75),min:0,max:.75,onChanged:(v)=>setModal(()=>dim=v),activeColor:skin.accent),
   _wallpaperSliderLabel(t('تمويه الخلفية','Background blur'),blur,percent:false),
   Slider(value:blur.clamp(0,12),min:0,max:12,onChanged:(v)=>setModal(()=>blur=v),activeColor:skin.accent),
   const SizedBox(height:8),
   Wrap(spacing:8,runSpacing:8,children:[
    OutlinedButton.icon(onPressed:()=>Navigator.pop(ctx,'clear'),icon:const Icon(Icons.layers_clear_outlined),label:Text(t('إزالة الصورة','Remove image'))),
    OutlinedButton.icon(onPressed:()=>Navigator.pop(ctx,'save'),icon:const Icon(Icons.tune_rounded),label:Text(t('تطبيق الإعدادات','Apply settings'))),
    FilledButton.icon(onPressed:()=>Navigator.pop(ctx,'choose'),icon:const Icon(Icons.photo_library_outlined),label:Text(t('اختيار صورة','Choose image')))
   ])
  ])))));
  if(action==null)return;
  final prefs=await SharedPreferences.getInstance();
  Future<void> saveSettings()async{
   await prefs.setDouble('ours_direct_wallpaper_opacity_'+widget.conversationId,opacity);
   await prefs.setDouble('ours_direct_wallpaper_dim_'+widget.conversationId,dim);
   await prefs.setDouble('ours_direct_wallpaper_blur_'+widget.conversationId,blur);
   if(mounted)setState(() {wallpaperOpacity=opacity;wallpaperDim=dim;wallpaperBlur=blur;});
  }
  if(action=='clear'){
   final old=wallpaperPath;await prefs.remove('ours_direct_wallpaper_'+widget.conversationId);
   if(mounted)setState(()=>wallpaperPath=null);
   if(old!=null){try{final file=File(old);if(await file.exists())await file.delete();}catch(_){}}
   await saveSettings();
  }else if(action=='save'){await saveSettings();}
  else if(action=='choose'){
   try{
    final picked=await picker.pickImage(source:ImageSource.gallery,imageQuality:96,maxWidth:3200,maxHeight:3200);if(picked==null)return;
    final dir=await getApplicationDocumentsDirectory();
    final target=File('${dir.path}/ours_chat_wallpaper_${widget.conversationId}.jpg');
    await File(picked.path).copy(target.path);
    await prefs.setString('ours_direct_wallpaper_'+widget.conversationId,target.path);
    await saveSettings();
    if(mounted)setState(()=>wallpaperPath=target.path);
   }catch(e){_show(t('تعذر تطبيق الخلفية. حاول اختيار صورة أخرى.','Could not apply wallpaper. Try another image.'));}
  }
 }
 Widget _wallpaperSliderLabel(String label,double value,{bool percent=true})=>Row(children:[Expanded(child:Text(label,style:TextStyle(color:skin.accent,fontWeight:FontWeight.w700,fontSize:12))),Text(percent?'${(value*100).round()}%':'${value.toStringAsFixed(1)}',style:TextStyle(color:skin.accent,fontFeatures:const [ui.FontFeature.tabularFigures()]))]);
 Future<void> _load() async{
  try{
   final hidden=await db.from('ours_direct_message_hides').select('message_id').eq('user_id',uid);
   hiddenIds..clear()..addAll(hidden.map((r)=>r['message_id'].toString()));
   final rows=await db.from('duo_direct_messages').select().eq('conversation_id',widget.conversationId).order('created_at');
   if(!mounted)return;setState((){messages..clear()..addAll(List<Map<String,dynamic>>.from(rows).where((m)=>!hiddenIds.contains(m['id'].toString())));loading=false;});
   await db.rpc('mark_ours_direct_messages_read',params:{'p_conversation_id':widget.conversationId});
   _bottom();
  }catch(e){if(mounted){setState(()=>loading=false);_show(t('تعذر تحميل المحادثة. تحقق من الاتصال وحاول مجددًا.','Could not load conversation. Check your connection and try again.'));}}
 }
 void _listen(){
  final filter=PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'conversation_id',value:widget.conversationId);
  channel=db.channel('ours-direct-'+widget.conversationId)
   .onPostgresChanges(event:PostgresChangeEvent.insert,schema:'public',table:'duo_direct_messages',filter:filter,callback:(p){
    final row=Map<String,dynamic>.from(p.newRecord);if(!mounted||hiddenIds.contains(row['id'].toString())||messages.any((m)=>m['id']==row['id']))return;setState(()=>messages.add(row));_bottom();
    if(row['sender_id']?.toString()!=uid){db.rpc('mark_ours_direct_messages_read',params:{'p_conversation_id':widget.conversationId});}
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
  const types={'jpg':'image/jpeg','jpeg':'image/jpeg','png':'image/png','webp':'image/webp','gif':'image/gif','m4a':'audio/mp4','aac':'audio/aac','mp3':'audio/mpeg','ogg':'audio/ogg','mp4':'video/mp4','mov':'video/quicktime','webm':'video/webm','pdf':'application/pdf','txt':'text/plain','csv':'text/csv','doc':'application/msword','docx':'application/vnd.openxmlformats-officedocument.wordprocessingml.document','xls':'application/vnd.ms-excel','xlsx':'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','ppt':'application/vnd.ms-powerpoint','pptx':'application/vnd.openxmlformats-officedocument.presentationml.presentation','zip':'application/zip'};
  return types[name.split('.').last.toLowerCase()]??'';
 }
 Future<void> _upload(Uint8List bytes,String name,String type,{int? maxViews}) async{
  if(bytes.isEmpty)return;if(bytes.length>20*1024*1024){_show(t('الحد الأقصى 20 ميجابايت','Maximum size is 20 MB'));return;}
  final mime=_mime(name);if(mime.isEmpty){_show(t('نوع الملف غير مدعوم','Unsupported file type'));return;}setState(()=>uploading=true);
  final safe=name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'),'_');
  final path=widget.conversationId+'/'+uid+'/'+DateTime.now().microsecondsSinceEpoch.toString()+'_'+safe;
  try{
   await db.storage.from(_bucket).uploadBinary(path,bytes,fileOptions:FileOptions(contentType:mime,upsert:false,cacheControl:'3600'));
   try{await db.from('duo_direct_messages').insert({'conversation_id':widget.conversationId,'sender_id':uid,'body':path,'message_type':type,'max_views':maxViews??1,'file_name':name,'file_size':bytes.length,'mime_type':mime});}
   catch(_){await db.storage.from(_bucket).remove([path]);rethrow;}
  }catch(e){_show(t('تعذر رفع المرفق. تحقق من الاتصال.','Could not upload the attachment. Check your connection.'));}finally{if(mounted)setState(()=>uploading=false);}
 }
 Future<Map<String,dynamic>?> _previewMedia({required Uint8List bytes,required String name}) async{
  const filterNames=['Original','Luminous','Warm','Cinematic','Mono','Golden','Cool','Vintage','Vivid','Soft','Noir','Sunrise'];
  const filterNamesAr=['أصلي','مضيء','دافئ','سينمائي','أحادي','ذهبي','بارد','قديم','حيوي','ناعم','داكن','شروق'];
  var filter=0,ratio=0,offsetX=.5,offsetY=.5,hd=true,mode='normal';
  Uint8List edited=bytes;
  void refresh(){edited=_processOursImage(bytes,filter:filter,ratio:ratio,offsetX:offsetX,offsetY:offsetY,hd:hd);}
  refresh();
  return await showDialog<Map<String,dynamic>>(context:context,barrierDismissible:false,builder:(ctx)=>StatefulBuilder(builder:(ctx,setModal)=>Dialog(
   backgroundColor:const Color(0xFF171326),insetPadding:const EdgeInsets.symmetric(horizontal:12,vertical:22),
   shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(25),side:BorderSide(color:skin.accent.withValues(alpha:.24))),
   child:SizedBox(width:MediaQuery.of(ctx).size.width,height:MediaQuery.of(ctx).size.height*.82,child:Padding(padding:const EdgeInsets.fromLTRB(15,14,15,12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Icon(Icons.tune_rounded,color:skin.accent,size:22),const SizedBox(width:8),Expanded(child:Text(t('استوديو تعديل الصورة','Photo edit studio'),style:const TextStyle(color:_gold,fontWeight:FontWeight.w900,fontSize:17))),IconButton(onPressed:()=>Navigator.pop(ctx),icon:const Icon(Icons.close,color:_lavender))]),
    Text(name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:_lavender,fontSize:10)),
    const SizedBox(height:10),
    Expanded(child:Center(child:ClipRRect(borderRadius:BorderRadius.circular(17),child:Image.memory(edited,fit:BoxFit.contain,width:double.infinity)))),
    const SizedBox(height:10),
    Row(children:[Text(t('الفلاتر الاحترافية','Pro filters'),style:TextStyle(color:skin.accent,fontSize:12,fontWeight:FontWeight.w800)),const Spacer(),Text('${filter+1}/12',style:TextStyle(color:skin.accent,fontSize:10))]),
    const SizedBox(height:7),
    SizedBox(height:54,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:12,separatorBuilder:(_,__)=>const SizedBox(width:7),itemBuilder:(c,i)=>ChoiceChip(label:Text(ar?filterNamesAr[i]:filterNames[i]),selected:filter==i,onSelected:(_)=>setModal(() {filter=i;refresh();}),selectedColor:skin.accent.withValues(alpha:.24),labelStyle:TextStyle(color:filter==i?Colors.white:_lavender,fontSize:10),side:BorderSide(color:skin.accent.withValues(alpha:filter==i ? .7 : .2))))),
    const SizedBox(height:8),
    Row(children:[Text(t('القص ونسبة الأبعاد','Crop & aspect ratio'),style:TextStyle(color:skin.accent,fontSize:12,fontWeight:FontWeight.w800)),const Spacer(),Switch(value:hd,activeColor:skin.accent,onChanged:(v)=>setModal(() {hd=v;refresh();}),materialTapTargetSize:MaterialTapTargetSize.shrinkWrap),Text('HD',style:TextStyle(color:skin.accent,fontWeight:FontWeight.w900))]),
    Wrap(spacing:6,runSpacing:4,children:[
     for(var i=0;i<4;i++)ChoiceChip(label:Text([t('أصلية','Original'), '1:1','4:5','16:9'][i]),selected:ratio==i,onSelected:(_)=>setModal(() {ratio=i;refresh();}),selectedColor:skin.accent.withValues(alpha:.24),labelStyle:TextStyle(color:ratio==i?Colors.white:_lavender,fontSize:10))
    ]),
    if(ratio!=0)Row(children:[
     Expanded(child:Slider(value:offsetX,min:0,max:1,onChanged:(v)=>setModal(() {offsetX=v;refresh();}),activeColor:skin.accent)),
     Expanded(child:Slider(value:offsetY,min:0,max:1,onChanged:(v)=>setModal(() {offsetY=v;refresh();}),activeColor:skin.accent)),
    ]),
    if(mode=='normal')Wrap(spacing:5,children:[
     ChoiceChip(label:Text(t('عادية','Normal')),selected:mode=='normal',onSelected:(_)=>setModal(() {mode='normal';})),
     ChoiceChip(label:Text(t('مرة واحدة','Once')),selected:mode=='once',onSelected:(_)=>setModal(() {mode='once';})),
     ChoiceChip(label:Text(t('مرتين','Twice')),selected:mode=='twice',onSelected:(_)=>setModal(() {mode='twice';})),
    ]) else Wrap(spacing:5,children:[
     ChoiceChip(label:Text(t('عادية','Normal')),selected:mode=='normal',onSelected:(_)=>setModal(() {mode='normal';})),
     ChoiceChip(label:Text(t('مرة واحدة','Once')),selected:mode=='once',onSelected:(_)=>setModal(() {mode='once';})),
     ChoiceChip(label:Text(t('مرتين','Twice')),selected:mode=='twice',onSelected:(_)=>setModal(() {mode='twice';})),
    ]),
    const SizedBox(height:8),
    Row(children:[
     Expanded(child:OutlinedButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('إلغاء','Cancel')))),
     const SizedBox(width:9),
     Expanded(child:FilledButton(onPressed:()=>Navigator.pop(ctx,{'bytes':edited,'mode':mode}),child:Text(t('اعتماد وإرسال','Apply & send'))))
    ])
   ]))),
  )));
 }
 Future<void> _pickImageWithMode() async{
  try{
   final f=await picker.pickImage(source:ImageSource.gallery,imageQuality:100,maxWidth:4096,maxHeight:4096);if(f==null)return;
   final bytes=await f.readAsBytes();final edited=await _previewMedia(bytes:bytes,name:f.name);if(edited==null)return;
   final mode=edited['mode'] as String;final output=edited['bytes'] as Uint8List;
   final name='ours_photo_'+DateTime.now().millisecondsSinceEpoch.toString()+'.jpg';
   await _upload(output,name,mode=='normal'?'image':mode=='once'?'view_once':'view_twice',maxViews:mode=='twice'?2:1);
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
  Future<String> _signedSticker(String path){
   if(widget.spaceId!=null&&path.startsWith('${widget.spaceId}/'))return db.storage.from('ours-stickers').createSignedUrl(path,900);
   return _signed(path);
  }
  Future<void> _createSharedSticker()async{
   if(widget.spaceId==null){_show(t('تعذر تحديد مساحتكما','Could not find your shared space'));return;}
   try{
    final result=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['png','jpg','jpeg','webp','gif'],withData:true);
    if(result==null||result.files.isEmpty)return;
    final file=result.files.single,bytes=file.bytes??(file.path==null?null:await File(file.path!).readAsBytes());
    if(bytes==null)throw Exception('Sticker data unavailable');
    final controller=TextEditingController(text:t('ملصقاتنا','OURS'));
    final pack=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:skin.bg,title:Text(t('إضافة إلى حزمة','Add to a pack')),content:TextField(controller:controller,maxLength:32,decoration:InputDecoration(labelText:t('اسم الحزمة','Pack name'))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('إلغاء','Cancel'))),FilledButton(onPressed:()=>Navigator.pop(ctx,controller.text.trim()),child:Text(t('إضافة','Add')))]));
    controller.dispose();if(pack==null||pack.isEmpty)return;
    final mime=_mime(file.name);if(mime.isEmpty)throw Exception('Unsupported image type');
    final safe=file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'),'_');
    final path='${widget.spaceId}/${uid}/${DateTime.now().microsecondsSinceEpoch}_${safe}';
    await db.storage.from('ours-stickers').uploadBinary(path,bytes,fileOptions:FileOptions(contentType:mime,upsert:false,cacheControl:'3600'));
    try{
     await db.from('duo_stickers').insert({'space_id':widget.spaceId,'created_by':uid,'sticker_type':'image','content':'OURS sticker','storage_path':path,'pack_name':pack,'display_name':file.name,'is_animated':file.name.toLowerCase().endsWith('.gif')});
     _show(t('تمت إضافة الملصق إلى الحزمة','Sticker added to the pack'));
    }catch(_){await db.storage.from('ours-stickers').remove([path]);rethrow;}
   }catch(e){_show(t('تعذر إضافة الملصق: $e','Could not add sticker: $e'));}
  }
  Future<void> _sendSticker() async{
   if(widget.spaceId==null){
    final recent=messages.where((m)=>m['message_type']=='sticker'&&(m['body']??'').toString().isNotEmpty&&m['body']!='[viewed]').toList().reversed.toList();
    final chosen=await showModalBottomSheet<String>(context:context,backgroundColor:skin.bg,showDragHandle:true,builder:(ctx)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
     ListTile(leading:Icon(Icons.add_photo_alternate_outlined,color:skin.accent),title:Text(t('إضافة ملصق','Add sticker')),onTap:()=>Navigator.pop(ctx,'__add__')),
     ...recent.map((m)=>ListTile(leading:Icon(Icons.sticky_note_2_outlined,color:skin.accent),title:Text((m['file_name']??m['body']).toString()),onTap:()=>Navigator.pop(ctx,m['body'].toString())))
    ])));
    if(chosen==null)return;if(chosen=='__add__'){await _uploadSelfStickerFallback();return;}
    await db.from('duo_direct_messages').insert({'conversation_id':widget.conversationId,'sender_id':uid,'body':chosen,'message_type':'sticker'});return;
   }
   List<Map<String,dynamic>> stickers=[];final favorites=<String>{};
   try{
    final data=await db.from('duo_stickers').select('id,pack_name,display_name,storage_path,is_animated,created_at').eq('space_id',widget.spaceId!).order('created_at',ascending:false);
    stickers=List<Map<String,dynamic>>.from(data);
    final fav=await db.from('duo_sticker_favorites').select('sticker_id').eq('user_id',uid);
    favorites.addAll(List<Map<String,dynamic>>.from(fav).map((x)=>x['sticker_id'].toString()));
   }catch(e){_show(t('تعذر تحميل مكتبة الملصقات','Could not load sticker library'));return;}
   var selectedPack='all';
   final packs=<String>{'all','favorites',...stickers.map((x)=>(x['pack_name']??'OURS').toString())}.toList();
   final chosen=await showModalBottomSheet<String>(context:context,backgroundColor:skin.bg,showDragHandle:true,isScrollControlled:true,builder:(ctx)=>StatefulBuilder(builder:(ctx,setModal){
    final visible=stickers.where((x)=>selectedPack=='all'||(selectedPack=='favorites'?favorites.contains(x['id'].toString()):(x['pack_name']??'OURS').toString()==selectedPack)).toList();
    return SafeArea(child:SizedBox(height:MediaQuery.of(ctx).size.height*.72,child:Column(children:[
     Padding(padding:const EdgeInsets.fromLTRB(14,12,14,6),child:Row(children:[Expanded(child:Text(t('مكتبة ملصقات OURS','OURS Sticker Library'),style:TextStyle(color:skin.accent,fontSize:17,fontWeight:FontWeight.w900))),IconButton(onPressed:()=>Navigator.pop(ctx,'__add__'),icon:Icon(Icons.add_photo_alternate_outlined,color:skin.accent))])),
     SizedBox(height:42,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:12),children:packs.map((pack)=>Padding(padding:const EdgeInsetsDirectional.only(end:7),child:ChoiceChip(label:Text(pack=='all'?t('الكل','All'):pack=='favorites'?t('المفضلة','Favorites'):pack),selected:selectedPack==pack,onSelected:(_)=>setModal(()=>selectedPack=pack),selectedColor:skin.accent,backgroundColor:skin.partner,labelStyle:TextStyle(color:selectedPack==pack?skin.bg:Colors.white,fontSize:11)))).toList())),
     Expanded(child:visible.isEmpty?Center(child:Text(t('لا توجد ملصقات في هذه الحزمة بعد','No stickers in this pack yet'),style:TextStyle(color:skin.accent))):GridView.builder(padding:const EdgeInsets.all(12),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,childAspectRatio:.82,crossAxisSpacing:9,mainAxisSpacing:9),itemCount:visible.length,itemBuilder:(ctx,i){
      final item=visible[i],id=item['id'].toString(),path=item['storage_path'].toString(),name=(item['display_name']??'OURS').toString(),favorite=favorites.contains(id);
      return Container(decoration:BoxDecoration(color:skin.partner,borderRadius:BorderRadius.circular(15),border:Border.all(color:skin.accent.withValues(alpha:.18))),child:Stack(children:[
       Positioned.fill(child:InkWell(borderRadius:BorderRadius.circular(15),onTap:()=>Navigator.pop(ctx,'send:$id'),child:Padding(padding:const EdgeInsets.fromLTRB(6,8,6,28),child:FutureBuilder<String>(future:_signedSticker(path),builder:(c,s)=>s.hasData?Image.network(s.data!,fit:BoxFit.contain,errorBuilder:(_,__,___)=>Icon(Icons.broken_image_outlined,color:skin.accent)):Center(child:CircularProgressIndicator(color:skin.accent,strokeWidth:2)))))),
       Positioned(left:3,right:3,bottom:3,child:Text(name,maxLines:1,overflow:TextOverflow.ellipsis,textAlign:TextAlign.center,style:TextStyle(color:skin.accent,fontSize:9))),
       Positioned(top:0,right:0,child:IconButton(padding:EdgeInsets.zero,constraints:const BoxConstraints.tightFor(width:28,height:28),onPressed:()async{
        try{if(favorite){await db.from('duo_sticker_favorites').delete().eq('sticker_id',id).eq('user_id',uid);setModal((){favorites.remove(id);});}else{await db.from('duo_sticker_favorites').insert({'sticker_id':id,'user_id':uid});setModal((){favorites.add(id);});}}catch(_){_show(t('تعذر تحديث المفضلة','Could not update favorites'));}
       },icon:Icon(favorite?Icons.star_rounded:Icons.star_border_rounded,color:favorite?const Color(0xFFFFD66B):skin.accent,size:18)))
      ]));
     }))
    ])));
   }));
   if(chosen==null)return;
   if(chosen=='__add__'){await _createSharedSticker();return;}
   if(chosen.startsWith('send:')){
    final id=chosen.substring(5),sticker=stickers.firstWhere((x)=>x['id'].toString()==id);
    try{await db.from('duo_direct_messages').insert({'conversation_id':widget.conversationId,'sender_id':uid,'body':sticker['storage_path'],'message_type':'sticker','file_name':sticker['display_name'],'mime_type':sticker['is_animated']==true?'image/gif':'image/png'});}
    catch(e){_show(t('تعذر إرسال الملصق: $e','Could not send sticker: $e'));}
   }
  }
  Future<void> _uploadSelfStickerFallback()async{
   try{final result=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['png','jpg','jpeg','webp','gif'],withData:true);if(result==null||result.files.isEmpty)return;final file=result.files.single,bytes=file.bytes??(file.path==null?null:await File(file.path!).readAsBytes());if(bytes==null)return;await _upload(bytes,'sticker_'+DateTime.now().millisecondsSinceEpoch.toString()+'.'+file.name.split('.').last.toLowerCase(),'sticker');}
   catch(e){_show(t('تعذر إضافة الملصق: $e','Could not add sticker: $e'));}
  }
 Future<void> _consumeTemporaryMedia(String messageId) async{
  try{
   final path=await db.rpc('consume_ours_temporary_media',params:{'p_message_id':messageId}) as String?;
   if(path==null||path.isEmpty){_show(t('انتهت مرات مشاهدة هذه الصورة','This photo has no views left'));await _load();return;}
   final url=await _signed(path);
   await showDialog<void>(context:context,barrierColor:Colors.black,builder:(ctx)=>Dialog(backgroundColor:Colors.black,insetPadding:EdgeInsets.zero,child:SizedBox.expand(child:SafeArea(child:Column(children:[
    Padding(padding:const EdgeInsets.all(12),child:Text(t('صورة مؤقتة','Temporary photo'),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700))),
    Expanded(child:Center(child:InteractiveViewer(minScale:.5,maxScale:4,child:Image.network(url,fit:BoxFit.contain)))),
    Padding(padding:const EdgeInsets.all(14),child:TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('إغلاق','Close'),style:const TextStyle(color:Colors.white))))
   ])))));
   final row=await db.from('duo_direct_messages').select('view_count,max_views').eq('id',messageId).maybeSingle();
   final count=(row?['view_count'] as num?)?.toInt()??1,limit=(row?['max_views'] as num?)?.toInt()??1;
   if(count>=limit){await db.storage.from(_bucket).remove([path]);}
   if(mounted)await _load();
  }catch(e){_show(t('تعذر فتح الصورة: $e','Could not open image: $e'));}
 }
 Future<void> _showAttachments() async{
  final choice=await showModalBottomSheet<String>(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,showDragHandle:false,builder:(ctx)=>SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(10,0,10,12),child:Container(padding:const EdgeInsets.fromLTRB(16,10,16,18),decoration:BoxDecoration(color:const Color(0xFF171326),borderRadius:BorderRadius.circular(26),border:Border.all(color:skin.accent.withValues(alpha:.22)),boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:.28),blurRadius:24,offset:const Offset(0,-5))]),child:Column(mainAxisSize:MainAxisSize.min,children:[
   Container(width:38,height:4,decoration:BoxDecoration(color:skin.accent.withValues(alpha:.42),borderRadius:BorderRadius.circular(8))),
   const SizedBox(height:14),Row(children:[Icon(Icons.add_to_photos_rounded,color:skin.accent,size:22),const SizedBox(width:9),Text(t('مشاركة المحتوى','Share something'),style:const TextStyle(color:_gold,fontSize:17,fontWeight:FontWeight.w900))]),
   const SizedBox(height:4),Align(alignment:AlignmentDirectional.centerStart,child:Text(t('اختر نوع المحتوى الذي تريد إرساله','Choose what you want to share'),style:const TextStyle(color:_lavender,fontSize:11))),
   const SizedBox(height:16),
   GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisCount:3,mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:1.02,children:[
    _attachmentTile(ctx,'media',Icons.photo_library_rounded,t('الصور','Photos'),t('المعرض','Gallery')),
    _attachmentTile(ctx,'video',Icons.movie_creation_rounded,t('فيديو','Video'),t('مقاطعك','Clips')),
    _attachmentTile(ctx,'file',Icons.folder_zip_rounded,t('ملفات','Files'),t('مستندات','Documents')),
    _attachmentTile(ctx,'sticker',Icons.auto_awesome_rounded,t('ملصقات','Stickers'),t('حزم OURS','OURS packs')),
   ])
  ])))));
  if(choice==null)return;
  switch(choice){case 'media':await _pickMedia();break;case 'video':await _pickVideo();break;case 'file':await _pickFile();break;case 'sticker':await _sendSticker();break;}
 }
 Widget _attachmentTile(BuildContext ctx,String value,IconData icon,String title,String subtitle){
  return Material(color:skin.partner.withValues(alpha:.82),borderRadius:BorderRadius.circular(17),child:InkWell(borderRadius:BorderRadius.circular(17),onTap:()=>Navigator.pop(ctx,value),child:Container(padding:const EdgeInsets.symmetric(horizontal:5,vertical:10),decoration:BoxDecoration(borderRadius:BorderRadius.circular(17),border:Border.all(color:skin.accent.withValues(alpha:.16))),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
   Container(width:42,height:42,decoration:BoxDecoration(gradient:LinearGradient(colors:[skin.accent.withValues(alpha:.24),skin.accent.withValues(alpha:.07)]),shape:BoxShape.circle),child:Icon(icon,color:skin.accent,size:22)),
   const SizedBox(height:7),Text(title,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:11)),
   const SizedBox(height:2),Text(subtitle,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:skin.accent,fontSize:9))
  ]))));
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
 Future<void> _downloadFile(String path,{String? name})async{
  HttpClient? client;
  try{
   final url=await _signed(path);client=HttpClient();
   final request=await client.getUrl(Uri.parse(url));final response=await request.close();
   if(response.statusCode<200||response.statusCode>=300)throw Exception('Download failed');
   final total=response.contentLength;var received=0;final bytes=BytesBuilder(copy:false);
   if(mounted)setState((){downloadProgress=total>0?0.0:null;downloading=true;});
   await for(final chunk in response){
    bytes.add(chunk);received+=chunk.length;
    if(mounted)setState(()=>downloadProgress=total>0?(received/total).clamp(0.0,1.0):null);
   }
   final saved=await FilePicker.platform.saveFile(fileName:(name?.trim().isNotEmpty==true?name!:path.split('/').last),bytes:bytes.takeBytes());
   if(saved!=null){_show(t('تم حفظ الملف في الموقع الذي اخترته','File saved to your selected location'));await launchUrl(Uri.parse(url),mode:LaunchMode.externalApplication);}
  }catch(e){_show(t('تعذر تحميل الملف. حاول مجددًا.','Could not download file. Try again.'));}
  finally{client?.close(force:true);if(mounted)setState((){downloadProgress=null;downloading=false;});}
 }
String _time(dynamic v){final d=DateTime.tryParse(v?.toString()??'')?.toLocal();return d==null?'':DateFormat(ar?'HH:mm':'h:mm a').format(d);}
 String _dateLabel(DateTime date){
  final today=DateUtils.dateOnly(DateTime.now()),day=DateUtils.dateOnly(date);
  if(day==today)return t('اليوم','Today');
  if(day==today.subtract(const Duration(days:1)))return t('أمس','Yesterday');
  return _oursDate(day,ar);
 }
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
  if(choice=='copy'){await Clipboard.setData(ClipboardData(text:type=='text'?body:(message['file_name']??body.split('/').last).toString()));_show(t('تم النسخ','Copied'));return;}
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
 void _jumpToMessage(String id){
  final index=messages.indexWhere((m)=>m['id'].toString()==id);
  if(index<0||!scroll.hasClients)return;
  final target=(index*150.0).clamp(0.0,scroll.position.maxScrollExtent);
  scroll.animateTo(target,duration:const Duration(milliseconds:320),curve:Curves.easeOutCubic);
  setState(()=>highlightedMessageId=id);
  Future<void>.delayed(const Duration(seconds:2),(){if(mounted&&highlightedMessageId==id)setState(()=>highlightedMessageId=null);});
 }
 Future<void> _searchMessages() async{
  final controller=TextEditingController();
  final query=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:const Color(0xFF211D30),title:Text(t('البحث في المحادثة','Search chat')),content:TextField(controller:controller,autofocus:true,decoration:InputDecoration(hintText:t('اكتب كلمة للبحث','Search for a word'))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('إلغاء','Cancel'))),FilledButton(onPressed:()=>Navigator.pop(ctx,controller.text.trim()),child:Text(t('بحث','Search')))]));
  controller.dispose();if(query==null||query.isEmpty)return;
  final found=messages.where((m)=>(m['message_type']=='text'||m['message_type']=='sticker')&&(m['body']??'').toString().toLowerCase().contains(query.toLowerCase())).toList();
  if(!mounted)return;
  await showModalBottomSheet<void>(context:context,isScrollControlled:true,backgroundColor:const Color(0xFF211D30),builder:(ctx)=>SafeArea(child:SizedBox(height:MediaQuery.of(ctx).size.height*.65,child:Column(children:[
   Padding(padding:const EdgeInsets.all(16),child:Text(t('نتائج البحث','Search results')+' ('+found.length.toString()+')',style:const TextStyle(color:_gold,fontWeight:FontWeight.bold))),
   Expanded(child:found.isEmpty?Center(child:Text(t('لا توجد نتائج','No results'))):ListView(children:found.map((m)=>ListTile(title:Text(m['body'].toString(),maxLines:2,overflow:TextOverflow.ellipsis),subtitle:Text(_time(m['created_at'])),onTap:(){Navigator.pop(ctx);_jumpToMessage(m['id'].toString());})).toList()))
  ]))));
 }
 Future<void> _openImageActions(String url) async{
  if(!mounted)return;
  await showDialog<void>(context:context,barrierColor:Colors.black,builder:(ctx)=>Dialog(
   backgroundColor:Colors.black,insetPadding:EdgeInsets.zero,
   child:SizedBox.expand(child:SafeArea(child:Column(children:[
    Expanded(child:Center(child:InteractiveViewer(minScale:.5,maxScale:5,child:Image.network(url,fit:BoxFit.contain,errorBuilder:(_,__,___)=>Center(child:Text(t('تعذر تحميل الصورة','Image failed to load'),style:const TextStyle(color:Colors.white))))))),
    Container(padding:const EdgeInsets.fromLTRB(10,8,10,12),decoration:BoxDecoration(color:skin.partner,border:Border(top:BorderSide(color:skin.accent.withValues(alpha:.18)))),child:Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:[
     TextButton.icon(onPressed:()=>Navigator.pop(ctx),icon:Icon(Icons.close,color:skin.accent),label:Text(t('إغلاق','Close'))),
     TextButton.icon(onPressed:()async{Navigator.pop(ctx);await _saveImageLocally(url);},icon:Icon(Icons.download_rounded,color:skin.accent),label:Text(t('حفظ','Save'))),
     TextButton.icon(onPressed:()async{Navigator.pop(ctx);try{final bytes=await _downloadImage(url);if(!mounted)return;await showDialog<void>(context:context,builder:(_)=>_ImageMarkupDialog(bytes:bytes,skin:skin,ar:ar));}catch(_){_show(t('تعذر فتح أدوات الرسم','Could not open drawing tools'));}},icon:Icon(Icons.draw_rounded,color:skin.accent),label:Text(t('الرسم','Draw')))
    ]))
   ])))
  ));
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
   Expanded(child:found.isEmpty?Center(child:Text(t('لا توجد عناصر بعد','Nothing shared yet'))):ListView(children:found.map((m)=>ListTile(leading:Icon(kind=='media'?Icons.image_outlined:Icons.insert_drive_file_outlined,color:skin.accent),title:Text((m['file_name']??(m['body']??'').toString().split('/').last).toString(),maxLines:1,overflow:TextOverflow.ellipsis),subtitle:Text(_time(m['created_at'])),onTap:(){Navigator.pop(ctx);_openLibraryItem(m);})).toList()))
  ]))));
 }
   @override void dispose(){typingTimer?.cancel();if(typingSent&&liveChannel!=null)unawaited(liveChannel!.sendBroadcastMessage(event:'typing',payload:{'user_id':uid,'typing':false}).then<void>((_){}));if(liveChannel!=null){unawaited(liveChannel!.untrack().then<void>((_){}));db.removeChannel(liveChannel!);}input.dispose();scroll.dispose();recorder?.dispose();if(channel!=null)db.removeChannel(channel!);super.dispose();}
 @override Widget build(BuildContext context){
  final me=db.auth.currentUser!.id;
  return Scaffold(backgroundColor:skin.bg,appBar:AppBar(
   backgroundColor:skin.bg, elevation:0, scrolledUnderElevation:0, centerTitle:false,
   toolbarHeight:76, titleSpacing:0,
   title:InkWell(
    borderRadius:BorderRadius.circular(16),
    onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OursProfilePage(userId:widget.partnerId))),
    child:Row(children:[
     Stack(clipBehavior:Clip.none,children:[
      Container(padding:const EdgeInsets.all(2),decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:skin.accent.withValues(alpha:.7),width:1.4)),child:CircleAvatar(radius:19,backgroundColor:skin.partner,child:Text((localPartnerName??widget.partnerName).trim().isEmpty?'O':(localPartnerName??widget.partnerName).trim().substring(0,1).toUpperCase(),style:TextStyle(color:skin.accent,fontWeight:FontWeight.w900,fontSize:17)))),
      Positioned(right:0,bottom:0,child:Container(width:11,height:11,decoration:BoxDecoration(color:partnerOnline?const Color(0xFF70D9A0):const Color(0xFF777181),shape:BoxShape.circle,border:Border.all(color:skin.bg,width:2))))
     ]),
     const SizedBox(width:10),
     Expanded(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(localPartnerName??widget.partnerName,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:15,fontWeight:FontWeight.w800,color:Colors.white)),
      const SizedBox(height:4),
      Row(children:[
       Flexible(child:Text(_presenceLabel(),maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:partnerTyping?skin.accent:partnerOnline?const Color(0xFF70D9A0):skin.accent.withValues(alpha:.78),fontSize:10,fontWeight:FontWeight.w600))),
       if(_streakCount()>0)Padding(padding:const EdgeInsetsDirectional.only(start:7),child:Tooltip(message:_streakStageName()+t(' · يحتسب اليوم عند تفاعل كل منكما',' · counts when both of you interact'),child:AnimatedContainer(duration:const Duration(milliseconds:320),padding:const EdgeInsets.symmetric(horizontal:7,vertical:3),decoration:BoxDecoration(gradient:LinearGradient(colors:switch(_streakStage()){1=>[const Color(0xFF467E88),const Color(0xFF6FAEAA)],2=>[const Color(0xFF3C9C8B),const Color(0xFF75C9A6)],3=>[const Color(0xFF5D75C8),const Color(0xFF9B7BDA)],4=>[const Color(0xFF9C62B6),const Color(0xFFD18BB4)],5=>[const Color(0xFFC27B46),const Color(0xFFE8BD77)],_=>[const Color(0xFFD7A84F),const Color(0xFFFFE3A2)]}),borderRadius:BorderRadius.circular(10)),child:Row(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.auto_awesome_rounded,color:Colors.white,size:10),const SizedBox(width:4),Text('${_streakCount()}',style:const TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w900))]))))
      ])
     ]))
    ]),
   ),
   actions:[
    IconButton(tooltip:t('اتصال صوتي','Voice call'),onPressed:()=>_callInfo(false),icon:Icon(Icons.call_outlined,color:skin.accent),style:IconButton.styleFrom(backgroundColor:skin.partner.withValues(alpha:.75),visualDensity:VisualDensity.compact)),
    IconButton(tooltip:t('اتصال مرئي','Video call'),onPressed:()=>_callInfo(true),icon:Icon(Icons.videocam_outlined,color:skin.accent),style:IconButton.styleFrom(backgroundColor:skin.partner.withValues(alpha:.75),visualDensity:VisualDensity.compact)),
    IconButton(tooltip:t('تفاصيل المحادثة','Chat details'),icon:Icon(Icons.more_horiz,color:skin.accent),style:IconButton.styleFrom(backgroundColor:skin.partner.withValues(alpha:.75),visualDensity:VisualDensity.compact),onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>_ChatDetailsPage(partnerId:widget.partnerId,partnerName:localPartnerName??widget.partnerName,skin:skin,profile:()=>OursProfilePage(userId:widget.partnerId),nickname:_changeLocalNickname,search:_searchMessages,media:()=>_showChatLibrary('media'),files:()=>_showChatLibrary('files'),themes:_chooseSkin,wallpaper:_chooseWallpaper))))
   ]),
   body:Stack(children:[
    Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:_ChatAtmospherePainter(skin)))),
    if(wallpaperPath!=null)Positioned.fill(child:IgnorePointer(child:ImageFiltered(imageFilter:ImageFilter.blur(sigmaX:wallpaperBlur,sigmaY:wallpaperBlur),child:Opacity(opacity:wallpaperOpacity,child:Image.file(File(wallpaperPath!),fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox.shrink()))))),
    if(wallpaperPath!=null)Positioned.fill(child:IgnorePointer(child:ColoredBox(color:skin.bg.withValues(alpha:wallpaperDim)))),
    Column(children:[
    Expanded(child:loading?Center(child:CircularProgressIndicator(color:skin.accent)):messages.isEmpty
     ?Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Icon(Icons.forum_outlined,color:skin.accent,size:52),const SizedBox(height:12),Text(t('ابدأ محادثتكما الخاصة','Start your private conversation'),style:const TextStyle(fontSize:19)),
      const SizedBox(height:7),Text(t('رسائل وصور وملفات وتسجيلات صوتية في مكان واحد.','Messages, photos, files and voice notes in one place.'),textAlign:TextAlign.center,style:TextStyle(color:skin.accent))
     ])))
     :ListView.builder(controller:scroll,padding:const EdgeInsets.all(12),itemCount:messages.length,itemBuilder:(ctx,i){
      final m=messages[i];final mine=m['sender_id']==me;final type=m['message_type']?.toString()??'text';final path=m['body']?.toString()??'';
      final createdAt=DateTime.tryParse(m['created_at']?.toString()??'')?.toLocal();
      final previousAt=i>0?DateTime.tryParse(messages[i-1]['created_at']?.toString()??'')?.toLocal():null;
      final showDate=createdAt!=null&&(previousAt==null||DateUtils.dateOnly(createdAt)!=DateUtils.dateOnly(previousAt));
      final showTimeDivider=createdAt!=null&&previousAt!=null&&createdAt.difference(previousAt)>const Duration(minutes:5);
      return Column(mainAxisSize:MainAxisSize.min,children:[
       if(showDate)Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Center(child:Container(padding:const EdgeInsets.symmetric(horizontal:13,vertical:6),decoration:BoxDecoration(color:skin.partner.withValues(alpha:.82),borderRadius:BorderRadius.circular(18),border:Border.all(color:skin.accent.withValues(alpha:.18))),child:Text(_dateLabel(createdAt),style:TextStyle(color:skin.accent,fontSize:10,fontWeight:FontWeight.w700))))),
       if(showTimeDivider)Padding(padding:const EdgeInsets.symmetric(vertical:9),child:Center(child:Container(padding:const EdgeInsets.symmetric(horizontal:11,vertical:5),decoration:BoxDecoration(color:skin.partner.withValues(alpha:.72),borderRadius:BorderRadius.circular(14),border:Border.all(color:skin.accent.withValues(alpha:.12))),child:Text(_time(m['created_at']),style:TextStyle(color:skin.accent,fontSize:10,fontWeight:FontWeight.w600))))),
       GestureDetector(
        onLongPress:()=>_messageActions(m,mine,type,path),
        onHorizontalDragEnd:(details){if((details.primaryVelocity??0).abs()>220)setState(()=>replyTo=m);},
        child:Align(alignment:mine?AlignmentDirectional.centerEnd:AlignmentDirectional.centerStart,child:Container(
         constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*.82),margin:const EdgeInsets.symmetric(vertical:5),padding:(type=='image'||type=='video'||type=='view_once'||type=='view_twice')?EdgeInsets.zero:const EdgeInsets.symmetric(horizontal:11,vertical:8),
         decoration:(type=='image'||type=='video'||type=='view_once'||type=='view_twice')?null:BoxDecoration(color:highlightedMessageId==m['id'].toString()?skin.accent.withValues(alpha:.24):(mine?skin.mine:skin.partner),borderRadius:BorderRadiusDirectional.only(topStart:const Radius.circular(17),topEnd:const Radius.circular(17),bottomStart:Radius.circular(mine?17:5),bottomEnd:Radius.circular(mine?5:17)),border:Border.all(color:highlightedMessageId==m['id'].toString()?skin.accent:skin.accent.withValues(alpha:.16),width:highlightedMessageId==m['id'].toString()?1.8:1)),
         child:IntrinsicWidth(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
          if(m['reply_to']!=null && messages.any((r)=>r['id'].toString()==m['reply_to'].toString()))
           Builder(builder:(context){
            final original=messages.firstWhere((r)=>r['id'].toString()==m['reply_to'].toString());
            final originalBody=(original['body']??'').toString();
            return InkWell(onTap:()=>_jumpToMessage(original['id'].toString()),borderRadius:BorderRadius.circular(8),child:Container(margin:const EdgeInsets.only(bottom:7),padding:const EdgeInsets.all(7),decoration:BoxDecoration(color:skin.bg.withValues(alpha:.45),borderRadius:BorderRadius.circular(8)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
             Text(original['sender_id']==uid?t('أنت', 'You'):(localPartnerName??widget.partnerName),style:TextStyle(color:skin.accent,fontSize:10,fontWeight:FontWeight.w800)),
             Text(originalBody,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(color:skin.accent,fontSize:11))
            ])));
           }),
          if(type=='sticker')FutureBuilder<String>(future:_signedSticker(path),builder:(c,s)=>s.hasData?Center(child:Image.network(s.data!,width:150,height:150,fit:BoxFit.contain,errorBuilder:(_,__,___)=>Icon(Icons.broken_image_outlined,color:skin.accent,size:42))):SizedBox(width:110,height:90,child:Center(child:CircularProgressIndicator(color:skin.accent,strokeWidth:2))))
          else if(type=='view_once'||type=='view_twice')
           ((m['view_count'] as num?)?.toInt()??0)>=((m['max_views'] as num?)?.toInt()??1)||m['viewed_at']!=null
            ?Text(t('انتهت مشاهدات الصورة','No views left'),style:TextStyle(color:skin.accent,fontSize:12))
            :FutureBuilder<String>(future:_signed(path),builder:(c,s)=>s.hasData
             ?Column(mainAxisSize:MainAxisSize.min,children:[ClipRRect(borderRadius:BorderRadius.circular(11),child:ImageFiltered(imageFilter:ImageFilter.blur(sigmaX:13,sigmaY:13),child:Image.network(s.data!,width:210,height:130,fit:BoxFit.cover))),const SizedBox(height:7),TextButton.icon(onPressed:()=>_consumeTemporaryMedia(m['id'].toString()),icon:Icon(Icons.visibility_outlined,color:skin.accent),label:Text((m['max_views']==2)?t('فتح الصورة · مشاهدتان','Open photo · two views'):t('فتح الصورة · مرة واحدة','Open photo · once')))])
             :Text(t('صورة مؤقتة','Temporary photo'),style:TextStyle(color:skin.accent,fontSize:12)))
          else if(type=='video')FutureBuilder<String>(future:_signed(path),builder:(c,s)=>s.hasError?Text(t('تعذر تحميل الفيديو','Could not load video'),style:TextStyle(color:skin.accent)):s.hasData?_DirectVideoBubble(url:s.data!,skin:skin):SizedBox(width:190,height:125,child:Center(child:CircularProgressIndicator(color:skin.accent))))
          else if(type=='image')FutureBuilder<String>(future:_signed(path),builder:(c,s){
           if(s.hasError)return Text(t('تعذر تحميل الصورة','Could not load image'),style:TextStyle(color:skin.accent));
           if(!s.hasData)return SizedBox(width:190,height:125,child:Center(child:CircularProgressIndicator(color:skin.accent)));
           return GestureDetector(onTap:()=>_openImageActions(s.data!),child:ClipRRect(borderRadius:BorderRadius.circular(13),child:Stack(children:[Image.network(s.data!,width:230,height:230,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Text(t('تعذر عرض الصورة','Image unavailable'))),Positioned(bottom:8,right:8,child:Container(padding:const EdgeInsets.all(6),decoration:BoxDecoration(color:Colors.black.withValues(alpha:.58),borderRadius:BorderRadius.circular(30)),child:Icon(Icons.zoom_out_map_rounded,color:Colors.white,size:17)))])));
          })
          else if(type=='file')InkWell(onTap:()=>_downloadFile(path,name:m['file_name']?.toString()),child:Row(mainAxisSize:MainAxisSize.min,children:[
           Icon(Icons.insert_drive_file_outlined,color:skin.accent,size:30),const SizedBox(width:8),
           Flexible(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text((m['file_name']??path.split('/').last.replaceFirst(RegExp(r'^\d+_'),'' )).toString(),maxLines:2,overflow:TextOverflow.ellipsis),
            Text('${((m['file_size'] as num?)?.toInt()??0)/1024>=1024?(((m['file_size'] as num?)?.toInt()??0)/1048576).toStringAsFixed(1)+' MB':(((m['file_size'] as num?)?.toInt()??0)/1024).toStringAsFixed(0)+' KB'} · ${(m['mime_type']??'').toString().split('/').last}',style:TextStyle(color:skin.accent,fontSize:10)),
            Text(t('اضغط لفتح الملف','Tap to open file'),style:TextStyle(color:skin.accent,fontSize:10))
           ]))
          ]))
          else if(type=='audio')_DirectAudioBubble(path:path,skin:skin,signed:_signed,ar:ar)
          else SelectableText(path,style:const TextStyle(color:Colors.white,height:1.4)),
          if(mine)Padding(padding:const EdgeInsets.only(top:4),child:Align(alignment:AlignmentDirectional.centerEnd,child:Text(_readReceipt(m['read_at']),style:TextStyle(color:m['read_at']!=null?skin.accent:skin.accent.withValues(alpha:.62),fontSize:9,fontWeight:FontWeight.w600))))
         ]))
        ))
       )
      ]);
     })),
    SafeArea(top:false,child:Padding(
     padding:const EdgeInsetsDirectional.fromSTEB(10,5,10,9),
     child:Container(
      padding:const EdgeInsets.symmetric(horizontal:8,vertical:8),
      decoration:BoxDecoration(
       gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[skin.partner.withValues(alpha:.98),skin.bg.withValues(alpha:.98)]),
       borderRadius:BorderRadius.circular(25),
       border:Border.all(color:skin.accent.withValues(alpha:.28),width:1),
       boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:.20),blurRadius:18,offset:const Offset(0,5))]
      ),
      child:recording?Row(children:[
       IconButton(onPressed:_cancelRecording,tooltip:t('إلغاء التسجيل','Cancel recording'),style:IconButton.styleFrom(backgroundColor:Colors.redAccent.withValues(alpha:.12)),icon:const Icon(Icons.delete_outline_rounded,color:Colors.redAccent)),
       Expanded(child:Text(t('جارٍ تسجيل الرسالة الصوتية…','Recording voice message…'),textAlign:TextAlign.center,style:TextStyle(color:skin.accent,fontSize:12,fontWeight:FontWeight.w700))),
       IconButton.filled(onPressed:sending?null:_sendRecording,style:IconButton.styleFrom(backgroundColor:skin.accent,foregroundColor:skin.bg),icon:const Icon(Icons.send_rounded))
      ]):Column(mainAxisSize:MainAxisSize.min,children:[
       if(downloading)Padding(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),child:LinearProgressIndicator(value:downloadProgress,color:skin.accent,minHeight:2)),
       if(partnerTyping)Padding(padding:const EdgeInsetsDirectional.fromSTEB(12,0,12,6),child:Align(alignment:AlignmentDirectional.centerStart,child:Text(t('يكتب الآن…','Typing…'),style:TextStyle(color:skin.accent,fontSize:11,fontStyle:FontStyle.italic)))),
       if(replyTo!=null)Container(margin:const EdgeInsets.fromLTRB(3,0,3,7),padding:const EdgeInsetsDirectional.fromSTEB(10,5,5,5),decoration:BoxDecoration(color:skin.bg.withValues(alpha:.62),borderRadius:BorderRadius.circular(13),border:BorderDirectional(start:BorderSide(color:skin.accent,width:3))),child:Row(children:[
        Icon(Icons.reply_rounded,color:skin.accent,size:18),const SizedBox(width:8),
        Expanded(child:Text((replyTo!['body']??'').toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:skin.accent,fontSize:11))),
        IconButton(onPressed:()=>setState(()=>replyTo=null),constraints:const BoxConstraints.tightFor(width:30,height:30),padding:EdgeInsets.zero,icon:Icon(Icons.close_rounded,color:skin.accent,size:17))
       ])),
       Row(crossAxisAlignment:CrossAxisAlignment.end,children:[
        IconButton(onPressed:uploading||sending?null:_showAttachments,tooltip:t('إرفاق صورة أو ملف أو ملصق','Attach photo, file or sticker'),style:IconButton.styleFrom(backgroundColor:skin.accent.withValues(alpha:.12),fixedSize:const Size(42,42)),icon:uploading?SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:skin.accent)):Icon(Icons.add_rounded,color:skin.accent,size:23)),
        const SizedBox(width:6),
        Expanded(child:Container(
         constraints:const BoxConstraints(minHeight:44),
         decoration:BoxDecoration(color:skin.bg.withValues(alpha:.48),borderRadius:BorderRadius.circular(19),border:Border.all(color:skin.accent.withValues(alpha:.12))),
         child:TextField(controller:input,minLines:1,maxLines:5,textInputAction:TextInputAction.send,onChanged:_handleTyping,onSubmitted:(_)=>_sendText(),style:const TextStyle(color:Colors.white,fontSize:14,height:1.35),decoration:InputDecoration(hintText:t('اكتب رسالة…','Write a message…'),hintStyle:TextStyle(color:skin.accent.withValues(alpha:.72),fontSize:13),border:InputBorder.none,enabledBorder:InputBorder.none,focusedBorder:InputBorder.none,contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:11)))
        )),
        const SizedBox(width:5),
        IconButton(onPressed:uploading||sending?null:_startRecording,tooltip:t('تسجيل صوتي','Voice message'),style:IconButton.styleFrom(backgroundColor:skin.accent.withValues(alpha:.12),fixedSize:const Size(42,42)),icon:Icon(Icons.mic_none_rounded,color:skin.accent,size:21)),
        const SizedBox(width:5),
        IconButton.filled(onPressed:sending||uploading?null:_sendText,tooltip:t('إرسال','Send'),style:IconButton.styleFrom(backgroundColor:skin.accent,foregroundColor:skin.bg,fixedSize:const Size(44,44)),icon:sending?const SizedBox(width:17,height:17,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send_rounded,size:20))
       ])
      ])
     )
    ))
   ]),
  ]));
 }
}

class OursAiPage extends StatefulWidget{
 final String spaceId;const OursAiPage({super.key,required this.spaceId});
 @override State<OursAiPage> createState()=>_OursAiPageState();
}
class _OursAiPageState extends State<OursAiPage>{
 final db=Supabase.instance.client,input=TextEditingController(),scroll=ScrollController();
 final messages=<Map<String,String>>[];
 bool sending=false,includeContext=false;String? wallpaperPath;_ChatSkin skin=_skins.first;
 bool get ar=>Localizations.localeOf(context).languageCode=='ar';String t(String a,String e)=>ar?a:e;
 @override void initState(){super.initState();_restore();_loadAppearance();}
 Future<void> _loadAppearance()async{
  final p=await SharedPreferences.getInstance(),id=p.getString('ours_ai_skin')??'ours';
  final found=_skins.where((x)=>x.id==id);
  if(mounted)setState((){skin=found.isEmpty?_skins.first:found.first;wallpaperPath=p.getString('ours_ai_wallpaper');});
 }
 Future<void> _chooseTheme()async{
  final selected=await showModalBottomSheet<String>(context:context,backgroundColor:skin.bg,showDragHandle:true,builder:(ctx)=>SafeArea(child:SizedBox(height:MediaQuery.of(ctx).size.height*.62,child:ListView(padding:const EdgeInsets.all(14),children:[
   Padding(padding:const EdgeInsets.all(8),child:Text(t('ثيم OURS AI','OURS AI theme'),style:TextStyle(color:skin.accent,fontWeight:FontWeight.w900,fontSize:18))),
   ..._skins.map((x)=>ListTile(leading:CircleAvatar(backgroundColor:x.accent,child:Icon(Icons.palette_rounded,color:x.bg)),title:Text(ar?x.ar:x.en,style:const TextStyle(color:Colors.white)),subtitle:Text(ar?x.id:x.id,style:const TextStyle(color:_lavender,fontSize:11)),onTap:()=>Navigator.pop(ctx,x.id)))
  ]))));
  if(selected==null)return;final p=await SharedPreferences.getInstance();await p.setString('ours_ai_skin',selected);
  if(mounted)setState(()=>skin=_skins.firstWhere((x)=>x.id==selected,orElse:()=>_skins.first));
 }
 Future<void> _chooseWallpaper()async{
  final action=await showModalBottomSheet<String>(context:context,backgroundColor:skin.bg,showDragHandle:true,builder:(ctx)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
   ListTile(leading:Icon(Icons.photo_library_outlined,color:skin.accent),title:Text(t('اختيار خلفية','Choose wallpaper')),onTap:()=>Navigator.pop(ctx,'choose')),
   ListTile(leading:Icon(Icons.layers_clear_outlined,color:skin.accent),title:Text(t('إزالة الخلفية','Remove wallpaper')),onTap:()=>Navigator.pop(ctx,'clear'))
  ])));
  if(action==null)return;final p=await SharedPreferences.getInstance();
  if(action=='clear'){final old=wallpaperPath;await p.remove('ours_ai_wallpaper');if(mounted)setState(()=>wallpaperPath=null);if(old!=null){try{final file=File(old);if(await file.exists())await file.delete();}catch(_){}}}
  else{try{final f=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:92,maxWidth:2400,maxHeight:2400);if(f==null)return;final dir=await getApplicationDocumentsDirectory(),target=File('${dir.path}/ours_ai_wallpaper.jpg');await File(f.path).copy(target.path);await p.setString('ours_ai_wallpaper',target.path);if(mounted)setState(()=>wallpaperPath=target.path);}catch(_){_notice(t('تعذر تطبيق الخلفية','Could not apply wallpaper'));}}
 }
 Future<List<Map<String,String>>> _context() async{
  final rows=await db.from('duo_messages').select('body,sender_id').eq('space_id',widget.spaceId).eq('message_type','text').isFilter('deleted_at',null).order('created_at',ascending:false).limit(20);
  return List<Map<String,dynamic>>.from(rows).reversed.map((r)=>{'sender':r['sender_id']==db.auth.currentUser!.id?(ar?'أنا':'Me'):(ar?'الشريك':'Partner'),'text':r['body'].toString()}).toList();
 }
 Future<void> _send({String? preset,String task='chat'}) async{
  final text=(preset??input.text).trim();if(text.isEmpty||sending)return;
  setState(()=>sending=true);messages.add({'role':'user','content':text,'created_at':DateTime.now().toIso8601String()});input.clear();_persist();_bottom();
  try{
   final ctx=includeContext?await _context():<Map<String,String>>[];
   final history=(messages.length>12?messages.sublist(messages.length-12):messages).map((m)=>{'role':m['role']??'user','content':m['content']??''}).toList();
   final r=await db.functions.invoke('ours-ai',body:{'space_id':widget.spaceId,'task':task,'messages':history,'context':ctx});
   final data=r.data is Map?Map<String,dynamic>.from(r.data):<String,dynamic>{};
   if(r.status!=200){final e=data['error']?.toString()??'';if(e=='GEMINI_SETUP_REQUIRED')throw Exception(t('مفتاح الذكاء الاصطناعي غير مضبوط على الخادم.','AI provider key is not configured on the server.'));
    if(e=='AI_LIMIT_REACHED')throw Exception(t('وصلنا لحد الاستخدام الحالي، حاول لاحقًا.','Usage limit reached. Try later.'));if(r.status==403)throw Exception(t('لا تملك صلاحية هذه المحادثة.','Conversation access denied.'));throw Exception(t('تعذر الاتصال بمساعد OURS.','Could not reach OURS AI.'));
   }
   final answer=data['answer']?.toString()??'';if(answer.isEmpty)throw Exception('Empty response');
   if(mounted){messages.add({'role':'assistant','content':answer,'created_at':DateTime.now().toIso8601String()});await _persist();}_bottom();
  }catch(e){
   if(mounted){final raw=e.toString().toLowerCase();final friendly=raw.contains('socket')||raw.contains('network')||raw.contains('connection')||raw.contains('timeout')?t('تعذر الاتصال بمساعد OURS. تحقق من الإنترنت وحاول مجددًا.','Could not reach OURS AI. Check your connection and retry.'):raw.contains('limit')?t('وصلنا إلى حد الاستخدام الحالي. حاول لاحقًا.','Usage limit reached. Please try later.'):t('تعذر إكمال الطلب الآن. حاول مرة أخرى.','Could not complete the request. Please retry.');messages.add({'role':'assistant','content':friendly,'created_at':DateTime.now().toIso8601String()});await _persist();}_bottom();
  }finally{if(mounted)setState(()=>sending=false);}
 }
 void _notice(String text){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(text)));}
 void _bottom()=>WidgetsBinding.instance.addPostFrameCallback((_){if(scroll.hasClients)scroll.animateTo(scroll.position.maxScrollExtent,duration:const Duration(milliseconds:220),curve:Curves.easeOut);});
 String _time(String? value){final date=DateTime.tryParse(value??'')?.toLocal();return date==null?'':DateFormat(ar?'HH:mm':'h:mm a').format(date);}
 String _dateLabel(DateTime date){final today=DateUtils.dateOnly(DateTime.now()),day=DateUtils.dateOnly(date);if(day==today)return t('اليوم','Today');if(day==today.subtract(const Duration(days:1)))return t('أمس','Yesterday');return _oursDate(day,ar);}
 void _jumpToMessage(int index){if(!scroll.hasClients)return;scroll.animateTo((index*155.0).clamp(0.0,scroll.position.maxScrollExtent),duration:const Duration(milliseconds:320),curve:Curves.easeOutCubic);}
 Future<void> _search()async{
  final controller=TextEditingController();
  final query=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:skin.bg,title:Text(t('البحث في محادثة AI','Search AI chat')),content:TextField(controller:controller,autofocus:true,decoration:InputDecoration(hintText:t('اكتب كلمة للبحث','Search for a word'))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('إلغاء','Cancel'))),FilledButton(onPressed:()=>Navigator.pop(ctx,controller.text.trim()),child:Text(t('بحث','Search')))]));
  controller.dispose();if(query==null||query.isEmpty)return;
  final found=<int>[];for(var i=0;i<messages.length;i++){if((messages[i]['content']??'').toLowerCase().contains(query.toLowerCase()))found.add(i);}
  if(!mounted)return;
  await showModalBottomSheet<void>(context:context,backgroundColor:skin.bg,isScrollControlled:true,builder:(ctx)=>SafeArea(child:SizedBox(height:MediaQuery.of(ctx).size.height*.6,child:ListView(children:found.reversed.map((i)=>ListTile(title:Text(messages[i]['content']??'',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white)),subtitle:Text(_time(messages[i]['created_at']),style:TextStyle(color:skin.accent)),onTap:(){Navigator.pop(ctx);_jumpToMessage(i);})).toList()))));
 }

 Future<void> _restore() async{try{final p=await SharedPreferences.getInstance();final raw=p.getString('ours_ai_history_'+db.auth.currentUser!.id);if(raw!=null){final decoded=(jsonDecode(raw) as List).map((e)=>Map<String,String>.from(e)).toList();if(mounted)setState(()=>messages.addAll(decoded));}}catch(_){} }
 Future<void> _persist() async{try{final p=await SharedPreferences.getInstance();await p.setString('ours_ai_history_'+db.auth.currentUser!.id,jsonEncode(messages.take(100).toList()));}catch(_){} }
 @override void dispose(){input.dispose();scroll.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:skin.bg,appBar:AppBar(backgroundColor:skin.bg,centerTitle:true,title:Column(mainAxisSize:MainAxisSize.min,children:[Text('OURS AI',style:TextStyle(color:skin.accent,letterSpacing:2,fontWeight:FontWeight.w800)),Text(t('مساعدك الذكي','Your private assistant'),style:TextStyle(color:skin.accent.withValues(alpha:.75),fontSize:10))]),actions:[
  IconButton(onPressed:_search,icon:Icon(Icons.search,color:skin.accent)),
  IconButton(onPressed:_chooseTheme,icon:Icon(Icons.palette_outlined,color:skin.accent)),
  IconButton(onPressed:_chooseWallpaper,icon:Icon(Icons.wallpaper_outlined,color:skin.accent))
 ]),
  body:Stack(children:[
   Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:_ChatAtmospherePainter(skin)))),
   if(wallpaperPath!=null)Positioned.fill(child:IgnorePointer(child:Opacity(opacity:.22,child:Image.file(File(wallpaperPath!),fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox.shrink())))),
   SafeArea(child:Column(children:[
    Container(margin:const EdgeInsets.fromLTRB(12,8,12,4),padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),decoration:BoxDecoration(color:skin.partner,borderRadius:BorderRadius.circular(15)),child:Row(children:[Icon(Icons.lock_outline_rounded,color:skin.accent,size:19),const SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t('سياق المحادثة','Chat context'),style:const TextStyle(fontWeight:FontWeight.w700,fontSize:12,color:Colors.white)),Text(t('اختياري · مغلق افتراضيًا','Optional · off by default'),style:TextStyle(color:skin.accent,fontSize:10))])),Switch(value:includeContext,onChanged:(v)=>setState(()=>includeContext=v),activeColor:skin.accent)])),
    SizedBox(height:40,child:SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(mainAxisSize:MainAxisSize.min,children:[
     ActionChip(label:Text(t('أفكار لنا','Ideas for us')),onPressed:sending?null:()=>_send(preset:t('اقترح أنشطة مناسبة لشخصين.','Suggest activities for two people.'),task:'ideas')),
     ActionChip(label:Text(t('تلخيص المحادثة','Summarize chat')),onPressed:sending||!includeContext?null:()=>_send(preset:t('لخّص آخر محادثاتنا.','Summarize our recent chat.'),task:'summary')),
     ActionChip(label:Text(t('خطط وأهداف','Plans')),onPressed:sending?null:()=>_send(preset:t('ساعدني أضع خطة عملية لأهدافي مع خطوات صغيرة قابلة للتنفيذ.','Help me create a practical plan with small actionable steps.'),task:'organize')),
     ActionChip(label:Text(t('مساعدة دراسية','Study help')),onPressed:sending?null:()=>_send(preset:t('ساعدني أذاكر موضوعًا بطريقة مبسطة مع أسئلة تدريبية.','Help me study a topic simply with practice questions.'),task:'study')),
     ActionChip(label:Text(t('أفكار إبداعية','Brainstorm')),onPressed:sending?null:()=>_send(preset:t('اعطني أفكارًا إبداعية ومختلفة لمشاريع وأنشطة ممتعة.','Give me creative and unusual project and activity ideas.'),task:'brainstorm')),
     ActionChip(label:Text(t('فضفضة وكتابة','Journal')),onPressed:sending?null:()=>_send(preset:t('ساعدني أرتب أفكاري وأكتب ما أشعر به بطريقة واضحة.','Help me organize my thoughts and journal clearly.'),task:'journal'))
    ]))),
    Padding(padding:const EdgeInsets.all(10),child:Text(t('قد تتم معالجة سؤالك عبر مزوّد ذكاء اصطناعي خارجي. لا تفعّل سياق المحادثة إلا إذا رغبت بإرسال الرسائل الأخيرة.','Your prompt may be processed by an external AI provider. Enable chat context only if you want recent messages shared.'),textAlign:TextAlign.center,style:TextStyle(color:skin.accent,fontSize:10))),
    Divider(color:skin.accent.withValues(alpha:.2)),
    Expanded(child:ListView.builder(controller:scroll,padding:const EdgeInsets.all(14),itemCount:messages.length,itemBuilder:(c,i){
     final m=messages[i],mine=m['role']=='user',date=DateTime.tryParse(m['created_at']??'')?.toLocal(),previous=i>0?DateTime.tryParse(messages[i-1]['created_at']??'')?.toLocal():null;
     final showDate=date!=null&&(previous==null||DateUtils.dateOnly(date)!=DateUtils.dateOnly(previous));
     return Column(children:[
      if(showDate)Padding(padding:const EdgeInsets.symmetric(vertical:9),child:Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:5),decoration:BoxDecoration(color:skin.partner,borderRadius:BorderRadius.circular(14)),child:Text(_dateLabel(date),style:TextStyle(color:skin.accent,fontSize:10,fontWeight:FontWeight.w700)))),
      Align(alignment:mine?AlignmentDirectional.centerEnd:AlignmentDirectional.centerStart,child:IntrinsicWidth(child:Container(constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*.82),margin:const EdgeInsets.symmetric(vertical:5),padding:const EdgeInsets.all(13),decoration:BoxDecoration(gradient:LinearGradient(colors:mine?[skin.mine,skin.mine.withValues(alpha:.86)]:[skin.partner,skin.bg]),borderRadius:BorderRadius.circular(17)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
       SelectableText(m['content']??'',style:const TextStyle(height:1.5,color:Colors.white)),
       const SizedBox(height:5),Align(alignment:AlignmentDirectional.centerEnd,child:Text(_time(m['created_at']),style:TextStyle(color:skin.accent,fontSize:10)))
      ]))))
     ]);
    })),
    if(sending)LinearProgressIndicator(color:skin.accent,minHeight:2),
    Padding(padding:const EdgeInsets.fromLTRB(10,8,10,12),child:Row(children:[
     Expanded(child:TextField(controller:input,minLines:1,maxLines:4,textInputAction:TextInputAction.send,onSubmitted:(_)=>_send(),decoration:InputDecoration(hintText:t('اسأل OURS AI…','Ask OURS AI…'),filled:true,fillColor:skin.partner,border:OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:BorderSide.none)))),
     IconButton(onPressed:sending?null:()=>_send(),icon:Icon(Icons.send_rounded,color:skin.accent))
    ]))
   ]))
  ]));
}

class _DirectVideoBubble extends StatefulWidget {
 final String url; final _ChatSkin skin;
 const _DirectVideoBubble({required this.url,required this.skin});
 @override State<_DirectVideoBubble> createState()=>_DirectVideoBubbleState();
}
class _DirectVideoBubbleState extends State<_DirectVideoBubble>{
 late final VideoPlayerController controller;bool failed=false;
 @override void initState(){super.initState();controller=VideoPlayerController.networkUrl(Uri.parse(widget.url));controller.initialize().then((_){if(mounted)setState((){});}).catchError((_){if(mounted)setState(()=>failed=true);});}
 @override void dispose(){controller.dispose();super.dispose();}
 @override Widget build(BuildContext context){
  if(failed)return SizedBox(width:210,height:140,child:Center(child:Text('تعذر تشغيل الفيديو',style:TextStyle(color:widget.skin.accent))));
  if(!controller.value.isInitialized)return SizedBox(width:210,height:140,child:Center(child:CircularProgressIndicator(color:widget.skin.accent)));
  return ClipRRect(borderRadius:BorderRadius.circular(12),child:SizedBox(width:230,child:AspectRatio(aspectRatio:controller.value.aspectRatio>0?controller.value.aspectRatio:16/9,child:Stack(alignment:Alignment.center,children:[
   VideoPlayer(controller),
   Material(color:Colors.black26,child:InkWell(onTap:(){if(controller.value.isPlaying){controller.pause();}else{controller.play();}setState((){});},child:Center(child:Icon(controller.value.isPlaying?Icons.pause_circle_filled:Icons.play_circle_fill,color:Colors.white,size:46)))),
   Positioned(left:8,right:8,bottom:7,child:VideoProgressIndicator(controller,allowScrubbing:true,colors:VideoProgressColors(playedColor:widget.skin.accent,bufferedColor:Colors.white54,backgroundColor:Colors.white24)))
  ]))));
 }
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
 final db=Supabase.instance.client,input=TextEditingController(),scroll=ScrollController(),picker=ImagePicker();
 final Map<String,Future<String>> urls={};final List<Map<String,dynamic>> rows=[];
 RealtimeChannel? channel;AudioRecorder? recorder;String? recordingPath,wallpaperPath;
 Map<String,dynamic>? replyTo;_ChatSkin skin=_skins.first;
 bool loading=true,sending=false,uploading=false,recording=false;
 bool get ar=>Localizations.localeOf(context).languageCode=='ar';
 String t(String a,String e)=>ar?a:e;
 String get uid=>db.auth.currentUser!.id;
 @override void initState(){super.initState();_loadSelfSkin();_load();_listen();}
 Future<void> _loadSelfSkin()async{
  final p=await SharedPreferences.getInstance();
  final id=p.getString('ours_self_skin')??'ours';
  final found=_skins.where((x)=>x.id==id);
  if(mounted)setState((){skin=found.isEmpty?_skins.first:found.first;wallpaperPath=p.getString('ours_self_wallpaper');});
 }
 Future<void> _chooseTheme()async{
  final selected=await showModalBottomSheet<String>(context:context,backgroundColor:_navy,showDragHandle:true,builder:(ctx)=>SafeArea(child:SizedBox(height:MediaQuery.of(ctx).size.height*.62,child:ListView(padding:const EdgeInsets.all(14),children:[
   Padding(padding:const EdgeInsets.all(8),child:Text(t('ثيم المحادثة','Chat theme'),style:const TextStyle(color:_gold,fontWeight:FontWeight.w900,fontSize:18))),
   ..._skins.map((x)=>ListTile(leading:CircleAvatar(backgroundColor:x.accent,child:Icon(Icons.palette_rounded,color:x.bg)),title:Text(ar?x.ar:x.en,style:const TextStyle(color:Colors.white)),subtitle:Text(ar?x.id:x.id,style:const TextStyle(color:_lavender,fontSize:11)),onTap:()=>Navigator.pop(ctx,x.id)))
  ]))));
  if(selected==null)return;
  final p=await SharedPreferences.getInstance();await p.setString('ours_self_skin',selected);
  if(mounted)setState(()=>skin=_skins.firstWhere((x)=>x.id==selected,orElse:()=>_skins.first));
 }
 Future<void> _chooseWallpaper()async{
  final action=await showModalBottomSheet<String>(context:context,backgroundColor:skin.bg,showDragHandle:true,builder:(ctx)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
   ListTile(leading:Icon(Icons.photo_library_outlined,color:skin.accent),title:Text(t('اختيار خلفية','Choose wallpaper')),onTap:()=>Navigator.pop(ctx,'choose')),
   ListTile(leading:Icon(Icons.layers_clear_outlined,color:skin.accent),title:Text(t('إزالة الخلفية','Remove wallpaper')),onTap:()=>Navigator.pop(ctx,'clear'))
  ])));
  if(action==null)return;
  final prefs=await SharedPreferences.getInstance();
  if(action=='clear'){
   final old=wallpaperPath;await prefs.remove('ours_self_wallpaper');
   if(mounted)setState(()=>wallpaperPath=null);
   if(old!=null){try{final file=File(old);if(await file.exists())await file.delete();}catch(_){}}
  }else{
   try{
    final f=await picker.pickImage(source:ImageSource.gallery,imageQuality:92,maxWidth:2400,maxHeight:2400);if(f==null)return;
    final dir=await getApplicationDocumentsDirectory(),target=File('${dir.path}/ours_self_wallpaper.jpg');
    await File(f.path).copy(target.path);await prefs.setString('ours_self_wallpaper',target.path);
    if(mounted)setState(()=>wallpaperPath=target.path);
   }catch(_){_notice(t('تعذر تطبيق الخلفية','Could not apply wallpaper'));}
  }
 }
 Future<void> _load()async{
  try{
   final data=await db.from('ours_self_messages').select().order('created_at');
   if(mounted)setState(()=>rows..clear()..addAll(List<Map<String,dynamic>>.from(data)));
  }catch(_){_notice(t('تعذر تحميل الرسائل المحفوظة. تحقق من الاتصال.','Could not load saved messages. Check your connection.'));}
  finally{if(mounted)setState(()=>loading=false);}
 }
 void _listen(){
  final filter=PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'user_id',value:uid);
  channel=db.channel('ours-self-$uid')
   .onPostgresChanges(event:PostgresChangeEvent.insert,schema:'public',table:'ours_self_messages',filter:filter,callback:(p){
    final row=Map<String,dynamic>.from(p.newRecord);
    if(!mounted||rows.any((r)=>r['id'].toString()==row['id'].toString()))return;
    setState(()=>rows.add(row));
   })
   .onPostgresChanges(event:PostgresChangeEvent.update,schema:'public',table:'ours_self_messages',filter:filter,callback:(p){
    final row=Map<String,dynamic>.from(p.newRecord),index=rows.indexWhere((r)=>r['id'].toString()==row['id'].toString());
    if(mounted&&index>=0)setState(()=>rows[index]=row);
   })
   .onPostgresChanges(event:PostgresChangeEvent.delete,schema:'public',table:'ours_self_messages',callback:(p){
    final id=p.oldRecord['id']?.toString();if(!mounted||id==null)return;
    setState(()=>rows.removeWhere((r)=>r['id'].toString()==id));
   }).subscribe();
 }
 void _notice(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
 Future<void> _send()async{
  final text=input.text.trim();if(text.isEmpty||sending)return;setState(()=>sending=true);
  try{
   final row=await db.from('ours_self_messages').insert({'user_id':uid,'body':text,'message_type':'text','reply_to':replyTo?['id']}).select().single();
   if(mounted&&!rows.any((r)=>r['id'].toString()==row['id'].toString()))setState(()=>rows.add(Map<String,dynamic>.from(row)));
   input.clear();if(mounted)setState(()=>replyTo=null);_bottom();
  }catch(_){_notice(t('تعذر حفظ الرسالة. حاول مجددًا.','Could not save message. Try again.'));}
  finally{if(mounted)setState(()=>sending=false);}
 }
 String _selfMime(String name){
  const types={'jpg':'image/jpeg','jpeg':'image/jpeg','png':'image/png','webp':'image/webp','gif':'image/gif','mp4':'video/mp4','mov':'video/quicktime','webm':'video/webm','m4a':'audio/mp4','aac':'audio/aac','mp3':'audio/mpeg','ogg':'audio/ogg','pdf':'application/pdf','txt':'text/plain','csv':'text/csv','doc':'application/msword','docx':'application/vnd.openxmlformats-officedocument.wordprocessingml.document','xls':'application/vnd.ms-excel','xlsx':'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','ppt':'application/vnd.ms-powerpoint','pptx':'application/vnd.openxmlformats-officedocument.presentationml.presentation','zip':'application/zip'};
  return types[name.split('.').last.toLowerCase()]??'';
 }
 Future<void> _uploadSelf(Uint8List bytes,String name,String type)async{
  if(bytes.isEmpty)return;if(bytes.length>20*1024*1024){_notice(t('الحد الأقصى 20 ميجابايت','Maximum size is 20 MB'));return;}
  final mime=_selfMime(name);if(mime.isEmpty){_notice(t('نوع الملف غير مدعوم','Unsupported file type'));return;}
  setState(()=>uploading=true);
  final safe=name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'),'_');
  final path='self/'+uid+'/'+DateTime.now().microsecondsSinceEpoch.toString()+'_'+safe;
  try{
   await db.storage.from('ours-direct-media').uploadBinary(path,bytes,fileOptions:FileOptions(contentType:mime,upsert:false,cacheControl:'3600'));
   try{
    final row=await db.from('ours_self_messages').insert({'user_id':uid,'body':path,'message_type':type,'file_name':name,'file_size':bytes.length,'mime_type':mime,'reply_to':replyTo?['id']}).select().single();
    if(mounted&&!rows.any((r)=>r['id'].toString()==row['id'].toString()))setState(()=>rows.add(Map<String,dynamic>.from(row)));
    if(mounted)setState(()=>replyTo=null);_bottom();
   }catch(_){await db.storage.from('ours-direct-media').remove([path]);rethrow;}
  }catch(_){_notice(t('تعذر رفع المرفق. حاول مجددًا.','Could not upload attachment. Try again.'));}
  finally{if(mounted)setState(()=>uploading=false);}
 }
 Future<void> _pickImage({bool sticker=false})async{
  try{
   if(sticker){
    final result=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['png','jpg','jpeg','webp','gif'],withData:true);
    if(result==null||result.files.isEmpty)return;
    final file=result.files.single,bytes=file.bytes??(file.path==null?null:await File(file.path!).readAsBytes());
    if(bytes==null)throw Exception('sticker');
    await _uploadSelf(bytes,'self_sticker_'+DateTime.now().millisecondsSinceEpoch.toString()+'.'+file.name.split('.').last.toLowerCase(),'sticker');
   }else{
    final f=await picker.pickImage(source:ImageSource.gallery,imageQuality:94,maxWidth:2400,maxHeight:2400);if(f==null)return;
    final ext=f.name.split('.').last.toLowerCase(),name=['png','webp'].contains(ext)?f.name:'self_'+DateTime.now().millisecondsSinceEpoch.toString()+'.jpg';
    await _uploadSelf(await f.readAsBytes(),name,'image');
   }
  }catch(_){_notice(t('تعذر اختيار الصورة','Could not select image'));}
 }
 Future<void> _previewSelfVideo(String path,{required String extension})async{
  final controller=VideoPlayerController.file(File(path));
  try{
   await controller.initialize();
   if(!mounted){await controller.dispose();return;}
   final accepted=await showDialog<bool>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setModal)=>AlertDialog(
    backgroundColor:skin.bg,title:Text(t('معاينة الفيديو','Video preview')),
    content:Column(mainAxisSize:MainAxisSize.min,children:[
     AspectRatio(aspectRatio:controller.value.aspectRatio,child:VideoPlayer(controller)),
     Row(mainAxisAlignment:MainAxisAlignment.center,children:[
      IconButton(onPressed:()=>setModal(()=>controller.value.isPlaying?controller.pause():controller.play()),icon:Icon(controller.value.isPlaying?Icons.pause:Icons.play_arrow,color:skin.accent)),
      IconButton(onPressed:()=>setModal(()=>controller.seekTo(Duration.zero)),icon:Icon(Icons.replay,color:skin.accent))
     ])
    ]),
    actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:Text(t('إلغاء','Cancel'))),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:Text(t('إرسال','Send')))]
   )));
   if(accepted==true){final file=File(path);if(await file.exists())await _uploadSelf(await file.readAsBytes(),'self_video_'+DateTime.now().microsecondsSinceEpoch.toString()+'.'+extension,'video');}
  }catch(_){_notice(t('تعذر معاينة الفيديو','Could not preview video'));}
  finally{await controller.dispose();}
 }
 Future<void> _pickVideoSelf()async{
  try{
   final file=await picker.pickVideo(source:ImageSource.gallery,maxDuration:const Duration(minutes:2));
   if(file==null)return;
   final ext=file.name.split('.').last.toLowerCase();
   if(!['mp4','mov','webm'].contains(ext)){_notice(t('صيغة الفيديو غير مدعومة','Unsupported video format'));return;}
   await _previewSelfVideo(file.path,extension:ext);
  }catch(_){_notice(t('تعذر اختيار الفيديو','Could not select video'));}
 }
 Future<void> _pickFile()async{
  try{final result=await FilePicker.platform.pickFiles(withData:true);if(result==null||result.files.isEmpty)return;
   final f=result.files.single,bytes=f.bytes??(f.path==null?null:await File(f.path!).readAsBytes());
   if(bytes==null)throw Exception('file');await _uploadSelf(bytes,f.name,'file');
  }catch(_){_notice(t('تعذر اختيار الملف','Could not select file'));}
 }
 Future<void> _showAttachments()async{
  final choice=await showModalBottomSheet<String>(context:context,backgroundColor:skin.bg,showDragHandle:true,builder:(ctx)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
   ListTile(leading:Icon(Icons.image_outlined,color:skin.accent),title:Text(t('صورة','Photo')),onTap:()=>Navigator.pop(ctx,'image')),
   ListTile(leading:Icon(Icons.videocam_outlined,color:skin.accent),title:Text(t('فيديو','Video')),onTap:()=>Navigator.pop(ctx,'video')),
   ListTile(leading:Icon(Icons.sticky_note_2_outlined,color:skin.accent),title:Text(t('ملصق من المعرض','Sticker from gallery')),onTap:()=>Navigator.pop(ctx,'sticker')),
   ListTile(leading:Icon(Icons.insert_drive_file_outlined,color:skin.accent),title:Text(t('ملف','File')),onTap:()=>Navigator.pop(ctx,'file'))
  ])));
  if(choice=='image')await _pickImage();if(choice=='video')await _pickVideoSelf();if(choice=='sticker')await _pickImage(sticker:true);if(choice=='file')await _pickFile();
 }
 Future<void> _startRecording()async{
  final r=recorder??=AudioRecorder();
  try{if(!await r.hasPermission()){_notice(t('اسمح باستخدام الميكروفون أولًا','Allow microphone access first'));return;}
   final dir=await getTemporaryDirectory(),path='${dir.path}/ours_self_${DateTime.now().microsecondsSinceEpoch}.m4a';
   await r.start(const RecordConfig(encoder:AudioEncoder.aacLc,bitRate:96000,sampleRate:44100,numChannels:1,echoCancel:true,noiseSuppress:true),path:path);
   if(mounted)setState((){recordingPath=path;recording=true;});
  }catch(_){_notice(t('تعذر بدء التسجيل','Could not start recording'));}
 }
 Future<void> _stopRecording({bool send=true})async{
  final r=recorder;if(r==null||!recording)return;
  String? path;
  try{path=await r.stop();if(send&&path!=null){final file=File(path);if(await file.exists())await _uploadSelf(await file.readAsBytes(),'voice_${DateTime.now().millisecondsSinceEpoch}.m4a','audio');}}
  catch(_){_notice(t('تعذر إرسال التسجيل','Could not send recording'));}
  finally{if(path!=null){try{final file=File(path);if(await file.exists())await file.delete();}catch(_){}}
   if(mounted)setState((){recording=false;recordingPath=null;});}
 }
 Future<String> _signedSelf(String path){
  final old=urls[path];if(old!=null)return old;
  final future=db.storage.from('ours-direct-media').createSignedUrl(path,900);urls[path]=future;
  future.then((_){Future<void>.delayed(const Duration(minutes:10),(){
   if(identical(urls[path],future)){urls.remove(path);if(mounted)setState((){});}
  });},onError:(_){if(identical(urls[path],future))urls.remove(path);});
  return future;
 }
 Future<void> _openSelfImage(String path)async{
  try{final url=await _signedSelf(path);if(!mounted)return;
   await showDialog<void>(context:context,barrierColor:Colors.black,builder:(ctx)=>Dialog(backgroundColor:Colors.black,insetPadding:EdgeInsets.zero,child:SizedBox.expand(child:SafeArea(child:Column(children:[
    Expanded(child:Center(child:InteractiveViewer(minScale:.5,maxScale:5,child:Image.network(url,fit:BoxFit.contain)))),
    Padding(padding:const EdgeInsets.all(14),child:TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('إغلاق','Close'),style:const TextStyle(color:Colors.white))))
   ])))));
  }catch(_){_notice(t('تعذر فتح الصورة','Could not open image'));}
 }
 Future<void> _openSelfFile(String path)async{
  try{final url=await _signedSelf(path);if(!await launchUrl(Uri.parse(url),mode:LaunchMode.externalApplication))_notice(t('تعذر فتح الملف','Could not open file'));}
  catch(_){_notice(t('تعذر فتح الملف','Could not open file'));}
 }
 Future<void> _noteActions(Map<String,dynamic> row)async{
  final choice=await showModalBottomSheet<String>(context:context,backgroundColor:skin.bg,showDragHandle:true,builder:(ctx)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
   ListTile(leading:Icon(Icons.reply,color:skin.accent),title:Text(t('رد','Reply')),onTap:()=>Navigator.pop(ctx,'reply')),
   ListTile(leading:Icon(Icons.push_pin_outlined,color:skin.accent),title:Text(t('تثبيت / إلغاء التثبيت','Pin / unpin')),onTap:()=>Navigator.pop(ctx,'pin')),
   ListTile(leading:const Icon(Icons.delete_outline_rounded,color:Colors.redAccent),title:Text(t('حذف الرسالة','Delete note')),onTap:()=>Navigator.pop(ctx,'delete'))
  ])));
  if(choice=='reply'){setState(()=>replyTo=row);return;}
  if(choice=='pin')await _togglePin(row);if(choice=='delete')await _delete(row);
 }
 Future<void> _togglePin(Map<String,dynamic> row)async{
  try{final value=!(row['pinned']==true);await db.from('ours_self_messages').update({'pinned':value}).eq('id',row['id']);if(mounted)setState(()=>row['pinned']=value);}
  catch(_){_notice(t('تعذر تحديث التثبيت','Could not update pin'));}
 }
 Future<void> _delete(Map<String,dynamic> row)async{
  try{
   await db.from('ours_self_messages').delete().eq('id',row['id']);
   final type=row['message_type']?.toString()??'text',path=row['body']?.toString()??'';
   if(['image','file','audio','sticker'].contains(type)){try{await db.storage.from('ours-direct-media').remove([path]);}catch(_){}}
   if(mounted)setState(()=>rows.removeWhere((r)=>r['id'].toString()==row['id'].toString()));
  }catch(_){_notice(t('تعذر حذف الرسالة','Could not delete message'));}
 }
 void _jumpSelfMessage(String id){
  final index=rows.indexWhere((r)=>r['id'].toString()==id);if(index<0||!scroll.hasClients)return;
  scroll.animateTo(((rows.length-1-index)*150.0).clamp(0.0,scroll.position.maxScrollExtent),duration:const Duration(milliseconds:320),curve:Curves.easeOutCubic);
 }
 Future<void> _searchSelf()async{
  final controller=TextEditingController();
  final query=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:skin.bg,title:Text(t('البحث في رسائلك','Search saved messages')),content:TextField(controller:controller,autofocus:true,decoration:InputDecoration(hintText:t('اكتب كلمة للبحث','Search for a word'))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('إلغاء','Cancel'))),FilledButton(onPressed:()=>Navigator.pop(ctx,controller.text.trim()),child:Text(t('بحث','Search')))]));
  controller.dispose();if(query==null||query.isEmpty)return;
  final found=rows.where((r)=>(r['body']??'').toString().toLowerCase().contains(query.toLowerCase())||(r['file_name']??'').toString().toLowerCase().contains(query.toLowerCase())).toList();
  if(!mounted)return;
  await showModalBottomSheet<void>(context:context,backgroundColor:skin.bg,isScrollControlled:true,builder:(ctx)=>SafeArea(child:SizedBox(height:MediaQuery.of(ctx).size.height*.6,child:ListView(children:found.map((r)=>ListTile(title:Text((r['file_name']??r['body']).toString(),maxLines:2,overflow:TextOverflow.ellipsis),subtitle:Text(_selfTime(r['created_at'])),onTap:(){Navigator.pop(ctx);_jumpSelfMessage(r['id'].toString());})).toList()))));
 }
 String _selfTime(dynamic value){final date=DateTime.tryParse(value?.toString()??'')?.toLocal();return date==null?'':DateFormat(ar?'HH:mm':'h:mm a').format(date);}
 String _selfDate(DateTime date){final today=DateUtils.dateOnly(DateTime.now()),day=DateUtils.dateOnly(date);if(day==today)return t('اليوم','Today');if(day==today.subtract(const Duration(days:1)))return t('أمس','Yesterday');return _oursDate(day,ar);}
 void _bottom()=>WidgetsBinding.instance.addPostFrameCallback((_){if(scroll.hasClients)scroll.animateTo(0,duration:const Duration(milliseconds:220),curve:Curves.easeOut);});
 @override void dispose(){if(channel!=null)db.removeChannel(channel!);recorder?.dispose();input.dispose();scroll.dispose();super.dispose();}
 @override Widget build(BuildContext context){
  return Scaffold(backgroundColor:skin.bg,appBar:AppBar(backgroundColor:skin.bg,centerTitle:true,title:Column(mainAxisSize:MainAxisSize.min,children:[
   Text(t('مراسلة نفسي','Saved messages'),style:TextStyle(color:skin.accent,fontSize:16,fontWeight:FontWeight.w800)),
   Text(t('مساحة لا يراها غيرك','Private to you'),style:TextStyle(color:skin.accent.withValues(alpha:.75),fontSize:10))
  ]),actions:[
   IconButton(onPressed:_searchSelf,icon:Icon(Icons.search,color:skin.accent)),
   IconButton(onPressed:_chooseTheme,icon:Icon(Icons.palette_outlined,color:skin.accent)),
   IconButton(onPressed:_chooseWallpaper,icon:Icon(Icons.wallpaper_outlined,color:skin.accent))
  ]),
  body:Stack(children:[
   Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:_ChatAtmospherePainter(skin)))),
   if(wallpaperPath!=null)Positioned.fill(child:IgnorePointer(child:Opacity(opacity:.24,child:Image.file(File(wallpaperPath!),fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox.shrink())))),
   Column(children:[
    Expanded(child:loading?Center(child:CircularProgressIndicator(color:skin.accent)):rows.isEmpty
     ?Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[
      Icon(Icons.bookmark_add_outlined,color:skin.accent,size:46),const SizedBox(height:12),
      Text(t('ابدأ أول رسالة لنفسك','Write your first note'),style:const TextStyle(color:Colors.white,fontSize:17,fontWeight:FontWeight.w700)),
      const SizedBox(height:6),Text(t('احفظ أفكارك ورسائلك وصورك وملفاتك هنا.','Keep your ideas, messages, photos and files here.'),style:TextStyle(color:skin.accent),textAlign:TextAlign.center)
     ])))
     :ListView.builder(controller:scroll,padding:const EdgeInsets.fromLTRB(14,14,14,18),itemCount:rows.length,itemBuilder:(c,i){
      final row=rows[rows.length-1-i],type=(row['message_type']??'text').toString(),body=(row['body']??'').toString();
      final date=DateTime.tryParse(row['created_at']?.toString()??'')?.toLocal();
      final previous=i+1<rows.length?DateTime.tryParse(rows[rows.length-2-i]['created_at']?.toString()??'')?.toLocal():null;
      final showDate=date!=null&&(previous==null||DateUtils.dateOnly(date)!=DateUtils.dateOnly(previous));
      final showTimeDivider=!showDate&&date!=null&&previous!=null&&date.difference(previous)>const Duration(minutes:5);
      return Column(children:[
       if(showDate)Padding(padding:const EdgeInsets.symmetric(vertical:10),child:Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:5),decoration:BoxDecoration(color:skin.partner,borderRadius:BorderRadius.circular(14)),child:Text(_selfDate(date),style:TextStyle(color:skin.accent,fontSize:10,fontWeight:FontWeight.w700)))),
       if(showTimeDivider)Padding(padding:const EdgeInsets.symmetric(vertical:9),child:Center(child:Container(padding:const EdgeInsets.symmetric(horizontal:11,vertical:5),decoration:BoxDecoration(color:skin.partner.withValues(alpha:.78),borderRadius:BorderRadius.circular(18),border:Border.all(color:skin.accent.withValues(alpha:.16))),child:Text(_selfTime(row['created_at']),style:TextStyle(color:skin.accent,fontSize:10))))),
       Align(alignment:AlignmentDirectional.centerEnd,child:GestureDetector(onLongPress:()=>_noteActions(row),child:Container(
        constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*.84),margin:const EdgeInsets.symmetric(vertical:5),padding:(type=='image'||type=='video')?EdgeInsets.zero:const EdgeInsets.symmetric(horizontal:14,vertical:11),
        decoration:(type=='image'||type=='video')?null:BoxDecoration(color:skin.mine,borderRadius:BorderRadius.circular(18),border:Border.all(color:skin.accent.withValues(alpha:.2))),
        child:IntrinsicWidth(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
         if(row['reply_to']!=null&&rows.any((r)=>r['id'].toString()==row['reply_to'].toString()))
          Builder(builder:(ctx){final original=rows.firstWhere((r)=>r['id'].toString()==row['reply_to'].toString());return InkWell(onTap:()=>_jumpSelfMessage(original['id'].toString()),child:Container(margin:const EdgeInsets.only(bottom:7),padding:const EdgeInsets.all(7),decoration:BoxDecoration(color:skin.bg.withValues(alpha:.4),borderRadius:BorderRadius.circular(8)),child:Text((original['body']??original['file_name']??'').toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(color:skin.accent,fontSize:11))));}),
         if(type=='image'||type=='sticker')FutureBuilder<String>(future:_signedSelf(body),builder:(c,s)=>s.hasError?SizedBox(width:180,height:90,child:Center(child:Text(t('تعذر تحميل الصورة','Could not load image'),style:TextStyle(color:skin.accent)))):s.hasData?GestureDetector(onTap:()=>_openSelfImage(body),child:ClipRRect(borderRadius:BorderRadius.circular(12),child:Image.network(s.data!,width:225,height:220,fit:BoxFit.cover,errorBuilder:(_,__,___)=>SizedBox(width:180,height:90,child:Center(child:Text(t('تعذر عرض الصورة','Image unavailable'),style:TextStyle(color:skin.accent))))))):SizedBox(width:180,height:130,child:Center(child:CircularProgressIndicator(color:skin.accent))))
         else if(type=='file')InkWell(onTap:()=>_openSelfFile(body),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.insert_drive_file_outlined,color:skin.accent,size:30),const SizedBox(width:8),Flexible(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text((row['file_name']??body.split('/').last).toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white)),Text('${((row['file_size'] as num?)?.toInt()??0)/1024>1024?(((row['file_size'] as num?)?.toInt()??0)/1048576).toStringAsFixed(1)+' MB':(((row['file_size'] as num?)?.toInt()??0)/1024).toStringAsFixed(0)+' KB'} · ${(row['mime_type']??'').toString()}',style:TextStyle(color:skin.accent,fontSize:10))]))]))
         else if(type=='audio')_DirectAudioBubble(path:body,skin:skin,signed:_signedSelf,ar:ar)
         else if(type=='video')FutureBuilder<String>(future:_signedSelf(body),builder:(c,s)=>s.hasError?Text(t('تعذر تحميل الفيديو','Could not load video'),style:TextStyle(color:skin.accent)):s.hasData?_DirectVideoBubble(url:s.data!,skin:skin):SizedBox(width:180,height:130,child:Center(child:CircularProgressIndicator(color:skin.accent))))
         else SelectableText(body,style:const TextStyle(color:Colors.white,height:1.5)),
         if(row['pinned']==true)Padding(padding:const EdgeInsets.only(top:4),child:Icon(Icons.push_pin_rounded,color:skin.accent,size:12))
        ]))
       )))
      ]);
     })),
    SafeArea(top:false,child:Container(padding:const EdgeInsets.fromLTRB(8,8,8,10),decoration:BoxDecoration(color:skin.bg,border:Border(top:BorderSide(color:skin.accent.withValues(alpha:.2)))),child:Column(mainAxisSize:MainAxisSize.min,children:[
     if(replyTo!=null)Container(margin:const EdgeInsets.fromLTRB(10,0,10,6),padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:skin.partner,borderRadius:BorderRadius.circular(10)),child:Row(children:[Icon(Icons.reply,color:skin.accent,size:17),const SizedBox(width:7),Expanded(child:Text((replyTo!['file_name']??replyTo!['body']??'').toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:skin.accent,fontSize:11))),IconButton(onPressed:()=>setState(()=>replyTo=null),icon:const Icon(Icons.close,size:16))])),
     Row(children:[
      IconButton(onPressed:uploading||sending?null:_showAttachments,icon:uploading?SizedBox(width:18,height:18,child:CircularProgressIndicator(color:skin.accent,strokeWidth:2)):Icon(Icons.add_circle_outline,color:skin.accent)),
      Expanded(child:TextField(controller:input,minLines:1,maxLines:5,textInputAction:TextInputAction.send,onSubmitted:(_)=>_send(),decoration:InputDecoration(hintText:t('اكتب لنفسك…','Write a note…'),filled:true,fillColor:skin.partner,border:OutlineInputBorder(borderRadius:BorderRadius.circular(22),borderSide:BorderSide.none),contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:11)))),
      if(recording)IconButton(onPressed:()=>_stopRecording(send:false),icon:Icon(Icons.delete_outline,color:skin.accent)),
      IconButton(onPressed:recording?()=>_stopRecording():_startRecording,icon:Icon(recording?Icons.send_rounded:Icons.mic_none_rounded,color:skin.accent)),
      IconButton.filled(onPressed:sending||uploading?null:_send,style:IconButton.styleFrom(backgroundColor:skin.accent,foregroundColor:skin.bg),icon:sending?const SizedBox(width:17,height:17,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send_rounded))
     ])
    ])))
   ])
  ]));
 }
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
 @override void paint(Canvas canvas,Size size){for(final stroke in strokes){if(stroke.points.length<2)continue;final path=Path()..moveTo(stroke.points.first.dx*size.width,stroke.points.first.dy*size.height);for(final p in stroke.points.skip(1))path.lineTo(p.dx*size.width,p.dy*size.height);canvas.drawPath(path,Paint()..color=stroke.color..strokeWidth=4..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round..style=PaintingStyle.stroke);}}
 @override bool shouldRepaint(covariant _MarkupPainter old)=>old.strokes!=strokes;
}
class _ChatDetailsPage extends StatelessWidget{
 final String partnerId,partnerName;final _ChatSkin skin;final Widget Function() profile;final VoidCallback nickname,search,media,files;final Future<void> Function() themes,wallpaper;
 const _ChatDetailsPage({required this.partnerId,required this.partnerName,required this.skin,required this.profile,required this.nickname,required this.search,required this.media,required this.files,required this.themes,required this.wallpaper});
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
  tile(Icons.wallpaper_rounded,t('خلفية المحادثة','Chat wallpaper'),t('اختر صورة واضبط وضوحها بشكل مستقل عن الثيم','Choose a photo and adjust visibility independently'),()=>wallpaper()),
 ]));
 }
}
class _ChatDetailTile extends StatelessWidget{
 final IconData icon;final String title,subtitle;final Color accent;final VoidCallback onTap;
 const _ChatDetailTile({required this.icon,required this.title,required this.subtitle,required this.accent,required this.onTap});
 @override Widget build(BuildContext c)=>InkWell(onTap:onTap,borderRadius:BorderRadius.circular(17),child:Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.symmetric(horizontal:14,vertical:13),decoration:BoxDecoration(color:const Color(0xFF211D30),borderRadius:BorderRadius.circular(17),border:Border.all(color:accent.withValues(alpha:.15))),child:Row(children:[Container(width:38,height:38,decoration:BoxDecoration(color:accent.withValues(alpha:.12),borderRadius:BorderRadius.circular(12)),child:Icon(icon,color:accent,size:21)),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800)),const SizedBox(height:3),Text(subtitle,style:TextStyle(color:accent.withValues(alpha:.8),fontSize:11))])),Icon(Icons.chevron_right_rounded,color:accent.withValues(alpha:.6))])));}

