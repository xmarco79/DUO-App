import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _mn=Color(0xFF10101C),_mp=Color(0xFF29213D),_mg=Color(0xFFD9BC86),_ml=Color(0xFFB9A2D5);

class OursMusicPage extends StatefulWidget {
 const OursMusicPage({super.key});
 @override State<OursMusicPage> createState()=>_OursMusicPageState();
}
class _OursMusicPageState extends State<OursMusicPage>{
 final AudioPlayer player=AudioPlayer();
 final TextEditingController search=TextEditingController();
 final List<Map<String,String>> tracks=[];
 int current=-1; bool loading=true,busy=false,shuffle=false,repeatAll=false;
 Duration position=Duration.zero,duration=Duration.zero;
 bool get ar=>Localizations.localeOf(context).languageCode=='ar';
 String t(String a,String e)=>ar?a:e;
 Map<String,String>? get selected=>current>=0&&current<tracks.length?tracks[current]:null;

 @override void initState(){
  super.initState();_restore();
  player.onPositionChanged.listen((v){if(mounted)setState(()=>position=v);});
  player.onDurationChanged.listen((v){if(mounted)setState(()=>duration=v);});
  player.onPlayerStateChanged.listen((_){if(mounted)setState((){});});
  player.onPlayerComplete.listen((_){if(tracks.isEmpty)return;if(current<tracks.length-1||repeatAll||shuffle){_next();}else if(mounted)setState(()=>position=Duration.zero);});
 }
 Future<Directory> _dir()async{final d=await getApplicationDocumentsDirectory();final out=Directory('${d.path}/ours_music');if(!await out.exists())await out.create(recursive:true);return out;}
 Future<void> _restore()async{try{final p=await SharedPreferences.getInstance();final raw=p.getString('ours_local_music_v1');if(raw!=null){final list=(jsonDecode(raw) as List).whereType<Map>().map((e)=>Map<String,String>.from(e)).where((e)=>File(e['path']??'').existsSync()).toList();if(mounted)setState(()=>tracks.addAll(list));}}catch(_){}if(mounted)setState(()=>loading=false);}
 Future<void> _persist()async{final p=await SharedPreferences.getInstance();await p.setString('ours_local_music_v1',jsonEncode(tracks));}
 Future<void> _add()async{
  if(busy)return;
  try{final result=await FilePicker.platform.pickFiles(type:FileType.audio,allowMultiple:true,withData:false);if(result==null)return;setState(()=>busy=true);final dir=await _dir();int added=0;
   for(final f in result.files){final path=f.path;if(path==null)continue;final src=File(path);if(!await src.exists())continue;final safe=f.name.replaceAll(RegExp(r'[^a-zA-Z0-9._ -]'),'_');final target=File('${dir.path}/${DateTime.now().microsecondsSinceEpoch}_$safe');await src.copy(target.path);tracks.add({'name':f.name,'path':target.path});added++;}
   await _persist();if(mounted){setState(()=>current=current<0&&tracks.isNotEmpty?0:current);_notice(added>0?t('أُضيف $added مقطع إلى مكتبتك','Added $added tracks'):t('تعذرت قراءة الملفات المحددة','Could not read selected files'));}
  }catch(e){_notice(t('تعذرت إضافة الموسيقى: $e','Could not import music: $e'));}finally{if(mounted)setState(()=>busy=false);}
 }
 Future<void> _play(int i)async{if(i<0||i>=tracks.length||busy)return;setState(()=>busy=true);try{await player.stop();setState(()=>current=i);position=Duration.zero;duration=Duration.zero;await player.play(DeviceFileSource(tracks[i]['path']!));}catch(e){_notice(t('تعذر تشغيل الملف: $e','Could not play file: $e'));}finally{if(mounted)setState(()=>busy=false);}}
 Future<void> _toggle()async{if(selected==null){if(tracks.isNotEmpty)await _play(0);return;}try{if(player.state==PlayerState.playing){await player.pause();}else if(player.state==PlayerState.paused){await player.resume();}else{await _play(current);}}catch(e){_notice(e.toString());}}
 Future<void> _next()async{if(tracks.isEmpty)return;final i=shuffle&&tracks.length>1?Random().nextInt(tracks.length):current+1;if(i>=tracks.length&&!repeatAll&&!shuffle){await player.stop();if(mounted)setState(()=>position=Duration.zero);return;}await _play(i%tracks.length);}
 Future<void> _prev()async{if(tracks.isEmpty)return;if(position>const Duration(seconds:3)){await player.seek(Duration.zero);return;}await _play((current-1+tracks.length)%tracks.length);}
 Future<void> _remove(int i)async{final path=tracks[i]['path']!;if(i==current)await player.stop();try{final f=File(path);if(await f.exists())await f.delete();}catch(_){}setState((){tracks.removeAt(i);if(tracks.isEmpty)current=-1;else if(i<current)current--;else if(i==current)current=i.clamp(0,tracks.length-1);});await _persist();}
 void _notice(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
 String _time(Duration d)=>'${d.inMinutes.remainder(60).toString().padLeft(2,'0')}:${d.inSeconds.remainder(60).toString().padLeft(2,'0')}';
 @override void dispose(){search.dispose();player.dispose();super.dispose();}

 @override Widget build(BuildContext context){
  final q=search.text.trim().toLowerCase();final visible=tracks.asMap().entries.where((e)=>e.value['name']!.toLowerCase().contains(q)).toList();final playing=player.state==PlayerState.playing;final max=duration.inMilliseconds>0?duration.inMilliseconds:1;final pos=position.inMilliseconds.clamp(0,max);
  return ListView(padding:const EdgeInsets.all(16),children:[
   Container(padding:const EdgeInsets.all(20),decoration:BoxDecoration(gradient:const LinearGradient(colors:[_mp,_mn],begin:Alignment.topRight,end:Alignment.bottomLeft),borderRadius:BorderRadius.circular(24),border:Border.all(color:_mg.withValues(alpha:.25))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[const Icon(Icons.graphic_eq_rounded,color:_mg,size:34),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t('موسيقانا','OUR MUSIC'),style:const TextStyle(color:_mg,fontWeight:FontWeight.bold,letterSpacing:2)),Text(t('مكتبتك داخل OURS','Your library inside OURS'),style:const TextStyle(color:_ml,fontSize:12))])),IconButton.filledTonal(onPressed:busy?null:_add,icon:const Icon(Icons.add_rounded),tooltip:t('إضافة موسيقى','Add music'))]),
    const SizedBox(height:12),Text(t('استمع بطريقتك','Listen your way'),style:const TextStyle(fontSize:21,fontWeight:FontWeight.bold)),const SizedBox(height:6),
    Text(t('استورد ملفاتك الصوتية واحفظها داخل التطبيق لتشغيلها لاحقًا دون إنترنت أو الانتقال إلى تطبيق آخر.','Import audio files and keep them inside the app for offline playback without switching to another app.'),style:const TextStyle(color:_ml,fontSize:12,height:1.5))
   ])),
   const SizedBox(height:14),
   Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:_mp,borderRadius:BorderRadius.circular(22)),child:Column(children:[
    Container(width:116,height:116,decoration:BoxDecoration(color:_mn,borderRadius:BorderRadius.circular(24)),child:const Icon(Icons.album_rounded,color:_mg,size:70)),
    const SizedBox(height:12),Text(selected?['name']??t('لا يوجد مقطع محدد','No track selected'),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16)),
    Text(t('مكتبة محلية','Local library'),style:const TextStyle(color:_ml,fontSize:11)),
    Slider(value:pos.toDouble(),max:max.toDouble(),activeColor:_mg,inactiveColor:_ml.withValues(alpha:.2),onChanged:selected==null?null:(v)=>setState(()=>position=Duration(milliseconds:v.round())),onChangeEnd:selected==null?null:(v)=>player.seek(Duration(milliseconds:v.round()))),
    Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(_time(position),style:const TextStyle(color:_ml,fontSize:10)),Text(_time(duration),style:const TextStyle(color:_ml,fontSize:10))]),
    Row(mainAxisAlignment:MainAxisAlignment.center,children:[
     IconButton(onPressed:tracks.isEmpty?null:()=>setState(()=>shuffle=!shuffle),color:shuffle?_mg:_ml,icon:const Icon(Icons.shuffle_rounded)),
     IconButton(onPressed:tracks.isEmpty?null:_prev,iconSize:30,icon:const Icon(Icons.skip_previous_rounded)),
     SizedBox(width:58,height:58,child:FilledButton(onPressed:busy||tracks.isEmpty?null:_toggle,style:FilledButton.styleFrom(backgroundColor:_mg,foregroundColor:_mn,shape:const CircleBorder(),padding:EdgeInsets.zero),child:busy?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)):Icon(playing?Icons.pause_rounded:Icons.play_arrow_rounded,size:32))),
     IconButton(onPressed:tracks.isEmpty?null:_next,iconSize:30,icon:const Icon(Icons.skip_next_rounded)),
     IconButton(onPressed:tracks.isEmpty?null:()=>setState(()=>repeatAll=!repeatAll),color:repeatAll?_mg:_ml,icon:const Icon(Icons.repeat_rounded)),
    ])
   ])),
   const SizedBox(height:18),Row(children:[Expanded(child:Text(t('قائمة التشغيل','PLAYLIST'),style:const TextStyle(color:_mg,fontWeight:FontWeight.bold,letterSpacing:1.4))),Text('${tracks.length} ${t('مقطع','tracks')}',style:const TextStyle(color:_ml,fontSize:11))]),
   const SizedBox(height:9),TextField(controller:search,onChanged:(_)=>setState((){}),decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:t('ابحث في مكتبتك','Search your library'),filled:true,fillColor:_mp,border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide.none))),
   const SizedBox(height:10),
   if(loading)const Center(child:CircularProgressIndicator(color:_mg))
   else if(tracks.isEmpty)Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:_mp,borderRadius:BorderRadius.circular(18)),child:Column(children:[const Icon(Icons.library_music_outlined,color:_ml,size:42),const SizedBox(height:8),Text(t('مكتبتك فارغة','Your library is empty')),const SizedBox(height:6),Text(t('أضف ملفات MP3 أو M4A أو WAV من جهازك.','Add MP3, M4A or WAV files from your device.'),textAlign:TextAlign.center,style:const TextStyle(color:_ml,fontSize:12)),const SizedBox(height:10),FilledButton.icon(onPressed:busy?null:_add,icon:const Icon(Icons.library_add),label:Text(t('إضافة مقاطع','Add tracks')))]))
   else if(visible.isEmpty)Padding(padding:const EdgeInsets.all(20),child:Text(t('لا توجد نتائج','No results'),textAlign:TextAlign.center))
   else ...visible.map((e){final i=e.key;final track=e.value;final active=i==current;return Container(margin:const EdgeInsets.only(bottom:7),decoration:BoxDecoration(color:active?_mg.withValues(alpha:.12):_mp,borderRadius:BorderRadius.circular(15),border:Border.all(color:active?_mg.withValues(alpha:.4):Colors.transparent)),child:ListTile(onTap:()=>_play(i),leading:Icon(active&&playing?Icons.equalizer_rounded:Icons.music_note_rounded,color:active?_mg:_ml),title:Text(track['name']!,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:active?_mg:Colors.white,fontSize:13)),subtitle:Text(active?t('يعمل الآن','Now playing'):t('محفوظ داخل التطبيق','Stored in app'),style:const TextStyle(color:_ml,fontSize:10)),trailing:PopupMenuButton<String>(onSelected:(v){if(v=='remove')_remove(i);},itemBuilder:(_)=>[PopupMenuItem(value:'remove',child:Text(t('إزالة','Remove')))])));}),
   if(busy)const Padding(padding:EdgeInsets.all(8),child:LinearProgressIndicator(color:_mg)),
   const SizedBox(height:8),Text(t('تُشغّل الملفات التي تختارها من جهازك فقط؛ لا يوجد بث أو تنزيل لموسيقى محمية بحقوق النشر.','Only audio files you choose from your device are played; the app does not stream or download copyrighted music.'),style:const TextStyle(color:_ml,fontSize:10))
  ]);
 }
}
