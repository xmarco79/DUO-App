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
 _ChatSkin('ours','هوية OURS','OURS Signature',Color(0xFF10101C),Color(0xFF48316B),Color(0xFF29213D),Color(0xFFD9BC86)),
 _ChatSkin('sea','نسيم البحر','Sea Breeze',Color(0xFF071B2A),Color(0xFF087E9B),Color(0xFF123B53),Color(0xFF8BE7E1)),
 _ChatSkin('tropical','شاطئ استوائي','Tropical Shore',Color(0xFF09252B),Color(0xFF12A99A),Color(0xFF17515A),Color(0xFFFFD79A)),
 _ChatSkin('forest','الغابة الهادئة','Forest Calm',Color(0xFF0B1D17),Color(0xFF26835D),Color(0xFF1B4937),Color(0xFFB3E7B8)),
 _ChatSkin('wildflower','زهور برية','Wildflower',Color(0xFF21152A),Color(0xFFAD65B8),Color(0xFF4C3157),Color(0xFFE8B9F2)),
 _ChatSkin('love','حب','Love',Color(0xFF28121E),Color(0xFFBD4778),Color(0xFF57263D),Color(0xFFFFC4D8)),
 _ChatSkin('sakura','ساكورا','Sakura',Color(0xFF251624),Color(0xFFB968A1),Color(0xFF55364F),Color(0xFFFFD5E9)),
 _ChatSkin('sunset','غروب','Sunset Glow',Color(0xFF27151A),Color(0xFFD66A45),Color(0xFF5B342D),Color(0xFFFFD08A)),
 _ChatSkin('starlight','ضوء النجوم','Starlight',Color(0xFF0C1128),Color(0xFF536BD1),Color(0xFF28365E),Color(0xFFC4D4FF)),
 _ChatSkin('lavender','لافندر','Lavender Dream',Color(0xFF1B1529),Color(0xFF8067BD),Color(0xFF453653),Color(0xFFDCCBFF)),
 _ChatSkin('winter','شتاء','Winter Frost',Color(0xFF101D2B),Color(0xFF579BC8),Color(0xFF29465D),Color(0xFFD3F0FF)),
 _ChatSkin('coffee','قهوة','Coffee House',Color(0xFF211711),Color(0xFFAD754A),Color(0xFF563B2D),Color(0xFFE8C69D)),
 _ChatSkin('meadow','مرج','Meadow',Color(0xFF142019),Color(0xFF79A83C),Color(0xFF3E5932),Color(0xFFD9F49B)),
 _ChatSkin('aurora','شفق قطبي','Aurora',Color(0xFF0A1D27),Color(0xFF258F83),Color(0xFF204B5B),Color(0xFFB7FFE6)),
 _ChatSkin('clear_sky','سماء صافية','Clear Sky',Color(0xFF101F32),Color(0xFF4D91C9),Color(0xFF304F70),Color(0xFFCBEAFF)),
 _ChatSkin('violet_night','ليلة بنفسجية','Violet Night',Color(0xFF171329),Color(0xFF7652B8),Color(0xFF40345F),Color(0xFFE0CEFF)),
];


String _normalizeOursSkinId(String id){
 const aliases={'ocean':'sea','rose':'love','cosmos':'starlight','desert':'coffee','glacier':'winter','ember':'sunset','neon':'violet_night','mint':'meadow','candy':'wildflower','mono':'ours'};
 return aliases[id]??id;
}

String _oursMessageTimestamp(DateTime date,bool arabic){
 final now=DateTime.now(),today=DateUtils.dateOnly(now),day=DateUtils.dateOnly(date);
 final time=DateFormat('h:mm a',arabic?'ar':'en').format(date);
 if(day==today)return time;
 if(day==today.subtract(const Duration(days:1)))return '${arabic?'أمس':'Yesterday'} $time';
 return '${_oursDate(day,arabic,withYear:false)} $time';
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
  if(size.isEmpty)return;
  final rect=Offset.zero&size;
  final accent=skin.accent;
  final palette=Color.lerp(skin.bg,skin.partner,.52)!;
  canvas.drawRect(rect,Paint()..shader=LinearGradient(
   begin:Alignment.topLeft,end:Alignment.bottomRight,
   colors:[skin.bg,palette,skin.bg],
  ).createShader(rect));
  void glow(Offset center,double radius,Color color,double opacity){
   canvas.drawCircle(center,radius,Paint()..shader=RadialGradient(colors:[color.withValues(alpha:opacity),color.withValues(alpha:0)]).createShader(Rect.fromCircle(center:center,radius:radius)));
  }
  void heart(Offset c,double r,Color color){
   final p=Path()..moveTo(c.dx,c.dy+r*.42)
    ..cubicTo(c.dx-r*.95,c.dy-r*.12,c.dx-r*.58,c.dy-r*.86,c.dx,c.dy-r*.38)
    ..cubicTo(c.dx+r*.58,c.dy-r*.86,c.dx+r*.95,c.dy-r*.12,c.dx,c.dy+r*.42)..close();
   canvas.drawPath(p,Paint()..color=color);
  }
  void flower(Offset c,double r,Color color,{Color center=const Color(0xFFFFD98B)}){
   for(var k=0;k<6;k++){
    canvas.save();canvas.translate(c.dx,c.dy);canvas.rotate(k*math.pi/3);
    canvas.drawOval(Rect.fromCenter(center:Offset(0,-r*.62),width:r*.55,height:r*.88),Paint()..color=color);
    canvas.restore();
   }
   canvas.drawCircle(c,r*.22,Paint()..color=center);
  }
  void fir(Offset c,double h,Color color){
   final trunk=Rect.fromCenter(center:Offset(c.dx,c.dy+h*.32),width:h*.055,height:h*.55);
   canvas.drawRect(trunk,Paint()..color=Color.lerp(color,Colors.black,.28)!);
   for(var tier=0;tier<4;tier++){
    final y=c.dy-h*.48+tier*h*.27;
    final w=h*(.30+tier*.10);
    final p=Path()..moveTo(c.dx,y)..lineTo(c.dx-w,y+h*.30)..quadraticBezierTo(c.dx,y+h*.23,c.dx+w,y+h*.30)..close();
    canvas.drawPath(p,Paint()..color=Color.lerp(color,Colors.black,tier*.055)!);
   }
  }
  void cloud(Offset c,double w,double h,Color color){
   final p=Path()..addOval(Rect.fromCenter(center:Offset(c.dx-w*.22,c.dy),width:w*.55,height:h))
    ..addOval(Rect.fromCenter(center:Offset(c.dx,c.dy-h*.14),width:w*.62,height:h*1.2))
    ..addOval(Rect.fromCenter(center:Offset(c.dx+w*.22,c.dy),width:w*.55,height:h))
    ..addRect(Rect.fromLTRB(c.dx-w*.4,c.dy-h*.1,c.dx+w*.4,c.dy+h*.38));
   canvas.drawPath(p,Paint()..color=color);
  }
  void star(Offset c,double r,Color color){
   final p=Path()..moveTo(c.dx,c.dy-r)..quadraticBezierTo(c.dx+r*.18,c.dy-r*.18,c.dx+r,c.dy)
    ..quadraticBezierTo(c.dx+r*.18,c.dy+r*.18,c.dx,c.dy+r)
    ..quadraticBezierTo(c.dx-r*.18,c.dy+r*.18,c.dx-r,c.dy)
    ..quadraticBezierTo(c.dx-r*.18,c.dy-r*.18,c.dx,c.dy-r)..close();
   canvas.drawPath(p,Paint()..color=color);
  }
  void hill(double y,Color color,double amplitude,double phase){
   final p=Path()..moveTo(0,size.height*y)
    ..cubicTo(size.width*.22,size.height*(y-amplitude),size.width*.72,size.height*(y+amplitude*.55),size.width,size.height*(y-amplitude*.2))
    ..lineTo(size.width,size.height)..lineTo(0,size.height)..close();
   canvas.drawPath(p,Paint()..color=color);
  }
  // Atmospheric lighting is stronger at the edges so message text remains clear.
  glow(Offset(size.width*.16,size.height*.12),size.width*.55,accent,.075);
  glow(Offset(size.width*.88,size.height*.82),size.width*.52,skin.partner,.09);

  switch(skin.id){
   case 'forest':
    glow(Offset(size.width*.52,size.height*.58),size.width*.65,const Color(0xFF4E9871),.12);
    hill(.70,const Color(0xFF09251B).withValues(alpha:.58),.12,.1);
    hill(.83,const Color(0xFF071811).withValues(alpha:.62),.09,.4);
    for(var layer=0;layer<3;layer++){
     final y=size.height*(.52+layer*.18);
     final h=size.height*(.32+layer*.08);
     final shade=[const Color(0xFF26533B),const Color(0xFF153B2B),const Color(0xFF0A2118)][layer].withValues(alpha:.43+layer*.08);
     for(var i=0;i<10;i++){
      final x=size.width*((i*127+layer*43)%997)/997;
      fir(Offset(x,y),h*(.72+((i*5)%5)*.12),shade);
     }
    }
    // Soft fog bands between the forest silhouettes.
    for(var band=0;band<3;band++){
     final y=size.height*(.48+band*.13);
     canvas.drawRect(Rect.fromLTRB(0,y,size.width,y+size.height*.045),Paint()..shader=LinearGradient(colors:[Colors.white.withValues(alpha:.015),const Color(0xFF9ACFB2).withValues(alpha:.055),Colors.white.withValues(alpha:.012)]).createShader(Rect.fromLTRB(0,y,size.width,y+size.height*.045)));
    }
    for(var i=0;i<34;i++){
     final x=size.width*((i*53)%997)/997,y=size.height*(.77+((i*19)%20)/100);
     final leaf=Path()..moveTo(x,y)..quadraticBezierTo(x-size.width*.035,y-size.height*.025,x-size.width*.018,y-size.height*.055)..quadraticBezierTo(x+size.width*.014,y-size.height*.04,x,y)..close();
     canvas.drawPath(leaf,Paint()..color=const Color(0xFF79B68A).withValues(alpha:.12));
    }
    break;
   case 'wildflower':
    hill(.73,const Color(0xFF263B2D).withValues(alpha:.35),.10,.3);
    hill(.86,const Color(0xFF16291F).withValues(alpha:.55),.08,.6);
    for(var i=0;i<44;i++){
     final x=size.width*((i*71)%997)/997,y=size.height*(.65+((i*37)%34)/100),h=size.height*(.055+((i*13)%15)/100);
     canvas.drawLine(Offset(x,y),Offset(x-size.width*.008,y-h),Paint()..color=const Color(0xFF8CB17C).withValues(alpha:.22)..strokeWidth=1.3);
     if(i%2==0)canvas.drawOval(Rect.fromCenter(center:Offset(x+size.width*.012,y-h*.52),width:size.width*.027,height:h*.24),Paint()..color=const Color(0xFF75A77C).withValues(alpha:.18));
     flower(Offset(x-size.width*.008,y-h),3.5+(i%5)*.8,[const Color(0xFFE8C9F7),const Color(0xFFFFD4A1),const Color(0xFFFFBFD7),const Color(0xFFC9DDFF)][i%4].withValues(alpha:.42));
    }
    break;
   case 'love':
    glow(Offset(size.width*.5,size.height*.4),size.width*.75,const Color(0xFFBD4778),.10);
    for(var i=0;i<26;i++){
     final x=size.width*((i*113)%997)/997,y=size.height*((i*157)%991)/991,r=8.0+(i%6)*5;
     heart(Offset(x,y),r,accent.withValues(alpha:.10+(i%4)*.018));
    }
    for(var i=0;i<30;i++){
     final x=size.width*((i*59)%991)/991,y=size.height*((i*89)%997)/997;
     canvas.save();canvas.translate(x,y);canvas.rotate(i*.61);
     canvas.drawOval(Rect.fromCenter(center:Offset.zero,width:5+(i%3)*2,height:12+(i%4)*3),Paint()..color=const Color(0xFFEFA0C2).withValues(alpha:.20));
     canvas.restore();
    }
    for(var i=0;i<8;i++)star(Offset(size.width*((i*139)%997)/997,size.height*((i*79)%991)/991),3.5,accent.withValues(alpha:.28));
    break;
   case 'starlight':
    glow(Offset(size.width*.76,size.height*.18),size.width*.25,const Color(0xFFFFE8B2),.18);
    final moon=Offset(size.width*.77,size.height*.17);
    canvas.drawCircle(moon,size.width*.095,Paint()..color=const Color(0xFFFFE9B9).withValues(alpha:.22));
    canvas.drawCircle(Offset(moon.dx+size.width*.04,moon.dy-size.width*.025),size.width*.086,Paint()..color=skin.bg);
    final constellation=[Offset(.12,.15),Offset(.27,.29),Offset(.41,.19),Offset(.56,.34),Offset(.73,.27),Offset(.89,.12),Offset(.81,.52),Offset(.58,.59)];
    final line=Paint()..color=accent.withValues(alpha:.19)..strokeWidth=1.0;
    for(var i=0;i<constellation.length-1;i++){final a=constellation[i],b=constellation[i+1];canvas.drawLine(Offset(a.dx*size.width,a.dy*size.height),Offset(b.dx*size.width,b.dy*size.height),line);}
    for(var i=0;i<120;i++){
     final x=size.width*((i*71)%997)/997,y=size.height*((i*137)%991)/991;
     final r=1.0+(i%4)*.7;canvas.drawCircle(Offset(x,y),r,Paint()..color=const Color(0xFFDCE7FF).withValues(alpha:.18+(i%3)*.04));
     if(i%11==0)star(Offset(x,y),r*2.4,accent.withValues(alpha:.27));
    }
    for(final p in constellation)star(Offset(p.dx*size.width,p.dy*size.height),3.4,accent.withValues(alpha:.32));
    break;
   case 'winter':
    hill(.78,const Color(0xFF8AC7E5).withValues(alpha:.10),.10,.2);
    hill(.88,const Color(0xFFB5DDF0).withValues(alpha:.12),.08,.5);
    for(var i=0;i<42;i++){
     final x=size.width*((i*83)%997)/997,y=size.height*((i*149)%991)/991,r=3.0+(i%6)*2.0;
     for(var arm=0;arm<6;arm++){final a=arm*math.pi/3;canvas.drawLine(Offset(x,y),Offset(x+math.cos(a)*r,y+math.sin(a)*r),Paint()..color=accent.withValues(alpha:.23)..strokeWidth=1.0);}
    }
    break;
   case 'coffee':
    glow(Offset(size.width*.76,size.height*.24),size.width*.33,const Color(0xFFD29A5D),.10);
    final cup=RRect.fromRectAndRadius(Rect.fromCenter(center:Offset(size.width*.76,size.height*.26),width:size.width*.23,height:size.height*.12),const Radius.circular(14));
    canvas.drawRRect(cup,Paint()..color=const Color(0xFFD6B48B).withValues(alpha:.18));
    canvas.drawRRect(cup,Paint()..color=accent.withValues(alpha:.38)..style=PaintingStyle.stroke..strokeWidth=1.5);
    canvas.drawCircle(Offset(size.width*.88,size.height*.26),size.width*.04,Paint()..color=accent.withValues(alpha:.22)..style=PaintingStyle.stroke..strokeWidth=2);
    for(var i=0;i<4;i++){
     final steam=Path()..moveTo(size.width*(.68+i*.035),size.height*.18)..cubicTo(size.width*(.65+i*.035),size.height*.13,size.width*(.73+i*.035),size.height*.09,size.width*(.69+i*.035),size.height*.04);
     canvas.drawPath(steam,Paint()..color=accent.withValues(alpha:.20)..style=PaintingStyle.stroke..strokeWidth=2.1);
    }
    for(var i=0;i<36;i++){
     final x=size.width*((i*67)%997)/997,y=size.height*((i*127)%991)/991;
     canvas.save();canvas.translate(x,y);canvas.rotate(i*.62);
     canvas.drawOval(Rect.fromCenter(center:Offset.zero,width:7+(i%4)*2,height:12+(i%3)*3),Paint()..color=accent.withValues(alpha:.10));
     canvas.restore();
    }
    break;
   case 'meadow':
    hill(.76,const Color(0xFF395A2C).withValues(alpha:.20),.10,.3);
    hill(.87,const Color(0xFF1D3521).withValues(alpha:.42),.08,.7);
    for(var i=0;i<70;i++){
     final x=size.width*((i*37)%997)/997,y=size.height*(.67+((i*17)%31)/100),h=size.height*(.025+((i*11)%10)/100);
     canvas.drawLine(Offset(x,y),Offset(x+math.sin(i*.7)*size.width*.018,y-h),Paint()..color=accent.withValues(alpha:.19)..strokeWidth=1.4);
    }
    for(var i=0;i<26;i++){final x=size.width*((i*79)%997)/997,y=size.height*(.72+((i*13)%25)/100);flower(Offset(x,y-size.height*.04),4+(i%3),const Color(0xFFFFE6B7).withValues(alpha:.28));}
    break;
   case 'clear_sky':
    glow(Offset(size.width*.78,size.height*.19),size.width*.27,const Color(0xFFFFE3A5),.12);
    for(var i=0;i<9;i++){final x=size.width*(.08+i*.13),y=size.height*(.16+(i%4)*.11);cloud(Offset(x,y),size.width*(.14+(i%3)*.035),size.height*.055,Colors.white.withValues(alpha:.075));}
    hill(.74,const Color(0xFF456E91).withValues(alpha:.08),.06,.5);
    break;
   case 'lavender':
    hill(.84,const Color(0xFF3C2B50).withValues(alpha:.24),.08,.2);
    for(var i=0;i<36;i++){
     final x=size.width*((i*73)%997)/997,y=size.height*(.86+((i*19)%12)/100),h=size.height*(.10+((i*7)%13)/100);
     canvas.drawLine(Offset(x,y),Offset(x-size.width*.01,y-h),Paint()..color=const Color(0xFF728B5A).withValues(alpha:.23)..strokeWidth=1.3);
     for(var j=0;j<6;j++){final fy=y-h+j*h*.13;canvas.drawOval(Rect.fromCenter(center:Offset(x-size.width*.008,fy),width:6,height:11),Paint()..color=const Color(0xFFB9A2D5).withValues(alpha:.30));}
    }
    break;
   case 'sea':
    glow(Offset(size.width*.52,size.height*.55),size.width*.55,const Color(0xFF3DC6D1),.11);
    for(var layer=0;layer<6;layer++){
     final y=size.height*(.50+layer*.075);
     final wave=Path()..moveTo(0,y)..cubicTo(size.width*.22,y-size.height*.05,size.width*.62,y+size.height*.04,size.width,y-size.height*.035)..lineTo(size.width,size.height)..lineTo(0,size.height)..close();
     canvas.drawPath(wave,Paint()..color=Color.lerp(const Color(0xFF117A9C),const Color(0xFF05283B),layer/6)!.withValues(alpha:.11+layer*.025));
     final highlight=Path()..moveTo(size.width*.08,y)..quadraticBezierTo(size.width*.42,y-size.height*.025,size.width*.75,y+size.height*.01);
     canvas.drawPath(highlight,Paint()..color=accent.withValues(alpha:.16)..style=PaintingStyle.stroke..strokeWidth=1.5);
    }
    for(var i=0;i<22;i++){final x=size.width*((i*83)%997)/997,y=size.height*((i*137)%991)/991;canvas.drawCircle(Offset(x,y),2+(i%4),Paint()..color=accent.withValues(alpha:.09));}
    break;
   case 'tropical':
    glow(Offset(size.width*.75,size.height*.20),size.width*.35,const Color(0xFFFFD27E),.10);
    for(var i=0;i<24;i++){
     final x=size.width*((i*61)%997)/997,y=size.height*((i*113)%991)/991;
     canvas.save();canvas.translate(x,y);canvas.rotate((i%9-4)*.22);
     final leaf=Path()..moveTo(0,0)..quadraticBezierTo(size.width*.04,-size.height*.07,size.width*.12,-size.height*.018)..quadraticBezierTo(size.width*.05,size.height*.018,0,0);
     canvas.drawPath(leaf,Paint()..color=accent.withValues(alpha:.15));
     canvas.drawLine(Offset.zero,Offset(size.width*.10,-size.height*.015),Paint()..color=accent.withValues(alpha:.12)..strokeWidth=1);
     canvas.restore();
    }
    for(var layer=0;layer<4;layer++){final p=Path()..moveTo(0,size.height*(.56+layer*.08))..cubicTo(size.width*.2,size.height*(.48+layer*.08),size.width*.68,size.height*(.63+layer*.07),size.width,size.height*(.53+layer*.08))..lineTo(size.width,size.height)..lineTo(0,size.height)..close();canvas.drawPath(p,Paint()..color=const Color(0xFF168F85).withValues(alpha:.055+layer*.018));}
    break;
   case 'aurora':
    glow(Offset(size.width*.5,size.height*.25),size.width*.55,const Color(0xFF58D4B5),.12);
    for(var i=0;i<5;i++){
     final p=Path()..moveTo(-size.width*.12,size.height*(.12+i*.09))
      ..cubicTo(size.width*.2,size.height*(.02+i*.11),size.width*.57,size.height*(.45+i*.08),size.width*1.12,size.height*(.11+i*.14));
     canvas.drawPath(p,Paint()..color=[accent,const Color(0xFF70BCEB),const Color(0xFF66E0B9),const Color(0xFF9D83D8),const Color(0xFF4FA9C7)][i].withValues(alpha:.13)..style=PaintingStyle.stroke..strokeWidth=24.0+i*9.0..maskFilter=const MaskFilter.blur(BlurStyle.normal,16));
    }
    for(var i=0;i<55;i++){final x=size.width*((i*71)%997)/997,y=size.height*((i*137)%991)/991;star(Offset(x,y),1.8+(i%3),accent.withValues(alpha:.16));}
    break;
   case 'sunset':
    glow(Offset(size.width*.78,size.height*.18),size.width*.28,const Color(0xFFFFB46C),.18);
    canvas.drawCircle(Offset(size.width*.78,size.height*.19),size.width*.14,Paint()..color=const Color(0xFFFFC27C).withValues(alpha:.16));
    hill(.66,const Color(0xFF6B3D3A).withValues(alpha:.18),.09,.1);
    hill(.78,const Color(0xFF3C252B).withValues(alpha:.26),.08,.6);
    for(var i=0;i<7;i++){final y=size.height*(.25+i*.045);canvas.drawLine(Offset(size.width*.65,y),Offset(size.width*.91,y),Paint()..color=accent.withValues(alpha:.10)..strokeWidth=1.2);}
    break;
   case 'sakura':
    glow(Offset(size.width*.25,size.height*.15),size.width*.32,const Color(0xFFFFB5D4),.10);
    for(var i=0;i<3;i++){
     final branch=Path()..moveTo(size.width*(.04+i*.08),size.height*(.08+i*.13))..quadraticBezierTo(size.width*.35,size.height*(.22+i*.11),size.width*.68,size.height*(.06+i*.18))..quadraticBezierTo(size.width*.85,size.height*(.13+i*.14),size.width*.97,size.height*(.29+i*.11));
     canvas.drawPath(branch,Paint()..color=const Color(0xFF6E465D).withValues(alpha:.24)..style=PaintingStyle.stroke..strokeWidth=3.0);
    }
    for(var i=0;i<45;i++){
     final x=size.width*((i*83)%997)/997,y=size.height*((i*137)%991)/991;
     canvas.save();canvas.translate(x,y);canvas.rotate(i*.41);
     canvas.drawOval(Rect.fromCenter(center:Offset.zero,width:6+(i%3)*2,height:12+(i%4)*2),Paint()..color=const Color(0xFFFFC6DF).withValues(alpha:.26));
     canvas.restore();
    }
    break;
   case 'violet_night':
    glow(Offset(size.width*.74,size.height*.22),size.width*.3,const Color(0xFF9C80E5),.11);
    for(var i=0;i<65;i++){final x=size.width*((i*73)%997)/997,y=size.height*((i*139)%991)/991;star(Offset(x,y),1.5+(i%3)*.8,accent.withValues(alpha:.20));}
    final moon=Offset(size.width*.72,size.height*.20);canvas.drawCircle(moon,size.width*.09,Paint()..color=accent.withValues(alpha:.16));
    break;
   case 'ours':
    for(var i=0;i<6;i++){
     final r=size.width*(.18+i*.10);
     canvas.drawOval(Rect.fromCenter(center:Offset(size.width*.52,size.height*.48),width:r*2,height:r*.72),Paint()..color=accent.withValues(alpha:.09-i*.009)..style=PaintingStyle.stroke..strokeWidth=1.0+i*.3);
    }
    for(var i=0;i<48;i++){final x=size.width*((i*67)%997)/997,y=size.height*((i*131)%991)/991;star(Offset(x,y),1.4+(i%3)*.6,accent.withValues(alpha:.19));}
    break;
  }
  // Gentle edge shading improves contrast for the chat without hiding artwork.
  canvas.drawRect(rect,Paint()..shader=LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.black.withValues(alpha:.13),Colors.transparent,Colors.black.withValues(alpha:.22)]).createShader(rect));
 }
 @override
 bool shouldRepaint(covariant _ChatAtmospherePainter oldDelegate)=>oldDelegate.skin.id!=skin.id;
}
class _RoundedMediaMessageClipper extends CustomClipper<Path> {
 const _RoundedMediaMessageClipper();
 @override
 Path getClip(Size size)=>Path()..addRRect(RRect.fromRectAndRadius(Offset.zero&size,const Radius.circular(18)));
 @override
 bool shouldReclip(covariant _RoundedMediaMessageClipper oldClipper)=>false;
}

class _MediaMessageClipper extends CustomClipper<Path> {
 @override
 Path getClip(Size size) => Path()..addRect(Offset.zero & size);
 @override
 bool shouldReclip(covariant _MediaMessageClipper oldClipper) => false;
}

class _MessageBubbleClipper extends CustomClipper<Path> {
 const _MessageBubbleClipper({required this.tailOnLeft});
 final bool tailOnLeft;

 @override
 Path getClip(Size size) {
  final w=size.width,h=size.height;
  if(w<=0||h<=0)return Path();
  // Reserve a real strip for the tail so the message body never collapses.
  final tailWidth=math.min(12.0,math.max(8.0,w*.12));
  final left=tailOnLeft?tailWidth:0.0;
  final right=tailOnLeft?w:w-tailWidth;
  final bodyWidth=math.max(1.0,right-left);
  final radius=math.min(22.0,math.min(h*.5,bodyWidth*.5));
  final body=Path()..addRRect(RRect.fromRectAndRadius(
   Rect.fromLTRB(left,0,right,h),Radius.circular(radius),
  ));
  // A compact curved tail, unioned with the rounded body. It stays inside
  // the clip bounds and cannot cut into short messages.
  final tailHeight=math.min(13.0,h*.38);
  final tail=Path();
  if(tailOnLeft){
   tail.moveTo(left+math.min(radius*.35,5.0),h-tailHeight*.72);
   tail.cubicTo(left-tailWidth*.08,h-tailHeight*.30,tailWidth*.12,h-tailHeight*.08,0,h);
   tail.cubicTo(tailWidth*.42,h,left+tailWidth*.34,h-tailHeight*.18,left+tailWidth*.78,h-tailHeight*.52);
   tail.close();
  }else{
   tail.moveTo(right-math.min(radius*.35,5.0),h-tailHeight*.72);
   tail.cubicTo(right+tailWidth*.08,h-tailHeight*.30,w-tailWidth*.12,h-tailHeight*.08,w,h);
   tail.cubicTo(w-tailWidth*.42,h,right-tailWidth*.34,h-tailHeight*.18,right-tailWidth*.78,h-tailHeight*.52);
   tail.close();
  }
  return Path.combine(PathOperation.union,body,tail);
 }

 @override
 bool shouldReclip(covariant _MessageBubbleClipper oldClipper)=>
  oldClipper.tailOnLeft!=tailOnLeft;
}

class _OursUnifiedMessageSurface extends StatelessWidget {
 final _ChatSkin skin; final bool isMine,isVisual; final Widget child;
 const _OursUnifiedMessageSurface({required this.skin,required this.isMine,required this.child,this.isVisual=false});
 @override Widget build(BuildContext context){
  final tailOnLeft=isMine
   ?Directionality.of(context)==ui.TextDirection.rtl
   :Directionality.of(context)==ui.TextDirection.ltr;
  final base=isMine?skin.mine:skin.partner;
  final bubbleGradient=LinearGradient(
   begin:Alignment.topLeft,end:Alignment.bottomRight,
   colors:[
    Color.lerp(base,Colors.white,isMine?.105:.045)!.withValues(alpha:.99),
    base,
    Color.lerp(base,skin.bg,isMine?.16:.30)!.withValues(alpha:.99),
   ],
   stops:const [0,.48,1],
  );
  final content=Container(
   constraints:BoxConstraints(minWidth:isVisual?0:76,maxWidth:MediaQuery.of(context).size.width*.78),
   padding:isVisual?EdgeInsets.zero:const EdgeInsets.fromLTRB(13,8,13,8),
   decoration:isVisual?BoxDecoration(
    borderRadius:BorderRadius.circular(16),
    border:Border.all(color:skin.accent.withValues(alpha:.30),width:.85),
   ):BoxDecoration(
    gradient:bubbleGradient,
    border:Border.all(
     color:isMine?skin.accent.withValues(alpha:.34):Colors.white.withValues(alpha:.095),
     width:isMine?1.0:.75,
    ),
   ),
   child:child,
  );
  return Padding(
   padding:const EdgeInsets.symmetric(vertical:2),
   child:isVisual
    ?ClipRRect(borderRadius:BorderRadius.circular(16),child:content)
    :PhysicalShape(
      clipper:_MessageBubbleClipper(tailOnLeft:tailOnLeft),
      color:Colors.transparent,
      elevation:3.6,
      shadowColor:(isMine?skin.accent:Colors.black).withValues(alpha:isMine?.16:.26),
      clipBehavior:Clip.antiAlias,
      child:content,
     ),
  );
 }
}

BoxDecoration _oursGlassPanelDecoration(_ChatSkin skin,{double radius=25})=>BoxDecoration(
 gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[
  Color.lerp(skin.partner,Colors.white,.035)!.withValues(alpha:.96),
  skin.bg.withValues(alpha:.94),
  Color.lerp(skin.partner,skin.bg,.48)!.withValues(alpha:.96),
 ],stops:const [0,.52,1]),
 borderRadius:BorderRadius.circular(radius),
 border:Border.all(color:skin.accent.withValues(alpha:.22),width:.85),
 boxShadow:[
  BoxShadow(color:Colors.black.withValues(alpha:.28),blurRadius:28,spreadRadius:-8,offset:const Offset(0,9)),
  BoxShadow(color:skin.accent.withValues(alpha:.055),blurRadius:18,spreadRadius:-5,offset:const Offset(0,-2)),
 ],
);

Widget _oursAtmosphereDepth(_ChatSkin skin)=>DecoratedBox(decoration:BoxDecoration(
 gradient:RadialGradient(center:const Alignment(-.88,-.92),radius:1.18,colors:[skin.accent.withValues(alpha:.075),Colors.transparent],stops:const [0,.82]),
 ),child:DecoratedBox(decoration:BoxDecoration(
 gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[
  Colors.black.withValues(alpha:.10),Colors.transparent,Colors.transparent,Colors.black.withValues(alpha:.20),
 ],stops:const [0,.22,.72,1]),
 ),child:const SizedBox.expand()));

Widget _wallpaperStudioAction(BuildContext ctx,{required IconData icon,required String title,required String subtitle,required Color accent,required VoidCallback onTap,bool danger=false}) {
 return Material(color:Colors.transparent,child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(17),child:Container(
  padding:const EdgeInsets.symmetric(horizontal:13,vertical:12),
  decoration:BoxDecoration(color:accent.withValues(alpha:.075),borderRadius:BorderRadius.circular(17),border:Border.all(color:accent.withValues(alpha:.18))),
  child:Row(children:[
   Container(width:38,height:38,decoration:BoxDecoration(color:accent.withValues(alpha:.13),borderRadius:BorderRadius.circular(12)),child:Icon(icon,color:accent,size:20)),
   const SizedBox(width:11),
   Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(title,style:TextStyle(color:danger?accent:Colors.white,fontWeight:FontWeight.w800,fontSize:12)),
    const SizedBox(height:3),
    Text(subtitle,style:TextStyle(color:Colors.white.withValues(alpha:.55),fontSize:10))
   ])),
   Icon(Icons.chevron_right_rounded,color:accent.withValues(alpha:.7))
  ])
 )));
}

Future<Map<String,dynamic>?> _openOursWallpaperStudio({
 required BuildContext context,required _ChatSkin skin,required String Function(String,String) t,
 required String? currentPath,required String preferenceKey,required String filePrefix,
 required double currentOpacity,currentZoom,currentRotation,currentDim,currentOffsetX,currentOffsetY,
 List<Map<String,dynamic>> previewMessages=const [],String? currentUserId,String partnerName='',
}) async {
 final exists=currentPath!=null&&await File(currentPath).exists();
 final action=await showModalBottomSheet<String>(context:context,backgroundColor:Colors.transparent,isScrollControlled:true,
  builder:(ctx)=>SafeArea(child:Container(
   margin:const EdgeInsets.fromLTRB(10,0,10,10),padding:const EdgeInsets.fromLTRB(18,12,18,18),
   decoration:BoxDecoration(color:const Color(0xFF171326),borderRadius:BorderRadius.circular(28),border:Border.all(color:skin.accent.withValues(alpha:.28)),boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:.30),blurRadius:28,offset:const Offset(0,-5))]),
   child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Center(child:Container(width:38,height:4,decoration:BoxDecoration(color:skin.accent.withValues(alpha:.42),borderRadius:BorderRadius.circular(8)))),
    const SizedBox(height:18),
    Row(children:[Container(width:44,height:44,decoration:BoxDecoration(color:skin.accent.withValues(alpha:.13),borderRadius:BorderRadius.circular(15)),child:Icon(Icons.wallpaper_rounded,color:skin.accent,size:23)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(t('استوديو خلفية المحادثة','Chat wallpaper studio'),style:TextStyle(color:skin.accent,fontSize:17,fontWeight:FontWeight.w900)),
     Text(t('اصنع أجواء محادثتك الخاصة','Create your own conversation atmosphere'),style:TextStyle(color:Colors.white.withValues(alpha:.58),fontSize:11))
    ]))]),
    const SizedBox(height:16),
    Container(height:132,decoration:BoxDecoration(color:const Color(0xFF292338),borderRadius:BorderRadius.circular(20),border:Border.all(color:skin.accent.withValues(alpha:.18))),clipBehavior:Clip.antiAlias,child:Stack(fit:StackFit.expand,children:[
     if(exists)Image.file(File(currentPath!),fit:BoxFit.cover,errorBuilder:(_,__,___)=>const SizedBox.shrink())
     else DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[skin.bg,skin.partner,skin.bg]))),
     DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.black.withValues(alpha:.04),Colors.black.withValues(alpha:.72)]))),
     PositionedDirectional(start:12,bottom:12,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.circle,size:7,color:exists?skin.accent:Colors.white54),const SizedBox(width:6),Text(exists?t('الخلفية الحالية','Current wallpaper'):t('لا توجد خلفية مخصصة','No custom wallpaper'),style:const TextStyle(color:Colors.white,fontSize:11,fontWeight:FontWeight.w800))]),
      const SizedBox(height:3),Text(exists?t('معاينة مباشرة لمظهر المحادثة','Preview of your chat background'):t('اختر صورة لتخصيص المساحة','Choose an image to personalize your space'),style:TextStyle(color:Colors.white.withValues(alpha:.72),fontSize:10))
     ]))
    ])),
    const SizedBox(height:14),
    _wallpaperStudioAction(ctx,icon:Icons.add_photo_alternate_rounded,title:t('اختيار خلفية جديدة','Choose a new wallpaper'),subtitle:t('اختر صورة من جهازك وابدأ التخصيص','Pick an image and start customizing'),accent:skin.accent,onTap:()=>Navigator.pop(ctx,'new')),
    if(exists) ...[
     const SizedBox(height:9),
     _wallpaperStudioAction(ctx,icon:Icons.tune_rounded,title:t('تعديل الخلفية الحالية','Edit current wallpaper'),subtitle:t('تابع ضبط الموضع والسطوع والتكبير','Adjust position, brightness and zoom'),accent:skin.accent,onTap:()=>Navigator.pop(ctx,'edit')),
     const SizedBox(height:9),
     _wallpaperStudioAction(ctx,icon:Icons.delete_outline_rounded,title:t('إزالة الخلفية','Remove wallpaper'),subtitle:t('العودة إلى خلفية الثيم الأصلية','Restore the theme background'),accent:Colors.redAccent,onTap:()=>Navigator.pop(ctx,'remove'),danger:true),
    ],
   ])
  )));
 if(action==null)return null;
 final prefs=await SharedPreferences.getInstance();
 if(action=='remove'){
  await prefs.remove(preferenceKey);
  for(final key in ['opacity','zoom','rotation','dim','offset_x','offset_y']){await prefs.remove('${preferenceKey}_${key}');}
  if(currentPath!=null){try{final old=File(currentPath);if(await old.exists())await old.delete();}catch(_){}}
  return {'path':null,'opacity':.22,'zoom':1.0,'rotation':0.0,'dim':.55,'offset_x':0.0,'offset_y':0.0};
 }
 File? source;
 if(action=='new'){final picked=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:96,maxWidth:3200,maxHeight:3200);if(picked==null)return null;source=File(picked.path);}
 else if(exists){source=File(currentPath!);}
 if(source==null||!await source.exists())return null;
 var zoom=action=='edit'?currentZoom:1.0,rotation=action=='edit'?currentRotation:0.0,dim=action=='edit'?currentDim:.48,opacity=action=='edit'?currentOpacity:.22,offsetX=action=='edit'?currentOffsetX:0.0,offsetY=action=='edit'?currentOffsetY:0.0;
 var gestureZoom=zoom,gestureRotation=rotation;
 final saved=await showDialog<bool>(context:context,barrierDismissible:false,builder:(dialogContext)=>StatefulBuilder(builder:(ctx,setEditor)=>Dialog.fullscreen(
  backgroundColor:skin.bg,
  child:Stack(fit:StackFit.expand,children:[
   Positioned.fill(child:Transform.translate(offset:Offset(offsetX,offsetY),child:Transform.rotate(angle:rotation,child:Transform.scale(scale:zoom,child:Opacity(opacity:(.55+opacity).clamp(.55,1.0),child:Image.file(source!,fit:BoxFit.cover,errorBuilder:(_,__,___)=>ColoredBox(color:skin.bg))))))),
   Positioned.fill(child:ColoredBox(color:skin.bg.withValues(alpha:dim))),
   SafeArea(child:Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(16,10,16,8),child:Row(children:[
     IconButton(onPressed:()=>Navigator.pop(ctx,false),icon:const Icon(Icons.close_rounded,color:Colors.white)),
     Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(t('معاينة خلفيتك','Your wallpaper preview'),style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.w900)),
      Text(t('شكل المحادثة قبل التطبيق','See how your chat will look'),style:TextStyle(color:Colors.white.withValues(alpha:.65),fontSize:10))
     ])),
     Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:skin.accent.withValues(alpha:.16),borderRadius:BorderRadius.circular(20),border:Border.all(color:skin.accent.withValues(alpha:.4))),child:Text(t('مباشر','LIVE'),style:TextStyle(color:skin.accent,fontSize:10,fontWeight:FontWeight.w900)))
    ])),
    Expanded(child:Padding(padding:const EdgeInsets.fromLTRB(14,8,14,10),child:Column(children:[
     Expanded(child:previewMessages.isEmpty
      ?Column(mainAxisAlignment:MainAxisAlignment.center,children:[
       _oursWallpaperPreviewBubble(t('مرحبًا! هذه معاينة لشكل الرسائل على الخلفية.','Hello! This is how messages will look on your wallpaper.'),false,skin),
       const SizedBox(height:12),_oursWallpaperPreviewBubble(t('الخلفية صارت أجمل بكثير ✨','The chat looks better already ✨'),true,skin),
      ])
      :ListView.builder(reverse:true,itemCount:previewMessages.length.clamp(0,8).toInt(),itemBuilder:(context,index){
       final m=previewMessages[previewMessages.length-1-index];
       final mine=currentUserId!=null&&m['sender_id']==currentUserId;
       final type=(m['message_type']??'text').toString();
       final body=(m['body']??'').toString();
       final label=type=='image'?t('صورة','Photo'):type=='video'?t('مقطع فيديو','Video'):type=='audio'?t('رسالة صوتية','Voice message'):type=='sticker'?t('ملصق','Sticker'):body;
       return Align(alignment:mine?AlignmentDirectional.centerEnd:AlignmentDirectional.centerStart,child:Container(
        constraints:BoxConstraints(maxWidth:MediaQuery.of(context).size.width*.76),
        margin:const EdgeInsets.symmetric(vertical:5),
        padding:const EdgeInsets.symmetric(horizontal:13,vertical:10),
        decoration:BoxDecoration(color:mine?skin.mine.withValues(alpha:.96):skin.partner.withValues(alpha:.96),borderRadius:BorderRadius.circular(17),border:Border.all(color:(mine?skin.accent:_lavender).withValues(alpha:.35)),boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:.12),blurRadius:12)]),
        child:Text(label,maxLines:4,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontSize:13,height:1.4))
       ));
      })),
     Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:10),decoration:BoxDecoration(color:skin.partner.withValues(alpha:.94),borderRadius:BorderRadius.circular(24),border:Border.all(color:skin.accent.withValues(alpha:.24))),child:Row(children:[
      Icon(Icons.add_circle_outline,color:skin.accent),const SizedBox(width:10),Expanded(child:Text(t('اكتب رسالة…','Write a message…'),style:TextStyle(color:Colors.white.withValues(alpha:.6),fontSize:12))),Icon(Icons.mic_none_rounded,color:skin.accent),const SizedBox(width:10),Icon(Icons.send_rounded,color:skin.accent)
     ]))
    ]))),
    Container(
     constraints:BoxConstraints(maxHeight:MediaQuery.of(ctx).size.height*.48),
     decoration:BoxDecoration(color:const Color(0xFF171326).withValues(alpha:.97),borderRadius:const BorderRadius.vertical(top:Radius.circular(28)),border:Border(top:BorderSide(color:skin.accent.withValues(alpha:.35))),boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:.3),blurRadius:24,offset:const Offset(0,-8))]),
     child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(18,12,18,18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Center(child:Container(width:38,height:4,decoration:BoxDecoration(color:skin.accent.withValues(alpha:.4),borderRadius:BorderRadius.circular(8)))),
      const SizedBox(height:12),
      Row(children:[Icon(Icons.tune_rounded,color:skin.accent),const SizedBox(width:8),Expanded(child:Text(t('ضبط الخلفية','Wallpaper controls'),style:TextStyle(color:skin.accent,fontSize:15,fontWeight:FontWeight.w900))),Text(t('اسحب الصورة لتحريكها','Drag photo to move'),style:const TextStyle(color:_lavender,fontSize:9))]),
      const SizedBox(height:8),
      ClipRRect(borderRadius:BorderRadius.circular(15),child:SizedBox(height:78,child:GestureDetector(
       onScaleStart:(d){gestureZoom=zoom;gestureRotation=rotation;},
       onScaleUpdate:(d)=>setEditor((){zoom=(gestureZoom*d.scale).clamp(1.0,3.2);rotation=gestureRotation+d.rotation;offsetX+=d.focalPointDelta.dx;offsetY+=d.focalPointDelta.dy;}),
       child:Stack(fit:StackFit.expand,children:[
        Transform.translate(offset:Offset(offsetX,offsetY),child:Transform.rotate(angle:rotation,child:Transform.scale(scale:zoom,child:Image.file(source!,fit:BoxFit.cover)))),
        ColoredBox(color:skin.bg.withValues(alpha:dim*.65)),
        Center(child:Text(t('اسحب هنا للتحريك والتكبير','Drag here to position and zoom'),style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w700)))
       ])
      ))),
      const SizedBox(height:10),
      _oursWallpaperSliderLabel(t('التكبير','Zoom'),'${zoom.toStringAsFixed(2)}×',skin),
      Slider(value:zoom,min:1,max:3.2,onChanged:(v)=>setEditor(()=>zoom=v),activeColor:skin.accent),
      _oursWallpaperSliderLabel(t('التعتيم','Dim'),'${(dim*100).round()}%',skin),
      Slider(value:dim,min:0,max:.85,onChanged:(v)=>setEditor(()=>dim=v),activeColor:skin.accent),
      _oursWallpaperSliderLabel(t('وضوح الصورة','Image clarity'),'${((.55+opacity)*100).round()}%',skin),
      Slider(value:opacity,min:.05,max:.45,onChanged:(v)=>setEditor(()=>opacity=v),activeColor:skin.accent),
      Row(children:[
       Expanded(child:OutlinedButton.icon(onPressed:()=>setEditor((){zoom=1;rotation=0;dim=.48;opacity=.22;offsetX=0;offsetY=0;gestureZoom=1;gestureRotation=0;}),icon:const Icon(Icons.restart_alt_rounded),label:Text(t('إعادة ضبط','Reset')))),
       const SizedBox(width:8),Expanded(child:OutlinedButton.icon(onPressed:()=>setEditor(()=>rotation=(rotation+math.pi/2)%(math.pi*2)),icon:const Icon(Icons.rotate_right_rounded),label:Text(t('تدوير 90°','Rotate 90°'))))
      ]),
      const SizedBox(height:8),
      SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:()=>Navigator.pop(ctx,true),style:FilledButton.styleFrom(backgroundColor:skin.accent,foregroundColor:skin.bg,padding:const EdgeInsets.symmetric(vertical:13)),icon:const Icon(Icons.check_rounded),label:Text(t('تطبيق الخلفية','Apply wallpaper'),style:const TextStyle(fontWeight:FontWeight.w900))))
     ]))
    )
   ])),
   Positioned.fill(child:IgnorePointer(child:GestureDetector(
    behavior:HitTestBehavior.translucent,
    onScaleStart:(d){gestureZoom=zoom;gestureRotation=rotation;},
    onScaleUpdate:(d){if(d.pointerCount>0)setEditor((){zoom=(gestureZoom*d.scale).clamp(1.0,3.2);rotation=gestureRotation+d.rotation;offsetX+=d.focalPointDelta.dx;offsetY+=d.focalPointDelta.dy;});}
   )))
  ])
 )));
 if(saved!=true)return null;
 try{
  var targetPath=currentPath??'';
  if(action=='new'){final dir=await getApplicationDocumentsDirectory();final target=File('${dir.path}/${filePrefix}_wallpaper_${DateTime.now().microsecondsSinceEpoch}.jpg');await source.copy(target.path);targetPath=target.path;}
  await prefs.setString(preferenceKey,targetPath);
  await prefs.setDouble('${preferenceKey}_opacity',opacity);await prefs.setDouble('${preferenceKey}_zoom',zoom);await prefs.setDouble('${preferenceKey}_rotation',rotation);await prefs.setDouble('${preferenceKey}_dim',dim);await prefs.setDouble('${preferenceKey}_offset_x',offsetX);await prefs.setDouble('${preferenceKey}_offset_y',offsetY);
  return {'path':targetPath,'opacity':opacity,'zoom':zoom,'rotation':rotation,'dim':dim,'offset_x':offsetX,'offset_y':offsetY};
 }catch(_){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(t('تعذر حفظ الخلفية. حاول اختيار صورة أخرى.','Could not save wallpaper. Try another image.'))));return null;}
}
Widget _oursWallpaperPreviewBubble(String value,bool mine,_ChatSkin skin)=>Align(alignment:mine?AlignmentDirectional.centerEnd:AlignmentDirectional.centerStart,child:Container(margin:const EdgeInsets.symmetric(vertical:5),padding:const EdgeInsets.symmetric(horizontal:14,vertical:11),constraints:const BoxConstraints(maxWidth:290),decoration:BoxDecoration(color:mine?skin.mine.withValues(alpha:.96):skin.partner.withValues(alpha:.96),borderRadius:BorderRadius.circular(17),border:Border.all(color:(mine?skin.accent:_lavender).withValues(alpha:.35))),child:Text(value,style:const TextStyle(color:Colors.white,fontSize:13,height:1.4))));
Widget _oursWallpaperSliderLabel(String label,String value,_ChatSkin skin)=>Row(children:[Expanded(child:Text(label,style:TextStyle(color:skin.accent,fontWeight:FontWeight.w700))),Text(value,style:TextStyle(color:skin.accent))]);

class OursDirectChatPage extends StatefulWidget{
 final String conversationId,partnerName,partnerId;
 final String? spaceId;
 const OursDirectChatPage({super.key,required this.conversationId,required this.partnerName,required this.partnerId,this.spaceId});
 @override State<OursDirectChatPage> createState()=>_OursDirectChatPageState();
}
class _OursDirectChatPageState extends State<OursDirectChatPage>{
 final db=Supabase.instance.client,input=TextEditingController(),scroll=ScrollController(),picker=ImagePicker();
 final Map<String,Future<String>> urls={};final List<Map<String,dynamic>> messages=[];
 final Set<String> hiddenIds={},pinnedMessageIds={};
 Uint8List? _editedPreviewBytes;
 Map<String,dynamic>? replyTo;
 RealtimeChannel? channel,liveChannel;AudioRecorder? recorder;String? recordingPath;
 Timer? typingTimer,recordingTimer;bool typingSent=false,partnerOnline=false,partnerTyping=false;DateTime? partnerLastSeen,recordingStartedAt;Duration recordingElapsed=Duration.zero;String? highlightedMessageId, _draggingReplyMessageId;
 double _replyDragOffset=0;
 bool loading=true,sending=false,recording=false,uploading=false,downloading=false;double? downloadProgress;String? localPartnerName,wallpaperPath;
 Timer? _outboxTimer;bool _syncingOutbox=false;double wallpaperOpacity=.22,wallpaperZoom=1,wallpaperRotation=0,wallpaperDim=.55,wallpaperOffsetX=0,wallpaperOffsetY=0;_ChatSkin skin=_skins.first;
 bool get ar=>Localizations.localeOf(context).languageCode=='ar';
 String t(String a,String e)=>ar?a:e;String get uid=>db.auth.currentUser!.id;
 
 @override void initState(){super.initState();localPartnerName=widget.partnerName;_loadSkin();_load();_listen();_startLiveStatus();_outboxTimer=Timer.periodic(const Duration(seconds:15),(_){_syncPendingText();_syncPendingMedia();});}
 Future<void> _changeLocalNickname() async{
  final prefs=await SharedPreferences.getInstance();final key='ours_partner_alias_${uid}_${widget.partnerId}';
  final controller=TextEditingController(text:prefs.getString(key)??widget.partnerName);
  final value=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:skin.bg,title:Text(t('اسم الطرف الآخر عندك','Your private nickname')),content:TextField(controller:controller,maxLength:24,decoration:InputDecoration(hintText:t('اسم يظهر لك فقط','Only visible to you'))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('إلغاء','Cancel'))),TextButton(onPressed:()=>Navigator.pop(ctx,controller.text.trim()),child:Text(t('حفظ','Save')))]));
  controller.dispose();if(value==null)return;if(value.isEmpty)await prefs.remove(key);else await prefs.setString(key,value);
  if(mounted)setState(()=>localPartnerName=value.isEmpty?widget.partnerName:value);
 }
 Future<void> _loadSkin() async{
  final p=await SharedPreferences.getInstance();final id=_normalizeOursSkinId(p.getString('ours_direct_skin_'+widget.conversationId)??'ours');
  final found=_skins.where((s)=>s.id==id);
  final savedWallpaper=p.getString('ours_direct_wallpaper_'+widget.conversationId);
  final wallpaperKey='ours_direct_wallpaper_'+widget.conversationId;
  final savedOpacity=p.getDouble('${wallpaperKey}_opacity')??p.getDouble('ours_direct_wallpaper_opacity_'+widget.conversationId)??.22;
  final savedZoom=p.getDouble('${wallpaperKey}_zoom')??p.getDouble('ours_direct_wallpaper_zoom_'+widget.conversationId)??1.0;
  final savedRotation=p.getDouble('${wallpaperKey}_rotation')??p.getDouble('ours_direct_wallpaper_rotation_'+widget.conversationId)??0.0;
  final savedDim=p.getDouble('${wallpaperKey}_dim')??p.getDouble('ours_direct_wallpaper_dim_'+widget.conversationId)??.55;
  final savedOffsetX=p.getDouble('${wallpaperKey}_offset_x')??p.getDouble('ours_direct_wallpaper_offset_x_'+widget.conversationId)??0.0;
  final savedOffsetY=p.getDouble('${wallpaperKey}_offset_y')??p.getDouble('ours_direct_wallpaper_offset_y_'+widget.conversationId)??0.0;
  if(mounted)setState((){skin=found.isEmpty?_skins.first:found.first;wallpaperPath=savedWallpaper;wallpaperOpacity=savedOpacity.clamp(.08,.45).toDouble();wallpaperZoom=savedZoom.clamp(1.0,2.5).toDouble();wallpaperRotation=savedRotation;wallpaperDim=savedDim.clamp(0.0,.85).toDouble();wallpaperOffsetX=savedOffsetX;wallpaperOffsetY=savedOffsetY;});
 }
 Future<void> _chooseSkin()async{
  final selected=await showModalBottomSheet<String>(context:context,backgroundColor:const Color(0xFF100D1B),showDragHandle:true,isScrollControlled:true,builder:(ctx)=>SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(14,8,14,18),child:Column(mainAxisSize:MainAxisSize.min,children:[
   Row(children:[Icon(Icons.palette_rounded,color:skin.accent,size:24),const SizedBox(width:9),Expanded(child:Text(t('أجواء OURS','OURS atmospheres'),style:TextStyle(color:skin.accent,fontSize:19,fontWeight:FontWeight.w900))),Text(t('اختر مزاجك','Choose your mood'),style:const TextStyle(color:_lavender,fontSize:10))]),
   const SizedBox(height:12),Container(width:double.infinity,padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:skin.bg,borderRadius:BorderRadius.circular(20),border:Border.all(color:skin.accent.withValues(alpha:.28))),child:Row(children:[Container(width:42,height:42,decoration:BoxDecoration(gradient:LinearGradient(colors:[skin.mine,skin.partner,skin.accent.withValues(alpha:.5)]),borderRadius:BorderRadius.circular(14)),child:Icon(Icons.chat_bubble_rounded,color:skin.accent)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t('معاينة الثيم الحالي','Current theme preview'),style:TextStyle(color:skin.accent,fontWeight:FontWeight.w800)),Text(ar?skin.ar:skin.en,style:const TextStyle(color:Colors.white,fontSize:12))]))])),
   const SizedBox(height:10),Flexible(child:GridView.builder(shrinkWrap:true,physics:const BouncingScrollPhysics(),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:1.55),itemCount:_skins.length,itemBuilder:(ctx,i){final x=_skins[i];final active=x.id==skin.id;return InkWell(onTap:()=>Navigator.pop(ctx,x.id),borderRadius:BorderRadius.circular(18),child:Container(clipBehavior:Clip.antiAlias,padding:const EdgeInsets.all(10),decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),border:Border.all(color:active?x.accent:Colors.white.withValues(alpha:.14),width:active?2:1)),child:Stack(children:[Positioned.fill(child:CustomPaint(painter:_ChatAtmospherePainter(x))),Positioned.fill(child:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.black.withValues(alpha:.12),Colors.transparent,Colors.black.withValues(alpha:.42)])))),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Container(width:9,height:9,decoration:BoxDecoration(color:x.accent,shape:BoxShape.circle)),const Spacer(),if(active)Icon(Icons.check_circle_rounded,color:x.accent,size:17)]),const Spacer(),Row(children:[Container(width:23,height:12,decoration:BoxDecoration(color:x.mine,borderRadius:BorderRadius.circular(8))),const SizedBox(width:4),Container(width:20,height:12,decoration:BoxDecoration(color:x.partner,borderRadius:BorderRadius.circular(8))),const Spacer(),Icon(Icons.auto_awesome_rounded,color:x.accent,size:15)]),const SizedBox(height:5),Text(ar?x.ar:x.en,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:11))])])));})),const SizedBox(height:6),Text(t('ألوان وخلفيات مصممة لكل مزاج','A distinct palette and atmosphere for every mood'),style:const TextStyle(color:_lavender,fontSize:10))
  ]))));
  if(selected==null)return;final p=await SharedPreferences.getInstance();await p.setString('ours_direct_skin_'+widget.conversationId,selected);
  if(mounted)setState(()=>skin=_skins.firstWhere((x)=>x.id==selected,orElse:()=>_skins.first));
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
 Future<void> _chooseWallpaper() async {
  final result=await _openOursWallpaperStudio(
   context:context,
   skin:skin,
   t:t,
   currentPath:wallpaperPath,
   preferenceKey:'ours_direct_wallpaper_${widget.conversationId}',
   filePrefix:'ours_direct_${widget.conversationId}',
   currentOpacity:wallpaperOpacity,
   currentZoom:wallpaperZoom,
   currentRotation:wallpaperRotation,
   currentDim:wallpaperDim,
   currentOffsetX:wallpaperOffsetX,
   currentOffsetY:wallpaperOffsetY,
   previewMessages:messages,
   currentUserId:uid,
   partnerName:localPartnerName??widget.partnerName,
  );
  if(result==null)return;
  if(mounted)setState((){
   wallpaperPath=result['path'] as String?;
   wallpaperOpacity=(result['opacity'] as num).toDouble();
   wallpaperZoom=(result['zoom'] as num).toDouble();
   wallpaperRotation=(result['rotation'] as num).toDouble();
   wallpaperDim=(result['dim'] as num).toDouble();
   wallpaperOffsetX=(result['offset_x'] as num).toDouble();
   wallpaperOffsetY=(result['offset_y'] as num).toDouble();
  });
 }
 Widget _wallpaperSliderLabel(String label,String value)=>Row(children:[
  Expanded(child:Text(label,style:TextStyle(color:skin.accent,fontWeight:FontWeight.w700))),
  Text(value,style:TextStyle(color:skin.accent)),
 ]);
 String get _chatCacheKey=>'ours_chat_cache_${uid}_${widget.conversationId}';
 String get _outboxKey=>'ours_chat_outbox_${uid}_${widget.conversationId}';
 Future<void> _persistChatCache() async{
  try{
   final prefs=await SharedPreferences.getInstance();
   final safe=messages.where((m)=>!['view_once','view_twice'].contains(m['message_type'])).map((m)=>Map<String,dynamic>.from(m)).toList();
   await prefs.setString(_chatCacheKey,jsonEncode(safe));
  }catch(_){}
 }
 Future<List<Map<String,dynamic>>> _readOutbox() async{
  final prefs=await SharedPreferences.getInstance();
  final raw=prefs.getString(_outboxKey);if(raw==null||raw.isEmpty)return [];
  try{return (jsonDecode(raw) as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();}
  catch(_){return [];}
 }
 Future<void> _writeOutbox(List<Map<String,dynamic>> items) async{
  final prefs=await SharedPreferences.getInstance();
  if(items.isEmpty){await prefs.remove(_outboxKey);return;}
  await prefs.setString(_outboxKey,jsonEncode(items));
 }
 Future<void> _queueTextMessage(String body,String? replyId,{String? messageId,String? createdAt}) async{
  final random=math.Random.secure();
  final bytes=List<int>.generate(16,(_)=>random.nextInt(256));
  bytes[6]=(bytes[6]&0x0f)|0x40;bytes[8]=(bytes[8]&0x3f)|0x80;
  final hex=bytes.map((v)=>v.toRadixString(16).padLeft(2,'0')).join();
  final generatedId='${hex.substring(0,8)}-${hex.substring(8,12)}-${hex.substring(12,16)}-${hex.substring(16,20)}-${hex.substring(20)}';
  final id=messageId??generatedId;
  final created=createdAt??DateTime.now().toUtc().toIso8601String();
  final row=<String,dynamic>{'id':id,'conversation_id':widget.conversationId,'sender_id':uid,'body':body,'message_type':'text','reply_to':replyId,'created_at':created,'local_pending':true};
  final queue=await _readOutbox();if(!queue.any((item)=>item['id'].toString()==id))queue.add(row);await _writeOutbox(queue);
  if(!mounted)return;
  final existing=messages.indexWhere((m)=>m['id'].toString()==id);
  if(existing>=0){setState(()=>messages[existing]=row);}else{setState(()=>messages.add(row));}
  messages.sort(_compareMessages);await _persistChatCache();_bottom();
 }
 Future<void> _syncPendingText() async{
  if(_syncingOutbox||!mounted)return;
  _syncingOutbox=true;
  try{
   final queue=await _readOutbox();if(queue.isEmpty)return;
   final remaining=<Map<String,dynamic>>[];
   for(var i=0;i<queue.length;i++){
    final item=queue[i];
    try{
     final payload=Map<String,dynamic>.from(item)..remove('local_pending');
     await db.from('duo_direct_messages').upsert(payload,onConflict:'id',ignoreDuplicates:true);
     if(mounted){
      final index=messages.indexWhere((m)=>m['id'].toString()==item['id'].toString());
      if(index>=0){final saved=Map<String,dynamic>.from(item)..remove('local_pending');setState(()=>messages[index]=saved);}
     }
    }catch(_){
     // Keep this message and every later message queued to preserve send order.
     remaining.addAll(queue.skip(i));
     break;
    }
   }
   await _writeOutbox(remaining);await _persistChatCache();
  }finally{_syncingOutbox=false;}
 }
 Future<void> _load() async{
  try{
   final prefs=await SharedPreferences.getInstance();
   // Load hide records BEFORE showing cached messages so deleted-for-me notes never flash.
   final hidden=await db.from('ours_direct_message_hides').select('message_id').eq('user_id',uid).timeout(const Duration(seconds:6));
   hiddenIds..clear()..addAll(hidden.map((r)=>r['message_id'].toString()));
   final cached=prefs.getString(_chatCacheKey);
   if(cached!=null){
    try{
     final rows=(jsonDecode(cached) as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList().where((m)=>!hiddenIds.contains(m['id'].toString())).toList();
     final queued=await _readOutbox();
     final combined=<String,Map<String,dynamic>>{};
     for(final row in rows){combined[row['id'].toString()]=row;}
     for(final row in queued){if(!hiddenIds.contains(row['id'].toString()))combined[row['id'].toString()]=row;}
     if(mounted)setState((){messages..clear()..addAll(combined.values);messages.sort(_compareMessages);loading=false;});
    }catch(_){}
   }
   final rows=await db.from('duo_direct_messages').select().eq('conversation_id',widget.conversationId).order('created_at',ascending:true).timeout(const Duration(seconds:8));
   final ordered=List<Map<String,dynamic>>.from(rows).where((m)=>!hiddenIds.contains(m['id'].toString())).toList()..sort(_compareMessages);
   final queued=await _readOutbox();final merged=<String,Map<String,dynamic>>{};
   for(final row in ordered){merged[row['id'].toString()]=row;}
   for(final row in queued){merged[row['id'].toString()]=row;}
   if(!mounted)return;setState((){messages..clear()..addAll(merged.values);loading=false;});
   await _persistChatCache();await _syncPendingText();await _syncPendingMedia();await _cacheRecentMedia();
   try{final pins=await db.from('ours_direct_message_pins').select('message_id').eq('user_id',uid).eq('conversation_id',widget.conversationId);if(mounted)setState(()=>pinnedMessageIds..clear()..addAll(pins.map((r)=>r['message_id'].toString())));}catch(_){}
   await db.rpc('mark_ours_direct_messages_read',params:{'p_conversation_id':widget.conversationId});
   _bottom();
  }catch(e){
   final queued=await _readOutbox();
   if(mounted){
    if(queued.isNotEmpty){setState(()=>messages.removeWhere((m)=>m['local_pending']==true));setState(()=>messages.addAll(queued));messages.sort(_compareMessages);}
    setState(()=>loading=false);_bottom();
    if(messages.isEmpty)_show(t('لا توجد رسائل محفوظة على هذا الجهاز بعد.','No messages have been saved on this device yet.'));
   }
  }
 }
 void _listen(){
  final filter=PostgresChangeFilter(type:PostgresChangeFilterType.eq,column:'conversation_id',value:widget.conversationId);
  channel=db.channel('ours-direct-'+widget.conversationId)
   .onPostgresChanges(event:PostgresChangeEvent.insert,schema:'public',table:'duo_direct_messages',filter:filter,callback:(p){
    final row=Map<String,dynamic>.from(p.newRecord);if(!mounted||hiddenIds.contains(row['id'].toString())||messages.any((m)=>m['id'].toString()==row['id'].toString()))return;setState((){messages.add(row);messages.sort(_compareMessages);});_persistChatCache();_bottom();
    if(row['sender_id']?.toString()!=uid){db.rpc('mark_ours_direct_messages_read',params:{'p_conversation_id':widget.conversationId});}
   })
   .onPostgresChanges(event:PostgresChangeEvent.delete,schema:'public',table:'duo_direct_messages',callback:(p){
    final id=p.oldRecord['id']?.toString();if(!mounted||id==null)return;setState(()=>messages.removeWhere((m)=>m['id'].toString()==id));
   })
   .onPostgresChanges(event:PostgresChangeEvent.update,schema:'public',table:'duo_direct_messages',filter:filter,callback:(p){
    final row=Map<String,dynamic>.from(p.newRecord);if(!mounted)return;final index=messages.indexWhere((m)=>m['id'].toString()==row['id'].toString());if(index>=0)setState(()=>messages[index]=row);
   }).subscribe();
 }
 int _compareMessages(Map<String,dynamic> a,Map<String,dynamic> b){
  final at=DateTime.tryParse(a['created_at']?.toString()??'')??DateTime.fromMillisecondsSinceEpoch(0);
  final bt=DateTime.tryParse(b['created_at']?.toString()??'')??DateTime.fromMillisecondsSinceEpoch(0);
  final byTime=at.compareTo(bt);if(byTime!=0)return byTime;
  return (a['id']?.toString()??'').compareTo(b['id']?.toString()??'');
 }
 void _bottom()=>WidgetsBinding.instance.addPostFrameCallback((_){if(scroll.hasClients)scroll.animateTo(scroll.position.maxScrollExtent,duration:const Duration(milliseconds:220),curve:Curves.easeOut);});
 void _show(String s){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s)));}
 Future<void> _sendText() async{
  final text=input.text.trim();if(text.isEmpty||sending)return;
  final replyId=replyTo?['id']?.toString();
  final random=math.Random.secure(),bytes=List<int>.generate(16,(_)=>random.nextInt(256));
  bytes[6]=(bytes[6]&0x0f)|0x40;bytes[8]=(bytes[8]&0x3f)|0x80;
  final hex=bytes.map((v)=>v.toRadixString(16).padLeft(2,'0')).join();
  final id='${hex.substring(0,8)}-${hex.substring(8,12)}-${hex.substring(12,16)}-${hex.substring(16,20)}-${hex.substring(20)}';
  final created=DateTime.now().toUtc().toIso8601String();
  final payload=<String,dynamic>{'id':id,'conversation_id':widget.conversationId,'sender_id':uid,'body':text,'message_type':'text','reply_to':replyId,'created_at':created};
  if(mounted){setState(()=>messages.add({...payload,'local_pending':true}));messages.sort(_compareMessages);_bottom();}
  setState(()=>sending=true);
  try{
   await db.from('duo_direct_messages').upsert(payload,onConflict:'id',ignoreDuplicates:true);
   if(mounted){
    final existing=messages.indexWhere((m)=>m['id'].toString()==id);
    if(existing<0){setState(()=>messages.add(Map<String,dynamic>.from(payload)));}
    else{setState(()=>messages[existing]=Map<String,dynamic>.from(payload));}
    messages.sort(_compareMessages);
    input.clear();setState(()=>replyTo=null);
    await _persistChatCache();_bottom();
   }
  }catch(e){
   try{await _queueTextMessage(text,replyId,messageId:id,createdAt:created);input.clear();if(mounted)setState(()=>replyTo=null);_show(t('حُفظت الرسالة محليًا وستُرسل عند عودة الاتصال','Message saved on this device and will send when connection returns'));}
   catch(_){if(mounted)setState(()=>messages.removeWhere((m)=>m['id'].toString()==id));_show(t('تعذر إرسال الرسالة أو حفظها محليًا','Could not send or save this message locally'));}
  }finally{if(mounted)setState(()=>sending=false);}
 }
 String _mime(String name){
  const types={'jpg':'image/jpeg','jpeg':'image/jpeg','png':'image/png','webp':'image/webp','gif':'image/gif','m4a':'audio/mp4','aac':'audio/aac','mp3':'audio/mpeg','ogg':'audio/ogg','mp4':'video/mp4','mov':'video/quicktime','webm':'video/webm','pdf':'application/pdf','txt':'text/plain','csv':'text/csv','doc':'application/msword','docx':'application/vnd.openxmlformats-officedocument.wordprocessingml.document','xls':'application/vnd.ms-excel','xlsx':'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','ppt':'application/vnd.ms-powerpoint','pptx':'application/vnd.openxmlformats-officedocument.presentationml.presentation','zip':'application/zip'};
  return types[name.split('.').last.toLowerCase()]??'';
 }
 String get _mediaOutboxKey=>'ours_chat_media_outbox_${uid}_${widget.conversationId}';
 String get _mediaCacheDirKey=>'ours_chat_media_cache_${uid}_${widget.conversationId}';
 Future<List<Map<String,dynamic>>> _readMediaOutbox() async{
  try{final p=await SharedPreferences.getInstance();final raw=p.getString(_mediaOutboxKey);if(raw==null)return [];return (jsonDecode(raw) as List).map((e)=>Map<String,dynamic>.from(e as Map)).toList();}catch(_){return [];}
 }
 Future<void> _writeMediaOutbox(List<Map<String,dynamic>> items) async{
  final p=await SharedPreferences.getInstance();if(items.isEmpty){await p.remove(_mediaOutboxKey);return;}await p.setString(_mediaOutboxKey,jsonEncode(items));
 }
 String _newLocalMessageId(){
  final random=math.Random.secure();final b=List<int>.generate(16,(_)=>random.nextInt(256));b[6]=(b[6]&15)|64;b[8]=(b[8]&63)|128;final h=b.map((v)=>v.toRadixString(16).padLeft(2,'0')).join();return '${h.substring(0,8)}-${h.substring(8,12)}-${h.substring(12,16)}-${h.substring(16,20)}-${h.substring(20)}';
 }
 Future<void> _queueMedia(Uint8List bytes,String name,String type,{int? maxViews}) async{
  final root=await getApplicationSupportDirectory();final dir=Directory('${root.path}/ours_media_outbox/${widget.conversationId}');
  await dir.create(recursive:true);final id=_newLocalMessageId();final safe=name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'),'_');
  final local=File('${dir.path}/${id}_${safe}');await local.writeAsBytes(bytes,flush:true);
  final now=DateTime.now().toUtc().toIso8601String();final item=<String,dynamic>{'id':id,'conversation_id':widget.conversationId,'sender_id':uid,'message_type':type,'file_name':name,'file_size':bytes.length,'mime_type':_mime(name),'max_views':maxViews??1,'created_at':now,'local_file_path':local.path};
  final queue=await _readMediaOutbox();queue.add(item);await _writeMediaOutbox(queue);
  if(!mounted)return;setState(()=>messages.add({...item,'body':local.path,'local_pending':true,'local_pending_media':true}));messages.sort(_compareMessages);await _persistChatCache();
  _show(t('حُفظ المرفق وسيُرسل تلقائيًا عند عودة الاتصال','Attachment saved and will send automatically when connection returns'));
 }
 Future<void> _syncPendingMedia() async{
  if(!mounted)return;final queue=await _readMediaOutbox();if(queue.isEmpty)return;
  final remaining=<Map<String,dynamic>>[];
  for(var i=0;i<queue.length;i++){
   final item=queue[i];final localPath=item['local_file_path']?.toString()??'';
   try{
    final file=File(localPath);if(!await file.exists())throw Exception('Queued attachment missing');
    final name=(item['file_name']??file.uri.pathSegments.last).toString();final safe=name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'),'_');
    final remotePath='${widget.conversationId}/${uid}/${item['id']}_${safe}';
    await db.storage.from(_bucket).upload(remotePath,file,fileOptions:FileOptions(contentType:(item['mime_type']??_mime(name)).toString(),upsert:true,cacheControl:'3600'));
    final payload=<String,dynamic>{'id':item['id'],'conversation_id':widget.conversationId,'sender_id':uid,'body':remotePath,'message_type':item['message_type'],'file_name':name,'file_size':item['file_size'],'mime_type':item['mime_type'],'max_views':item['max_views'],'created_at':item['created_at']};
    await db.from('duo_direct_messages').upsert(payload,onConflict:'id',ignoreDuplicates:true);
    if(await file.exists())await file.delete();
    final index=messages.indexWhere((m)=>m['id'].toString()==item['id'].toString());
    if(index>=0){final row=Map<String,dynamic>.from(payload);if(mounted)setState(()=>messages[index]=row);}
   }catch(_){remaining.addAll(queue.skip(i));break;}
  }
  await _writeMediaOutbox(remaining);await _persistChatCache();
 }
 Future<File?> _cachedMediaFile(String path) async{
  if(path.isEmpty||path=='[viewed]')return null;
  try{
   final root=await getApplicationSupportDirectory();final dir=Directory('${root.path}/ours_media_cache/${widget.conversationId}');await dir.create(recursive:true);
   final safe=path.split('/').last.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'),'_');final file=File('${dir.path}/${safe}');
   if(await file.exists()&&await file.length()>0)return file;
   final url=await _signed(path);final client=HttpClient();
   try{final req=await client.getUrl(Uri.parse(url));final res=await req.close();if(res.statusCode<200||res.statusCode>=300)return null;
    final sink=file.openWrite();await res.pipe(sink);await sink.flush();await sink.close();
   }finally{client.close();}
   if(await file.exists()&&await file.length()>0)return file;
  }catch(_){}
  return null;
 }
 Future<void> _upload(Uint8List bytes,String name,String type,{int? maxViews}) async{
  if(bytes.isEmpty)return;if(bytes.length>100*1024*1024){_show(t('الحد الأقصى 100 ميجابايت','Maximum size is 100 MB'));return;}
  final mime=_mime(name);if(mime.isEmpty){_show(t('نوع الملف غير مدعوم','Unsupported file type'));return;}setState(()=>uploading=true);
  final safe=name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'),'_');
  final path=widget.conversationId+'/'+uid+'/'+DateTime.now().microsecondsSinceEpoch.toString()+'_'+safe;
  try{
   await db.storage.from(_bucket).uploadBinary(path,bytes,fileOptions:FileOptions(contentType:mime,upsert:false,cacheControl:'3600'));
   try{await db.from('duo_direct_messages').insert({'conversation_id':widget.conversationId,'sender_id':uid,'body':path,'message_type':type,'max_views':maxViews??1,'file_name':name,'file_size':bytes.length,'mime_type':mime});}
   catch(_){await db.storage.from(_bucket).remove([path]);rethrow;}
  }catch(e){
   try{await _queueMedia(bytes,name,type,maxViews:maxViews);}catch(queueError){_show(t('تعذر حفظ المرفق محليًا: $queueError','Could not save attachment locally: $queueError'));}
  }finally{if(mounted)setState(()=>uploading=false);}
 }
 Future<Uint8List> _renderEditedImage(Uint8List bytes,int filter,double crop,List<List<Offset>> strokes) async{
  final codec=await ui.instantiateImageCodec(bytes);final frame=await codec.getNextFrame();final source=frame.image;
  final recorder=ui.PictureRecorder();final canvas=Canvas(recorder);
  final w=source.width.toDouble(),h=source.height.toDouble(),sw=w/crop,sh=h/crop;
  final src=Rect.fromLTWH((w-sw)/2,(h-sh)/2,sw,sh),dst=Rect.fromLTWH(0,0,w,h);
  const matrices=<List<double>>[
   <double>[1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0],
   <double>[.393,.769,.189,0,0,.349,.686,.168,0,0,.272,.534,.131,0,0,0,0,0,1,0],
   <double>[.85,0,0,0,18,0,.94,0,0,8,0,0,1.12,0,18,0,0,0,1,0],
   <double>[1.15,0,0,0,8,0,1.15,0,0,8,0,0,1.15,0,8,0,0,0,1,0],
   <double>[1.08,0,0,0,0,0,.92,0,0,4,0,0,.82,0,12,0,0,0,1,0],
   <double>[.9,0,0,0,18,0,.9,0,0,12,0,0,.9,0,6,0,0,0,1,0],
   <double>[1.12,0,0,0,0,0,1.02,0,0,0,0,0,.92,0,0,0,0,0,1,0],
   <double>[.95,.05,0,0,0,.02,1.04,.02,0,0,0,.03,1.1,0,0,0,0,0,1,0],
   <double>[1.08,.02,0,0,8,0,1.02,.01,0,4,0,0,.88,0,8,0,0,0,1,0],
   <double>[.72,.18,.08,0,12,.12,.82,.08,0,8,.04,.08,.72,0,18,0,0,0,1,0],
   <double>[.92,.08,0,0,4,.04,.94,.02,0,2,0,.03,1.08,0,8,0,0,0,1,0],
   <double>[.82,.12,.04,0,0,.08,.9,.06,0,4,.02,.06,1.08,0,10,0,0,0,1,0],
   <double>[.88,.04,.02,0,0,.02,.92,.04,0,8,.02,.04,1.12,0,14,0,0,0,1,0],
   <double>[.72,.12,.08,0,0,.08,.82,.1,0,6,.04,.1,1.02,0,12,0,0,0,1,0],
   <double>[.9,.08,.02,0,10,.02,.88,.04,0,2,.02,.06,.82,0,0,0,0,0,1,0],
  ];
  canvas.drawImageRect(source,src,dst,Paint()..filterQuality=FilterQuality.high..colorFilter=ColorFilter.matrix(matrices[filter.clamp(0,14).toInt()]));
  for(final stroke in strokes){if(stroke.length<2)continue;final path=Path()..moveTo(stroke.first.dx*w,stroke.first.dy*h);for(final point in stroke.skip(1)){path.lineTo(point.dx*w,point.dy*h);}canvas.drawPath(path,Paint()..color=const Color(0xFFFFD66B)..strokeWidth=(w/260).clamp(4,16).toDouble()..strokeCap=StrokeCap.round..style=PaintingStyle.stroke);}
  final picture=recorder.endRecording();final image=await picture.toImage(source.width,source.height);final data=await image.toByteData(format:ui.ImageByteFormat.png);
  source.dispose();image.dispose();picture.dispose();codec.dispose();if(data==null)throw Exception('Image export failed');return data.buffer.asUint8List();
 }
 Future<String?> _previewMedia({required Uint8List bytes,required String name,required bool video}) async{
  var mode='normal',filter=0;var crop=1.0;var drawing=false;var hd=true;var showOriginal=false;var strokes=<List<Offset>>[];var activeStroke=<Offset>[];
  _editedPreviewBytes=null;
  return await showDialog<String>(context:context,barrierDismissible:false,builder:(ctx)=>StatefulBuilder(builder:(ctx,setEditor)=>Dialog(
   backgroundColor:Colors.black,insetPadding:EdgeInsets.zero,child:SizedBox.expand(child:SafeArea(child:Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(14,8,8,8),child:Row(children:[Icon(Icons.auto_awesome_rounded,color:skin.accent),const SizedBox(width:9),Expanded(child:Text(t('استوديو معاينة الوسائط','Media preview studio'),style:TextStyle(color:skin.accent,fontSize:17,fontWeight:FontWeight.w900))),IconButton(onPressed:()=>Navigator.pop(ctx,null),icon:const Icon(Icons.close,color:Colors.white))])),
    Expanded(child:Center(child:video?Container(width:double.infinity,margin:const EdgeInsets.all(16),decoration:BoxDecoration(color:skin.partner,borderRadius:BorderRadius.circular(22)),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(Icons.video_file_rounded,color:skin.accent,size:72),Text(name,style:TextStyle(color:skin.accent),maxLines:2,overflow:TextOverflow.ellipsis)])):LayoutBuilder(builder:(context,constraints)=>GestureDetector(
     onPanStart:drawing?(d)=>setEditor(()=>activeStroke=[Offset((d.localPosition.dx/constraints.maxWidth).clamp(0,1).toDouble(),(d.localPosition.dy/constraints.maxHeight).clamp(0,1).toDouble())]):null,
     onPanUpdate:drawing?(d)=>setEditor(()=>activeStroke.add(Offset((d.localPosition.dx/constraints.maxWidth).clamp(0,1),(d.localPosition.dy/constraints.maxHeight).clamp(0,1)))):null,
     onPanEnd:drawing?(_)=>setEditor((){if(activeStroke.isNotEmpty)strokes.add(List<Offset>.from(activeStroke));activeStroke=[];}):null,
     child:Stack(fit:StackFit.expand,children:[
      Center(child:Transform.scale(scale:crop,child:ColorFiltered(colorFilter:showOriginal?const ColorFilter.mode(Colors.transparent,BlendMode.dst):const [ColorFilter.mode(Colors.transparent,BlendMode.dst),ColorFilter.matrix(<double>[.393,.769,.189,0,0,.349,.686,.168,0,0,.272,.534,.131,0,0,0,0,0,1,0]),ColorFilter.matrix(<double>[.85,0,0,0,18,0,.94,0,0,8,0,0,1.12,0,18,0,0,0,1,0]),ColorFilter.matrix(<double>[1.15,0,0,0,8,0,1.15,0,0,8,0,0,1.15,0,8,0,0,0,1,0]),ColorFilter.matrix(<double>[1.08,0,0,0,0,0,.92,0,0,4,0,0,.82,0,12,0,0,0,1,0]),ColorFilter.matrix(<double>[.9,0,0,0,18,0,.9,0,0,12,0,0,.9,0,6,0,0,0,1,0]),ColorFilter.matrix(<double>[1.12,0,0,0,0,0,1.02,0,0,0,0,0,.92,0,0,0,0,0,1,0]),ColorFilter.matrix(<double>[.95,.05,0,0,0,.02,1.04,.02,0,0,0,.03,1.1,0,0,0,0,0,1,0]),ColorFilter.matrix(<double>[1.08,.02,0,0,8,0,1.02,.01,0,4,0,0,.88,0,8,0,0,0,1,0]),ColorFilter.matrix(<double>[.72,.18,.08,0,12,.12,.82,.08,0,8,.04,.08,.72,0,18,0,0,0,1,0]),ColorFilter.matrix(<double>[.92,.08,0,0,4,.04,.94,.02,0,2,0,.03,1.08,0,8,0,0,0,1,0]),ColorFilter.matrix(<double>[.82,.12,.04,0,0,.08,.9,.06,0,4,.02,.06,1.08,0,10,0,0,0,1,0]),ColorFilter.matrix(<double>[.88,.04,.02,0,0,.02,.92,.04,0,8,.02,.04,1.12,0,14,0,0,0,1,0]),ColorFilter.matrix(<double>[.72,.12,.08,0,0,.08,.82,.1,0,6,.04,.1,1.02,0,12,0,0,0,1,0]),ColorFilter.matrix(<double>[.9,.08,.02,0,10,.02,.88,.04,0,2,.02,.06,.82,0,0,0,0,0,1,0])][filter],child:Image.memory(bytes,fit:BoxFit.contain,width:constraints.maxWidth,height:constraints.maxHeight)))),
      CustomPaint(painter:_PreviewStrokePainter([...strokes,if(activeStroke.isNotEmpty)activeStroke])),
     ])
    )))),
    if(!video)Container(padding:const EdgeInsets.fromLTRB(14,10,14,12),decoration:BoxDecoration(color:const Color(0xFF171326),border:Border(top:BorderSide(color:skin.accent.withValues(alpha:.22)))),child:Column(mainAxisSize:MainAxisSize.min,children:[
     Row(children:[
      _previewTool(t('قص','Crop'),Icons.crop_rounded,crop>1.01,()=>setEditor(()=>crop=crop>=1.8?1.0:crop+.2)),
      _previewTool(t('رسم','Draw'),Icons.draw_rounded,drawing,()=>setEditor(()=>drawing=!drawing)),
      _previewTool(t('الفلاتر','Filters'),Icons.filter_vintage_rounded,filter!=0,()=>setEditor(()=>filter=(filter+1)%15)),
      _previewTool('HD',Icons.hd_rounded,hd,()=>setEditor(()=>hd=!hd))
     ]),
     const SizedBox(height:6),Row(children:[
      Expanded(child:Text(t('المعاينة','Preview'),style:TextStyle(color:skin.accent,fontSize:10,fontWeight:FontWeight.w700))),
      TextButton.icon(onPressed:()=>setEditor(()=>showOriginal=!showOriginal),icon:Icon(showOriginal?Icons.auto_awesome:Icons.compare,color:skin.accent,size:16),label:Text(showOriginal?t('عرض التعديلات','Show edits'):t('قبل / بعد','Before / after'),style:TextStyle(color:skin.accent,fontSize:10))),
      IconButton(onPressed:()=>setEditor(()=>strokes.isEmpty?null:strokes.removeLast()),tooltip:t('تراجع عن آخر خط','Undo last stroke'),icon:Icon(Icons.undo_rounded,color:skin.accent)),
      IconButton(onPressed:()=>setEditor(()=>strokes.clear()),tooltip:t('مسح الرسم','Clear drawing'),icon:Icon(Icons.delete_outline_rounded,color:skin.accent)),
     ]),
     const SizedBox(height:8),Row(children:[Expanded(child:Text(hd?t('الجودة الأصلية · دون ضغط إضافي','Original quality · no extra compression'):t('جودة متوازنة · حجم أقل','Balanced quality · smaller size'),style:TextStyle(color:skin.accent,fontSize:11))),Text(t('فلتر '+(filter+1).toString()+' / 15','Filter '+(filter+1).toString()+' / 15'),style:TextStyle(color:skin.accent,fontSize:10)),IconButton(onPressed:()=>setEditor((){filter=0;crop=1;drawing=false;strokes.clear();activeStroke.clear();}),icon:Icon(Icons.restart_alt_rounded,color:skin.accent))]),
     Wrap(spacing:7,children:[
      ChoiceChip(label:Text(t('عادية','Normal')),selected:mode=='normal',onSelected:(_)=>setEditor(()=>mode='normal')),
      ChoiceChip(label:Text(t('مرة واحدة','Once')),selected:mode=='once',onSelected:(_)=>setEditor(()=>mode='once')),
      ChoiceChip(label:Text(t('مرتين','Twice')),selected:mode=='twice',onSelected:(_)=>setEditor(()=>mode='twice')),
     ])
    ])),
    Padding(padding:const EdgeInsets.fromLTRB(14,8,14,14),child:Row(children:[
     Expanded(child:OutlinedButton(onPressed:()=>Navigator.pop(ctx,null),child:Text(t('إلغاء','Cancel')))),
     const SizedBox(width:10),Expanded(child:FilledButton.icon(onPressed:()async{try{if(!video)_editedPreviewBytes=await _renderEditedImage(bytes,filter,crop,strokes);if(ctx.mounted)Navigator.pop(ctx,mode);}catch(_){_show(t('تعذر تطبيق التعديلات','Could not apply edits'));}},icon:const Icon(Icons.send_rounded),label:Text(t('إرسال','Send'))))
    ]))
   ])))
  )));
 }
 Widget _previewTool(String label,IconData icon,bool active,VoidCallback onTap)=>Expanded(child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(13),child:Container(padding:const EdgeInsets.symmetric(vertical:9,horizontal:3),decoration:BoxDecoration(color:active?skin.accent.withValues(alpha:.17):Colors.white.withValues(alpha:.04),borderRadius:BorderRadius.circular(13),border:Border.all(color:active?skin.accent.withValues(alpha:.6):Colors.white.withValues(alpha:.08))),child:Column(children:[Icon(icon,color:skin.accent,size:21),const SizedBox(height:4),Text(label,style:TextStyle(color:skin.accent,fontSize:10,fontWeight:FontWeight.w700))]))));
 Future<void> _pickImageWithMode() async{
  try{
   final f=await picker.pickImage(source:ImageSource.gallery,imageQuality:100,maxWidth:4096,maxHeight:4096);if(f==null)return;
   final bytes=await f.readAsBytes();final mode=await _previewMedia(bytes:bytes,name:f.name,video:false);if(mode==null)return;final edited=_editedPreviewBytes??bytes;_editedPreviewBytes=null;
   final ext=f.name.split('.').last.toLowerCase();final name=['png','webp'].contains(ext)?f.name:'photo_'+DateTime.now().millisecondsSinceEpoch.toString()+'.jpg';
   await _upload(edited,name,mode=='normal'?'image':mode=='once'?'view_once':'view_twice',maxViews:mode=='twice'?2:1);
  }catch(e){_show(t('تعذر اختيار الصورة: $e','Could not select image: $e'));}
 }
 Future<String?> _previewVideoFile(String path) async{
  final controller=VideoPlayerController.file(File(path));
  try{await controller.initialize();}catch(_){await controller.dispose();return null;}
  var mode='normal',hd=true;
  try{
   final result=await showDialog<String>(context:context,barrierDismissible:false,builder:(ctx)=>StatefulBuilder(builder:(ctx,setEditor)=>Dialog(
    backgroundColor:Colors.black,insetPadding:EdgeInsets.zero,child:SizedBox.expand(child:SafeArea(child:Column(children:[
     Padding(padding:const EdgeInsets.fromLTRB(14,8,8,8),child:Row(children:[Icon(Icons.movie_creation_outlined,color:skin.accent),const SizedBox(width:9),Expanded(child:Text(t('معاينة الفيديو','Video preview'),style:TextStyle(color:skin.accent,fontSize:17,fontWeight:FontWeight.w900))),IconButton(onPressed:()=>Navigator.pop(ctx,null),icon:const Icon(Icons.close,color:Colors.white))])),
     Expanded(child:Center(child:AspectRatio(aspectRatio:controller.value.aspectRatio,child:VideoPlayer(controller)))),
     Row(mainAxisAlignment:MainAxisAlignment.center,children:[
      IconButton(onPressed:()=>setEditor(()=>controller.value.isPlaying?controller.pause():controller.play()),icon:Icon(controller.value.isPlaying?Icons.pause_circle_filled:Icons.play_circle_fill,color:skin.accent,size:42)),
      IconButton(onPressed:()=>setEditor(()=>controller.seekTo(Duration.zero)),icon:Icon(Icons.replay_rounded,color:skin.accent,size:28))
     ]),
     Container(width:double.infinity,padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:const Color(0xFF171326),border:Border(top:BorderSide(color:skin.accent.withValues(alpha:.2)))),child:Column(children:[
      Row(children:[Expanded(child:Text(t('جودة الفيديو','Video quality'),style:TextStyle(color:skin.accent,fontWeight:FontWeight.w700))),Switch(value:hd,onChanged:(v)=>setEditor(()=>hd=v),activeThumbColor:skin.accent),Text('HD',style:TextStyle(color:skin.accent,fontWeight:FontWeight.w900))]),
      Wrap(spacing:7,children:[
       ChoiceChip(label:Text(t('عادية','Normal')),selected:mode=='normal',onSelected:(_)=>setEditor(()=>mode='normal')),
       ChoiceChip(label:Text(t('مرة واحدة','Once')),selected:mode=='once',onSelected:(_)=>setEditor(()=>mode='once')),
       ChoiceChip(label:Text(t('مرتين','Twice')),selected:mode=='twice',onSelected:(_)=>setEditor(()=>mode='twice')),
      ]),
      const SizedBox(height:10),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:()=>Navigator.pop(ctx,mode),icon:const Icon(Icons.send_rounded),label:Text(t('إرسال الفيديو','Send video'))))
     ]))
    ])))
   )));
   return result;
  }finally{await controller.dispose();}
 }
 Future<void> _pickVideo() async{
  try{
   final f=await picker.pickVideo(source:ImageSource.gallery,maxDuration:const Duration(minutes:2));if(f==null)return;
   final ext=f.name.split('.').last.toLowerCase();if(!['mp4','mov','webm'].contains(ext)){_show(t('صيغة الفيديو غير مدعومة','Unsupported video format'));return;}
   final mode=await _previewVideoFile(f.path);if(mode==null)return;
   await _upload(await f.readAsBytes(),f.name,mode=='normal'?'video':mode=='once'?'view_once':'view_twice',maxViews:mode=='twice'?2:1);
  }catch(e){_show(t('تعذر اختيار الفيديو: $e','Could not select video: $e'));}
 }
  Future<String> _signedSticker(String path){
   return urls.putIfAbsent('sticker:$path',(){
    if(widget.spaceId!=null&&path.startsWith('${widget.spaceId}/'))return db.storage.from('ours-stickers').createSignedUrl(path,900);
    return _signed(path);
   });
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
   final searchController=TextEditingController();
   List<Map<String,dynamic>> stickers=[];final favorites=<String>{};
   urls.removeWhere((key,_)=>key.startsWith('sticker:'));
   try{
    final data=await db.from('duo_stickers').select('id,pack_name,display_name,storage_path,is_animated,created_at').eq('space_id',widget.spaceId!).order('created_at',ascending:false);
    stickers=List<Map<String,dynamic>>.from(data);
    final fav=await db.from('duo_sticker_favorites').select('sticker_id').eq('user_id',uid);
    favorites.addAll(List<Map<String,dynamic>>.from(fav).map((x)=>x['sticker_id'].toString()));
   }catch(e){_show(t('تعذر تحميل مكتبة الملصقات','Could not load sticker library'));return;}
   var selectedPack='all';
   final packs=<String>{'all','favorites',...stickers.map((x)=>(x['pack_name']??'OURS').toString())}.toList();
   final chosen=await showModalBottomSheet<String>(context:context,backgroundColor:skin.bg,showDragHandle:true,isScrollControlled:true,builder:(ctx)=>StatefulBuilder(builder:(ctx,setModal){
    final query=searchController.text.trim().toLowerCase();
    final visible=stickers.where((x){
     final name=(x['display_name']??'').toString().toLowerCase();
     final pack=(x['pack_name']??'OURS').toString().toLowerCase();
     final matchesQuery=query.isEmpty||name.contains(query)||pack.contains(query);
     final matchesPack=selectedPack=='all'||(selectedPack=='favorites'?favorites.contains(x['id'].toString()):pack==selectedPack.toLowerCase());
     return matchesQuery&&matchesPack;
    }).toList();
    return SafeArea(child:SizedBox(height:MediaQuery.of(ctx).size.height*.72,child:Column(children:[
     Padding(padding:const EdgeInsets.fromLTRB(14,12,14,6),child:Row(children:[Expanded(child:Text(t('مكتبة ملصقات OURS','OURS Sticker Library'),style:TextStyle(color:skin.accent,fontSize:17,fontWeight:FontWeight.w900))),IconButton(onPressed:()=>Navigator.pop(ctx,'__add__'),icon:Icon(Icons.add_photo_alternate_outlined,color:skin.accent))])),
      Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:5),child:TextField(controller:searchController,onChanged:(_)=>setModal((){}),decoration:InputDecoration(hintText:t('ابحث عن ملصق أو حزمة','Search stickers or packs'),prefixIcon:Icon(Icons.search,color:skin.accent),filled:true,fillColor:skin.partner,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none)))),
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
   searchController.dispose();
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
 Future<void> _saveVideoLocally(String path,{void Function(double?)? onProgress}) async {
  try {
   if(path.isEmpty||path=='[viewed]')return;
   onProgress?.call(0);
   final url=await _signed(path);
   final client=HttpClient();
   late Uint8List bytes;
   try{
    final request=await client.getUrl(Uri.parse(url));
    final response=await request.close();
    if(response.statusCode<200||response.statusCode>=300)throw Exception('Download failed');
    final builder=BytesBuilder(copy:false);
    final total=response.contentLength;
    var received=0;
    await for(final chunk in response){builder.add(chunk);received+=chunk.length;onProgress?.call(total>0?(received/total).clamp(0.0,1.0):null);}
    bytes=builder.takeBytes();onProgress?.call(1);
   }finally{client.close();}
   if(bytes.isEmpty)throw Exception('Empty video');
   final name='OURS_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
   final saved=await FilePicker.platform.saveFile(fileName:name,bytes:bytes);
   if(!mounted)return;
   _show(saved==null?t('تم إلغاء الحفظ','Saving cancelled'):t('تم حفظ الفيديو بجودته الأصلية','Video saved in its original quality'));
  }catch(e){
   if(mounted)_show(t('تعذر حفظ الفيديو: $e','Could not save video: $e'));
  }
 }
 Future<void> _playVideo(String path,{String? messageId}) async {
  VideoPlayerController? controller;
  try {
   final url=await _signed(path);
   controller=VideoPlayerController.networkUrl(Uri.parse(url));
   await controller.initialize();
   final player=controller;
   if(!mounted){await player.dispose();return;}
   await player.setLooping(false);
   StateSetter? refreshModal;
   double? saveProgress;
   bool savingVideo=false;
   void refreshPlayer(){if(mounted&&player.value.isInitialized)refreshModal?.call((){});}
   player.addListener(refreshPlayer);
   try{await showDialog<void>(context:context,barrierDismissible:false,barrierColor:Colors.black,builder:(ctx){
    return StatefulBuilder(builder:(ctx,setModal){
     refreshModal=setModal;
     void toggle(){setModal((){player.value.isPlaying?player.pause():player.play();});}
     String clock(Duration d){final sec=d.inSeconds;return '${(sec~/60).toString().padLeft(2,'0')}:${(sec%60).toString().padLeft(2,'0')}';}
     final duration=player.value.duration;
     final current=player.value.position;
     final max=duration.inMilliseconds>0?duration.inMilliseconds.toDouble():1.0;
     final progress=current.inMilliseconds.toDouble().clamp(0.0,max);
     return Dialog.fullscreen(backgroundColor:const Color(0xFF08070D),child:SafeArea(child:Stack(children:[
      Positioned.fill(child:Container(decoration:BoxDecoration(gradient:RadialGradient(center:Alignment.center,radius:1.1,colors:[skin.partner.withValues(alpha:.65),const Color(0xFF08070D)])))),
      Column(children:[
       Padding(padding:const EdgeInsets.symmetric(horizontal:14,vertical:8),child:Row(children:[
        IconButton(onPressed:()=>Navigator.pop(ctx),icon:const Icon(Icons.close_rounded,color:Colors.white,size:25)),
        IconButton(tooltip:t('حفظ الفيديو','Save video'),onPressed:savingVideo?null:()=>_saveVideoLocally(path,onProgress:(value){if(mounted)refreshModal?.call((){saveProgress=value;savingVideo=value==null||value<1;});}).whenComplete(()=>refreshModal?.call((){savingVideo=false;saveProgress=null;})),icon:Icon(savingVideo?Icons.downloading_rounded:Icons.download_rounded,color:_gold,size:23)),
        const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t('مشاهدة الفيديو','Video playback'),style:TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:16)),Text(t('مشغل OURS','OURS PLAYER'),style:TextStyle(color:_gold,fontWeight:FontWeight.w700,fontSize:10,letterSpacing:1.6)),if(savingVideo)Text(saveProgress==null?t('جارٍ الحفظ…','Saving…'):'\${(saveProgress!*100).round()}%',style:TextStyle(color:_gold,fontSize:10,fontWeight:FontWeight.w700))])),
        Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:_gold.withValues(alpha:.12),border:Border.all(color:_gold.withValues(alpha:.3)),borderRadius:BorderRadius.circular(20)),child:Text('VIDEO',style:TextStyle(color:_gold,fontSize:10,fontWeight:FontWeight.w900,letterSpacing:1.2)))
       ])),
       Expanded(child:Center(child:Padding(padding:const EdgeInsets.symmetric(horizontal:8),child:AspectRatio(aspectRatio:player.value.aspectRatio>0?player.value.aspectRatio:16/9,child:ClipRRect(borderRadius:BorderRadius.circular(20),child:Stack(fit:StackFit.expand,children:[
        VideoPlayer(player),
        if(!player.value.isPlaying)Container(color:Colors.black.withValues(alpha:.16),child:Center(child:InkWell(onTap:toggle,borderRadius:BorderRadius.circular(48),child:Container(width:76,height:76,decoration:BoxDecoration(shape:BoxShape.circle,color:_gold.withValues(alpha:.18),border:Border.all(color:_gold.withValues(alpha:.8),width:1.4)),child:const Icon(Icons.play_arrow_rounded,color:Colors.white,size:48))))),
        if(player.value.isPlaying)Positioned(bottom:10,right:10,child:Container(padding:const EdgeInsets.all(6),decoration:BoxDecoration(color:Colors.black.withValues(alpha:.35),borderRadius:BorderRadius.circular(8)),child:const Icon(Icons.equalizer_rounded,color:_gold,size:16)))
       ])))))),
       Padding(padding:const EdgeInsets.fromLTRB(18,18,18,22),child:Container(padding:const EdgeInsets.fromLTRB(14,14,14,12),decoration:BoxDecoration(color:const Color(0xFF171421),borderRadius:BorderRadius.circular(22),border:Border.all(color:_gold.withValues(alpha:.18)),boxShadow:[BoxShadow(color:_gold.withValues(alpha:.06),blurRadius:18)]),child:Column(mainAxisSize:MainAxisSize.min,children:[
        Row(children:[Text(clock(current),style:const TextStyle(color:Colors.white)),Expanded(child:Slider(value:progress,min:0,max:max,onChanged:(v)=>setModal(()=>player.seekTo(Duration(milliseconds:v.round()))),activeColor:_gold,inactiveColor:Colors.white12)),Text(clock(duration),style:TextStyle(color:Colors.white.withValues(alpha:.65)))]),
        Row(children:[
         IconButton(onPressed:()=>setModal(()=>player.seekTo(Duration(seconds:(current.inSeconds-10).clamp(0,duration.inSeconds).toInt()))),icon:const Icon(Icons.replay_10_rounded,color:Colors.white,size:26)),
         const Spacer(),
         IconButton(onPressed:()=>setModal(()=>player.seekTo(Duration.zero)),icon:const Icon(Icons.restart_alt_rounded,color:Colors.white70,size:24)),
         const SizedBox(width:10),
         InkWell(onTap:toggle,borderRadius:BorderRadius.circular(40),child:Container(width:58,height:58,decoration:BoxDecoration(shape:BoxShape.circle,gradient:LinearGradient(colors:[_gold,Color.lerp(_gold,skin.accent,.5)!]),boxShadow:[BoxShadow(color:_gold.withValues(alpha:.24),blurRadius:18)]),child:Icon(player.value.isPlaying?Icons.pause_rounded:Icons.play_arrow_rounded,color:const Color(0xFF18121F),size:34))),
         const SizedBox(width:10),
         IconButton(onPressed:()=>setModal(()=>player.seekTo(Duration(seconds:(current.inSeconds+10).clamp(0,duration.inSeconds).toInt()))),icon:const Icon(Icons.forward_10_rounded,color:Colors.white,size:26)),
         const Spacer(),
         PopupMenuButton<double>(initialValue:1.0,color:const Color(0xFF282333),onSelected:(v)=>setModal(()=>player.setPlaybackSpeed(v)),itemBuilder:(_)=>[.5,.75,1.0,1.25,1.5,2.0].map<PopupMenuEntry<double>>((v)=>PopupMenuItem<double>(value:v,child:Text('${v}x',style:const TextStyle(color:Colors.white)))).toList(),child:Padding(padding:const EdgeInsets.all(8),child:Text('${player.value.playbackSpeed}x',style:TextStyle(color:_gold,fontWeight:FontWeight.w800))))
        ]),
        if(messageId!=null)Padding(padding:const EdgeInsets.only(top:4),child:TextButton.icon(onPressed:(){Navigator.pop(ctx);_jumpToMessage(messageId);},icon:Icon(Icons.chat_bubble_outline_rounded,color:skin.accent,size:17),label:Text(t('العودة إلى الرسالة','Back to message'),style:TextStyle(color:skin.accent,fontWeight:FontWeight.w700))))
       ])))
      ])
     ])));
    });
   });}finally{player.removeListener(refreshPlayer);}
  }catch(e){_show(t('تعذر تشغيل الفيديو. تحقق من الاتصال.','Could not play video. Check your connection.'));}
  finally{await controller?.dispose();}
 }
 Future<void> _consumeTemporaryMedia(String messageId) async{
  VideoPlayerController? videoController;
  try{
   final media=messages.firstWhere((m)=>m['id'].toString()==messageId,orElse:()=>{});
   final isVideo=media['mime_type']?.toString().startsWith('video/')==true||media['message_type']=='video';
   // Validate the storage link before consuming a view so network/storage failures
   // don't burn the user's limited view count.
   final originalPath=(media['body']??'').toString();
   if(originalPath.isEmpty||originalPath=='[viewed]'){_show(t('انتهت مرات مشاهدة هذه الوسائط','No views left for this media'));await _load();return;}
   final url=await _signed(originalPath);
   if(isVideo){videoController=VideoPlayerController.networkUrl(Uri.parse(url));await videoController.initialize();}
   else {
    // Confirm image is decodable before consuming its view.
    final probe=Image.network(url);
    await precacheImage(probe.image,context);
   }
   final path=await db.rpc('consume_ours_temporary_media',params:{'p_message_id':messageId}) as String?;
   if(path==null||path.isEmpty){await videoController?.dispose();videoController=null;_show(t('انتهت مرات مشاهدة هذه الوسائط','No views left for this media'));await _load();return;}
    final temporaryVideo = videoController;
   if(!mounted)return;
   await showDialog<void>(context:context,barrierColor:Colors.black,builder:(ctx)=>Dialog(backgroundColor:Colors.black,insetPadding:EdgeInsets.zero,child:SizedBox.expand(child:SafeArea(child:Column(children:[
    Padding(padding:const EdgeInsets.all(12),child:Text(isVideo?t('فيديو مؤقت','Temporary video'):t('صورة مؤقتة','Temporary photo'),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700))),
    Expanded(child:Center(child:isVideo && temporaryVideo != null?AspectRatio(aspectRatio:temporaryVideo.value.aspectRatio,child:VideoPlayer(temporaryVideo)):InteractiveViewer(minScale:.5,maxScale:4,child:Image.network(url,fit:BoxFit.contain)))),
    if(isVideo && temporaryVideo != null)Row(mainAxisAlignment:MainAxisAlignment.center,children:[IconButton(onPressed:()=>temporaryVideo.value.isPlaying?temporaryVideo.pause():temporaryVideo.play(),icon:Icon(temporaryVideo.value.isPlaying?Icons.pause:Icons.play_arrow,color:Colors.white)),IconButton(onPressed:()=>temporaryVideo.seekTo(Duration.zero),icon:const Icon(Icons.replay,color:Colors.white))]),
    Padding(padding:const EdgeInsets.all(14),child:TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('إغلاق','Close'),style:const TextStyle(color:Colors.white))))
   ])))));
   final row=await db.from('duo_direct_messages').select('view_count,max_views').eq('id',messageId).maybeSingle();
   final count=(row?['view_count'] as num?)?.toInt()??1,limit=(row?['max_views'] as num?)?.toInt()??1;
   if(count>=limit)await db.storage.from(_bucket).remove([path]);
   if(mounted)await _load();
  }catch(e){_show(t('تعذر فتح الوسائط: $e','Could not open media: $e'));}
  finally{await videoController?.dispose();}
 }
 Future<void> _showAttachments() async{
  final choice=await showModalBottomSheet<String>(context:context,backgroundColor:skin.bg,showDragHandle:true,isScrollControlled:true,builder:(ctx)=>SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(18,8,18,22),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
   Text(t('إرسال الوسائط','Share media'),style:TextStyle(color:skin.accent,fontSize:18,fontWeight:FontWeight.w800)),
   const SizedBox(height:5),Text(t('اختر ما تريد مشاركته','Choose what you want to share'),style:TextStyle(color:skin.accent.withValues(alpha:.65),fontSize:12)),
   const SizedBox(height:16),
   Row(children:[
    Expanded(child:_attachmentTile(ctx,'image',Icons.photo_rounded,t('صورة','Photo'),t('إرسال الصور','Send photos'),const Color(0xFF9C83F5))),
    const SizedBox(width:10),Expanded(child:_attachmentTile(ctx,'video',Icons.play_circle_rounded,t('فيديو','Video'),t('إرسال المقاطع','Send videos'),const Color(0xFFDB9D58))),
   ]),
   const SizedBox(height:10),
   Row(children:[
    Expanded(child:_attachmentTile(ctx,'file',Icons.insert_drive_file_rounded,t('ملف','File'),t('مستندات وملفات','Documents'),const Color(0xFF67B9D4))),
    const SizedBox(width:10),Expanded(child:_attachmentTile(ctx,'sticker',Icons.stars_rounded,t('ملصقات','Stickers'),t('ملصقات OURS','OURS stickers'),const Color(0xFFE58BB7))),
   ])
  ]))));
  if(choice==null)return;
  switch(choice){case 'image':await _pickImageWithMode();break;case 'video':await _pickVideo();break;case 'file':await _pickFile();break;case 'sticker':await _sendSticker();break;}
 }
 Widget _attachmentTile(BuildContext ctx,String value,IconData icon,String title,String subtitle,Color color){
  return InkWell(onTap:()=>Navigator.pop(ctx,value),borderRadius:BorderRadius.circular(18),child:Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:color.withValues(alpha:.11),border:Border.all(color:color.withValues(alpha:.27)),borderRadius:BorderRadius.circular(18)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:44,height:44,decoration:BoxDecoration(color:color.withValues(alpha:.2),borderRadius:BorderRadius.circular(14)),child:Icon(icon,color:color,size:24)),const SizedBox(height:11),Text(title,style:TextStyle(color:skin.accent,fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(subtitle,style:TextStyle(color:skin.accent.withValues(alpha:.65),fontSize:11))])));
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
   if(mounted){recordingTimer?.cancel();recordingStartedAt=DateTime.now();recordingElapsed=Duration.zero;setState((){recordingPath=p;recording=true;});recordingTimer=Timer.periodic(const Duration(seconds:1),(_){if(!mounted||recordingStartedAt==null)return;setState(()=>recordingElapsed=DateTime.now().difference(recordingStartedAt!));});}
  }catch(e){_show(t('تعذر بدء التسجيل: $e','Could not start recording: $e'));}
 }
 Future<void> _cancelRecording() async{
  recordingTimer?.cancel();recordingStartedAt=null;recordingElapsed=Duration.zero;
  final p=recordingPath;try{await recorder?.cancel();if(p!=null&&await File(p).exists())await File(p).delete();}catch(_){}
  if(mounted)setState((){recording=false;recordingPath=null;});
 }
 Future<void> _sendRecording() async{
  final r=recorder;if(r==null||!recording)return;recordingTimer?.cancel();recordingStartedAt=null;recordingElapsed=Duration.zero;setState((){sending=true;recording=false;});String? p;
  try{p=await r.stop();if(p==null)throw Exception('Recording unavailable');final f=File(p);if(!await f.exists())throw Exception('Recording not found');
   await _upload(await f.readAsBytes(),'voice_'+DateTime.now().millisecondsSinceEpoch.toString()+'.m4a','audio');
  }catch(e){_show(t('تعذر إرسال التسجيل: $e','Could not send recording: $e'));}
  finally{recordingTimer?.cancel();recordingStartedAt=null;recordingElapsed=Duration.zero;if(p!=null&&await File(p).exists())await File(p).delete();if(mounted)setState((){sending=false;recordingPath=null;});}
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
String _time(dynamic v){final d=DateTime.tryParse(v?.toString()??'')?.toLocal();return d==null?'':_oursMessageTimestamp(d,ar);}
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
 Future<void> _messageActions(BuildContext anchorContext,Map<String,dynamic> message,bool mine,String type,String body) async{
  final id=message['id'].toString();
  final anchor=anchorContext.findRenderObject() as RenderBox?;
  final overlay=Overlay.of(context).context.findRenderObject() as RenderBox?;
  if(anchor==null||overlay==null)return;
  final topLeft=anchor.localToGlobal(Offset.zero,ancestor:overlay);
  final bottomRight=anchor.localToGlobal(anchor.size.bottomRight(Offset.zero),ancestor:overlay);
  final rect=Rect.fromPoints(topLeft,bottomRight);
  final screen=MediaQuery.of(context).size;
  final menuWidth=math.min(158.0,screen.width*.44);
  final right=screen.width-rect.right;
  final menuLeft=right>=menuWidth+10?rect.right+6:math.max(6.0,rect.left-menuWidth-6);
  final itemCount=4+(mine&&type=='text'?1:0)+(mine?1:0);
  final menuHeight=itemCount*37.0+8;
  final menuTop=(rect.center.dy-menuHeight/2).clamp(8.0,screen.height-menuHeight-8);
  final position=RelativeRect.fromLTRB(menuLeft,menuTop,screen.width-menuLeft-menuWidth,screen.height-menuTop-1);
  final isPinned=pinnedMessageIds.contains(id);
  final choice=await showMenu<String>(
   context:context,
   position:position,
   elevation:12,
   color:skin.partner,
   shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12),side:BorderSide(color:skin.accent.withValues(alpha:.20),width:.7)),
   constraints:BoxConstraints.tightFor(width:menuWidth),
   items:[
    _messageMenuItem('reply',t('رد','Reply'),Icons.reply_rounded),
    _messageMenuItem('copy',t('نسخ','Copy'),Icons.copy_rounded),
    _messageMenuItem('pin',isPinned?t('إلغاء التثبيت','Unpin'):t('تثبيت','Pin'),isPinned?Icons.push_pin_outlined:Icons.push_pin_rounded),
    if(mine&&type=='text')_messageMenuItem('edit',t('تعديل','Edit'),Icons.edit_rounded),
    _messageMenuItem('local',t('حذف لديك','Delete for me'),Icons.delete_outline_rounded,color:Colors.orangeAccent),
    if(mine)_messageMenuItem('everyone',t('حذف لدى الجميع','Delete for everyone'),Icons.delete_forever_rounded,color:Colors.redAccent),
   ],
  );
  if(choice==null)return;
  if(choice=='copy'){await Clipboard.setData(ClipboardData(text:type=='text'?body:(message['file_name']??body.split('/').last).toString()));_show(t('تم النسخ','Copied'));return;}
  if(choice=='reply'){setState(()=>replyTo=message);return;}
  if(choice=='pin'){
   try{
    if(isPinned){await db.from('ours_direct_message_pins').delete().eq('message_id',id).eq('user_id',uid);if(mounted)setState(()=>pinnedMessageIds.remove(id));_show(t('تم إلغاء تثبيت الرسالة','Message unpinned'));}
    else{await db.from('ours_direct_message_pins').upsert({'message_id':id,'conversation_id':widget.conversationId,'user_id':uid});if(mounted)setState(()=>pinnedMessageIds.add(id));_show(t('تم تثبيت الرسالة','Message pinned'));}
   }catch(e){_show(t('تعذر تثبيت الرسالة. تأكد من تطبيق تحديث قاعدة البيانات.','Could not pin message. Make sure the database migration is applied.'));}
   return;
  }
  if(choice=='edit'){
   final controller=TextEditingController(text:body);
   final edited=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(backgroundColor:skin.partner,title:Text(t('تعديل الرسالة','Edit message'),style:TextStyle(color:skin.accent)),content:TextField(controller:controller,autofocus:true,maxLines:5,minLines:1,decoration:InputDecoration(hintText:t('اكتب التعديل','Edit your message'))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:Text(t('إلغاء','Cancel'))),FilledButton(onPressed:()=>Navigator.pop(ctx,controller.text.trim()),child:Text(t('حفظ','Save')))]));
   controller.dispose();if(edited==null||edited.isEmpty||edited==body)return;
   try{final editedAt=DateTime.now().toUtc().toIso8601String();final saved=await db.from('duo_direct_messages').update({'body':edited,'edited_at':editedAt}).eq('id',id).eq('sender_id',uid).select('id,body,edited_at').maybeSingle();if(saved==null)throw StateError('Message was not updated. Check update permissions.');if(mounted){final index=messages.indexWhere((m)=>m['id'].toString()==id);if(index>=0)setState((){messages[index]['body']=saved['body'];messages[index]['edited_at']=saved['edited_at'];});}_show(t('تم تعديل الرسالة','Message edited'));}catch(e){_show(t('تعذر تعديل الرسالة: $e','Could not edit message: $e'));}
   return;
  }
  try{if(choice=='local'){await db.from('ours_direct_message_hides').insert({'message_id':id,'user_id':uid});hiddenIds.add(id);if(mounted)setState(()=>messages.removeWhere((m)=>m['id'].toString()==id));await _persistChatCache();}else{await db.from('duo_direct_messages').delete().eq('id',id).eq('sender_id',uid);if(['image','view_once','view_twice','video','audio','file'].contains(type)){try{await db.storage.from(_bucket).remove([body]);}catch(_){}}if(mounted)setState(()=>messages.removeWhere((m)=>m['id'].toString()==id));}}catch(e){_show(t('تعذر حذف الرسالة: $e','Could not delete message: $e'));}
 }
 PopupMenuItem<String> _messageMenuItem(String value,String label,IconData icon,{Color? color})=>PopupMenuItem<String>(
  value:value,
  height:37,
  padding:const EdgeInsets.symmetric(horizontal:10),
  child:Row(children:[
   Icon(icon,size:15,color:color??skin.accent),
   const SizedBox(width:9),
   Expanded(child:Text(label,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:color??Colors.white,fontSize:12,fontWeight:FontWeight.w600))),
  ]),
 );
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
 Future<void> _cacheRecentMedia() async{
  final candidates=messages.where((m)=>['image','video','audio','file','sticker'].contains(m['message_type'])&&!['view_once','view_twice'].contains(m['message_type'])&&(m['body']??'').toString().isNotEmpty&&(m['local_file_path']==null)).toList().reversed.take(24).toList();
  var changed=false;
  for(final row in candidates){
   final file=await _cachedMediaFile(row['body'].toString());
   if(file!=null){row['local_file_path']=file.path;changed=true;}
  }
  if(changed){await _persistChatCache();if(mounted)setState((){});}
 }
 Future<void> _openImageActions(String url,{String? messageId,File? localFile}) async{
  if(!mounted)return;
  await showDialog<void>(context:context,barrierColor:Colors.black,builder:(ctx)=>Dialog(
   backgroundColor:Colors.black,insetPadding:EdgeInsets.zero,
   child:SizedBox.expand(child:SafeArea(child:Column(children:[
    Expanded(child:Center(child:InteractiveViewer(minScale:.5,maxScale:5,child:localFile!=null?Image.file(localFile,fit:BoxFit.contain,errorBuilder:(_,__,___)=>Center(child:Text(t('تعذر تحميل الصورة','Image failed to load'),style:const TextStyle(color:Colors.white)))):Image.network(url,fit:BoxFit.contain,errorBuilder:(_,__,___)=>Center(child:Text(t('تعذر تحميل الصورة','Image failed to load'),style:const TextStyle(color:Colors.white))))))),
    Container(padding:const EdgeInsets.fromLTRB(10,8,10,12),decoration:BoxDecoration(color:skin.partner,border:Border(top:BorderSide(color:skin.accent.withValues(alpha:.18)))),child:Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:[
     TextButton.icon(onPressed:()=>Navigator.pop(ctx),icon:Icon(Icons.close,color:skin.accent),label:Text(t('إغلاق','Close'))),
     if(messageId!=null)TextButton.icon(onPressed:(){Navigator.pop(ctx);_jumpToMessage(messageId);},icon:Icon(Icons.my_location_rounded,color:skin.accent),label:Text(t('إظهار في المحادثة','Show in chat'))),
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
 Widget _wallpaperStudioAction(BuildContext ctx,{required IconData icon,required String title,required String subtitle,required Color accent,required VoidCallback onTap,bool danger=false}) {
  return Material(color:Colors.transparent,child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(17),child:Container(
   padding:const EdgeInsets.symmetric(horizontal:13,vertical:12),
   decoration:BoxDecoration(color:accent.withValues(alpha:.075),borderRadius:BorderRadius.circular(17),border:Border.all(color:accent.withValues(alpha:.18))),
   child:Row(children:[Container(width:38,height:38,decoration:BoxDecoration(color:accent.withValues(alpha:.13),borderRadius:BorderRadius.circular(12)),child:Icon(icon,color:accent,size:20)),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:TextStyle(color:danger?accent:Colors.white,fontWeight:FontWeight.w800,fontSize:12)),const SizedBox(height:3),Text(subtitle,style:TextStyle(color:Colors.white.withValues(alpha:.55),fontSize:10))])),Icon(Icons.chevron_right_rounded,color:accent.withValues(alpha:.7))])
  )));
 }
 Future<void> _openLibraryItem(Map<String,dynamic> message) async{
  final type=message['message_type']?.toString()??'';
  final path=message['body']?.toString()??'';
  if(type=='view_once'||type=='view_twice'){await _consumeTemporaryMedia(message['id'].toString());return;}
  if(type=='image'){
   try{final local=message['local_file_path']?.toString();if(local!=null&&await File(local).exists()){await _openImageActions('',messageId:message['id'].toString(),localFile:File(local));}else{final cached=await _cachedMediaFile(path);if(cached!=null){message['local_file_path']=cached.path;await _persistChatCache();await _openImageActions('',messageId:message['id'].toString(),localFile:cached);}else{final url=await _signed(path);await _openImageActions(url,messageId:message['id'].toString());}}}
   catch(_){_show(t('تعذر فتح الصورة. تحقق من الاتصال.','Could not open image. Check your connection.'));}
   return;
  }
  if(type=='video'){await _playVideo(path,messageId:message['id'].toString());return;}
  await _openFile(path);
 }
 Future<void> _showChatLibrary(String kind) async{
  final types=kind=='media'?['image','view_once','view_twice','video']:['file','audio'];
  final found=messages.where((m)=>types.contains(m['message_type'])).toList().reversed.toList();
  await showModalBottomSheet<void>(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,builder:(ctx)=>SafeArea(child:Container(
   height:MediaQuery.of(ctx).size.height*.80,margin:const EdgeInsets.fromLTRB(8,0,8,8),
   decoration:BoxDecoration(color:const Color(0xFF211D30),borderRadius:BorderRadius.circular(26),border:Border.all(color:skin.accent.withValues(alpha:.22))),
   child:Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(18,13,14,12),child:Row(children:[
     Container(width:40,height:40,decoration:BoxDecoration(color:skin.accent.withValues(alpha:.12),borderRadius:BorderRadius.circular(13)),child:Icon(kind=='media'?Icons.photo_library_rounded:Icons.folder_rounded,color:skin.accent)),
     const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(kind=='media'?t('الوسائط المرسلة','Shared media'):t('الملفات','Files'),style:TextStyle(color:skin.accent,fontWeight:FontWeight.w900,fontSize:16)),
      Text('${found.length} ${t('عنصر','items')}',style:TextStyle(color:Colors.white.withValues(alpha:.55),fontSize:10))
     ])),
     IconButton(onPressed:()=>Navigator.pop(ctx),icon:Icon(Icons.close_rounded,color:skin.accent))
    ])),
    Divider(height:1,color:skin.accent.withValues(alpha:.12)),
    Expanded(child:found.isEmpty?Center(child:Column(mainAxisSize:MainAxisSize.min,children:[
     Icon(kind=='media'?Icons.photo_library_outlined:Icons.folder_open_rounded,size:42,color:skin.accent.withValues(alpha:.5)),
     const SizedBox(height:10),Text(t('لا توجد عناصر بعد','Nothing shared yet'),style:TextStyle(color:Colors.white.withValues(alpha:.65)))
    ])):kind=='media'?GridView.builder(
     padding:const EdgeInsets.all(12),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,crossAxisSpacing:9,mainAxisSpacing:9,childAspectRatio:.88),
     itemCount:found.length,itemBuilder:(context,index){
      final m=found[index],type=(m['message_type']??'').toString(),path=(m['body']??'').toString();
      final temporary=type=='view_once'||type=='view_twice';
      final video=type=='video'||m['mime_type']?.toString().startsWith('video/')==true;
      return Material(color:const Color(0xFF302A40),borderRadius:BorderRadius.circular(15),clipBehavior:Clip.antiAlias,child:InkWell(
       onTap:(){Navigator.pop(ctx);_openLibraryItem(m);},
       child:Stack(fit:StackFit.expand,children:[
        if(type=='image'&&!temporary&&path.isNotEmpty)FutureBuilder<String>(future:_signed(path),builder:(context,snapshot)=>snapshot.hasData?Image.network(snapshot.data!,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Container(color:skin.partner,child:Icon(Icons.broken_image_outlined,color:skin.accent))):Container(color:skin.partner,child:Center(child:CircularProgressIndicator(color:skin.accent,strokeWidth:1.8))))
        else if(video&&!temporary&&path.isNotEmpty)FutureBuilder<String>(future:_signed(path),builder:(context,snapshot)=>snapshot.hasData?_LibraryVideoPreview(url:snapshot.data!,accent:skin.accent):Container(color:skin.partner,child:Center(child:CircularProgressIndicator(color:skin.accent,strokeWidth:1.8))))
        else DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[skin.partner,skin.bg,skin.accent.withValues(alpha:.22)])),child:Center(child:Icon(temporary?Icons.timer_outlined:(video?Icons.play_circle_fill_rounded:Icons.insert_drive_file_rounded),color:Colors.white.withValues(alpha:.9),size:35))),
        DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.transparent,Colors.black.withValues(alpha:.68)]))),
        PositionedDirectional(start:7,end:7,bottom:7,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
         if(video)Row(children:[const Icon(Icons.play_arrow_rounded,color:Colors.white,size:13),Text(t('فيديو','Video'),style:const TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w700))])
         else if(temporary)Text(t('مؤقتة','Temporary'),style:const TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w700)),
         Text(_time(m['created_at']),maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:Colors.white.withValues(alpha:.85),fontSize:9))
        ]))
       ])
      ));
     }
    ):ListView.separated(
     padding:const EdgeInsets.all(12),itemCount:found.length,separatorBuilder:(_,__)=>Divider(color:skin.accent.withValues(alpha:.10)),
     itemBuilder:(context,index){final m=found[index];return ListTile(
      contentPadding:const EdgeInsets.symmetric(horizontal:8,vertical:3),
      leading:Container(width:44,height:44,decoration:BoxDecoration(color:skin.accent.withValues(alpha:.12),borderRadius:BorderRadius.circular(13)),child:Icon(m['message_type']=='audio'?Icons.audio_file_rounded:Icons.insert_drive_file_outlined,color:skin.accent)),
      title:Text((m['file_name']??(m['body']??'').toString().split('/').last).toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700)),
      subtitle:Text(_time(m['created_at']),style:TextStyle(color:skin.accent.withValues(alpha:.75),fontSize:10)),
      trailing:Icon(Icons.open_in_new_rounded,color:skin.accent,size:18),
      onTap:(){Navigator.pop(ctx);_openLibraryItem(m);}
     );}
    ))
   ])
  )));
 }
   @override void dispose(){_outboxTimer?.cancel();typingTimer?.cancel();recordingTimer?.cancel();if(typingSent&&liveChannel!=null)unawaited(liveChannel!.sendBroadcastMessage(event:'typing',payload:{'user_id':uid,'typing':false}).then<void>((_){}));if(liveChannel!=null){unawaited(liveChannel!.untrack().then<void>((_){}));db.removeChannel(liveChannel!);}input.dispose();scroll.dispose();recorder?.dispose();if(channel!=null)db.removeChannel(channel!);super.dispose();}
 @override Widget build(BuildContext context){
  final me=db.auth.currentUser!.id;
  return Scaffold(backgroundColor:skin.bg,appBar:AppBar(backgroundColor:Colors.transparent,flexibleSpace:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[skin.partner.withValues(alpha:.48),skin.bg.withValues(alpha:.96)]))), elevation:0, scrolledUnderElevation:0, toolbarHeight:76, centerTitle:true, surfaceTintColor:Colors.transparent, shape:Border(bottom:BorderSide(color:skin.accent.withValues(alpha:.14),width:.8)),
   leadingWidth:48,
   leading:IconButton(
    tooltip:t('رجوع','Back'),
    onPressed:()=>Navigator.maybePop(context),
    icon:Icon(Icons.arrow_back_ios_new_rounded,color:skin.accent,size:19),
   ),
   titleSpacing:0,
   title:InkWell(
    borderRadius:BorderRadius.circular(16),
    onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>OursProfilePage(userId:widget.partnerId))),
    child:Row(children:[
     FutureBuilder<Map<String,dynamic>?>(
      future:db.from('duo_profiles').select('*').eq('user_id',widget.partnerId).maybeSingle(),
      builder:(context,snapshot){
       final profile=snapshot.data??<String,dynamic>{};
       final raw=(profile['avatar_url']??profile['photo_url']??profile['avatar']??profile['profile_image']??'').toString();
       return Stack(clipBehavior:Clip.none,children:[
        CircleAvatar(
         radius:22,
         backgroundColor:skin.partner,
         backgroundImage:raw.startsWith('http')?NetworkImage(raw):null,
         child:raw.startsWith('http')?null:Icon(Icons.person_rounded,color:skin.accent,size:23),
        ),
        PositionedDirectional(end:-1,bottom:-1,child:Container(
         width:11,height:11,
         decoration:BoxDecoration(color:partnerOnline?const Color(0xFF55D98B):const Color(0xFF858594),shape:BoxShape.circle,border:Border.all(color:skin.bg,width:2)),
        )),
       ]);
      }),
     const SizedBox(width:11),
     Expanded(child:Column(
      mainAxisSize:MainAxisSize.min,
      crossAxisAlignment:CrossAxisAlignment.start,
      children:[
       Text(localPartnerName??widget.partnerName,maxLines:1,overflow:TextOverflow.ellipsis,
        style:TextStyle(color:skin.accent,fontSize:15,fontWeight:FontWeight.w800)),
       const SizedBox(height:3),
       Text(_presenceLabel(),maxLines:1,overflow:TextOverflow.ellipsis,
        style:TextStyle(color:skin.accent.withValues(alpha:.72),fontSize:10.5,fontWeight:FontWeight.w500)),
      ],
     )),
    ]),
   ),
   actions:[
    IconButton(
    tooltip:t('اتصال صوتي','Voice call'),onPressed:()=>_callInfo(false),
    style:IconButton.styleFrom(backgroundColor:skin.partner.withValues(alpha:.72),shape:const CircleBorder(),fixedSize:const Size(38,38),padding:EdgeInsets.zero),
    icon:Icon(Icons.call_outlined,color:skin.accent,size:19)),
   IconButton(
    tooltip:t('اتصال مرئي','Video call'),onPressed:()=>_callInfo(true),
    style:IconButton.styleFrom(backgroundColor:skin.partner.withValues(alpha:.72),shape:const CircleBorder(),fixedSize:const Size(38,38),padding:EdgeInsets.zero),
    icon:Icon(Icons.videocam_outlined,color:skin.accent,size:20)),
   IconButton(
    tooltip:t('تفاصيل المحادثة','Chat details'),
    style:IconButton.styleFrom(backgroundColor:skin.partner.withValues(alpha:.72),shape:const CircleBorder(),fixedSize:const Size(38,38),padding:EdgeInsets.zero),
    onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>StatefulBuilder(builder:(detailsContext,refreshDetails)=>_ChatDetailsPage(
     partnerId:widget.partnerId,partnerName:localPartnerName??widget.partnerName,skin:skin,
     profile:()=>OursProfilePage(userId:widget.partnerId),nickname:_changeLocalNickname,
     search:_searchMessages,media:()=>_showChatLibrary('media'),files:()=>_showChatLibrary('files'),
     themes:()async{await _chooseSkin();refreshDetails((){});},wallpaper:_chooseWallpaper)))),
    icon:Icon(Icons.more_vert_rounded,color:skin.accent,size:20)),
   ],
  ),
  body:Stack(children:[
    if(wallpaperPath==null)Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:_ChatAtmospherePainter(skin)))),
    if(wallpaperPath!=null)Positioned.fill(child:IgnorePointer(child:ClipRect(child:Transform.translate(offset:Offset(wallpaperOffsetX,wallpaperOffsetY),child:Transform.rotate(angle:wallpaperRotation,child:Transform.scale(scale:wallpaperZoom,child:Opacity(opacity:(.55+wallpaperOpacity).clamp(.55,1.0),child:Image.file(File(wallpaperPath!),fit:BoxFit.cover,errorBuilder:(_,__,___)=>CustomPaint(painter:_ChatAtmospherePainter(skin)))))))))),
    if(wallpaperPath!=null)Positioned.fill(child:IgnorePointer(child:ColoredBox(color:skin.bg.withValues(alpha:wallpaperDim)))),
    Positioned.fill(child:IgnorePointer(child:_oursAtmosphereDepth(skin))),
    Column(children:[
    if(pinnedMessageIds.isNotEmpty)Padding(padding:const EdgeInsets.fromLTRB(10,6,10,2),child:InkWell(onTap:(){final pinned=messages.where((m)=>pinnedMessageIds.contains(m['id'].toString())).toList();if(pinned.isNotEmpty)_jumpToMessage(pinned.last['id'].toString());},borderRadius:BorderRadius.circular(13),child:Container(width:double.infinity,padding:const EdgeInsets.symmetric(horizontal:12,vertical:9),decoration:BoxDecoration(color:skin.partner.withValues(alpha:.96),borderRadius:BorderRadius.circular(13),border:Border.all(color:skin.accent.withValues(alpha:.28))),child:Row(children:[Icon(Icons.push_pin_rounded,color:skin.accent,size:17),const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[Text(t('رسالة مثبتة','Pinned message'),style:TextStyle(color:skin.accent,fontSize:10,fontWeight:FontWeight.w800)),Text((pinnedMessageIds.isNotEmpty?messages.firstWhere((m)=>pinnedMessageIds.contains(m['id'].toString()),orElse:()=>{})['body']??'':'').toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontSize:11))])),Icon(Icons.keyboard_arrow_down_rounded,color:skin.accent)])))),
    Expanded(child:loading?Center(child:CircularProgressIndicator(color:skin.accent)):messages.isEmpty
     ?Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
      Icon(Icons.forum_outlined,color:skin.accent,size:52),const SizedBox(height:12),Text(t('ابدأ محادثتكما الخاصة','Start your private conversation'),style:const TextStyle(fontSize:19)),
      const SizedBox(height:7),Text(t('رسائل وصور وملفات وتسجيلات صوتية في مكان واحد.','Messages, photos, files and voice notes in one place.'),textAlign:TextAlign.center,style:TextStyle(color:skin.accent))
     ])))
     :ListView.builder(controller:scroll,padding:const EdgeInsets.all(12),itemCount:messages.length,itemBuilder:(ctx,i){
      final m=messages[i];final mine=m['sender_id']==me;final isRtl=Directionality.of(ctx)==ui.TextDirection.rtl;final swipeSign=mine?(isRtl?1.0:-1.0):(isRtl?-1.0:1.0);final type=m['message_type']?.toString()??'text';final path=m['body']?.toString()??'';final isVisualMessage=type=='image'||type=='video'||type=='sticker'||type=='view_once'||type=='view_twice';final isReplySwipeable=type=='text'||type=='image'||type=='video'||type=='sticker'||type=='audio'||type=='view_once'||type=='view_twice';final isOutlinedMedia=type=='image'||type=='video'||type=='view_once'||type=='view_twice';
      final createdAt=DateTime.tryParse(m['created_at']?.toString()??'')?.toLocal();
      final previousAt=i>0?DateTime.tryParse(messages[i-1]['created_at']?.toString()??'')?.toLocal():null;
      final showDate=createdAt!=null&&(previousAt==null||DateUtils.dateOnly(createdAt)!=DateUtils.dateOnly(previousAt));
      final showTimeGap=createdAt!=null&&previousAt!=null&&!showDate&&createdAt.difference(previousAt)>=const Duration(minutes:5);
      return Column(mainAxisSize:MainAxisSize.min,children:[
       if(showDate)Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Center(child:Container(padding:const EdgeInsets.symmetric(horizontal:13,vertical:6),decoration:BoxDecoration(color:skin.partner.withValues(alpha:.82),borderRadius:BorderRadius.circular(18),border:Border.all(color:skin.accent.withValues(alpha:.18))),child:Text(_dateLabel(createdAt),style:TextStyle(color:skin.accent,fontSize:10,fontWeight:FontWeight.w700))))),
       if (showTimeGap)
        Padding(
         padding: const EdgeInsets.symmetric(vertical: 10),
         child: Center(
          child: Container(
           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
           decoration: BoxDecoration(
            color: skin.partner.withValues(alpha: .76),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: skin.accent.withValues(alpha: .14)),
           ),
           child: Text(
            _time(createdAt),
            style: TextStyle(
             color: skin.accent.withValues(alpha: .92),
             fontSize: 10,
             fontWeight: FontWeight.w700,
            ),
           ),
          ),
         ),
        ),
       if(m['edited_at']!=null||pinnedMessageIds.contains(m['id'].toString()))Padding(padding:const EdgeInsets.only(bottom:3),child:Align(alignment:mine?AlignmentDirectional.centerEnd:AlignmentDirectional.centerStart,child:Row(mainAxisSize:MainAxisSize.min,children:[if(pinnedMessageIds.contains(m['id'].toString()))Icon(Icons.push_pin_rounded,size:10,color:skin.accent),if(pinnedMessageIds.contains(m['id'].toString()))const SizedBox(width:3),if(pinnedMessageIds.contains(m['id'].toString()))Text(t('مثبّتة','Pinned'),style:TextStyle(color:skin.accent,fontSize:9,fontWeight:FontWeight.w800)),if(pinnedMessageIds.contains(m['id'].toString())&&m['edited_at']!=null)const SizedBox(width:5),if(m['edited_at']!=null)Text(t('تم التعديل','Edited'),style:TextStyle(color:skin.accent.withValues(alpha:.8),fontSize:9,fontWeight:FontWeight.w600))]))),
       GestureDetector(
        onLongPress:()=>_messageActions(context,m,mine,type,path),
        onHorizontalDragStart:isReplySwipeable?(_){setState((){_draggingReplyMessageId=m['id'].toString();_replyDragOffset=0;});}:null,
        onHorizontalDragUpdate:isReplySwipeable?(details){
         // Own messages: right in Arabic, left in English. Partner messages: the opposite.
         final delta=(details.primaryDelta??0)*swipeSign;
         if(_draggingReplyMessageId==m['id'].toString()){
          setState(()=>_replyDragOffset=(_replyDragOffset+delta).clamp(0.0,76.0).toDouble());
         }
        }:null,
        onHorizontalDragEnd:isReplySwipeable?(details){
         final velocity=(details.primaryVelocity??0)*swipeSign;
         final shouldReply=_draggingReplyMessageId==m['id'].toString()&&(_replyDragOffset>=58||(_replyDragOffset>=22&&velocity>520));
         setState((){_draggingReplyMessageId=null;_replyDragOffset=0;if(shouldReply)replyTo=m;});
        }:null,
        onHorizontalDragCancel:isReplySwipeable?(){if(_draggingReplyMessageId==m['id'].toString())setState((){_draggingReplyMessageId=null;_replyDragOffset=0;});}:null,
        child:Stack(clipBehavior:Clip.none,alignment:AlignmentDirectional.centerStart,children:[
         if(isReplySwipeable&&_draggingReplyMessageId==m['id'].toString())
          Positioned(left:swipeSign>0?5:null,right:swipeSign<0?5:null,child:Opacity(opacity:(_replyDragOffset/58).clamp(0.0,1.0).toDouble(),child:Transform.scale(scale:(.72+(_replyDragOffset/58).clamp(0.0,1.0).toDouble()*.28),child:Icon(Icons.reply_rounded,color:skin.accent,size:22)))),
         Transform.translate(offset:Offset((_draggingReplyMessageId==m['id'].toString()?_replyDragOffset*swipeSign:0),0),child:Padding(padding:const EdgeInsets.fromLTRB(0,7,0,25),child:Align(alignment:mine?AlignmentDirectional.centerEnd:AlignmentDirectional.centerStart,child:PhysicalShape(clipper:isOutlinedMedia?_RoundedMediaMessageClipper():(isVisualMessage?_MediaMessageClipper():_MessageBubbleClipper(tailOnLeft:mine?Directionality.of(context)==ui.TextDirection.rtl:Directionality.of(context)==ui.TextDirection.ltr)),color:isOutlinedMedia||isVisualMessage?Colors.transparent:(mine?skin.mine:skin.partner),elevation:isOutlinedMedia||isVisualMessage?0:2.5,shadowColor:Colors.black.withValues(alpha:.22),clipBehavior:Clip.antiAlias,child:Container(
         constraints:BoxConstraints(minWidth:isOutlinedMedia||isVisualMessage?0:72,maxWidth:MediaQuery.of(context).size.width*.78),padding:isOutlinedMedia?EdgeInsets.zero: (isVisualMessage?const EdgeInsets.all(2):const EdgeInsets.fromLTRB(14,10,14,12)),
         decoration:BoxDecoration(color:isVisualMessage?Colors.transparent:(highlightedMessageId==m['id'].toString()?Color.lerp(skin.accent,skin.mine,.55):(mine?skin.mine:skin.partner)),border:Border.all(color:highlightedMessageId==m['id'].toString()?skin.accent:(isOutlinedMedia?const Color(0xFFB9B4C6).withValues(alpha:.58):(mine?skin.accent.withValues(alpha:.20):_lavender.withValues(alpha:.14))),width:highlightedMessageId==m['id'].toString()?1.5:(isOutlinedMedia ? .8 : (isVisualMessage ? 0 : .55))),borderRadius:isOutlinedMedia?BorderRadius.circular(18):(isVisualMessage?BorderRadius.circular(15):null)),
         child:IntrinsicWidth(child:Column(crossAxisAlignment:CrossAxisAlignment.center,mainAxisSize:MainAxisSize.min,children:[


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
            ?Container(
             padding:const EdgeInsets.symmetric(horizontal:13,vertical:9),
             decoration:BoxDecoration(
              color:skin.accent.withValues(alpha:.10),
              borderRadius:BorderRadius.circular(15),
              border:Border.all(color:skin.accent.withValues(alpha:.34),width:1),
             ),
             child:Row(mainAxisSize:MainAxisSize.min,children:[
              Icon(Icons.visibility_off_outlined,color:skin.accent,size:16),
              const SizedBox(width:7),
              Text(t('تمت المشاهدة','Viewed'),style:TextStyle(color:skin.accent,fontSize:12,fontWeight:FontWeight.w800)),
             ]),
            )
            :FutureBuilder<String>(future:_signed(path),builder:(c,s)=>s.hasData
             ?InkWell(onTap:()=>_consumeTemporaryMedia(m['id'].toString()),borderRadius:BorderRadius.circular(16),child:ClipRRect(borderRadius:BorderRadius.circular(16),child:Container(width:220,height:145,color:skin.partner,child:Stack(fit:StackFit.expand,children:[
              if(m['mime_type']?.toString().startsWith('video/')==true)ImageFiltered(imageFilter:ImageFilter.blur(sigmaX:30,sigmaY:30),child:Container(decoration:BoxDecoration(gradient:LinearGradient(colors:[skin.accent.withValues(alpha:.30),skin.partner.withValues(alpha:.88),skin.mine.withValues(alpha:.55)])))) else ImageFiltered(imageFilter:ImageFilter.blur(sigmaX:30,sigmaY:30),child:Image.network(s.data!,fit:BoxFit.cover,color:skin.accent.withValues(alpha:.16),colorBlendMode:BlendMode.overlay)),
              Container(decoration:BoxDecoration(gradient:LinearGradient(colors:[skin.bg.withValues(alpha:.28),skin.accent.withValues(alpha:.14),skin.partner.withValues(alpha:.40)]))),
              Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(m['mime_type']?.toString().startsWith('video/')==true?Icons.play_circle_fill_rounded:Icons.visibility_rounded,color:Colors.white,size:34),const SizedBox(height:8),Text(m['mime_type']?.toString().startsWith('video/')==true?t('اضغط لمشاهدة الفيديو','Tap to view video'):((m['max_views']==2)?t('اضغط لفتح · مرتين','Tap to open · twice'):t('اضغط لفتح الصورة','Tap to open image')),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800),textAlign:TextAlign.center)])
             ]))))
             :SizedBox(width:160,height:110,child:Center(child:CircularProgressIndicator(color:skin.accent,strokeWidth:2))))
          else if(type=='video')InkWell(onTap:()=>_playVideo(path,messageId:m['id'].toString()),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.play_circle_fill,color:skin.accent,size:36),const SizedBox(width:8),Text(t('مقطع فيديو · تشغيل','Video · Play'))]))
          else if(type=='image')FutureBuilder<String>(future:_signed(path),builder:(c,s){
           if(s.hasError)return Text(t('تعذر تحميل الصورة','Could not load image'),style:TextStyle(color:skin.accent));
           if(!s.hasData)return SizedBox(width:190,height:125,child:Center(child:CircularProgressIndicator(color:skin.accent)));
           return GestureDetector(
            onTap:()=>_openImageActions(s.data!,messageId:m['id'].toString()),
            child:ClipRRect(
             borderRadius:BorderRadius.circular(18),
             child:ConstrainedBox(
              constraints:const BoxConstraints(maxWidth:280,maxHeight:360),
              child:Image.network(
               s.data!,
               fit:BoxFit.contain,
               errorBuilder:(_,__,___)=>Padding(padding:const EdgeInsets.all(18),child:Text(t('تعذر عرض الصورة','Image unavailable'),style:TextStyle(color:skin.accent))),
              ),
             ),
            ),
           );
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
          else if(type=='text')Center(child:Text(path,textAlign:TextAlign.center,softWrap:true,style:const TextStyle(color:Colors.white,fontSize:15,fontWeight:FontWeight.w500,height:1.4)))
          else Center(child:Text(path,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white,fontSize:14,height:1.35))),
         ]))
        ))))),
         if(mine && m['local_pending']==true)
          PositionedDirectional(start:-16,bottom:20,child:SizedBox(width:11,height:11,child:CircularProgressIndicator(strokeWidth:1.6,color:skin.accent))),
         if(mine && m['read_at']!=null)
          PositionedDirectional(end:0,bottom:-15,child:Text(t('تمت المشاهدة','Seen'),style:TextStyle(color:skin.accent.withValues(alpha:.88),fontSize:9,fontWeight:FontWeight.w700))),
       ]),
      ),
      ]);
     })),
    SafeArea(top:false,child:Container(margin:const EdgeInsets.fromLTRB(10,5,10,8),padding:const EdgeInsets.fromLTRB(9,10,9,9),decoration:_oursGlassPanelDecoration(skin),
     child:recording?Row(children:[
      IconButton(constraints:const BoxConstraints.tightFor(width:42,height:42),padding:EdgeInsets.zero,onPressed:sending?null:_cancelRecording,tooltip:t('إلغاء التسجيل','Cancel recording'),icon:Icon(Icons.close_rounded,color:skin.accent.withValues(alpha:.82),size:21)),
      Expanded(child:Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:11),decoration:BoxDecoration(gradient:LinearGradient(begin:AlignmentDirectional.centerStart,end:AlignmentDirectional.centerEnd,colors:[skin.partner.withValues(alpha:.92),skin.partner.withValues(alpha:.58)]),borderRadius:BorderRadius.circular(20),border:Border.all(color:skin.accent.withValues(alpha:.22))),child:Row(children:[
       Icon(Icons.graphic_eq_rounded,color:skin.accent,size:22),const SizedBox(width:10),
       Expanded(child:Text(t('تسجيل صوتي','Recording audio'),style:TextStyle(color:skin.accent,fontSize:12,fontWeight:FontWeight.w700))),
       Container(padding:const EdgeInsets.symmetric(horizontal:11,vertical:6),decoration:BoxDecoration(color:skin.bg.withValues(alpha:.48),borderRadius:BorderRadius.circular(12),border:Border.all(color:skin.accent.withValues(alpha:.16))),child:Text('${recordingElapsed.inMinutes.toString().padLeft(2,'0')}:${(recordingElapsed.inSeconds%60).toString().padLeft(2,'0')}',style:TextStyle(color:skin.accent,fontSize:15,fontWeight:FontWeight.w800,fontFeatures:const [FontFeature.tabularFigures()]))),
      ]))),
      IconButton(constraints:const BoxConstraints.tightFor(width:42,height:42),padding:EdgeInsets.zero,onPressed:sending?null:_sendRecording,tooltip:t('إيقاف وإرسال التسجيل','Stop and send recording'),icon:Icon(Icons.send_rounded,color:skin.accent))
     ]):Column(mainAxisSize:MainAxisSize.min,children:[
      if(downloading)Padding(padding:const EdgeInsets.symmetric(horizontal:14,vertical:4),child:LinearProgressIndicator(value:downloadProgress,color:skin.accent,minHeight:2)),
      if(partnerTyping)Padding(padding:const EdgeInsetsDirectional.fromSTEB(16,0,16,6),child:Align(alignment:AlignmentDirectional.centerStart,child:Text(t('يكتب الآن…','Typing…'),style:TextStyle(color:skin.accent,fontSize:11,fontStyle:FontStyle.italic)))),
      if(replyTo!=null)Container(margin:const EdgeInsets.fromLTRB(12,0,12,6),padding:const EdgeInsets.symmetric(horizontal:12,vertical:7),decoration:BoxDecoration(color:skin.partner,borderRadius:BorderRadius.circular(12)),child:Row(children:[Icon(Icons.reply,color:skin.accent,size:18),const SizedBox(width:8),Expanded(child:Text((replyTo!['body']??'').toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:skin.accent,fontSize:12))),IconButton(onPressed:()=>setState(()=>replyTo=null),icon:const Icon(Icons.close,size:17))])),
      Row(crossAxisAlignment:CrossAxisAlignment.center,children:[
      if(recording)IconButton(constraints:const BoxConstraints.tightFor(width:42,height:42),padding:EdgeInsets.zero,onPressed:_cancelRecording,tooltip:t('إلغاء التسجيل','Cancel recording'),icon:Icon(Icons.delete_outline_rounded,color:skin.accent,size:22)),
      if(recording)Expanded(child:Container(
       padding:const EdgeInsets.symmetric(horizontal:12,vertical:9),
       decoration:BoxDecoration(color:skin.partner.withValues(alpha:.72),borderRadius:BorderRadius.circular(22),border:Border.all(color:skin.accent.withValues(alpha:.25))),
       child:Column(mainAxisSize:MainAxisSize.min,children:[
        Row(children:[
         Container(width:9,height:9,decoration:const BoxDecoration(color:Colors.redAccent,shape:BoxShape.circle)),
         const SizedBox(width:8),
         Expanded(child:Text(t('تسجيل صوتي','Audio recording'),style:TextStyle(color:skin.accent,fontSize:12,fontWeight:FontWeight.w700))),
         Text('${recordingElapsed.inMinutes.toString().padLeft(2,'0')}:${(recordingElapsed.inSeconds%60).toString().padLeft(2,'0')}',style:TextStyle(color:skin.accent,fontSize:15,fontWeight:FontWeight.w900,fontFeatures:const [FontFeature.tabularFigures()])),
        ]),
        const SizedBox(height:7),
        ClipRRect(borderRadius:BorderRadius.circular(5),child:LinearProgressIndicator(value:null,minHeight:3,backgroundColor:skin.accent.withValues(alpha:.18),color:Colors.redAccent))
       ])
      )),
      if(!recording)IconButton(constraints:const BoxConstraints.tightFor(width:42,height:42),padding:EdgeInsets.zero,visualDensity:VisualDensity.standard,onPressed:uploading||sending?null:_showAttachments,tooltip:t('إرفاق صورة أو ملف أو ملصق','Attach photo, file or sticker'),icon:uploading?SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:skin.accent)):Icon(Icons.add_circle_outline_rounded,color:skin.accent,size:22)),
      if(!recording)Expanded(child:TextField(controller:input,minLines:1,maxLines:5,textInputAction:TextInputAction.send,textDirection:Directionality.of(context),style:const TextStyle(fontSize:14,height:1.25),textAlignVertical:TextAlignVertical.center,onChanged:_handleTyping,onSubmitted:(_)=>_sendText(),decoration:InputDecoration(isDense:true,hintText:t('اكتب رسالة…','Write a message…'),hintStyle:const TextStyle(fontSize:13,height:1.25),filled:true,fillColor:skin.partner.withValues(alpha:.94),border:OutlineInputBorder(borderRadius:BorderRadius.circular(21),borderSide:BorderSide(color:skin.accent.withValues(alpha:.10),width:.7)),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(21),borderSide:BorderSide(color:skin.accent.withValues(alpha:.10),width:.7)),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(21),borderSide:BorderSide(color:skin.accent.withValues(alpha:.48),width:1.1)),contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:12)))),
      if(!recording)IconButton(constraints:const BoxConstraints.tightFor(width:42,height:42),padding:EdgeInsets.zero,visualDensity:VisualDensity.standard,onPressed:uploading||sending?null:_startRecording,tooltip:t('تسجيل صوتي','Record audio'),icon:Icon(Icons.mic_none_rounded,color:skin.accent,size:22)),
      IconButton.filled(constraints:const BoxConstraints.tightFor(width:42,height:42),padding:EdgeInsets.zero,visualDensity:VisualDensity.standard,onPressed:recording?_sendRecording:(sending||uploading?null:_sendText),style:IconButton.styleFrom(backgroundColor:skin.accent,foregroundColor:skin.bg),icon:sending?const SizedBox(width:17,height:17,child:CircularProgressIndicator(strokeWidth:2)):Icon(recording?Icons.send_rounded:Icons.send_rounded,size:20))
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
 final db=Supabase.instance.client,input=TextEditingController(),scroll=ScrollController();
 final messages=<Map<String,String>>[];
 bool sending=false,includeContext=false;String? wallpaperPath;double wallpaperOpacity=.22,wallpaperZoom=1,wallpaperRotation=0,wallpaperDim=.55,wallpaperOffsetX=0,wallpaperOffsetY=0;_ChatSkin skin=_skins.first;
 bool get ar=>Localizations.localeOf(context).languageCode=='ar';String t(String a,String e)=>ar?a:e;
 @override void initState(){super.initState();_restore();_loadAppearance();}
 Future<void> _loadAppearance()async{
  final p=await SharedPreferences.getInstance(),id=_normalizeOursSkinId(p.getString('ours_ai_skin')??'ours');
  final found=_skins.where((x)=>x.id==id);
  if(mounted)setState((){skin=found.isEmpty?_skins.first:found.first;wallpaperPath=p.getString('ours_ai_wallpaper');wallpaperOpacity=p.getDouble('ours_ai_wallpaper_opacity')??.22;wallpaperZoom=p.getDouble('ours_ai_wallpaper_zoom')??1;wallpaperRotation=p.getDouble('ours_ai_wallpaper_rotation')??0;wallpaperDim=p.getDouble('ours_ai_wallpaper_dim')??.55;wallpaperOffsetX=p.getDouble('ours_ai_wallpaper_offset_x')??0;wallpaperOffsetY=p.getDouble('ours_ai_wallpaper_offset_y')??0;});
 }
 Future<void> _chooseTheme()async{
  final selected=await showModalBottomSheet<String>(context:context,backgroundColor:const Color(0xFF100D1B),showDragHandle:true,isScrollControlled:true,builder:(ctx)=>SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(14,8,14,18),child:Column(mainAxisSize:MainAxisSize.min,children:[
   Row(children:[Icon(Icons.palette_rounded,color:skin.accent,size:24),const SizedBox(width:9),Expanded(child:Text(t('أجواء OURS','OURS atmospheres'),style:TextStyle(color:skin.accent,fontSize:19,fontWeight:FontWeight.w900))),Text(t('اختر مزاجك','Choose your mood'),style:const TextStyle(color:_lavender,fontSize:10))]),
   const SizedBox(height:12),Container(width:double.infinity,padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:skin.bg,borderRadius:BorderRadius.circular(20),border:Border.all(color:skin.accent.withValues(alpha:.28))),child:Row(children:[Container(width:42,height:42,decoration:BoxDecoration(gradient:LinearGradient(colors:[skin.mine,skin.partner,skin.accent.withValues(alpha:.5)]),borderRadius:BorderRadius.circular(14)),child:Icon(Icons.chat_bubble_rounded,color:skin.accent)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t('معاينة الثيم الحالي','Current theme preview'),style:TextStyle(color:skin.accent,fontWeight:FontWeight.w800)),Text(ar?skin.ar:skin.en,style:const TextStyle(color:Colors.white,fontSize:12))]))])),
   const SizedBox(height:10),Flexible(child:GridView.builder(shrinkWrap:true,physics:const BouncingScrollPhysics(),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:1.55),itemCount:_skins.length,itemBuilder:(ctx,i){final x=_skins[i];final active=x.id==skin.id;return InkWell(onTap:()=>Navigator.pop(ctx,x.id),borderRadius:BorderRadius.circular(18),child:Container(clipBehavior:Clip.antiAlias,padding:const EdgeInsets.all(10),decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),border:Border.all(color:active?x.accent:Colors.white.withValues(alpha:.14),width:active?2:1)),child:Stack(children:[Positioned.fill(child:CustomPaint(painter:_ChatAtmospherePainter(x))),Positioned.fill(child:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.black.withValues(alpha:.12),Colors.transparent,Colors.black.withValues(alpha:.42)])))),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Container(width:9,height:9,decoration:BoxDecoration(color:x.accent,shape:BoxShape.circle)),const Spacer(),if(active)Icon(Icons.check_circle_rounded,color:x.accent,size:17)]),const Spacer(),Row(children:[Container(width:23,height:12,decoration:BoxDecoration(color:x.mine,borderRadius:BorderRadius.circular(8))),const SizedBox(width:4),Container(width:20,height:12,decoration:BoxDecoration(color:x.partner,borderRadius:BorderRadius.circular(8))),const Spacer(),Icon(Icons.auto_awesome_rounded,color:x.accent,size:15)]),const SizedBox(height:5),Text(ar?x.ar:x.en,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:11))])])));})),const SizedBox(height:6),Text(t('ألوان وخلفيات مصممة لكل مزاج','A distinct palette and atmosphere for every mood'),style:const TextStyle(color:_lavender,fontSize:10))
  ]))));
  if(selected==null)return;final p=await SharedPreferences.getInstance();await p.setString('ours_ai_skin',selected);
  if(mounted)setState(()=>skin=_skins.firstWhere((x)=>x.id==selected,orElse:()=>_skins.first));
 }
 Future<void> _chooseWallpaper()async{
  final result=await _openOursWallpaperStudio(context:context,skin:skin,t:t,currentPath:wallpaperPath,preferenceKey:'ours_ai_wallpaper',filePrefix:'ours_ai',currentOpacity:wallpaperOpacity,currentZoom:wallpaperZoom,currentRotation:wallpaperRotation,currentDim:wallpaperDim,currentOffsetX:wallpaperOffsetX,currentOffsetY:wallpaperOffsetY,previewMessages:[{'sender_id':db.auth.currentUser!.id,'message_type':'text','body':t('مرحبًا، كيف أقدر أساعدك؟','Hello, how can I help?')},{'sender_id':'ours-ai','message_type':'text','body':t('هذه معاينة لمحادثة OURS AI','Preview of OURS AI chat')}],currentUserId:db.auth.currentUser!.id,partnerName:'OURS AI');
  if(result==null)return;
  if(mounted)setState((){
   wallpaperPath=result['path'] as String?;
   wallpaperOpacity=(result['opacity'] as num).toDouble();wallpaperZoom=(result['zoom'] as num).toDouble();wallpaperRotation=(result['rotation'] as num).toDouble();wallpaperDim=(result['dim'] as num).toDouble();wallpaperOffsetX=(result['offset_x'] as num).toDouble();wallpaperOffsetY=(result['offset_y'] as num).toDouble();
  });
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
 void _bottom()=>WidgetsBinding.instance.addPostFrameCallback((_){if(scroll.hasClients)scroll.animateTo(scroll.position.maxScrollExtent,duration:const Duration(milliseconds:220),curve:Curves.easeOut);});
 String _time(String? value){final date=DateTime.tryParse(value??'')?.toLocal();return date==null?'':_oursMessageTimestamp(date,ar);}
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
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:skin.bg,appBar:AppBar(backgroundColor:Colors.transparent,flexibleSpace:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[skin.partner.withValues(alpha:.48),skin.bg.withValues(alpha:.96)]))),elevation:0,scrolledUnderElevation:0,toolbarHeight:76,centerTitle:false,titleSpacing:0,surfaceTintColor:Colors.transparent,shape:Border(bottom:BorderSide(color:skin.accent.withValues(alpha:.14),width:.8)),leadingWidth:48,leading:IconButton(tooltip:t('رجوع','Back'),onPressed:()=>Navigator.maybePop(context),icon:Icon(Icons.arrow_back_ios_new_rounded,color:skin.accent,size:19)),title:Row(mainAxisSize:MainAxisSize.min,children:[Container(width:40,height:40,decoration:BoxDecoration(color:skin.partner,border:Border.all(color:skin.accent.withValues(alpha:.35)),shape:BoxShape.circle),child:Icon(Icons.auto_awesome_rounded,color:skin.accent,size:20)),const SizedBox(width:9),Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Text('OURS AI',style:TextStyle(color:skin.accent,letterSpacing:1.3,fontWeight:FontWeight.w800,fontSize:14)),Text(t('مساعدك الذكي','Your private assistant'),style:TextStyle(color:skin.accent.withValues(alpha:.75),fontSize:10))])]),actions:[
  IconButton(style:IconButton.styleFrom(backgroundColor:skin.partner.withValues(alpha:.72),shape:const CircleBorder(),fixedSize:const Size(38,38),padding:EdgeInsets.zero),onPressed:_search,icon:Icon(Icons.search,color:skin.accent,size:19)),
  IconButton(style:IconButton.styleFrom(backgroundColor:skin.partner.withValues(alpha:.72),shape:const CircleBorder(),fixedSize:const Size(38,38),padding:EdgeInsets.zero),onPressed:_chooseTheme,icon:Icon(Icons.palette_outlined,color:skin.accent,size:19)),
  IconButton(style:IconButton.styleFrom(backgroundColor:skin.partner.withValues(alpha:.72),shape:const CircleBorder(),fixedSize:const Size(38,38),padding:EdgeInsets.zero),onPressed:_chooseWallpaper,icon:Icon(Icons.wallpaper_outlined,color:skin.accent,size:19))
 ]),
  body:Stack(children:[
   if(wallpaperPath==null)Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:_ChatAtmospherePainter(skin)))),
   if(wallpaperPath!=null)Positioned.fill(child:IgnorePointer(child:ClipRect(child:Transform.translate(offset:Offset(wallpaperOffsetX,wallpaperOffsetY),child:Transform.rotate(angle:wallpaperRotation,child:Transform.scale(scale:wallpaperZoom,child:Opacity(opacity:(.55+wallpaperOpacity).clamp(.55,1.0),child:Image.file(File(wallpaperPath!),fit:BoxFit.cover,errorBuilder:(_,__,___)=>CustomPaint(painter:_ChatAtmospherePainter(skin)))))))))),
   if(wallpaperPath!=null)Positioned.fill(child:IgnorePointer(child:ColoredBox(color:skin.bg.withValues(alpha:wallpaperDim)))),
    Positioned.fill(child:IgnorePointer(child:_oursAtmosphereDepth(skin))),
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
     final showTimeGap=date!=null&&previous!=null&&!showDate&&date.difference(previous)>=const Duration(minutes:5);
     return Column(children:[
      if(showDate)Padding(padding:const EdgeInsets.symmetric(vertical:9),child:Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:5),decoration:BoxDecoration(color:skin.partner,borderRadius:BorderRadius.circular(14)),child:Text(_dateLabel(date),style:TextStyle(color:skin.accent,fontSize:10,fontWeight:FontWeight.w700)))),
      if(showTimeGap)Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Text(_time(m['created_at']),style:TextStyle(color:skin.accent.withValues(alpha:.82),fontSize:10,fontWeight:FontWeight.w700))),
      Align(alignment:mine?AlignmentDirectional.centerEnd:AlignmentDirectional.centerStart,child:Stack(clipBehavior:Clip.none,children:[_OursUnifiedMessageSurface(skin:skin,isMine:mine,child:Text(m['content']??'',textAlign:TextAlign.start,style:const TextStyle(height:1.32,fontSize:14.5,color:Colors.white))),if(sending&&mine&&i==messages.length-1)PositionedDirectional(start:-16,top:0,bottom:0,child:Center(child:SizedBox(width:11,height:11,child:CircularProgressIndicator(strokeWidth:1.6,color:skin.accent))))]))
     ]);
    })),
    
    SafeArea(top:false,child:Container(
     margin:const EdgeInsets.fromLTRB(10,5,10,8),
     padding:const EdgeInsets.fromLTRB(9,10,9,9),
     decoration:_oursGlassPanelDecoration(skin),
     child:Row(children:[
      Expanded(child:TextField(controller:input,minLines:1,maxLines:4,textInputAction:TextInputAction.send,onSubmitted:(_)=>_send(),decoration:InputDecoration(isDense:true,hintText:t('اسأل OURS AI…','Ask OURS AI…'),filled:true,fillColor:skin.partner.withValues(alpha:.94),border:OutlineInputBorder(borderRadius:BorderRadius.circular(21),borderSide:BorderSide(color:skin.accent.withValues(alpha:.10),width:.7)),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(21),borderSide:BorderSide(color:skin.accent.withValues(alpha:.10),width:.7)),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(21),borderSide:BorderSide(color:skin.accent.withValues(alpha:.48),width:1.1)),contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:12)))),
      const SizedBox(width:5),IconButton.filled(constraints:const BoxConstraints.tightFor(width:42,height:42),onPressed:sending?null:()=>_send(),style:IconButton.styleFrom(backgroundColor:skin.accent,foregroundColor:skin.bg),icon:sending?const SizedBox(width:17,height:17,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.send_rounded))
     ])))
   ]))
  ]));
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
 RealtimeChannel? channel;AudioRecorder? recorder;Timer? recordingTimer;DateTime? recordingStartedAt;Duration recordingElapsed=Duration.zero;String? recordingPath,wallpaperPath;double wallpaperOpacity=.22,wallpaperZoom=1,wallpaperRotation=0,wallpaperDim=.55,wallpaperOffsetX=0,wallpaperOffsetY=0;
 Map<String,dynamic>? replyTo;_ChatSkin skin=_skins.first;
 bool loading=true,sending=false,uploading=false,recording=false;
 bool get ar=>Localizations.localeOf(context).languageCode=='ar';
 String t(String a,String e)=>ar?a:e;
 String get uid=>db.auth.currentUser!.id;
 @override void initState(){super.initState();_loadSelfSkin();_load();_listen();}
 Future<void> _loadSelfSkin()async{
  final p=await SharedPreferences.getInstance();
  final id=_normalizeOursSkinId(p.getString('ours_self_skin')??'ours');
  final found=_skins.where((x)=>x.id==id);
  if(mounted)setState((){skin=found.isEmpty?_skins.first:found.first;wallpaperPath=p.getString('ours_self_wallpaper');wallpaperOpacity=p.getDouble('ours_self_wallpaper_opacity')??.22;wallpaperZoom=p.getDouble('ours_self_wallpaper_zoom')??1;wallpaperRotation=p.getDouble('ours_self_wallpaper_rotation')??0;wallpaperDim=p.getDouble('ours_self_wallpaper_dim')??.55;wallpaperOffsetX=p.getDouble('ours_self_wallpaper_offset_x')??0;wallpaperOffsetY=p.getDouble('ours_self_wallpaper_offset_y')??0;});
 }
 Future<void> _chooseTheme()async{
  final selected=await showModalBottomSheet<String>(context:context,backgroundColor:const Color(0xFF100D1B),showDragHandle:true,isScrollControlled:true,builder:(ctx)=>SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(14,8,14,18),child:Column(mainAxisSize:MainAxisSize.min,children:[
   Row(children:[Icon(Icons.palette_rounded,color:skin.accent,size:24),const SizedBox(width:9),Expanded(child:Text(t('أجواء OURS','OURS atmospheres'),style:TextStyle(color:skin.accent,fontSize:19,fontWeight:FontWeight.w900))),Text(t('اختر مزاجك','Choose your mood'),style:const TextStyle(color:_lavender,fontSize:10))]),
   const SizedBox(height:12),Container(width:double.infinity,padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:skin.bg,borderRadius:BorderRadius.circular(20),border:Border.all(color:skin.accent.withValues(alpha:.28))),child:Row(children:[Container(width:42,height:42,decoration:BoxDecoration(gradient:LinearGradient(colors:[skin.mine,skin.partner,skin.accent.withValues(alpha:.5)]),borderRadius:BorderRadius.circular(14)),child:Icon(Icons.chat_bubble_rounded,color:skin.accent)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t('معاينة الثيم الحالي','Current theme preview'),style:TextStyle(color:skin.accent,fontWeight:FontWeight.w800)),Text(ar?skin.ar:skin.en,style:const TextStyle(color:Colors.white,fontSize:12))]))])),
   const SizedBox(height:10),Flexible(child:GridView.builder(shrinkWrap:true,physics:const BouncingScrollPhysics(),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:10,crossAxisSpacing:10,childAspectRatio:1.55),itemCount:_skins.length,itemBuilder:(ctx,i){final x=_skins[i];final active=x.id==skin.id;return InkWell(onTap:()=>Navigator.pop(ctx,x.id),borderRadius:BorderRadius.circular(18),child:Container(clipBehavior:Clip.antiAlias,padding:const EdgeInsets.all(10),decoration:BoxDecoration(borderRadius:BorderRadius.circular(18),border:Border.all(color:active?x.accent:Colors.white.withValues(alpha:.14),width:active?2:1)),child:Stack(children:[Positioned.fill(child:CustomPaint(painter:_ChatAtmospherePainter(x))),Positioned.fill(child:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.black.withValues(alpha:.12),Colors.transparent,Colors.black.withValues(alpha:.42)])))),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Container(width:9,height:9,decoration:BoxDecoration(color:x.accent,shape:BoxShape.circle)),const Spacer(),if(active)Icon(Icons.check_circle_rounded,color:x.accent,size:17)]),const Spacer(),Row(children:[Container(width:23,height:12,decoration:BoxDecoration(color:x.mine,borderRadius:BorderRadius.circular(8))),const SizedBox(width:4),Container(width:20,height:12,decoration:BoxDecoration(color:x.partner,borderRadius:BorderRadius.circular(8))),const Spacer(),Icon(Icons.auto_awesome_rounded,color:x.accent,size:15)]),const SizedBox(height:5),Text(ar?x.ar:x.en,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:11))])])));})),const SizedBox(height:6),Text(t('ألوان وخلفيات مصممة لكل مزاج','A distinct palette and atmosphere for every mood'),style:const TextStyle(color:_lavender,fontSize:10))
  ]))));
  if(selected==null)return;final p=await SharedPreferences.getInstance();await p.setString('ours_self_skin',selected);
  if(mounted)setState(()=>skin=_skins.firstWhere((x)=>x.id==selected,orElse:()=>_skins.first));
 }
 Future<void> _chooseWallpaper()async{
  final result=await _openOursWallpaperStudio(context:context,skin:skin,t:t,currentPath:wallpaperPath,preferenceKey:'ours_self_wallpaper',filePrefix:'ours_self',currentOpacity:wallpaperOpacity,currentZoom:wallpaperZoom,currentRotation:wallpaperRotation,currentDim:wallpaperDim,currentOffsetX:wallpaperOffsetX,currentOffsetY:wallpaperOffsetY,previewMessages:[{'sender_id':uid,'message_type':'text','body':t('هذه معاينة لمراسلة نفسك','Preview of Saved messages')},{'sender_id':uid,'message_type':'text','body':t('الخلفية تظهر خلف الرسائل تمامًا','Wallpaper preview behind your notes')}],currentUserId:uid,partnerName:t('مراسلة نفسي','Saved messages'));
  if(result==null)return;
  if(mounted)setState((){
   wallpaperPath=result['path'] as String?;
   wallpaperOpacity=(result['opacity'] as num).toDouble();wallpaperZoom=(result['zoom'] as num).toDouble();wallpaperRotation=(result['rotation'] as num).toDouble();wallpaperDim=(result['dim'] as num).toDouble();wallpaperOffsetX=(result['offset_x'] as num).toDouble();wallpaperOffsetY=(result['offset_y'] as num).toDouble();
  });
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
  final text=input.text.trim();if(text.isEmpty||sending)return;
  final pendingId='local_${DateTime.now().microsecondsSinceEpoch}';
  final pendingRow=<String,dynamic>{'id':pendingId,'user_id':uid,'body':text,'message_type':'text','reply_to':replyTo?['id'],'created_at':DateTime.now().toUtc().toIso8601String(),'local_pending':true};
  setState((){sending=true;rows.add(pendingRow);});_bottom();
  try{
   final row=await db.from('ours_self_messages').insert({'user_id':uid,'body':text,'message_type':'text','reply_to':replyTo?['id']}).select().single();
   if(mounted)setState((){rows.removeWhere((r)=>r['id'].toString()==pendingId);if(!rows.any((r)=>r['id'].toString()==row['id'].toString()))rows.add(Map<String,dynamic>.from(row));});
   input.clear();if(mounted)setState(()=>replyTo=null);_bottom();
  }catch(_){if(mounted)setState(()=>rows.removeWhere((r)=>r['id'].toString()==pendingId));_notice(t('تعذر حفظ الرسالة. حاول مجددًا.','Could not save message. Try again.'));}
  finally{if(mounted)setState(()=>sending=false);}
 }
 String _selfMime(String name){
  const types={'jpg':'image/jpeg','jpeg':'image/jpeg','png':'image/png','webp':'image/webp','gif':'image/gif','m4a':'audio/mp4','aac':'audio/aac','mp3':'audio/mpeg','ogg':'audio/ogg','pdf':'application/pdf','txt':'text/plain','csv':'text/csv','doc':'application/msword','docx':'application/vnd.openxmlformats-officedocument.wordprocessingml.document','xls':'application/vnd.ms-excel','xlsx':'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','ppt':'application/vnd.ms-powerpoint','pptx':'application/vnd.openxmlformats-officedocument.presentationml.presentation','zip':'application/zip'};
  return types[name.split('.').last.toLowerCase()]??'';
 }
 Future<void> _uploadSelf(Uint8List bytes,String name,String type)async{
  if(bytes.isEmpty)return;if(bytes.length>100*1024*1024){_notice(t('الحد الأقصى 100 ميجابايت','Maximum size is 100 MB'));return;}
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
 Future<void> _pickFile()async{
  try{final result=await FilePicker.platform.pickFiles(withData:true);if(result==null||result.files.isEmpty)return;
   final f=result.files.single,bytes=f.bytes??(f.path==null?null:await File(f.path!).readAsBytes());
   if(bytes==null)throw Exception('file');await _uploadSelf(bytes,f.name,'file');
  }catch(_){_notice(t('تعذر اختيار الملف','Could not select file'));}
 }
 Future<void> _pickVideo()async{try{final picked=await picker.pickVideo(source:ImageSource.gallery,maxDuration:const Duration(minutes:2));if(picked==null)return;final extension=picked.name.split('.').last.toLowerCase();if(!['mp4','mov','webm'].contains(extension)){_notice(t('صيغة الفيديو غير مدعومة','Unsupported video format'));return;}await _uploadSelf(await picked.readAsBytes(),picked.name,'file');}catch(_){_notice(t('تعذر اختيار الفيديو','Could not select video'));}}
 Future<void> _showAttachments()async{final choice=await showModalBottomSheet<String>(context:context,backgroundColor:skin.bg,showDragHandle:true,isScrollControlled:true,builder:(ctx)=>SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(18,8,18,22),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t('إرسال الوسائط','Share media'),style:TextStyle(color:skin.accent,fontSize:18,fontWeight:FontWeight.w800)),const SizedBox(height:5),Text(t('اختر ما تريد مشاركته','Choose what you want to share'),style:TextStyle(color:skin.accent.withValues(alpha:.65),fontSize:12)),const SizedBox(height:16),Row(children:[Expanded(child:_selfAttachmentTile(ctx,'image',Icons.photo_rounded,t('صورة','Photo'),t('إرسال الصور','Send photos'),const Color(0xFF9C83F5))),const SizedBox(width:10),Expanded(child:_selfAttachmentTile(ctx,'video',Icons.play_circle_rounded,t('فيديو','Video'),t('إرسال المقاطع','Send videos'),const Color(0xFFDB9D58)))]),const SizedBox(height:10),Row(children:[Expanded(child:_selfAttachmentTile(ctx,'file',Icons.insert_drive_file_rounded,t('ملف','File'),t('مستندات وملفات','Documents'),const Color(0xFF67B9D4))),const SizedBox(width:10),Expanded(child:_selfAttachmentTile(ctx,'sticker',Icons.stars_rounded,t('ملصقات','Stickers'),t('ملصقات OURS','OURS stickers'),const Color(0xFFE58BB7)))])]))));if(choice==null)return;switch(choice){case 'image':await _pickImage();break;case 'video':await _pickVideo();break;case 'file':await _pickFile();break;case 'sticker':await _pickImage(sticker:true);break;}}
 Widget _selfAttachmentTile(BuildContext ctx,String value,IconData icon,String title,String subtitle,Color color)=>InkWell(onTap:()=>Navigator.pop(ctx,value),borderRadius:BorderRadius.circular(18),child:Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:color.withValues(alpha:.11),border:Border.all(color:color.withValues(alpha:.27)),borderRadius:BorderRadius.circular(18)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:44,height:44,decoration:BoxDecoration(color:color.withValues(alpha:.2),borderRadius:BorderRadius.circular(14)),child:Icon(icon,color:color,size:24)),const SizedBox(height:11),Text(title,style:TextStyle(color:skin.accent,fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(subtitle,style:TextStyle(color:skin.accent.withValues(alpha:.65),fontSize:11))])));
 Future<void> _startRecording()async{
  final r=recorder??=AudioRecorder();
  try{if(!await r.hasPermission()){_notice(t('اسمح باستخدام الميكروفون أولًا','Allow microphone access first'));return;}
   final dir=await getTemporaryDirectory(),path='${dir.path}/ours_self_${DateTime.now().microsecondsSinceEpoch}.m4a';
   await r.start(const RecordConfig(encoder:AudioEncoder.aacLc,bitRate:96000,sampleRate:44100,numChannels:1,echoCancel:true,noiseSuppress:true),path:path);
   if(mounted){recordingTimer?.cancel();recordingStartedAt=DateTime.now();recordingElapsed=Duration.zero;setState((){recordingPath=path;recording=true;});recordingTimer=Timer.periodic(const Duration(seconds:1),(_){if(!mounted||recordingStartedAt==null)return;setState(()=>recordingElapsed=DateTime.now().difference(recordingStartedAt!));});}
  }catch(_){_notice(t('تعذر بدء التسجيل','Could not start recording'));}
 }
 Future<void> _stopRecording({bool send=true})async{
  final r=recorder;if(r==null||!recording)return;recordingTimer?.cancel();recordingStartedAt=null;recordingElapsed=Duration.zero;
  String? path;
  try{path=await r.stop();if(send&&path!=null){final file=File(path);if(await file.exists())await _uploadSelf(await file.readAsBytes(),'voice_${DateTime.now().millisecondsSinceEpoch}.m4a','audio');}}
  catch(_){_notice(t('تعذر إرسال التسجيل','Could not send recording'));}
  finally{if(path!=null){try{final file=File(path);if(await file.exists())await file.delete();}catch(_){}}
   if(mounted)setState((){recording=false;recordingPath=null;});}
 }
 Future<String> _signedSelf(String path){
  final old=urls[path];if(old!=null)return old;
  final future=db.storage.from('ours-direct-media').createSignedUrl(path,900);urls[path]=future;return future;
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
 String _selfTime(dynamic value){final date=DateTime.tryParse(value?.toString()??'')?.toLocal();return date==null?'':_oursMessageTimestamp(date,ar);}
 String _selfDate(DateTime date){final today=DateUtils.dateOnly(DateTime.now()),day=DateUtils.dateOnly(date);if(day==today)return t('اليوم','Today');if(day==today.subtract(const Duration(days:1)))return t('أمس','Yesterday');return _oursDate(day,ar);}
 void _bottom()=>WidgetsBinding.instance.addPostFrameCallback((_){if(scroll.hasClients)scroll.animateTo(0,duration:const Duration(milliseconds:220),curve:Curves.easeOut);});
 @override void dispose(){recordingTimer?.cancel();if(channel!=null)db.removeChannel(channel!);recorder?.dispose();input.dispose();scroll.dispose();super.dispose();}
 @override Widget build(BuildContext context){
  return Scaffold(backgroundColor:skin.bg,appBar:AppBar(backgroundColor:Colors.transparent,flexibleSpace:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[skin.partner.withValues(alpha:.48),skin.bg.withValues(alpha:.96)]))),elevation:0,scrolledUnderElevation:0,toolbarHeight:76,centerTitle:false,titleSpacing:0,surfaceTintColor:Colors.transparent,shape:Border(bottom:BorderSide(color:skin.accent.withValues(alpha:.14),width:.8)),leadingWidth:48,leading:IconButton(tooltip:t('رجوع','Back'),onPressed:()=>Navigator.maybePop(context),icon:Icon(Icons.arrow_back_ios_new_rounded,color:skin.accent,size:19)),title:Row(mainAxisSize:MainAxisSize.min,children:[Container(width:40,height:40,decoration:BoxDecoration(color:skin.partner,border:Border.all(color:skin.accent.withValues(alpha:.35)),shape:BoxShape.circle),child:Icon(Icons.bookmark_rounded,color:skin.accent,size:20)),const SizedBox(width:9),Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[Text(t('مراسلة نفسي','Saved messages'),style:TextStyle(color:skin.accent,fontSize:14,fontWeight:FontWeight.w800)),Text(t('مساحة لا يراها غيرك','Private to you'),style:TextStyle(color:skin.accent.withValues(alpha:.75),fontSize:10))])]),actions:[
   IconButton(style:IconButton.styleFrom(backgroundColor:skin.partner.withValues(alpha:.72),shape:const CircleBorder(),fixedSize:const Size(38,38),padding:EdgeInsets.zero),onPressed:_searchSelf,icon:Icon(Icons.search,color:skin.accent,size:19)),
   IconButton(style:IconButton.styleFrom(backgroundColor:skin.partner.withValues(alpha:.72),shape:const CircleBorder(),fixedSize:const Size(38,38),padding:EdgeInsets.zero),onPressed:_chooseTheme,icon:Icon(Icons.palette_outlined,color:skin.accent,size:19)),
   IconButton(style:IconButton.styleFrom(backgroundColor:skin.partner.withValues(alpha:.72),shape:const CircleBorder(),fixedSize:const Size(38,38),padding:EdgeInsets.zero),onPressed:_chooseWallpaper,icon:Icon(Icons.wallpaper_outlined,color:skin.accent,size:19))
  ]),
  body:Stack(children:[
   if(wallpaperPath==null)Positioned.fill(child:IgnorePointer(child:CustomPaint(painter:_ChatAtmospherePainter(skin)))),
   if(wallpaperPath!=null)Positioned.fill(child:IgnorePointer(child:ClipRect(child:Transform.translate(offset:Offset(wallpaperOffsetX,wallpaperOffsetY),child:Transform.rotate(angle:wallpaperRotation,child:Transform.scale(scale:wallpaperZoom,child:Opacity(opacity:(.55+wallpaperOpacity).clamp(.55,1.0),child:Image.file(File(wallpaperPath!),fit:BoxFit.cover,errorBuilder:(_,__,___)=>CustomPaint(painter:_ChatAtmospherePainter(skin)))))))))),
   if(wallpaperPath!=null)Positioned.fill(child:IgnorePointer(child:ColoredBox(color:skin.bg.withValues(alpha:wallpaperDim)))),
    Positioned.fill(child:IgnorePointer(child:_oursAtmosphereDepth(skin))),
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
      final showTimeGap=date!=null&&previous!=null&&!showDate&&date.difference(previous).abs()>=const Duration(minutes:5);
      return Column(children:[
       if(showDate)Padding(padding:const EdgeInsets.symmetric(vertical:10),child:Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:5),decoration:BoxDecoration(color:skin.partner,borderRadius:BorderRadius.circular(14)),child:Text(_selfDate(date),style:TextStyle(color:skin.accent,fontSize:10,fontWeight:FontWeight.w700)))),
       if(showTimeGap)Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Text(_selfTime(row['created_at']),style:TextStyle(color:skin.accent.withValues(alpha:.82),fontSize:10,fontWeight:FontWeight.w700))),
       Align(alignment:AlignmentDirectional.centerEnd,child:Stack(clipBehavior:Clip.none,children:[GestureDetector(onLongPress:()=>_noteActions(row),child:_OursUnifiedMessageSurface(skin:skin,isMine:true,isVisual:type=='image'||type=='sticker',child:IntrinsicWidth(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
         if(row['reply_to']!=null&&rows.any((r)=>r['id'].toString()==row['reply_to'].toString()))
          Builder(builder:(ctx){final original=rows.firstWhere((r)=>r['id'].toString()==row['reply_to'].toString());return InkWell(onTap:()=>_jumpSelfMessage(original['id'].toString()),child:Container(margin:const EdgeInsets.only(bottom:7),padding:const EdgeInsets.all(7),decoration:BoxDecoration(color:skin.bg.withValues(alpha:.4),borderRadius:BorderRadius.circular(8)),child:Text((original['body']??original['file_name']??'').toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(color:skin.accent,fontSize:11))));}),
         if(type=='image'||type=='sticker')FutureBuilder<String>(future:_signedSelf(body),builder:(c,s)=>s.hasData?GestureDetector(onTap:()=>_openSelfImage(body),child:type=='sticker'?Image.network(s.data!,width:150,height:150,fit:BoxFit.contain,errorBuilder:(_,__,___)=>Icon(Icons.broken_image_outlined,color:skin.accent,size:38)):ClipRRect(borderRadius:BorderRadius.circular(13),child:Image.network(s.data!,width:225,height:220,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Icon(Icons.broken_image_outlined,color:skin.accent,size:38)))):SizedBox(width:180,height:130,child:Center(child:CircularProgressIndicator(color:skin.accent))))
         else if(type=='file'&&(row['mime_type']??'').toString().startsWith('video/'))FutureBuilder<String>(future:_signedSelf(body),builder:(c,s)=>s.hasData?GestureDetector(onTap:()=>launchUrl(Uri.parse(s.data!),mode:LaunchMode.externalApplication),child:ClipRRect(borderRadius:BorderRadius.circular(13),child:AspectRatio(aspectRatio:16/9,child:_LibraryVideoPreview(url:s.data!,accent:skin.accent)))):SizedBox(width:190,height:112,child:Center(child:CircularProgressIndicator(color:skin.accent))))
         else if(type=='file')InkWell(onTap:()=>_openSelfFile(body),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.insert_drive_file_outlined,color:skin.accent,size:30),const SizedBox(width:8),Flexible(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text((row['file_name']??body.split('/').last).toString(),maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white)),Text('${((row['file_size'] as num?)?.toInt()??0)/1024>1024?(((row['file_size'] as num?)?.toInt()??0)/1048576).toStringAsFixed(1)+' MB':(((row['file_size'] as num?)?.toInt()??0)/1024).toStringAsFixed(0)+' KB'} · ${(row['mime_type']??'').toString()}',style:TextStyle(color:skin.accent,fontSize:10))]))]))
         else if(type=='audio')_DirectAudioBubble(path:body,skin:skin,signed:_signedSelf,ar:ar)
         else Text(body,textAlign:TextAlign.center,style:const TextStyle(color:Colors.white,height:1.5)),
         if(row['pinned']==true)Padding(padding:const EdgeInsets.only(top:4),child:Icon(Icons.push_pin_rounded,color:skin.accent,size:12))
        ]))
       )),
       if(row['local_pending']==true)PositionedDirectional(start:-16,top:0,bottom:0,child:Center(child:SizedBox(width:11,height:11,child:CircularProgressIndicator(strokeWidth:1.6,color:skin.accent)))),
      ]))
      ]);
     })),
    SafeArea(
     top: false,
     child: Container(
      margin: const EdgeInsets.fromLTRB(10, 5, 10, 8),
      padding: const EdgeInsets.fromLTRB(9, 10, 9, 9),
      decoration: _oursGlassPanelDecoration(skin),
      child: recording
       ? Row(children: [
        IconButton(
         constraints: const BoxConstraints.tightFor(width: 42, height: 42),
         padding: EdgeInsets.zero,
         onPressed: sending ? null : () => _stopRecording(send: false),
         tooltip: t('إلغاء التسجيل', 'Cancel recording'),
         icon: Icon(Icons.close_rounded, color: skin.accent.withValues(alpha: .82), size: 21),
        ),
        Expanded(
         child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
           gradient: LinearGradient(begin: AlignmentDirectional.centerStart, end: AlignmentDirectional.centerEnd, colors: [skin.partner.withValues(alpha: .92), skin.partner.withValues(alpha: .58)]),
           borderRadius: BorderRadius.circular(20),
           border: Border.all(color: skin.accent.withValues(alpha: .22)),
          ),
          child: Row(children: [
           Icon(Icons.graphic_eq_rounded, color: skin.accent, size: 22),
           const SizedBox(width: 10),
           Expanded(child: Text(t('تسجيل صوتي', 'Recording audio'), style: TextStyle(color: skin.accent, fontSize: 12, fontWeight: FontWeight.w700))),
           Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(color: skin.bg.withValues(alpha: .48), borderRadius: BorderRadius.circular(12), border: Border.all(color: skin.accent.withValues(alpha: .16))),
            child: Text('${recordingElapsed.inMinutes.toString().padLeft(2, '0')}:${(recordingElapsed.inSeconds % 60).toString().padLeft(2, '0')}', style: TextStyle(color: skin.accent, fontSize: 15, fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()])),
           ),
          ]),
         ),
        ),
        IconButton(
         constraints: const BoxConstraints.tightFor(width: 42, height: 42),
         padding: EdgeInsets.zero,
         onPressed: sending ? null : () => _stopRecording(),
         tooltip: t('إيقاف وإرسال التسجيل', 'Stop and send recording'),
         icon: Icon(Icons.send_rounded, color: skin.accent),
        ),
       ])
       : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
         if (uploading)
          Padding(
           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
           child: LinearProgressIndicator(color: skin.accent, minHeight: 2),
          ),
         if (replyTo != null)
          Container(
           margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
           decoration: BoxDecoration(color: skin.partner, borderRadius: BorderRadius.circular(12)),
           child: Row(children: [
            Icon(Icons.reply, color: skin.accent, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text((replyTo!['body'] ?? replyTo!['file_name'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: skin.accent, fontSize: 12))),
            IconButton(onPressed: () => setState(() => replyTo = null), icon: const Icon(Icons.close, size: 17)),
           ]),
          ),
         Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
           IconButton(
            constraints: const BoxConstraints.tightFor(width: 42, height: 42),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.standard,
            onPressed: uploading || sending ? null : _showAttachments,
            tooltip: t('إرفاق صورة أو ملف أو ملصق', 'Attach photo, file or sticker'),
            icon: uploading ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: skin.accent)) : Icon(Icons.add_circle_outline_rounded, color: skin.accent, size: 22),
           ),
           Expanded(
            child: TextField(
             controller: input,
             minLines: 1,
             maxLines: 5,
             textInputAction: TextInputAction.send,
             textDirection: Directionality.of(context),
             style: const TextStyle(fontSize: 14, height: 1.25),
             textAlignVertical: TextAlignVertical.center,
             onSubmitted: (_) => _send(),
             decoration: InputDecoration(
              isDense: true,
              hintText: t('اكتب لنفسك…', 'Write a note…'),
              hintStyle: const TextStyle(fontSize: 13, height: 1.25),
              filled: true,
              fillColor: skin.partner.withValues(alpha: .94),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(21), borderSide: BorderSide(color: skin.accent.withValues(alpha: .10), width: .7)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(21), borderSide: BorderSide(color: skin.accent.withValues(alpha: .10), width: .7)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(21), borderSide: BorderSide(color: skin.accent.withValues(alpha: .48), width: 1.1)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
             ),
            ),
           ),
           IconButton(
            constraints: const BoxConstraints.tightFor(width: 42, height: 42),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.standard,
            onPressed: uploading || sending ? null : _startRecording,
            tooltip: t('تسجيل صوتي', 'Record audio'),
            icon: Icon(Icons.mic_none_rounded, color: skin.accent, size: 22),
           ),
           IconButton.filled(
            constraints: const BoxConstraints.tightFor(width: 42, height: 42),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.standard,
            onPressed: sending || uploading ? null : _send,
            style: IconButton.styleFrom(backgroundColor: skin.accent, foregroundColor: skin.bg),
            icon: sending ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded, size: 20),
           ),
          ],
         ),
        ],
       ),
     ),
    ),
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
   for(final stroke in all){if(stroke.points.length<2)continue;final path=Path()..moveTo(stroke.points.first.dx*sx,stroke.points.first.dy*sy);for(final p in stroke.points.skip(1))path..lineTo(p.dx*sx,p.dy*sy);canvas.drawPath(path,Paint()..color=stroke.color..strokeWidth=math.max(5.0,decoded.width/180.0)..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round..style=PaintingStyle.stroke);}
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
 @override void paint(Canvas canvas,Size size){for(final stroke in strokes){if(stroke.points.length<2)continue;final path=Path()..moveTo(stroke.points.first.dx*size.width,stroke.points.first.dy*size.height);for(final p in stroke.points.skip(1))path..lineTo(p.dx*size.width,p.dy*size.height);canvas.drawPath(path,Paint()..color=stroke.color..strokeWidth=4..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round..style=PaintingStyle.stroke);}}
 @override bool shouldRepaint(covariant _MarkupPainter old)=>old.strokes!=strokes;
}
class _ChatDetailsPage extends StatelessWidget{
 final String partnerId,partnerName;final _ChatSkin skin;final Widget Function() profile;final VoidCallback nickname,search,media,files;final Future<void> Function() themes,wallpaper;
 const _ChatDetailsPage({required this.partnerId,required this.partnerName,required this.skin,required this.profile,required this.nickname,required this.search,required this.media,required this.files,required this.themes,required this.wallpaper});
 @override Widget build(BuildContext context){final ar=Localizations.localeOf(context).languageCode=='ar';String t(String a,String e)=>ar?a:e;
 Widget section(String title)=>Padding(padding:const EdgeInsets.fromLTRB(5,20,5,9),child:Text(title,style:TextStyle(color:skin.accent,fontSize:12,fontWeight:FontWeight.w800,letterSpacing:.4)));
 Widget tile(IconData icon,String title,String subtitle,VoidCallback action)=>_ChatDetailTile(icon:icon,title:title,subtitle:subtitle,accent:skin.accent,onTap:action);
 return Scaffold(backgroundColor:skin.bg,appBar:AppBar(backgroundColor:Colors.transparent,flexibleSpace:DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[skin.partner.withValues(alpha:.48),skin.bg.withValues(alpha:.96)]))),title:Text(t('تفاصيل المحادثة','Chat details')),centerTitle:true),body:ListView(padding:const EdgeInsets.fromLTRB(16,12,16,28),children:[
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



class _PreviewStrokePainter extends CustomPainter{
 final List<List<Offset>> strokes;
 const _PreviewStrokePainter(this.strokes);
 @override void paint(Canvas canvas,Size size){
  for(final stroke in strokes){if(stroke.length<2)continue;final path=Path()..moveTo(stroke.first.dx*size.width,stroke.first.dy*size.height);for(final point in stroke.skip(1)){path.lineTo(point.dx*size.width,point.dy*size.height);}canvas.drawPath(path,Paint()..color=const Color(0xFFFFD66B)..strokeWidth=4..strokeCap=StrokeCap.round..style=PaintingStyle.stroke);}
 }
 @override bool shouldRepaint(covariant _PreviewStrokePainter old)=>old.strokes!=strokes;
}


class _LibraryVideoPreview extends StatefulWidget {
 final String url;final Color accent;
 const _LibraryVideoPreview({required this.url,required this.accent});
 @override State<_LibraryVideoPreview> createState()=>_LibraryVideoPreviewState();
}
class _LibraryVideoPreviewState extends State<_LibraryVideoPreview> {
 VideoPlayerController? controller;
 @override void initState(){super.initState();_initialize();}
 Future<void> _initialize()async{
  final player=VideoPlayerController.networkUrl(Uri.parse(widget.url));
  controller=player;
  try{await player.initialize();await player.pause();if(mounted)setState((){});}
  catch(_){await player.dispose();if(identical(controller,player))controller=null;if(mounted)setState((){});}
 }
 @override void dispose(){controller?.dispose();super.dispose();}
 @override Widget build(BuildContext context){
  final player=controller;
  if(player==null||!player.value.isInitialized)return Container(color:const Color(0xFF302A40),child:Center(child:Icon(Icons.movie_outlined,color:widget.accent,size:30)));
  return Stack(fit:StackFit.expand,children:[
   ClipRect(child:FittedBox(fit:BoxFit.cover,child:SizedBox(width:player.value.size.width,height:player.value.size.height,child:VideoPlayer(player)))),
   Center(child:Container(width:36,height:36,decoration:BoxDecoration(color:Colors.black.withValues(alpha:.48),shape:BoxShape.circle,border:Border.all(color:Colors.white.withValues(alpha:.7))),child:const Icon(Icons.play_arrow_rounded,color:Colors.white,size:25)))
  ]);
 }
}
