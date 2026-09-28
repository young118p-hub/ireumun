// 우리 케미: 두 사람 사주로 보는 궁합 (무료로 보이는 부분은 전부 이 규칙, AI 없음)
// 점수 = 기본 45 + 일간(0~20) + 일지(0~16) + 띠(0~8) + 시지(0~6) + 오행 보완(0~10), 최대 99.
// - 일간: 간합 20 / 상생 15 / 비화 10 / 상극 5 / 충 2
// - 일지·띠·시지: 지지 관계 (육합 > 삼합 > 같음·없음 > 해 > 형 > 원진 > 충)
// - 시지는 둘 다 태어난 시간을 알 때만. 모르면 중간 점수(4)로 두어 시간을 안 넣었다고 점수가 크게 흔들리지 않게.
// - 오행 보완: 내게 가장 부족한 오행을 상대가 몇 개 가졌는지 (양쪽 방향, 각 0~5)
// 같은 두 사람이면 순서를 바꿔도 같은 점수. 궁합 점수는 학파마다 달라 이 표는 흔한 기준을 점수로 옮긴 것.

import '../../core/constants/saju_constants.dart';
import '../../core/text/josa.dart';
import '../services/saju_calculator.dart';
import 'pair_chemi_content.dart';

export 'pair_chemi_content.dart' show tenGodTexts;

enum PairRelation {
  lover('연인', '커플'),
  friend('친구', '친구'),
  coworker('동료', '팀');

  const PairRelation(this.label, this.noun);
  final String label;
  final String noun;
}

class PairPerson {
  final String name; // 부르는 이름 (조사가 붙는 자리에 쓴다)
  final SajuResult saju;
  final bool hourKnown;

  const PairPerson({required this.name, required this.saju, required this.hourKnown});

  int get dayStem => SajuConstants.cheongan.indexOf(saju.dayPillar[0]);
  int get dayBranch => SajuConstants.jiji.indexOf(saju.dayPillar[1]);
  int get yearBranch => SajuConstants.jiji.indexOf(saju.yearPillar[1]);
  int? get hourBranch => hourKnown ? SajuConstants.jiji.indexOf(saju.hourPillar[1]) : null;
  String get animal => SajuConstants.jijiAnimal[yearBranch];
}

class PairPart {
  final String label; // 일간 궁합
  final String badge; // 정임합 · 찰떡 …
  final int points;
  final int max;
  final String text;
  final bool known; // 시간을 몰라 중간 점수를 준 항목이면 false

  const PairPart(this.label, this.badge, this.points, this.max, this.text, {this.known = true});
}

class TenGodView {
  final String from; // 이 사람에게
  final String to; // 상대는
  final String name; // 정관
  final String title; // 정관(正官)
  final String text;
  const TenGodView(this.from, this.to, this.name, this.title, this.text);
}

class PairChemi {
  final PairPerson a;
  final PairPerson b;
  final PairRelation relation;
  final int score;
  final List<PairPart> parts;
  final List<TenGodView> tenGods; // a가 보는 b, b가 보는 a
  final bool stemHarmony;

  const PairChemi({
    required this.a,
    required this.b,
    required this.relation,
    required this.score,
    required this.parts,
    required this.tenGods,
    required this.stemHarmony,
  });

  static const base = 45;

  bool get bothHoursKnown => a.hourKnown && b.hourKnown;

  String get accuracy => bothHoursKnown
      ? '두 사람 여덟 글자 모두로 봤어요'
      : '태어난 시간을 모르는 사람이 있어서 시주는 빼고 봤어요';

  String get title {
    final n = relation.noun;
    if (stemHarmony) return '서로 끌어당기는 간합 $n';
    if (score >= 90) return '천생연분에 가까운 $n';
    if (score >= 80) return '서로를 채워 주는 좋은 $n';
    if (score >= 70) return '맞춰 갈수록 단단해지는 $n';
    return '배울 게 많은 $n';
  }

  List<String> get tags => [
        score >= 90 ? '#찰떡케미' : score >= 80 ? '#좋은케미' : '#알아가는케미',
        '#${a.animal}띠×${b.animal}띠',
      ];
}

// ============================================================
// 관계 판정
// ============================================================

int _el(int stem) => stem ~/ 2; // 0목 1화 2토 3금 4수
const _elName = ['목', '화', '토', '금', '수'];
const _elHanja = ['木', '火', '土', '金', '水'];

String _stemKey(int x, int y) => [x, y].map((i) => SajuConstants.cheongan[i]).join();
String _branchKey(int x, int y) {
  final s = [x, y]..sort();
  return s.map((i) => SajuConstants.jiji[i]).join();
}

String _animal(int b) => SajuConstants.jijiAnimal[b];

enum BranchRel { harmony, trine, same, none, harm, punish, wonjin, clash }

BranchRel branchRelation(int x, int y) {
  final d = (x - y).abs();
  if (d == 6) return BranchRel.clash;
  const wonjin = {'자미', '축오', '인유', '묘신', '진해', '사술'};
  if (wonjin.contains(_branchKey(x, y))) return BranchRel.wonjin;
  if ((x + y) % 12 == 1) return BranchRel.harmony; // 자축 인해 묘술 진유 사신 오미
  if (x != y && x % 4 == y % 4) return BranchRel.trine; // 신자진 해묘미 인오술 사유축
  const punish = {'인사', '사신', '인신', '축술', '미술', '축미', '자묘'}; // 키는 지지 순서대로 (술미 → 미술)
  const selfPunish = {4, 6, 9, 11}; // 진 오 유 해
  if (x == y) return selfPunish.contains(x) ? BranchRel.punish : BranchRel.same;
  if (punish.contains(_branchKey(x, y))) return BranchRel.punish;
  const harm = {'인사', '묘진', '신해', '유술'};
  if (harm.contains(_branchKey(x, y))) return BranchRel.harm;
  return BranchRel.none;
}

String branchRelLabel(BranchRel r) => switch (r) {
      BranchRel.harmony => '육합',
      BranchRel.trine => '삼합',
      BranchRel.same => '같은 지지',
      BranchRel.none => '합·충 없음',
      BranchRel.harm => '해',
      BranchRel.punish => '형',
      BranchRel.wonjin => '원진',
      BranchRel.clash => '충',
    };

/// 지지 관계 해설 (일지·띠·시지 공통)
String branchText(int x, int y) {
  final r = branchRelation(x, y);
  final ax = _animal(x), ay = _animal(y);
  switch (r) {
    case BranchRel.harmony:
      return branchHarmonyTexts[_branchKey(x, y)]!;
    case BranchRel.clash:
      return branchClashTexts[_branchKey(x, y)]!;
    case BranchRel.wonjin:
      return branchWonjinTexts[_branchKey(x, y)]!;
    case BranchRel.trine:
      // x % 4: 0 신자진 수 / 1 사유축 금 / 2 인오술 화 / 3 해묘미 목
      return branchTrineTexts[const ['수', '금', '화', '목'][x % 4]]!.$2;
    case BranchRel.punish:
      return x == y
          ? '같은 $ax끼리의 자형(自刑)이에요. 닮아서 편하지만 서로의 단점도 거울처럼 보여요. 상대를 고치려 하기보다 인정해 주기.'
          : '${waGwa(ax)} $ay의 형(刑)이에요. 서로를 다듬으려다 상처를 줄 수 있어요. 지적보다 인정이 먼저예요.';
    case BranchRel.harm:
      return '${waGwa(ax)} $ay의 해(害)예요. 겉으로는 괜찮은데 속으로 서운함이 쌓이기 쉬워요. 작은 건 바로 말하기.';
    case BranchRel.same:
      return '둘 다 ${ieyo(ax)}. 비슷한 속마음이라 말하지 않아도 통하는 게 많아요.';
    case BranchRel.none:
      return '${waGwa(ax)} ${eunNeun(ay)} 특별히 끌어당기지도 부딪히지도 않는 사이예요. 관계는 함께 보낸 시간만큼 자라요.';
  }
}

String tenGod(int myStem, int otherStem) {
  final m = _el(myStem), o = _el(otherStem);
  final samePolarity = myStem % 2 == otherStem % 2;
  if (m == o) return samePolarity ? '비견' : '겁재';
  if ((m + 1) % 5 == o) return samePolarity ? '식신' : '상관';
  if ((m + 2) % 5 == o) return samePolarity ? '편재' : '정재';
  if ((o + 2) % 5 == m) return samePolarity ? '편관' : '정관';
  return samePolarity ? '편인' : '정인';
}

// ============================================================
// 계산
// ============================================================

PairPart _dayStemPart(PairPerson a, PairPerson b) {
  final x = a.dayStem, y = b.dayStem;
  final sx = SajuConstants.cheongan[x], sy = SajuConstants.cheongan[y];
  final ex = _el(x), ey = _el(y);
  final key = _stemKey(x < y ? x : y, x < y ? y : x);
  String elWord(int e, String s) => '$s(${_elName[e]}${_elHanja[e]})';

  if ((x - y).abs() == 5) {
    final (t, body) = stemHarmonyTexts[key]!;
    return PairPart('일간 궁합', '$t · 찰떡', 20, 20, body);
  }
  if ((x - y).abs() == 6 && (x < 4 || y < 4)) {
    final (t, body) = stemClashTexts[key]!;
    return PairPart('일간 궁합', '$t · 주의', 2, 20, body);
  }
  if (ex == ey) {
    return PairPart('일간 궁합', '비화 · 닮은 기운', 10, 20,
        '둘 다 ${_elName[ex]}(${_elHanja[ex]}) 기운($sx·$sy)이에요. 생각과 속도가 비슷해서 편하지만, 부딪히면 둘 다 물러서지 않아요. 양보하는 순서를 정해 두면 좋아요.');
  }
  final (giver, taker, gs, ts) = (ex + 1) % 5 == ey
      ? (a, b, elWord(ex, sx), elWord(ey, sy))
      : (ey + 1) % 5 == ex
          ? (b, a, elWord(ey, sy), elWord(ex, sx))
          : (a, b, '', ''); // 상극은 아래에서
  if (gs.isNotEmpty) {
    return PairPart('일간 궁합', '상생 · 살려 주는 사이', 15, 20,
        '${giver.name}의 $gs 기운이 ${taker.name}의 $ts 기운을 살려요. ${eunNeun(taker.name)} ${giver.name} 곁에서 힘을 얻고, ${eunNeun(giver.name)} ${eulReul(taker.name)} 챙기며 보람을 느껴요.');
  }
  final (ruler, ruled, rs, rds) = (ex + 2) % 5 == ey ? (a, b, elWord(ex, sx), elWord(ey, sy)) : (b, a, elWord(ey, sy), elWord(ex, sx));
  return PairPart('일간 궁합', '상극 · 한쪽이 이끄는 사이', 5, 20,
      '${ruler.name}의 $rs 기운이 ${ruled.name}의 $rds 기운을 누르는 관계예요. ${iGa(ruler.name)} 이끌고 ${iGa(ruled.name)} 맞춰 주기 쉬워서, ${ruled.name}의 속도를 기다려 주는 게 중요해요.');
}

const _branchPoints16 = {
  BranchRel.harmony: 16, BranchRel.trine: 13, BranchRel.same: 9, BranchRel.none: 8,
  BranchRel.harm: 5, BranchRel.punish: 4, BranchRel.wonjin: 3, BranchRel.clash: 2,
};
const _branchPoints8 = {
  BranchRel.harmony: 8, BranchRel.trine: 8, BranchRel.same: 6, BranchRel.none: 5,
  BranchRel.harm: 4, BranchRel.punish: 4, BranchRel.wonjin: 2, BranchRel.clash: 2,
};
const _branchPoints6 = {
  BranchRel.harmony: 6, BranchRel.trine: 6, BranchRel.same: 4, BranchRel.none: 4,
  BranchRel.harm: 3, BranchRel.punish: 3, BranchRel.wonjin: 1, BranchRel.clash: 1,
};

String _verdict(int points, int max) => points * 10 >= max * 8 ? '찰떡' : (points * 10 >= max * 5 ? '무난' : '주의');

PairPart _branchPart(String label, int x, int y, Map<BranchRel, int> table, int max, {String prefix = ''}) {
  final r = branchRelation(x, y);
  final pts = table[r]!;
  final pair = '${SajuConstants.jiji[x]}${SajuConstants.jiji[y]}';
  return PairPart(label, '${r == BranchRel.none ? '' : '$pair '}${branchRelLabel(r)} · ${_verdict(pts, max)}', pts, max,
      '$prefix${branchText(x, y)}');
}

(PairPart, int) _complement(PairPerson a, PairPerson b) {
  int weakest(PairPerson p) {
    final c = [for (final e in _elName) p.saju.ohengBalance[e] ?? 0];
    final min = c.reduce((x, y) => x < y ? x : y);
    return c.indexOf(min);
  }

  int pts(int n) => n >= 3 ? 5 : n * 2;
  final wa = weakest(a), wb = weakest(b);
  final na = b.saju.ohengBalance[_elName[wa]] ?? 0; // a에게 부족한 기운을 b가 가진 수
  final nb = a.saju.ohengBalance[_elName[wb]] ?? 0;
  String line(PairPerson who, PairPerson from, int e, int n) => n == 0
      ? '${who.name}에게 부족한 ${_elName[e]}(${_elHanja[e]}) 기운은 ${from.name}에게도 없어요. 둘이 함께 채워 갈 부분이에요.'
      : '${who.name}에게 부족한 ${_elName[e]}(${_elHanja[e]}) 기운을 ${iGa(from.name)} $n개 가졌어요. ${eunNeun(from.name)} ${who.name}에게 ${elementRoles[_elName[e]]} 사람이에요.';
  final total = pts(na) + pts(nb);
  return (
    PairPart('오행 보완', '${_verdict(total, 10)} · 서로 채워 주는 정도', total, 10,
        '${line(a, b, wa, na)}\n${line(b, a, wb, nb)}'),
    total,
  );
}

PairChemi pairChemi(PairPerson a, PairPerson b, {PairRelation relation = PairRelation.lover}) {
  final stem = _dayStemPart(a, b);
  final spouseLabel = relation == PairRelation.lover ? '배우자 자리(일지)' : '속마음 자리(일지)';
  final day = _branchPart(spouseLabel, a.dayBranch, b.dayBranch, _branchPoints16, 16,
      prefix: relation == PairRelation.lover ? '태어난 날의 지지는 배우자 자리라서 궁합에서 가장 중요하게 봐요. ' : '');
  final zodiac = _branchPart('띠 궁합 (${a.animal}띠 × ${b.animal}띠)', a.yearBranch, b.yearBranch, _branchPoints8, 8);
  final hour = a.hourBranch != null && b.hourBranch != null
      ? _branchPart('시주 궁합', a.hourBranch!, b.hourBranch!, _branchPoints6, 6,
          prefix: '태어난 시간은 함께 늙어 가는 모습과 속 깊은 곳을 보여 줘요. ')
      : const PairPart('시주 궁합', '시간 미상', 4, 6, '두 사람 모두 태어난 시간을 알면 볼 수 있어요. 지금은 중간 점수로 두었어요.',
          known: false);
  final (comp, _) = _complement(a, b);

  final parts = [stem, day, zodiac, hour, comp];
  final raw = PairChemi.base + parts.fold<int>(0, (s, p) => s + p.points);

  TenGodView view(PairPerson me, PairPerson other) {
    final g = tenGod(me.dayStem, other.dayStem);
    final (t, text) = tenGodTexts[g]!;
    return TenGodView(me.name, other.name, g, t, text);
  }

  return PairChemi(
    a: a,
    b: b,
    relation: relation,
    score: raw > 99 ? 99 : raw,
    parts: parts,
    tenGods: [view(a, b), view(b, a)],
    stemHarmony: (a.dayStem - b.dayStem).abs() == 5,
  );
}
