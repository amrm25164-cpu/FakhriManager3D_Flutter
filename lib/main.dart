import 'dart:async';
import 'package:flutter/material.dart';
import 'game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

String t(String ar, String en) => G.arabic ? ar : en;
String money(int k) => '${(k / 1000).toStringAsFixed(1)}M';
const _green = Color(0xFF2ECC71);

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: G,
      builder: (context, _) => MaterialApp(
        title: 'Fakhri Manager 3D',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: _green, scaffoldBackgroundColor: const Color(0xFF0B1F15)),
        builder: (c, child) => Directionality(textDirection: G.arabic ? TextDirection.rtl : TextDirection.ltr, child: child!),
        home: const StartPage(),
      ),
    );
  }
}

Widget bigBtn(String text, VoidCallback f, {IconData? icon}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
          onPressed: f,
          icon: Icon(icon ?? Icons.sports_soccer),
          label: Text(text, style: const TextStyle(fontSize: 17)),
        ),
      ),
    );

Widget card(Widget child) => Card(margin: const EdgeInsets.symmetric(vertical: 5), child: Padding(padding: const EdgeInsets.all(12), child: child));
void snack(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));
String resMsg(String k) => {
      'ok': t('تمت الصفقة!', 'Deal done!'),
      'rejected': t('رفض النادي العرض', 'Offer rejected'),
      'no_funds': t('الميزانية لا تكفي', 'Not enough budget'),
      'squad_full': t('الفريق ممتلئ (26)', 'Squad full (26)'),
      'squad_min': t('لا يمكن البيع: الحد الأدنى 16 لاعبًا', 'Cannot sell: minimum 16 players'),
      'sold': t('تم البيع', 'Sold'),
      'gone': t('اللاعب غير متاح', 'Player unavailable'),
    }[k] ?? k;

// ---------------- البداية ----------------
class StartPage extends StatelessWidget {
  const StartPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.sports_soccer, size: 90, color: _green),
            const SizedBox(height: 12),
            const Text('Fakhri Manager 3D', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            Text(t('لعبة محاكاة مهنة مدرب كرة القدم', 'Football manager career simulator')),
            const SizedBox(height: 32),
            bigBtn(t('مسيرة جديدة', 'New Career'), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewCareerPage())), icon: Icons.add),
            FutureBuilder<bool>(
              future: G.hasSave(),
              builder: (c, s) => s.data == true
                  ? bigBtn(t('متابعة المسيرة المحفوظة', 'Continue saved career'), () async {
                      final ok = await G.load();
                      if (!c.mounted) return;
                      if (ok) {
                        Navigator.push(c, MaterialPageRoute(builder: (_) => const Shell()));
                      } else {
                        snack(c, t('لا يوجد حفظ صالح', 'No valid save found'));
                      }
                    }, icon: Icons.play_arrow)
                  : const SizedBox.shrink(),
            ),
            bigBtn(G.arabic ? 'English' : 'العربية', G.toggleLang, icon: Icons.language),
          ]),
        ),
      ),
    );
  }
}

class NewCareerPage extends StatefulWidget {
  const NewCareerPage({super.key});
  @override
  State<NewCareerPage> createState() => _NewCareerState();
}

class _NewCareerState extends State<NewCareerPage> {
  final ctrl = TextEditingController();
  int sel = 0;
  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('مسيرة جديدة', 'New Career'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: ctrl, decoration: InputDecoration(labelText: t('اسم المدرب', 'Coach name'), border: const OutlineInputBorder())),
        const SizedBox(height: 16),
        Text(t('اختر النادي', 'Choose your club'), style: const TextStyle(fontSize: 18)),
        for (var i = 0; i < 8; i++)
          RadioListTile<int>(value: i, groupValue: sel, onChanged: (v) => setState(() => sel = v!), title: Text(G.clubName(i))),
        const SizedBox(height: 8),
        bigBtn(t('ابدأ المسيرة', 'Start career'), () {
          G.newCareer(ctrl.text.trim(), sel);
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const Shell()), (r) => r.isFirst);
        }),
      ]),
    );
  }
}

// ---------------- الهيكل ----------------
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int idx = 0;
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: G,
      builder: (context, _) {
        final pages = [const DashPage(), const SquadPage(), const MatchPage(), const TablePage(), const MarketPage()];
        return Scaffold(
          appBar: AppBar(title: Text(G.clubName(G.club))),
          body: pages[idx],
          bottomNavigationBar: NavigationBar(
            selectedIndex: idx,
            onDestinationSelected: (i) => setState(() => idx = i),
            destinations: [
              NavigationDestination(icon: const Icon(Icons.home), label: t('الرئيسية', 'Home')),
              NavigationDestination(icon: const Icon(Icons.groups), label: t('الفريق', 'Squad')),
              NavigationDestination(icon: const Icon(Icons.sports_soccer), label: t('المباراة', 'Match')),
              NavigationDestination(icon: const Icon(Icons.leaderboard), label: t('الدوري', 'League')),
              NavigationDestination(icon: const Icon(Icons.swap_horiz), label: t('الانتقالات', 'Transfers')),
            ],
          ),
        );
      },
    );
  }
}

class DashPage extends StatelessWidget {
  const DashPage({super.key});
  @override
  Widget build(BuildContext context) {
    final m = G.nextFixture();
    return ListView(padding: const EdgeInsets.all(16), children: [
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${t('المدرب', 'Coach')}: ${G.coach}', style: const TextStyle(fontSize: 18)),
        Text('${t('الموسم', 'Season')} ${G.season}  •  ${t('الجولة', 'Round')} ${G.week + 1}/${G.fixtures.length}'),
        Text('${t('الميزانية', 'Budget')}: ${money(G.clubs[G.club].budget)}'),
        Text('${t('الترتيب', 'Rank')}: ${G.rankOf(G.club)}'),
      ])),
      card(Column(children: [
        Text(t('المباراة القادمة', 'Next match')),
        const SizedBox(height: 6),
        Text('${G.clubName(m[0])}  ×  ${G.clubName(m[1])}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ])),
      bigBtn('${t('البريد والعروض', 'Mail & offers')} (${G.offers.length})', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MailPage())), icon: Icons.mail),
      bigBtn(t('سجل المدرب', 'Coach record'), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage())), icon: Icons.emoji_events),
      bigBtn(t('الإعدادات والحفظ', 'Settings & save'), () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())), icon: Icons.settings),
    ]);
  }
}

// ---------------- الفريق ----------------
class SquadPage extends StatelessWidget {
  const SquadPage({super.key});
  @override
  Widget build(BuildContext context) {
    final list = G.squad(G.club)..sort((a, b) => a.pos != b.pos ? a.pos.compareTo(b.pos) : b.ovr.compareTo(a.ovr));
    final xi = G.lineup(G.club).map((p) => p.id).toSet();
    return ListView(padding: const EdgeInsets.all(12), children: [
      Row(children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: G.formation,
            decoration: InputDecoration(labelText: t('التشكيلة', 'Formation'), border: const OutlineInputBorder()),
            items: forms.keys.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
            onChanged: (v) => G.setFormation(v!),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: G.tactic,
            decoration: InputDecoration(labelText: t('التكتيك', 'Tactic'), border: const OutlineInputBorder()),
            items: tactics.map((k) => DropdownMenuItem(value: k, child: Text(G.tacticName(k)))).toList(),
            onChanged: (v) => G.setTactic(v!),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      Text(t('الأساسيون مظللون. افتح اللاعب لجعله احتياطيًا.', 'Starters are highlighted. Open a player to bench him.'), style: const TextStyle(fontSize: 12)),
      for (final p in list)
        Card(
          color: xi.contains(p.id) ? const Color(0xFF1B4D32) : null,
          child: ListTile(
            title: Text(G.pname(p)),
            subtitle: Text('${G.posName(p.pos)} • ${t('العمر', 'Age')} ${p.age} • ${t('لياقة', 'Fit')} ${p.fit}%${p.inj > 0 ? ' • 🚑 ${p.inj}' : ''}${G.benched.contains(p.id) ? ' • ${t('احتياطي', 'Bench')}' : ''}'),
            trailing: Text('${p.ovr}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _green)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerPage(p.id))),
          ),
        ),
    ]);
  }
}

class PlayerPage extends StatelessWidget {
  final int pid;
  const PlayerPage(this.pid, {super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: G,
      builder: (context, _) {
        final p = G.find(pid);
        if (p == null) return Scaffold(appBar: AppBar(), body: Center(child: Text(resMsg('gone'))));
        final mine = p.club == G.club;
        return Scaffold(
          appBar: AppBar(title: Text(G.pname(p))),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${G.posName(p.pos)} • ${G.clubName(p.club)}', style: const TextStyle(fontSize: 18)),
              Text('${t('العمر', 'Age')}: ${p.age}   ${t('التقييم', 'OVR')}: ${p.ovr}   ${t('الإمكانات', 'POT')}: ${p.pot}'),
              Text('${t('القيمة', 'Value')}: ${money(p.value)}   ${t('الراتب/أسبوع', 'Wage/wk')}: ${p.wage}k'),
              Text('${t('العقد (سنوات)', 'Contract (yrs)')}: ${p.contract}   ${t('لياقة', 'Fitness')}: ${p.fit}%'),
              Text('${t('أهداف', 'Goals')}: ${p.goals}   ${t('مشاركات', 'Apps')}: ${p.apps}'),
              if (p.inj > 0) Text('🚑 ${t('مصاب', 'Injured')}: ${p.inj} ${t('أسابيع', 'weeks')}', style: const TextStyle(color: Colors.redAccent)),
            ])),
            if (mine) ...[
              bigBtn(G.benched.contains(p.id) ? t('أعده للتشكيلة الأساسية', 'Return to starting pool') : t('اجعله احتياطيًا', 'Bench player'), () => G.toggleBench(p.id), icon: Icons.chair),
              bigBtn(t('بيع اللاعب', 'Sell player'), () {
                final r = G.sell(p.id);
                snack(context, resMsg(r));
                if (r == 'sold') Navigator.pop(context);
              }, icon: Icons.sell),
            ] else
              for (final pct in [90, 100, 115])
                bigBtn('${t('عرض', 'Offer')} $pct% (${money((p.value * pct / 100).toInt())})', () {
                  final r = G.buy(p.id, pct);
                  snack(context, resMsg(r));
                }, icon: Icons.shopping_cart),
          ]),
        );
      },
    );
  }
}

// ---------------- المباراة ----------------
class MatchPage extends StatefulWidget {
  const MatchPage({super.key});
  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  bool highlights = false;
  @override
  Widget build(BuildContext context) {
    final m = G.nextFixture();
    final r = G.last;
    return ListView(padding: const EdgeInsets.all(16), children: [
      card(Column(children: [
        Text('${t('الجولة', 'Round')} ${G.week + 1}'),
        Text('${G.clubName(m[0])}  ×  ${G.clubName(m[1])}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ])),
      bigBtn(t('شاهد المباراة', 'Watch match'), () {
        G.playRound();
        final res = G.last;
        if (res != null) Navigator.push(context, MaterialPageRoute(builder: (_) => MatchViewer(res)));
      }, icon: Icons.visibility),
      bigBtn(t('محاكاة سريعة', 'Quick sim'), () {
        setState(() => highlights = false);
        G.playRound();
      }, icon: Icons.fast_forward),
      bigBtn(t('أبرز الأحداث', 'Highlights'), () {
        setState(() => highlights = true);
        G.playRound();
      }, icon: Icons.star),
      if (r != null) ResultCard(r, highlights: highlights),
    ]);
  }
}

class ResultCard extends StatelessWidget {
  final MatchResult r;
  final bool highlights;
  const ResultCard(this.r, {super.key, this.highlights = false});
  @override
  Widget build(BuildContext context) {
    Widget row(String k, String ar, String en) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('${r.st[k]![0].round()}'), Text(t(ar, en)), Text('${r.st[k]![1].round()}')]),
        );
    final evs = r.ev.where((e) => !highlights || e.t == 'goal');
    return Column(children: [
      card(Column(children: [
        Text('${G.clubName(r.h)}  ${r.gh} - ${r.ga}  ${G.clubName(r.a)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _green), textAlign: TextAlign.center),
        const Divider(),
        row('poss', 'الاستحواذ %', 'Possession %'),
        row('shots', 'التسديدات', 'Shots'),
        row('sot', 'على المرمى', 'On target'),
        row('corners', 'ركنيات', 'Corners'),
        row('fouls', 'أخطاء', 'Fouls'),
        row('passes', 'تمريرات', 'Passes'),
      ])),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t('أحداث المباراة', 'Match events'), style: const TextStyle(fontWeight: FontWeight.bold)),
        for (final e in evs) Text("${e.m}'  ${e.txt}"),
      ])),
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t('نتائج الجولة', 'Round results'), style: const TextStyle(fontWeight: FontWeight.bold)),
        for (final x in G.roundResults) Text('${G.clubName(x.h)} ${x.gh}-${x.ga} ${G.clubName(x.a)}'),
      ])),
    ]);
  }
}

// ---------------- مشاهدة المباراة (ملعب 2D) ----------------
class MatchViewer extends StatefulWidget {
  final MatchResult r;
  const MatchViewer(this.r, {super.key});
  @override
  State<MatchViewer> createState() => _MatchViewerState();
}

class _MatchViewerState extends State<MatchViewer> {
  int minute = 0, gh = 0, ga = 0, speed = 120;
  Offset ball = const Offset(0.5, 0.5);
  String flash = '';
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    timer?.cancel();
    timer = Timer.periodic(Duration(milliseconds: speed), (_) => _tick());
  }

  void _tick() {
    if (minute >= 90) {
      timer?.cancel();
      return;
    }
    setState(() {
      minute++;
      final side = (minute * 7919 % 100) < widget.r.st['poss']![0] ? 0 : 1;
      final dir = side == 0 ? 1.0 : -1.0;
      final j = (minute * 37 % 10) / 10.0 - 0.5;
      final nx = (ball.dx + dir * (0.04 + (minute * 13 % 5) * 0.01) + j * 0.1).clamp(0.05, 0.95).toDouble();
      final ny = (ball.dy + ((minute * 17 % 10) / 10.0 - 0.5) * 0.3).clamp(0.1, 0.9).toDouble();
      ball = Offset(nx, ny);
      for (final e in widget.r.ev.where((e) => e.m == minute)) {
        if (e.t == 'goal') {
          if (e.s == 0) {
            gh++;
          } else {
            ga++;
          }
          ball = Offset(e.s == 0 ? 0.97 : 0.03, 0.5);
          flash = e.txt;
        }
      }
    });
  }

  void _skip() {
    timer?.cancel();
    setState(() {
      minute = 90;
      gh = widget.r.gh;
      ga = widget.r.ga;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    final shown = r.ev.where((e) => e.m <= minute).toList().reversed.toList();
    return Scaffold(
      appBar: AppBar(title: Text("$minute'")),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text('${G.clubName(r.h)}  $gh - $ga  ${G.clubName(r.a)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        AspectRatio(
          aspectRatio: 1.6,
          child: CustomPaint(
            painter: PitchPainter(ball, forms[G.formation]!, forms['4-4-2']!, minute),
            size: Size.infinite,
          ),
        ),
        if (flash.isNotEmpty) Padding(padding: const EdgeInsets.all(4), child: Text(flash, style: const TextStyle(color: Colors.amber))),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextButton(
              onPressed: () {
                speed = speed == 120 ? 40 : 120;
                _start();
              },
              child: Text(t('تغيير السرعة', 'Speed'))),
          TextButton(onPressed: _skip, child: Text(t('تخطي للنهاية', 'Skip to end'))),
        ]),
        Expanded(
          child: ListView(children: [for (final e in shown) ListTile(dense: true, title: Text("${e.m}'  ${e.txt}"))]),
        ),
      ]),
    );
  }
}

class PitchPainter extends CustomPainter {
  final Offset ball;
  final List<int> home, away;
  final int tick;
  PitchPainter(this.ball, this.home, this.away, this.tick);

  void _team(Canvas canvas, Size s, List<int> f, bool isHome, Color col) {
    final paint = Paint()..color = col;
    for (var line = 0; line < 4; line++) {
      final n = f[line];
      final base = [0.06, 0.2, 0.34, 0.46][line];
      for (var i = 0; i < n; i++) {
        final wob = ((tick + i * 3 + line) % 6 - 3) * 0.003;
        final x = isHome ? base : 1 - base;
        final y = (i + 1) / (n + 1);
        canvas.drawCircle(Offset((x + wob) * s.width, y * s.height), 7, paint);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF1E7B3A));
    final line = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(6, 6, s.width - 12, s.height - 12), line);
    canvas.drawLine(Offset(s.width / 2, 6), Offset(s.width / 2, s.height - 6), line);
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), s.height * 0.15, line);
    canvas.drawRect(Rect.fromLTWH(6, s.height * 0.28, s.width * 0.12, s.height * 0.44), line);
    canvas.drawRect(Rect.fromLTWH(s.width - 6 - s.width * 0.12, s.height * 0.28, s.width * 0.12, s.height * 0.44), line);
    _team(canvas, s, home, true, Colors.blueAccent);
    _team(canvas, s, away, false, Colors.redAccent);
    canvas.drawCircle(Offset(ball.dx * s.width, ball.dy * s.height), 6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(PitchPainter o) => o.ball != ball || o.tick != tick;
}

// ---------------- الدوري ----------------
class TablePage extends StatelessWidget {
  const TablePage({super.key});
  @override
  Widget build(BuildContext context) {
    final tbl = G.sortedTable();
    final sc = [...G.players]..sort((a, b) => b.goals.compareTo(a.goals));
    return ListView(padding: const EdgeInsets.all(12), children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 14,
          columns: [
            const DataColumn(label: Text('#')),
            DataColumn(label: Text(t('النادي', 'Club'))),
            DataColumn(label: Text(t('لعب', 'P'))),
            DataColumn(label: Text(t('فاز', 'W'))),
            DataColumn(label: Text(t('تعادل', 'D'))),
            DataColumn(label: Text(t('خسر', 'L'))),
            DataColumn(label: Text(t('فارق', 'GD'))),
            DataColumn(label: Text(t('نقاط', 'Pts'))),
          ],
          rows: [
            for (var i = 0; i < tbl.length; i++)
              DataRow(color: tbl[i] == G.club ? WidgetStateProperty.all(const Color(0xFF1B4D32)) : null, cells: [
                DataCell(Text('${i + 1}')),
                DataCell(Text(G.clubName(tbl[i]))),
                DataCell(Text('${G.clubs[tbl[i]].pl}')),
                DataCell(Text('${G.clubs[tbl[i]].w}')),
                DataCell(Text('${G.clubs[tbl[i]].d}')),
                DataCell(Text('${G.clubs[tbl[i]].l}')),
                DataCell(Text('${G.clubs[tbl[i]].gd}')),
                DataCell(Text('${G.clubs[tbl[i]].pts}')),
              ]),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Text(t('الهدافون', 'Top scorers'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      for (final p in sc.take(5).where((p) => p.goals > 0)) ListTile(dense: true, title: Text(G.pname(p)), subtitle: Text(G.clubName(p.club)), trailing: Text('${p.goals}')),
    ]);
  }
}

// ---------------- الانتقالات ----------------
class MarketPage extends StatefulWidget {
  const MarketPage({super.key});
  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  bool youth = false;
  @override
  Widget build(BuildContext context) {
    var pool = G.players.where((p) => p.club != G.club).toList();
    if (youth) {
      pool = pool.where((p) => p.age <= 21).toList()..sort((a, b) => b.pot.compareTo(a.pot));
    } else {
      pool.sort((a, b) => b.ovr.compareTo(a.ovr));
    }
    return ListView(padding: const EdgeInsets.all(12), children: [
      Text('${t('الميزانية', 'Budget')}: ${money(G.clubs[G.club].budget)}', style: const TextStyle(fontSize: 18)),
      Row(children: [
        Expanded(child: bigBtn(t('الأفضل', 'Top'), () => setState(() => youth = false), icon: Icons.star)),
        const SizedBox(width: 8),
        Expanded(child: bigBtn(t('كشافة', 'Scout'), () => setState(() => youth = true), icon: Icons.search)),
      ]),
      for (final p in pool.take(25))
        Card(
          child: ListTile(
            title: Text(G.pname(p)),
            subtitle: Text('${G.posName(p.pos)} • ${G.clubName(p.club)} • ${t('العمر', 'Age')} ${p.age} • POT ${p.pot}'),
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${p.ovr}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _green)),
              Text(money(p.value), style: const TextStyle(fontSize: 11)),
            ]),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerPage(p.id))),
          ),
        ),
    ]);
  }
}

// ---------------- البريد/السجل/الإعدادات ----------------
class MailPage extends StatelessWidget {
  const MailPage({super.key});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: G,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(t('البريد والعروض', 'Mail & offers'))),
        body: ListView(padding: const EdgeInsets.all(12), children: [
          if (G.offers.isEmpty) Text(t('لا توجد عروض حاليًا', 'No offers right now')),
          for (var i = 0; i < G.offers.length; i++)
            if (G.find(G.offers[i].pid) != null)
              card(Column(children: [
                Text('${t('عرض من', 'Offer from')} ${G.clubName(G.offers[i].club)}: ${G.pname(G.find(G.offers[i].pid)!)} ← ${money(G.offers[i].price)}'),
                Row(children: [
                  Expanded(
                      child: bigBtn(t('قبول', 'Accept'), () {
                    final o = G.offers[i];
                    snack(context, resMsg(G.sell(o.pid, o.price)));
                  }, icon: Icons.check)),
                  const SizedBox(width: 8),
                  Expanded(child: bigBtn(t('رفض', 'Reject'), () => G.rejectOffer(i), icon: Icons.close)),
                ]),
              ])),
          const Divider(),
          for (final s in G.inbox.take(20)) ListTile(dense: true, title: Text(s)),
        ]),
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('سجل المدرب', 'Coach record'))),
      body: ListView(padding: const EdgeInsets.all(12), children: [
        if (G.history.isEmpty) Text(t('لا يوجد سجل بعد', 'No history yet')),
        for (final h in G.history)
          card(Text('${t('الموسم', 'Season')} ${h['season']}: ${t('البطل', 'Champion')} ${G.clubName(h['champ']!)} • ${t('مركزك', 'Your position')} ${h['pos']} • ${h['pts']} ${t('نقطة', 'pts')}')),
      ]),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t('الإعدادات والحفظ', 'Settings & save'))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        bigBtn(t('حفظ يدوي', 'Manual save'), () async {
          final ok = await G.save();
          if (context.mounted) snack(context, ok ? t('تم الحفظ', 'Saved') : t('فشل الحفظ', 'Save failed'));
        }, icon: Icons.save),
        bigBtn(t('تحميل المسيرة', 'Load career'), () async {
          final ok = await G.load();
          if (context.mounted) snack(context, ok ? t('تم التحميل', 'Loaded') : t('لا يوجد حفظ صالح', 'No valid save found'));
        }, icon: Icons.download),
        bigBtn(G.arabic ? 'English' : 'العربية', G.toggleLang, icon: Icons.language),
      ]),
    );
  }
}