import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ours_tic_tac_toe_page.dart';

const _n = Color(0xFF10101C), _p = Color(0xFF29213D), _g = Color(0xFFD9BC86), _l = Color(0xFFB9A2D5);
String _t(BuildContext c, String a, String e) => Localizations.localeOf(c).languageCode == 'ar' ? a : e;

class OursMiniGamesPage extends StatelessWidget {
  final String? spaceId;
  const OursMiniGamesPage({super.key, this.spaceId});

  @override
  Widget build(BuildContext context) {
    final entries = [
      (Icons.grid_view_rounded, 'لعبة الذاكرة', 'Memory Match', 'اجمعا الأزواج وتنافسا على النقاط', 'Find pairs and compete', const _MemoryPage()),
      (Icons.bolt_rounded, 'اختبار المعلومات', 'Quick Quiz', 'عشرة أسئلة متنوعة وسريعة', 'Ten quick mixed questions', const _QuizPage()),
      (Icons.psychology_alt_rounded, 'خمن الكلمة', 'Word Riddle', 'اكتشف الكلمة من التلميح', 'Guess the word from a clue', const _WordPage()),
    ];
    return Scaffold(
      backgroundColor: _n,
      appBar: AppBar(title: Text(_t(context, 'ألعاب OURS', 'OURS ARCADE'))),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(colors: [Color(0xFF39304D), Color(0xFF1C1A2A), _n], begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: _g.withValues(alpha: .3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.sports_esports_rounded, color: _g, size: 36),
            const SizedBox(height: 12),
            Text(_t(context, 'وقت اللعب!', 'LET’S PLAY'), style: const TextStyle(color: _g, letterSpacing: 3, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_t(context, 'تحديات صغيرة، لحظات أكبر', 'Small games. Big moments.'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_t(context, 'اختارا لعبة وابدآ التحدي. الألعاب المصغرة تعمل على الجهاز نفسه ويمكنكما تمرير الجهاز بالتناوب.', 'Pick a game and challenge each other. Mini-games run on this device, so you can take turns passing it.'), style: const TextStyle(color: _l, height: 1.5)),
          ])),
        const SizedBox(height: 22),
        Text(_t(context, 'اختارا لعبتكما', 'CHOOSE A GAME'), style: const TextStyle(color: _g, letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _ArcadeCard(
          icon: e.$1, title: _t(context, e.$2, e.$3), desc: _t(context, e.$4, e.$5),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => e.$6))))),
        if (spaceId != null) _ArcadeCard(icon: Icons.grid_3x3_rounded, title: 'XO · Online',
          desc: _t(context, 'العبا مباشرة من جهازين عبر مساحتكما المشتركة.', 'Play live from two devices in your shared space.'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OursTicTacToePage(spaceId: spaceId!)))),
        const SizedBox(height: 14),
        Text(_t(context, 'الألعاب المصغرة محلية؛ نتائجها محفوظة على هذا الجهاز فقط ولا تُرسل للطرف الآخر.', 'Mini-game scores stay on this device and are not sent to your partner.'),
          textAlign: TextAlign.center, style: const TextStyle(color: _l, fontSize: 11, height: 1.5)),
      ]),
    );
  }
}

class _ArcadeCard extends StatelessWidget {
  final IconData icon; final String title, desc; final VoidCallback onTap;
  const _ArcadeCard({required this.icon, required this.title, required this.desc, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(color: _p, borderRadius: BorderRadius.circular(19),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(19), child: Padding(
      padding: const EdgeInsets.all(17), child: Row(children: [
        Container(width: 52, height: 52, decoration: BoxDecoration(color: _g.withValues(alpha: .13), borderRadius: BorderRadius.circular(15)),
          child: Icon(icon, color: _g, size: 28)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 5), Text(desc, style: const TextStyle(color: _l, fontSize: 12, height: 1.4)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, color: _l, size: 15),
      ]))));
}

class _Shell extends StatelessWidget {
  final String title, subtitle; final Widget child;
  const _Shell(this.title, this.subtitle, this.child);
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: _n, appBar: AppBar(title: Text(title)),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(18), children: [
      Text(subtitle, style: const TextStyle(color: _l, height: 1.5)),
      const SizedBox(height: 18), child,
    ])));
}

class _Score extends StatelessWidget {
  final String label; final int value; final Color color;
  const _Score(this.label, this.value, [this.color = _g]);
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(color: _p, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: .35))),
    child: Column(children: [Text(label, style: const TextStyle(color: _l, fontSize: 11)),
      const SizedBox(height: 3), Text(value.toString(), style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold))]));
}

class _MemoryPage extends StatefulWidget {
  const _MemoryPage();
  @override
  State<_MemoryPage> createState() => _MemoryState();
}
class _MemoryState extends State<_MemoryPage> {
  final _rng = Random();
  final _icons = const [Icons.star_rounded, Icons.favorite_rounded, Icons.coffee_rounded, Icons.music_note_rounded,
    Icons.pets_rounded, Icons.flight_rounded, Icons.bolt_rounded, Icons.spa_rounded];
  late List<int> _deck;
  final Set<int> _matched = {};
  final List<int> _open = [];
  final List<int> _score = [0, 0];
  int _turn = 0; bool _locked = false, _done = false;
  @override
  void initState() { super.initState(); _reset(); }
  void _reset() {
    _deck = List.generate(16, (i) => i ~/ 2)..shuffle(_rng);
    _matched.clear(); _open.clear(); _score[0] = 0; _score[1] = 0; _turn = 0; _locked = false; _done = false;
    if (mounted) setState(() {});
  }
  Future<void> _flip(int i) async {
    if (_locked || _done || _matched.contains(i) || _open.contains(i)) return;
    setState(() => _open.add(i));
    if (_open.length != 2) return;
    _locked = true;
    final a = _open[0], b = _open[1];
    if (_deck[a] == _deck[b]) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() { _matched.addAll([a,b]); _score[_turn]++; _open.clear(); _locked = false; _done = _matched.length == 16; });
      if (_done) _result();
    } else {
      await Future.delayed(const Duration(milliseconds: 850));
      if (!mounted) return;
      setState(() { _open.clear(); _turn = 1 - _turn; _locked = false; });
    }
  }
  void _result() {
    final winner = _score[0] == _score[1] ? _t(context,'تعادل رائع!','A perfect tie!')
      : _score[0] > _score[1] ? _t(context,'فاز اللاعب الأول!','Player 1 wins!') : _t(context,'فاز اللاعب الثاني!','Player 2 wins!');
    showDialog<void>(context: context, barrierDismissible: false, builder: (d) => AlertDialog(backgroundColor: _p,
      title: Text(winner, textAlign: TextAlign.center),
      content: Text(_t(context,'النتيجة: ','Score: ') + _score[0].toString() + ' - ' + _score[1].toString(),
        textAlign: TextAlign.center, style: const TextStyle(color: _l)),
      actions: [FilledButton(onPressed: () { Navigator.pop(d); _reset(); }, child: Text(_t(context,'العبا مجددًا','Play again')))]));
  }
  @override
  Widget build(BuildContext context) => _Shell(_t(context,'لعبة الذاكرة','Memory Match'),
    _t(context,'اكشفا البطاقات وابحثا عن الأزواج. عند الخطأ ينتقل الدور للطرف الآخر.','Reveal cards and find matching pairs. A miss passes the turn.'),
    Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _Score(_t(context,'اللاعب الأول','PLAYER 1'),_score[0],_turn == 0 ? _g : _l),
        _Score(_t(context,'اللاعب الثاني','PLAYER 2'),_score[1],_turn == 1 ? _g : _l)]),
      const SizedBox(height: 14),
      Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _p,borderRadius: BorderRadius.circular(14)),
        child: Text(_t(context,'دور اللاعب ','PLAYER ') + (_turn+1).toString(),textAlign: TextAlign.center,style: const TextStyle(color:_g,fontWeight:FontWeight.bold))),
      const SizedBox(height: 14),
      GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),itemCount:16,
        gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:4,crossAxisSpacing:9,mainAxisSpacing:9),
        itemBuilder:(c,i){final visible=_matched.contains(i)||_open.contains(i);return InkWell(onTap:()=>_flip(i),borderRadius:BorderRadius.circular(14),
          child: AnimatedContainer(duration:const Duration(milliseconds:180),decoration:BoxDecoration(color:visible?_g.withValues(alpha:.16):_p,borderRadius:BorderRadius.circular(14),border:Border.all(color:visible?_g:_l.withValues(alpha:.2))),
            child:Center(child:visible?Icon(_icons[_deck[i]],color:_g,size:29):const Icon(Icons.question_mark_rounded,color:_l))));}),
      const SizedBox(height:18),
      OutlinedButton.icon(onPressed:_reset,icon:const Icon(Icons.refresh_rounded),label:Text(_t(context,'إعادة اللعبة','Restart game'))),
    ]));
}

class _Q {
  final String ar,en; final List<String> a,b; final int correct;
  const _Q(this.ar,this.en,this.a,this.b,this.correct);
}
const _questions = <_Q>[
  _Q('كم عدد أضلاع الشكل السداسي؟','How many sides does a hexagon have?',['5','6','7','8'],['5','6','7','8'],1),
  _Q('ما الكوكب المعروف بالكوكب الأحمر؟','Which planet is known as the Red Planet?',['الزهرة','المريخ','زحل','عطارد'],['Venus','Mars','Saturn','Mercury'],1),
  _Q('ما ناتج 9 × 7؟','What is 9 × 7?',['56','63','72','69'],['56','63','72','69'],1),
  _Q('ما أكبر محيط على الأرض؟','What is the largest ocean on Earth?',['الأطلسي','الهندي','الهادئ','المتجمد'],['Atlantic','Indian','Pacific','Arctic'],2),
  _Q('كم دقيقة في ساعتين؟','How many minutes are in two hours?',['90','100','120','140'],['90','100','120','140'],2),
  _Q('ما العضو المسؤول عن ضخ الدم؟','Which organ pumps blood?',['الرئة','الكبد','القلب','الكلى'],['Lungs','Liver','Heart','Kidneys'],2),
  _Q('كم ضلعًا للمثلث؟','How many sides does a triangle have?',['2','3','4','5'],['2','3','4','5'],1),
  _Q('ما أقرب نجم إلى الأرض؟','What is the closest star to Earth?',['الشمس','الشعرى','النسر الواقع','سهيل'],['The Sun','Sirius','Vega','Canopus'],0),
  _Q('أي حيوان يُعرف بسفينة الصحراء؟','Which animal is called the ship of the desert?',['الحصان','الجمل','الغزال','الفيل'],['Horse','Camel','Gazelle','Elephant'],1),
  _Q('ما اللغة القديمة المرتبطة بروما؟','Which ancient language is associated with Rome?',['اليونانية','اللاتينية','العربية','الفارسية'],['Greek','Latin','Arabic','Persian'],1),
];

class _QuizPage extends StatefulWidget { const _QuizPage(); @override State<_QuizPage> createState()=>_QuizState(); }
class _QuizState extends State<_QuizPage> {
  late List<_Q> _round; int _i=0,_score=0,_selected=-1; bool _done=false;
  @override void initState(){super.initState();_round=[..._questions]..shuffle();}
  Future<void> _answer(int v) async {
    if(_selected!=-1||_done)return;
    setState(() { _selected = v; if (v == _round[_i].correct) _score++; });
    await Future.delayed(const Duration(milliseconds:800)); if(!mounted)return;
    if(_i==_round.length-1){setState(()=>_done=true);_saveBest();}
    else setState(() { _i++; _selected = -1; });
  }
  Future<void> _saveBest() async {try{final p=await SharedPreferences.getInstance();final old=p.getInt('ours_quiz_best')??0;if(_score>old)await p.setInt('ours_quiz_best',_score);}catch(_){}}
  void _restart() => setState(() { _round = [..._questions]..shuffle(); _i = 0; _score = 0; _selected = -1; _done = false; });
  @override Widget build(BuildContext context)=>_Shell(_t(context,'اختبار المعلومات','Quick Quiz'),
    _t(context,'عشرة أسئلة متنوعة. اختر الإجابة الصحيحة وانتقل للسؤال التالي.','Ten mixed questions. Choose the correct answer to continue.'),
    FutureBuilder<int>(future:SharedPreferences.getInstance().then((p)=>p.getInt('ours_quiz_best')??0),builder:(c,b)=>Column(children:[
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[_Score(_t(context,'نتيجتك','SCORE'),_score),_Score(_t(context,'أفضل نتيجة','BEST'),b.data??0,_l)]),
      const SizedBox(height:18),
      if(_done)...[
        const Icon(Icons.emoji_events_rounded,color:_g,size:70),const SizedBox(height:12),
        Text(_t(context,'أحسنت! نتيجتك ','Well done! You scored ')+_score.toString()+'/10',textAlign:TextAlign.center,style:const TextStyle(color:_g,fontSize:22,fontWeight:FontWeight.bold)),
        const SizedBox(height:16),FilledButton.icon(onPressed:_restart,icon:const Icon(Icons.replay),label:Text(_t(context,'العب مرة أخرى','Play again'))),
      ]else...[
        LinearProgressIndicator(value:(_i+1)/_round.length,minHeight:7,backgroundColor:_p,borderRadius:BorderRadius.circular(8)),
        const SizedBox(height:16),
        Text(_t(context,'السؤال ','QUESTION ')+(_i+1).toString()+' / 10',style:const TextStyle(color:_l)),
        const SizedBox(height:12),
        Container(width:double.infinity,padding:const EdgeInsets.all(20),decoration:BoxDecoration(color:_p,borderRadius:BorderRadius.circular(18)),
          child:Text(_t(context,_round[_i].ar,_round[_i].en),textAlign:TextAlign.center,style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold,height:1.4))),
        const SizedBox(height:16),
        ...List.generate(4,(v){final correct=_round[_i].correct==v;final chosen=_selected==v;final col=_selected==-1?_l.withValues(alpha:.2):correct?const Color(0xFF75B99B):chosen?const Color(0xFFE47D83):_l.withValues(alpha:.12);
          return Padding(padding:const EdgeInsets.only(bottom:9),child:SizedBox(width:double.infinity,child:OutlinedButton(
            onPressed:_selected==-1?()=>_answer(v):null,style:OutlinedButton.styleFrom(backgroundColor:col.withValues(alpha:.12),side:BorderSide(color:col),padding:const EdgeInsets.symmetric(vertical:15)),
            child:Text(_t(context,_round[_i].a[v],_round[_i].b[v]),style:TextStyle(color:_selected!=-1&&correct?const Color(0xFF75B99B):Colors.white)))));}),
      ],
    ])));
}

class _Word {
  final String clueAr,clueEn; final List<String> choicesAr,choicesEn; final int answer;
  const _Word(this.clueAr,this.clueEn,this.choicesAr,this.choicesEn,this.answer);
}
const _words = <_Word>[
  _Word('يظهر مضيئًا في السماء ليلًا','It lights up the night sky',['شمس','قمر','نجم','سحاب'],['Sun','Moon','Star','Cloud'],1),
  _Word('نستخدمه لفتح الأقفال','Used to open locks',['باب','مفتاح','مصباح','كتاب'],['Door','Key','Lamp','Book'],1),
  _Word('مساحة واسعة من الماء المالح','A large body of salt water',['نهر','بحر','جبل','صحراء'],['River','Sea','Mountain','Desert'],1),
  _Word('تخبرنا بالوقت','It tells us the time',['ساعة','مرآة','نافذة','حقيبة'],['Clock','Mirror','Window','Bag'],0),
  _Word('نقرأ صفحاته لنتعلم','We read its pages to learn',['قلم','كرسي','كتاب','هاتف'],['Pen','Chair','Book','Phone'],2),
  _Word('لها جذع وأغصان وأوراق','It has a trunk, branches and leaves',['زهرة','شجرة','حجر','غيمة'],['Flower','Tree','Stone','Cloud'],1),
  _Word('تسافر في السماء','It travels through the sky',['سفينة','قطار','طائرة','دراجة'],['Ship','Train','Airplane','Bicycle'],2),
  _Word('ماء متجمد وبارد','Frozen water',['رمل','مطر','ثلج','دخان'],['Sand','Rain','Ice','Smoke'],2),
];
class _WordPage extends StatefulWidget{const _WordPage();@override State<_WordPage> createState()=>_WordState();}
class _WordState extends State<_WordPage>{
  late List<_Word> _round;int _i=0,_score=0,_selected=-1;bool _done=false;
  @override void initState(){super.initState();_round=[..._words]..shuffle();}
  Future<void> _choose(int v) async { if (_selected != -1 || _done) return; setState(() { _selected = v; if (v == _round[_i].answer) _score++; }); await Future.delayed(const Duration(milliseconds: 850)); if (!mounted) return; if (_i == _round.length - 1) setState(() => _done = true); else setState(() { _i++; _selected = -1; }); }
  void _restart() => setState(() { _round = [..._words]..shuffle(); _i = 0; _score = 0; _selected = -1; _done = false; });
  @override Widget build(BuildContext context)=>_Shell(_t(context,'خمن الكلمة','Word Riddle'),_t(context,'اقرأ التلميح واختر الكلمة المناسبة. لديك ثماني جولات.','Read the clue and choose the matching word. Eight rounds.'),
    Column(children:[
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[_Score(_t(context,'النقاط','POINTS'),_score),_Score(_t(context,'الجولة','ROUND'),_done?8:_i+1,_l)]),
      const SizedBox(height:18),
      if(_done)...[
        const Icon(Icons.lightbulb_rounded,color:_g,size:70),const SizedBox(height:12),
        Text(_t(context,'أصبت ','You got ')+_score.toString()+'/8',style:const TextStyle(color:_g,fontSize:22,fontWeight:FontWeight.bold)),
        const SizedBox(height:16),FilledButton.icon(onPressed:_restart,icon:const Icon(Icons.replay),label:Text(_t(context,'جولة جديدة','New round'))),
      ]else...[
        LinearProgressIndicator(value:(_i+1)/8,minHeight:7,backgroundColor:_p,borderRadius:BorderRadius.circular(8)),
        const SizedBox(height:20),
        Container(width:double.infinity,padding:const EdgeInsets.all(24),decoration:BoxDecoration(color:_p,borderRadius:BorderRadius.circular(20),border:Border.all(color:_g.withValues(alpha:.2))),
          child:Column(children:[const Icon(Icons.lightbulb_outline_rounded,color:_g,size:38),const SizedBox(height:12),
            Text(_t(context,_round[_i].clueAr,_round[_i].clueEn),textAlign:TextAlign.center,style:const TextStyle(fontSize:18,height:1.5))])),
        const SizedBox(height:18),
        ...List.generate(4,(v){final correct=v==_round[_i].answer;final col=_selected==-1?_l.withValues(alpha:.25):correct?const Color(0xFF75B99B):v==_selected?const Color(0xFFE47D83):_l.withValues(alpha:.15);
          return Padding(padding:const EdgeInsets.only(bottom:9),child:SizedBox(width:double.infinity,child:OutlinedButton(
            onPressed:_selected==-1?()=>_choose(v):null,style:OutlinedButton.styleFrom(backgroundColor:_selected!=-1&&correct?const Color(0xFF75B99B).withValues(alpha:.12):_p,side:BorderSide(color:col),padding:const EdgeInsets.symmetric(vertical:15)),
            child:Text(_t(context,_round[_i].choicesAr[v],_round[_i].choicesEn[v]),style:const TextStyle(color:Colors.white,fontSize:16)))));}),
      ],
    ]));
}
