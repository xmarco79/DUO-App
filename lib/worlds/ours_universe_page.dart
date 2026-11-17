import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _bg = Color(0xFF0B0A16), _panel = Color(0xFF19152A), _panel2 = Color(0xFF28203D);
const _lilac = Color(0xFFC7B4E8), _gold = Color(0xFFE5C58C), _muted = Color(0xFF9288A9);

enum _Section { hub, store, collection }

class OursUniversePage extends StatefulWidget {
  const OursUniversePage({super.key, required this.spaceId, required this.onOpenClassic});
  final String? spaceId;
  final VoidCallback onOpenClassic;
  @override
  State<OursUniversePage> createState() => _OursUniversePageState();
}

class _OursUniversePageState extends State<OursUniversePage> {
  SupabaseClient get db => Supabase.instance.client;
  _Section section = _Section.hub;
  bool loading = false, busy = false;
  String? error;
  int coins = 100, xp = 0, level = 1;
  List<Map<String, dynamic>> catalog = [], inventory = [];
  bool get connected => widget.spaceId != null && db.auth.currentUser != null;
  bool get preview => !connected;
  bool get ar => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() { super.initState(); load(); }

  @override
  void didUpdateWidget(covariant OursUniversePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spaceId != widget.spaceId) load();
  }

  Future<void> load() async {
    if (!mounted) return;
    setState(() { loading = true; error = null; });
    try {
      final items = await db.from('ours_universe_catalog').select().eq('is_available', true).order('price');
      if (connected) {
        final wallet = await db.rpc('ours_universe_get_wallet', params: {'p_space_id': widget.spaceId});
        final rows = await db.from('ours_universe_inventory').select('item_code,quantity,acquired_at')
          .eq('space_id', widget.spaceId!).eq('user_id', db.auth.currentUser!.id)
          .order('acquired_at', ascending: false);
        final data = wallet is Map ? Map<String, dynamic>.from(wallet) : <String, dynamic>{};
        if (!mounted) return;
        setState(() {
          coins = (data['coins'] as num?)?.toInt() ?? 100;
          xp = (data['xp'] as num?)?.toInt() ?? 0;
          level = (data['level'] as num?)?.toInt() ?? 1;
          catalog = List<Map<String, dynamic>>.from(items);
          inventory = List<Map<String, dynamic>>.from(rows);
          loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          coins = 100; xp = 0; level = 1;
          catalog = List<Map<String, dynamic>>.from(items);
          inventory = []; loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { loading = false; error = 'تعذر تحميل العالم. قد تحتاج قاعدة البيانات إلى ترحيل OURS UNIVERSE.'; });
    }
  }

  void note(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value), backgroundColor: _panel2));
  }

  Future<void> claimDaily() async {
    if (!connected) { note('هذه معاينة فقط. اربط مساحة مشتركة لتفعيل المكافآت.'); return; }
    if (busy) return;
    setState(() => busy = true);
    try {
      final result = await db.rpc('ours_universe_claim_daily_reward', params: {'p_space_id': widget.spaceId});
      note(result is Map && result['claimed'] == true
        ? 'وصلتك 25 عملة و10 نقاط خبرة!' : 'استلمت مكافأة اليوم بالفعل. ارجع غدًا!');
      await load();
    } catch (_) { note('تعذر استلام المكافأة. حاول مرة أخرى.'); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> buy(Map<String, dynamic> item) async {
    if (!connected) { note('الشراء متاح بعد ربط المساحة المشتركة.'); return; }
    if (busy) return;
    setState(() => busy = true);
    try {
      await db.rpc('ours_universe_purchase_item', params: {
        'p_space_id': widget.spaceId, 'p_item_code': item['item_code']});
      note('تمت إضافة ' + label(item, 'title_ar', 'title_en') + ' إلى مقتنياتك.');
      await load();
    } catch (e) {
      final value = e.toString().toLowerCase();
      if (value.contains('not enough coins')) note('عملاتك لا تكفي لشراء هذا العنصر.');
      else if (value.contains('level requirement')) note('ارفع مستواك أولًا لفتح هذا العنصر.');
      else note('تعذر إتمام الشراء. حاول مرة أخرى.');
    } finally { if (mounted) setState(() => busy = false); }
  }

  String label(Map<String, dynamic> item, String arKey, String enKey) =>
    (item[ar ? arKey : enKey] ?? '').toString();
  String rarity(String value) => switch (value) {
    'rare' => ar ? 'نادر' : 'Rare',
    'epic' => ar ? 'ملحمي' : 'Epic',
    'legendary' => ar ? 'أسطوري' : 'Legendary',
    _ => ar ? 'شائع' : 'Common',
  };
  Color rarityColor(String value) => switch (value) {
    'rare' => const Color(0xFF78B7E8),
    'epic' => const Color(0xFFB994F2),
    'legendary' => _gold,
    _ => _lilac,
  };

  Widget coinBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
    decoration: BoxDecoration(color: _panel2, borderRadius: BorderRadius.circular(30),
      border: Border.all(color: _gold.withValues(alpha: .4))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Text('✦', style: TextStyle(color: _gold, fontSize: 18)),
      const SizedBox(width: 7),
      Text(coins.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      const SizedBox(width: 4),
      Text(ar ? 'عملة' : 'coins', style: const TextStyle(color: _muted, fontSize: 11)),
    ]),
  );

  Widget header() => Padding(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('OURS UNIVERSE', style: TextStyle(color: _gold, fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.w700)),
        const SizedBox(height: 5),
        Text(ar ? 'عالمكما يبدأ من هنا' : 'Your universe starts here',
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
      ])),
      coinBadge(),
    ]),
  );

  Widget sectionChip(_Section value, IconData icon, String title) {
    final active = section == value;
    return ChoiceChip(selected: active, onSelected: (_) => setState(() => section = value),
      avatar: Icon(icon, size: 17, color: active ? _bg : _lilac), label: Text(title),
      selectedColor: _gold, backgroundColor: _panel,
      side: BorderSide(color: active ? _gold : _lilac.withValues(alpha: .18)),
      labelStyle: TextStyle(color: active ? _bg : Colors.white, fontWeight: FontWeight.w600));
  }

  Widget hero() => Container(
    height: 205, margin: const EdgeInsets.fromLTRB(18, 4, 18, 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25),
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF49365F), Color(0xFF211A38), Color(0xFF11101F)]),
      border: Border.all(color: _lilac.withValues(alpha: .25)),
      boxShadow: [BoxShadow(color: const Color(0xFF8A67C2).withValues(alpha: .14), blurRadius: 25)]),
    child: Stack(children: [
      Positioned(right: -25, top: -45, child: Container(width: 175, height: 175,
        decoration: BoxDecoration(shape: BoxShape.circle, color: _lilac.withValues(alpha: .07)))),
      Positioned(right: 27, top: 25, child: Container(width: 125, height: 125,
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: const RadialGradient(colors: [Color(0xFFE5D5FF), Color(0xFF9270BD), Color(0xFF34274C)]),
          boxShadow: [BoxShadow(color: _lilac.withValues(alpha: .35), blurRadius: 25)]),
        child: const Center(child: Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFE9C1), size: 42)))),
      Positioned(right: 4, top: 60, child: Container(width: 170, height: 52,
        decoration: BoxDecoration(border: Border.all(color: _gold.withValues(alpha: .65)),
          borderRadius: BorderRadius.circular(100)))),
      Positioned(left: 18, top: 23, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: _gold.withValues(alpha: .15), borderRadius: BorderRadius.circular(20)),
          child: Text(preview ? 'وضع المعاينة' : 'العالم متصل',
            style: const TextStyle(color: _gold, fontSize: 10, fontWeight: FontWeight.w700))),
        const SizedBox(height: 12),
        Text(ar ? 'الساحة\nالمركزية' : 'THE\nHUB',
          style: const TextStyle(color: Colors.white, fontSize: 25, height: 1.05, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(ar ? 'نقطة انطلاق رحلتكما' : 'The start of your journey',
          style: const TextStyle(color: _lilac, fontSize: 11)),
      ])),
    ]),
  );

  Widget progressCard() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 18), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _lilac.withValues(alpha: .14))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(
          shape: BoxShape.circle, color: _gold.withValues(alpha: .13)),
          child: const Icon(Icons.stars_rounded, color: _gold)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(ar ? 'المستوى ' + level.toString() : 'Level ' + level.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          Text(ar ? xp.toString() + ' نقطة خبرة' : xp.toString() + ' XP',
            style: const TextStyle(color: _muted, fontSize: 12)),
        ])),
        Text(ar ? 'المستوى التالي' : 'Next level', style: const TextStyle(color: _lilac, fontSize: 11)),
      ]),
      const SizedBox(height: 13),
      ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(
        value: (xp % 100) / 100, minHeight: 7, backgroundColor: _bg, color: _gold)),
      const SizedBox(height: 7),
      Text(ar ? (100 - (xp % 100)).toString() + ' نقطة للمستوى التالي'
        : (100 - (xp % 100)).toString() + ' XP to next level',
        style: const TextStyle(color: _muted, fontSize: 11)),
    ]),
  );

  Widget portal(String title, String subtitle, IconData icon, {bool open = false}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: open ? const Color(0xFF2B2342) : _panel,
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: open ? _gold.withValues(alpha: .45) : _lilac.withValues(alpha: .13))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(
          color: open ? _gold.withValues(alpha: .16) : _bg, borderRadius: BorderRadius.circular(13)),
          child: Icon(icon, color: open ? _gold : _muted)),
        const Spacer(),
        Icon(open ? Icons.arrow_outward_rounded : Icons.lock_outline_rounded,
          color: open ? _gold : _muted, size: 17),
      ]),
      const SizedBox(height: 13),
      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 5),
      Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11, height: 1.35)),
      if (!open) ...[const SizedBox(height: 9), Text(ar ? 'قريبًا' : 'Coming soon',
        style: const TextStyle(color: _gold, fontSize: 10))],
    ]),
  );

  Widget hub() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    hero(), progressCard(),
    Padding(padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Row(children: [
        Expanded(child: Text(ar ? 'بوابات العوالم' : 'WORLD PORTALS',
          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700))),
        Text(ar ? '1 / 4 متاح' : '1 / 4 available', style: const TextStyle(color: _muted, fontSize: 11)),
      ])),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
      child: GridView.count(crossAxisCount: 2, shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10,
        mainAxisSpacing: 10, childAspectRatio: 1.12, children: [
          portal(ar ? 'الساحة المركزية' : 'Central Hub',
            ar ? 'المتجر والمقتنيات والتقدم' : 'Store, collection and progress',
            Icons.castle_rounded, open: true),
          portal(ar ? 'عالم السماء' : 'Sky Realm',
            ar ? 'جزر طائرة وأسرار سماوية' : 'Floating islands and sky secrets', Icons.cloud_rounded),
          portal(ar ? 'غابة الظلال' : 'Shadow Forest',
            ar ? 'ممرات وألغاز خفية' : 'Hidden paths and puzzles', Icons.forest_rounded),
          portal(ar ? 'أعماق البلور' : 'Crystal Depths',
            ar ? 'مدينة غارقة ومقتنيات نادرة' : 'A lost city and rare finds', Icons.water_rounded),
        ])),
    Container(margin: const EdgeInsets.fromLTRB(18, 16, 18, 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _panel2, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withValues(alpha: .18))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.card_giftcard_rounded, color: _gold), const SizedBox(width: 9),
          Expanded(child: Text(ar ? 'مكافأة الدخول اليومية' : 'DAILY ARRIVAL REWARD',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
          const Text('+25 ✦', style: TextStyle(color: _gold, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 7),
        Text(ar ? 'عملات ونقاط خبرة مرة كل يوم.' : 'Collect coins and XP once each day.',
          style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: busy ? null : claimDaily,
          style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _bg),
          icon: const Icon(Icons.redeem_rounded),
          label: Text(ar ? 'استلام المكافأة' : 'Claim reward'))),
      ])),
    Padding(padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
      child: OutlinedButton.icon(onPressed: widget.onOpenClassic,
        icon: const Icon(Icons.widgets_outlined),
        label: Text(ar ? 'فتح أنشطة العالم الحالية' : 'Open existing world activities'),
        style: OutlinedButton.styleFrom(foregroundColor: _lilac,
          side: BorderSide(color: _lilac.withValues(alpha: .25)),
          padding: const EdgeInsets.symmetric(vertical: 14)))),
  ]);

  Widget itemCard(Map<String, dynamic> item, {required bool owned}) {
    final code = item['item_code'];
    final r = (item['rarity'] ?? 'common').toString();
    final requiredLevel = (item['level_required'] as num?)?.toInt() ?? 1;
    final price = (item['price'] as num?)?.toInt() ?? 0;
    final quantity = inventory.where((v) => v['item_code'] == code)
      .fold<int>(0, (sum, v) => sum + ((v['quantity'] as num?)?.toInt() ?? 0));
    final color = rarityColor(r);
    return Container(padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .25))),
      child: Row(children: [
        Container(width: 54, height: 54, decoration: BoxDecoration(
          color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(15)),
          child: Center(child: Text((item['icon'] ?? '✦').toString(), style: const TextStyle(fontSize: 26)))),
        const SizedBox(width: 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label(item, 'title_ar', 'title_en'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(label(item, 'description_ar', 'description_en'),
            style: const TextStyle(color: _muted, fontSize: 10, height: 1.35)),
          const SizedBox(height: 5),
          Text(rarity(r), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          if (owned) Text(ar ? 'الكمية: ' + quantity.toString() : 'Owned: ' + quantity.toString(),
            style: const TextStyle(color: _lilac, fontSize: 10)),
        ])),
        const SizedBox(width: 7),
        if (owned) const Icon(Icons.check_circle_rounded, color: Colors.greenAccent)
        else Column(children: [
          Text(price.toString() + ' ✦', style: const TextStyle(color: _gold, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          SizedBox(height: 33, child: FilledButton(
            onPressed: (busy || preview || level < requiredLevel) ? null : () => buy(item),
            style: FilledButton.styleFrom(backgroundColor: _gold, foregroundColor: _bg,
              padding: const EdgeInsets.symmetric(horizontal: 9)),
            child: Text(level < requiredLevel ? 'Lv ' + requiredLevel.toString() : (ar ? 'شراء' : 'Buy'),
              style: const TextStyle(fontSize: 10)))),
        ]),
      ]),
    );
  }

  Widget store() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Padding(padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(ar ? 'متجر العوالم' : 'UNIVERSE STORE',
          style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(ar ? 'مقتنيات تجميلية بعملات اللعب فقط.' : 'Cosmetics purchased with in-game coins only.',
          style: const TextStyle(color: _muted, fontSize: 12)),
      ])),
    if (catalog.isEmpty) Padding(padding: const EdgeInsets.all(22),
      child: Text(ar ? 'سيظهر المتجر بعد تجهيز بيانات العالم.' : 'The store will appear when universe data is ready.',
        textAlign: TextAlign.center, style: const TextStyle(color: _muted)))
    else Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(children: catalog.map((v) => Padding(
        padding: const EdgeInsets.only(bottom: 10), child: itemCard(v, owned: false))).toList())),
  ]);

  Widget collection() {
    final owned = catalog.where((item) => inventory.any((v) => v['item_code'] == item['item_code'])).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
        child: Text(ar ? 'مقتنياتي' : 'MY COLLECTION',
          style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800))),
      if (owned.isEmpty) Container(margin: const EdgeInsets.symmetric(horizontal: 18), padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(18)),
        child: Column(children: [
          const Icon(Icons.inventory_2_outlined, color: _lilac, size: 38),
          const SizedBox(height: 10),
          Text(ar ? 'مجموعتك ما زالت تنتظرك' : 'Your collection is waiting',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          TextButton(onPressed: () => setState(() => section = _Section.store),
            child: Text(ar ? 'استكشف المتجر' : 'Explore store')),
        ]))
      else Padding(padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(children: owned.map((v) => Padding(
          padding: const EdgeInsets.only(bottom: 10), child: itemCard(v, owned: true))).toList())),
    ]);
  }

  @override
  Widget build(BuildContext context) => Container(color: _bg,
    child: SafeArea(top: true, bottom: false,
      child: RefreshIndicator(color: _gold, onRefresh: load,
        child: CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: [
          SliverToBoxAdapter(child: header()),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(18, 3, 18, 8),
            child: Wrap(spacing: 7, children: [
              sectionChip(_Section.hub, Icons.public_rounded, ar ? 'الساحة' : 'Hub'),
              sectionChip(_Section.store, Icons.storefront_rounded, ar ? 'المتجر' : 'Store'),
              sectionChip(_Section.collection, Icons.inventory_2_rounded, ar ? 'مقتنياتي' : 'Collection'),
            ]))),
          if (preview) SliverToBoxAdapter(child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 5), padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(13)),
            child: Row(children: [
              const Icon(Icons.visibility_outlined, color: _gold, size: 18), const SizedBox(width: 8),
              Expanded(child: Text(ar ? 'معاينة — اربط مساحة لتفعيل الحفظ والاقتصاد.'
                : 'Preview — connect a shared space to save progress and use the economy.',
                style: const TextStyle(color: _lilac, fontSize: 11))),
            ]))),
          if (error != null) SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(18),
            child: Text(error!, style: const TextStyle(color: Colors.orangeAccent)))),
          if (loading) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator(color: _gold)))),
          if (!loading && section == _Section.hub) SliverToBoxAdapter(child: hub()),
          if (!loading && section == _Section.store) SliverToBoxAdapter(child: store()),
          if (!loading && section == _Section.collection) SliverToBoxAdapter(child: collection()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ]))),
  );
}
