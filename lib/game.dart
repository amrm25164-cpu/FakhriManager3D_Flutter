import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _rng = Random();
int ri(int a, int b) => a + _rng.nextInt(b - a + 1);
double rd() => _rng.nextDouble();

const forms = <String, List<int>>{
  '4-3-3': [1, 4, 3, 3],
  '4-2-3-1': [1, 4, 5, 1],
  '4-4-2': [1, 4, 4, 2],
  '3-5-2': [1, 3, 5, 2],
};
const tactics = ['balanced', 'possession', 'press', 'counter', 'deep'];
const tacticsAr = {'balanced': 'متوازن', 'possession': 'استحواذ', 'press': 'ضغط عالٍ', 'counter': 'مرتدات', 'deep': 'دفاع متأخر'};
const tacticsEn = {'balanced': 'Balanced', 'possession': 'Possession', 'press': 'High press', 'counter': 'Counter', 'deep': 'Deep defence'};
const clubsAr = ['نادي الصقور', 'نادي النمور', 'نادي الفرسان', 'نادي الأسود', 'نادي النجوم', 'نادي العاصفة', 'نادي الشراع', 'نادي الواحة'];
const clubsEn = ['Falcons FC', 'Tigers FC', 'Knights FC', 'Lions FC', 'Stars FC', 'Storm FC', 'Sails FC', 'Oasis FC'];
const fnAr = ['عمر', 'خالد', 'يوسف', 'سامي', 'ماجد', 'فارس', 'نبيل', 'رامي', 'هشام', 'طارق', 'زياد', 'ليث'];
const fnEn = ['Omar', 'Khaled', 'Yousef', 'Sami', 'Majed', 'Fares', 'Nabil', 'Rami', 'Hisham', 'Tarek', 'Ziad', 'Layth'];
const lnAr = ['الحداد', 'النجار', 'المنصور', 'الفهد', 'السالم', 'الزعبي', 'الراشد', 'البدر', 'العلي', 'الشامي', 'القاسم', 'التميمي'];
const lnEn = ['Haddad', 'Najjar', 'Mansour', 'Fahd', 'Salem', 'Zoubi', 'Rashed', 'Badr', 'Ali', 'Shami', 'Qasim', 'Tamimi'];

class Player {
  int id, fn, ln, age, pos, club, ovr, pot, contract, fit, inj, goals, apps, value = 0, wage = 0;
  Player(this.id, this.fn, this.ln, this.age, this.pos, this.club, this.ovr, this.pot, this.contract,
      [this.fit = 100, this.inj = 0, this.goals = 0, this.apps = 0]) {
    calc();
  }
  void calc() {
    value = (pow(max(ovr - 45, 1).toDouble(), 2.3) * 3.0 * (age < 30 ? 1.0 : 0.7)).toInt();
    wage = max(3, (value / 180).floor());
  }

  Map<String, dynamic> toJson() => {
        'id': id, 'fn': fn, 'ln': ln, 'age': age, 'pos': pos, 'club': club, 'ovr': ovr, 'pot': pot,
        'contract': contract, 'fit': fit, 'inj': inj, 'goals': goals, 'apps': apps
      };
  factory Player.fromJson(Map<String, dynamic> j) => Player(j['id'], j['fn'], j['ln'], j['age'], j['pos'], j['club'],
      j['ovr'], j['pot'], j['contract'], j['fit'], j['inj'], j['goals'], j['apps']);
}

class Club {
  int strength, budget, pts = 0, pl = 0, w = 0, d = 0, l = 0, gf = 0, ga = 0;
  Club(this.strength, this.budget);
  int get gd => gf - ga;
  void reset() {
    pts = pl = w = d = l = gf = ga = 0;
  }

  Map<String, dynamic> toJson() => {'s': strength, 'b': budget, 'pts': pts, 'pl': pl, 'w': w, 'd': d, 'l': l, 'gf': gf, 'ga': ga};
  factory Club.fromJson(Map<String, dynamic> j) => Club(j['s'], j['b'])
    ..pts = j['pts']
    ..pl = j['pl']
    ..w = j['w']
    ..d = j['d']
    ..l = j['l']
    ..gf = j['gf']
    ..ga = j['ga'];
}

class Offer {
  int pid, club, price;
  Offer(this.pid, this.club, this.price);
  Map<String, dynamic> toJson() => {'pid': pid, 'club': club, 'price': price};
  factory Offer.fromJson(Map<String, dynamic> j) => Offer(j['pid'], j['club'], j['price']);
}

class Ev {
  int m, s, pid;
  String t, txt;
  Ev(this.m, this.s, this.t, this.pid, this.txt);
}

class Rating {
  double gk, def, mid, att;
  Rating(this.gk, this.def, this.mid, this.att);
}

class MatchResult {
  int h, a, gh, ga;
  List<Ev> ev;
  Map<String, List<num>> st;
  List<List<Player>> xi;
  MatchResult(this.h, this.a, this.gh, this.ga, this.ev, this.st, this.xi);
}

class Game extends ChangeNotifier {
  bool arabic = true;
  String coach = '';
  int club = 0, week = 0, season = 1, nextId = 0;
  String formation = '4-3-3', tactic = 'balanced';
  List<Club> clubs = [];
  List<Player> players = [];
  List<List<List<int>>> fixtures = [];
  List<Map<String, int>> history = [];
  List<String> inbox = [];
  List<Offer> offers = [];
  Set<int> benched = {};
  MatchResult? last;
  List<MatchResult> roundResults = [];

  bool get started => clubs.isNotEmpty;
  String clubName(int i) => arabic ? clubsAr[i] : clubsEn[i];
  String pname(Player p) => arabic ? '${fnAr[p.fn]} ${lnAr[p.ln]}' : '${fnEn[p.fn]} ${lnEn[p.ln]}';
  String tacticName(String k) => arabic ? tacticsAr[k]! : tacticsEn[k]!;
  String posName(int p) => arabic ? ['حارس', 'مدافع', 'وسط', 'مهاجم'][p] : ['GK', 'DEF', 'MID', 'ATT'][p];
  Player? find(int id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Player> squad(int c) => players.where((p) => p.club == c).toList();
  void notify() => notifyListeners();
  void toggleLang() {
    arabic = !arabic;
    notifyListeners();
  }

  void setFormation(String f) {
    formation = f;
    notifyListeners();
  }

  void setTactic(String t) {
    tactic = t;
    notifyListeners();
  }

  void toggleBench(int id) {
    if (!benched.add(id)) benched.remove(id);
    notifyListeners();
  }

  Player genPlayer(int c, int pos, int strength) {
    final ovr = (strength + ri(-9, 9)).clamp(40, 90).toInt();
    final age = ri(17, 36);
    final pot = (ovr + (age < 24 ? ri(0, 12) : ri(0, 2))).clamp(ovr, 94).toInt();
    return Player(nextId++, _rng.nextInt(12), _rng.nextInt(12), age, pos, c, ovr, pot, ri(1, 4));
  }

  void buildFixtures() {
    final t = List<int>.generate(8, (i) => i);
    final rounds = <List<List<int>>>[];
    for (var r = 0; r < 7; r++) {
      final rd = <List<int>>[];
      for (var i = 0; i < 4; i++) {
        final a = t[i], b = t[7 - i];
        rd.add(r % 2 == 0 ? [a, b] : [b, a]);
      }
      rounds.add(rd);
      t.insert(1, t.removeLast());
    }
    final second = rounds.map((rd) => rd.map((m) => [m[1], m[0]]).toList()).toList();
    fixtures = [...rounds, ...second];
  }

  void newCareer(String name, int clubIdx) {
    coach = name.isEmpty ? 'Coach' : name;
    club = clubIdx;
    week = 0;
    season = 1;
    formation = '4-3-3';
    tactic = 'balanced';
    clubs = [];
    players = [];
    history = [];
    inbox = [];
    offers = [];
    benched = {};
    last = null;
    nextId = 0;
    for (var i = 0; i < 8; i++) {
      final s = 55 + ri(0, 18);
      clubs.add(Club(s, 40000));
      for (final k in [[0, 2], [1, 6], [2, 6], [3, 4]]) {
        for (var j = 0; j < k[1]; j++) {
          players.add(genPlayer(i, k[0], s));
        }
      }
    }
    buildFixtures();
    save();
    notifyListeners();
  }

  List<int> nextFixture() {
    for (final m in fixtures[week]) {
      if (m[0] == club || m[1] == club) return m;
    }
    return [club, club];
  }

  List<Player> lineup(int c) {
    final need = forms[c == club ? formation : '4-4-2']!;
    final xi = <Player>[];
    for (var pos = 0; pos < 4; pos++) {
      final pool = players.where((x) => x.club == c && x.pos == pos).toList();
      double key(Player x) => (x.inj > 0 || (c == club && benched.contains(x.id))) ? 0.0 : x.ovr * (0.7 + x.fit / 333);
      pool.sort((a, b) => key(b).compareTo(key(a)));
      xi.addAll(pool.take(need[pos]));
    }
    return xi;
  }

  Rating rating(int c) {
    final xi = lineup(c);
    final sums = [0.0, 0.0, 0.0, 0.0];
    final cnt = [0, 0, 0, 0];
    for (final p in xi) {
      sums[p.pos] += p.ovr * (0.7 + p.fit / 333);
      cnt[p.pos]++;
    }
    final v = List<double>.generate(4, (i) => cnt[i] > 0 ? sums[i] / cnt[i] : 30.0);
    final r = Rating(v[0], v[1], v[2], v[3]);
    if (c == club) {
      switch (tactic) {
        case 'possession':
          r.mid += 3;
          r.att -= 1;
          break;
        case 'press':
          r.att += 2;
          r.def -= 2;
          break;
        case 'counter':
          r.att += 2;
          r.mid -= 2;
          break;
        case 'deep':
          r.def += 3;
          r.att -= 3;
          break;
      }
    }
    return r;
  }

  Player pickScorer(List<Player> xi) {
    const wts = [0.0, 0.7, 2.0, 5.0];
    var tot = 0.0;
    for (final p in xi) {
      tot += wts[p.pos];
    }
    var r = rd() * tot;
    for (final p in xi) {
      r -= wts[p.pos];
      if (r <= 0) return p;
    }
    return xi.last;
  }

  MatchResult simMatch(int h, int a) {
    final rt = [rating(h), rating(a)];
    final xi = [lineup(h), lineup(a)];
    final ids = [h, a];
    final ph = (50.0 + (rt[0].mid - rt[1].mid) * 1.3 + 3.0).clamp(30.0, 70.0).toDouble();
    final poss = <num>[ph, 100 - ph];
    final shots = <num>[0, 0], sot = <num>[0, 0], corners = <num>[0, 0], fouls = <num>[0, 0], passes = <num>[0, 0];
    final goals = [0, 0];
    final ev = <Ev>[];
    for (var s = 0; s < 2; s++) {
      final o = 1 - s;
      final n = max(3, 6 + (poss[s] / 10).floor() + ri(0, 5) + ((rt[s].att - rt[o].def) * 0.25).toInt());
      shots[s] = n;
      passes[s] = (300 * poss[s] / 50).toInt() + ri(-30, 30);
      corners[s] = ri(1, 3) + (n / 4).floor();
      fouls[s] = ri(7, 15);
      final pr = (0.11 + (rt[s].att - (rt[o].def + rt[o].gk) * 0.5) * 0.006).clamp(0.03, 0.35).toDouble();
      for (var i = 0; i < n; i++) {
        final m = ri(1, 90);
        if (rd() < pr) {
          final p = pickScorer(xi[s]);
          sot[s]++;
          goals[s]++;
          ev.add(Ev(m, s, 'goal', p.id,
              arabic ? '⚽ هدف لـ ${clubName(ids[s])} بواسطة ${pname(p)}!' : '⚽ GOAL for ${clubName(ids[s])} by ${pname(p)}!'));
        } else if (rd() < 0.35) {
          sot[s]++;
          final p2 = pickScorer(xi[s]);
          ev.add(Ev(m, s, 'save', -1,
              arabic ? '🧤 تسديدة من ${pname(p2)} يتصدى لها الحارس' : '🧤 Shot by ${pname(p2)} saved by the keeper'));
        }
      }
      final cards = ri(0, 3);
      final cands = xi[s].where((x) => x.pos != 0).toList();
      for (var i = 0; i < cards; i++) {
        final cp = cands[_rng.nextInt(cands.length)];
        ev.add(Ev(ri(5, 90), s, 'yellow', -1, arabic ? '🟨 بطاقة صفراء لـ ${pname(cp)}' : '🟨 Yellow card: ${pname(cp)}'));
      }
    }
    ev.sort((x, y) => x.m.compareTo(y.m));
    return MatchResult(h, a, goals[0], goals[1], ev,
        {'poss': poss, 'shots': shots, 'sot': sot, 'corners': corners, 'fouls': fouls, 'passes': passes}, xi);
  }

  void applyMatch(MatchResult r) {
    final hh = clubs[r.h], aa = clubs[r.a];
    hh.pl++;
    aa.pl++;
    hh.gf += r.gh;
    hh.ga += r.ga;
    aa.gf += r.ga;
    aa.ga += r.gh;
    if (r.gh > r.ga) {
      hh.pts += 3;
      hh.w++;
      aa.l++;
    } else if (r.gh < r.ga) {
      aa.pts += 3;
      aa.w++;
      hh.l++;
    } else {
      hh.pts++;
      aa.pts++;
      hh.d++;
      aa.d++;
    }
    for (final e in r.ev) {
      if (e.t == 'goal') find(e.pid)?.goals++;
    }
    for (var s = 0; s < 2; s++) {
      final cid = s == 0 ? r.h : r.a;
      final hi = (cid == club && tactic == 'press') ? 12 : 9;
      for (final p in r.xi[s]) {
        p.apps++;
        p.fit = max(40, p.fit - ri(5, hi));
        if (rd() < 0.02) {
          p.inj = ri(1, 5) + 1;
          if (p.club == club) {
            inbox.insert(0, arabic ? '🚑 ${pname(p)} مصاب لمدة ${p.inj - 1} أسابيع' : '🚑 ${pname(p)} injured for ${p.inj - 1} weeks');
          }
        }
      }
    }
  }

  void playRound() {
    final rd0 = fixtures[week];
    roundResults = [];
    last = null;
    final played = <Player>{};
    for (final m in rd0) {
      final r = simMatch(m[0], m[1]);
      applyMatch(r);
      roundResults.add(r);
      played.addAll(r.xi[0]);
      played.addAll(r.xi[1]);
      if (r.h == club || r.a == club) last = r;
    }
    for (final p in players) {
      p.fit = min(100, p.fit + (played.contains(p) ? 2 : 8));
      if (p.inj > 0) p.inj--;
    }
    for (var i = 0; i < 8; i++) {
      var wages = 0;
      for (final p in squad(i)) {
        wages += p.wage;
      }
      clubs[i].budget += 900 - wages;
    }
    if (rd() < 0.15) makeOffer();
    week++;
    if (week >= fixtures.length) endSeason();
    save();
    notifyListeners();
  }

  List<int> sortedTable() {
    final idx = List<int>.generate(8, (i) => i);
    idx.sort((a, b) {
      final x = clubs[a], y = clubs[b];
      if (x.pts != y.pts) return y.pts.compareTo(x.pts);
      if (x.gd != y.gd) return y.gd.compareTo(x.gd);
      return y.gf.compareTo(x.gf);
    });
    return idx;
  }

  int rankOf(int c) => sortedTable().indexOf(c) + 1;

  void endSeason() {
    final t = sortedTable();
    final rk = t.indexOf(club) + 1;
    history.add({'season': season, 'champ': t[0], 'pos': rk, 'pts': clubs[club].pts});
    inbox.insert(0, arabic ? '🏆 نهاية الموسم $season: البطل ${clubName(t[0])}، وترتيبك $rk' : '🏆 Season $season over: champions ${clubName(t[0])}, you finished $rk');
    clubs[club].budget += (9 - rk) * 1500;
    for (final p in players) {
      p.age++;
      if (p.age <= 24) {
        p.ovr = min(p.pot, p.ovr + ri(0, 4));
      } else if (p.age >= 31) {
        p.ovr = max(40, p.ovr - ri(0, 3));
      } else {
        p.ovr = (p.ovr + ri(-1, 1)).clamp(40, 92).toInt();
      }
      p.contract--;
      if (p.contract <= 0) p.contract = 2;
      p.goals = 0;
      p.apps = 0;
      p.fit = 100;
      p.inj = 0;
      p.calc();
    }
    season++;
    week = 0;
    for (final c in clubs) {
      c.reset();
    }
    buildFixtures();
    offers = [];
  }

  String buy(int pid, int pct) {
    final p = find(pid);
    if (p == null) return 'gone';
    final price = (p.value * pct / 100).toInt();
    if (price > clubs[club].budget) return 'no_funds';
    if (squad(club).length >= 26) return 'squad_full';
    if (rd() < (0.25 + (pct - 85) * 0.02).clamp(0.05, 0.95).toDouble()) {
      clubs[club].budget -= price;
      clubs[p.club].budget += price;
      p.club = club;
      p.contract = 3;
      save();
      notifyListeners();
      return 'ok';
    }
    return 'rejected';
  }

  String sell(int pid, [int price = -1]) {
    final p = find(pid);
    if (p == null || p.club != club) return 'gone';
    if (squad(club).length <= 16) return 'squad_min';
    final pr = price >= 0 ? price : (p.value * 0.95).toInt();
    final buyer = (club + ri(1, 7)) % 8;
    clubs[club].budget += pr;
    clubs[buyer].budget -= pr;
    p.club = buyer;
    benched.remove(pid);
    offers.removeWhere((o) => o.pid == pid);
    save();
    notifyListeners();
    return 'sold';
  }

  void rejectOffer(int i) {
    if (i >= 0 && i < offers.length) offers.removeAt(i);
    notifyListeners();
  }

  void makeOffer() {
    final mine = squad(club);
    if (mine.isEmpty || offers.length >= 3) return;
    final p = mine[_rng.nextInt(mine.length)];
    if (offers.any((o) => o.pid == p.id)) return;
    offers.add(Offer(p.id, (club + ri(1, 7)) % 8, (p.value * (0.9 + rd() * 0.5)).toInt()));
  }

  Map<String, dynamic> toJson() => {
        'arabic': arabic, 'coach': coach, 'club': club, 'week': week, 'season': season, 'formation': formation,
        'tactic': tactic, 'nextId': nextId, 'clubs': clubs.map((c) => c.toJson()).toList(),
        'players': players.map((p) => p.toJson()).toList(), 'fixtures': fixtures, 'history': history,
        'inbox': inbox, 'offers': offers.map((o) => o.toJson()).toList(), 'benched': benched.toList()
      };

  Future<bool> hasSave() async {
    try {
      final sp = await SharedPreferences.getInstance();
      return sp.containsKey('save');
    } catch (_) {
      return false;
    }
  }

  Future<bool> save() async {
    try {
      final sp = await SharedPreferences.getInstance();
      return await sp.setString('save', jsonEncode(toJson()));
    } catch (_) {
      return false;
    }
  }

  Future<bool> load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final s = sp.getString('save');
      if (s == null) return false;
      final j = jsonDecode(s) as Map<String, dynamic>;
      final nc = (j['clubs'] as List).map((e) => Club.fromJson(e as Map<String, dynamic>)).toList();
      final np = (j['players'] as List).map((e) => Player.fromJson(e as Map<String, dynamic>)).toList();
      final nf = (j['fixtures'] as List)
          .map((rd) => (rd as List).map((m) => (m as List).map((x) => x as int).toList()).toList())
          .toList();
      final nh = (j['history'] as List).map((e) => Map<String, int>.from(e as Map)).toList();
      final no = (j['offers'] as List).map((e) => Offer.fromJson(e as Map<String, dynamic>)).toList();
      arabic = j['arabic'] as bool;
      coach = j['coach'] as String;
      club = j['club'] as int;
      week = j['week'] as int;
      season = j['season'] as int;
      formation = j['formation'] as String;
      tactic = j['tactic'] as String;
      nextId = j['nextId'] as int;
      inbox = List<String>.from(j['inbox'] as List);
      benched = Set<int>.from(j['benched'] as List);
      clubs = nc;
      players = np;
      fixtures = nf;
      history = nh;
      offers = no;
      last = null;
      roundResults = [];
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final G = Game();
