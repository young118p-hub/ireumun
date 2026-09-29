// 이름 케미 (무료, 서버·AI 없음): 두 사람 이름의 소리 오행(음령오행)으로 보는 궁합
// - 글자의 첫소리(초성)로 오행: ㄱㅋ 목 / ㄴㄷㄹㅌ 화 / ㅇㅎ 토 / ㅅㅈㅊ 금 / ㅁㅂㅍ 수
//   (학파에 따라 ㅇㅎ을 수, ㅁㅂㅍ을 토로 보기도 한다. 요즘 작명에서 흔한 쪽을 따른다)
// - 점수 = 기본 58 + 대표 기운 관계(상생 22 / 비화 14 / 상극 6) + 두 이름을 합친 오행 다양성(0~15)
//   + 각 이름의 소리 흐름(상생으로 이어진 곳 하나당 1, 최대 3) → 64~98
// - 같은 두 이름이면 순서를 바꿔도 같은 점수. 랜덤 없음.
// 생일까지 넣는 사주 궁합은 '우리 케미'가 따로 맡는다.

import 'package:flutter/widgets.dart';
import '../../core/text/josa.dart';
import '../chemi_common/improve.dart';

const elements = ['목', '화', '토', '금', '수'];

// 초성 19자 순서: ㄱ ㄲ ㄴ ㄷ ㄸ ㄹ ㅁ ㅂ ㅃ ㅅ ㅆ ㅇ ㅈ ㅉ ㅊ ㅋ ㅌ ㅍ ㅎ
const _chosungElement = [
  '목', '목', '화', '화', '화', '화', '수', '수', '수', '금',
  '금', '토', '금', '금', '금', '목', '화', '수', '토',
];

bool isHangulName(String s) => RegExp(r'^[가-힣]{2,4}$').hasMatch(s);

/// 한 글자의 소리 오행 (한글 음절이 아니면 null)
String? soundElement(String syllable) {
  if (syllable.isEmpty) return null;
  final code = syllable.runes.first;
  if (code < 0xAC00 || code > 0xD7A3) return null;
  return _chosungElement[(code - 0xAC00) ~/ 588];
}

/// a가 b를 살리는지 (목→화→토→금→수→목)
bool generates(String a, String b) => elements[(elements.indexOf(a) + 1) % 5] == b;

/// a가 b를 누르는지 (목→토→수→화→금→목)
bool controls(String a, String b) => elements[(elements.indexOf(a) + 2) % 5] == b;

enum ElementRelation { harmony, same, clash }

ElementRelation relationOf(String a, String b) {
  if (a == b) return ElementRelation.same;
  if (generates(a, b) || generates(b, a)) return ElementRelation.harmony;
  return ElementRelation.clash;
}

class ElementPersona {
  final String name; // 새싹 기운
  final String desc;
  const ElementPersona(this.name, this.desc);
}

const personas = {
  '목': ElementPersona('새싹 기운', '쭉쭉 뻗어 나가는 성장형. 새로운 걸 시작하는 힘이 있어요.'),
  '화': ElementPersona('불꽃 기운', '밝고 뜨거운 표현형. 분위기를 달구는 힘이 있어요.'),
  '토': ElementPersona('대지 기운', '든든하고 넉넉한 중심형. 사람을 모으는 힘이 있어요.'),
  '금': ElementPersona('보석 기운', '단단하고 반짝이는 원칙형. 끝맺음을 짓는 힘이 있어요.'),
  '수': ElementPersona('물결 기운', '유연하고 깊은 지혜형. 흐름을 읽는 힘이 있어요.'),
};

// 두 대표 기운의 해설. 키는 오행 순서대로 정렬한 두 글자 (순서를 바꿔도 같은 글)
const _pairTexts = {
  '목목': '둘 다 새싹 기운. 같이 자라는 사이지만, 둘 다 앞만 보다 쉬는 법을 잊을 수 있어요.',
  '화화': '불꽃 둘이 만난 뜨거운 사이. 재미는 최고, 다툼도 불꽃처럼 빨리 붙었다 빨리 꺼져요.',
  '토토': '대지 둘. 흔들림 없이 든든하지만, 변화가 필요할 땐 누군가 먼저 움직여야 해요.',
  '금금': '보석 둘. 서로의 원칙을 존중하지만, 고집이 부딪히면 둘 다 단단하게 맞서요.',
  '수수': '물결 둘. 말하지 않아도 흐름을 읽는 사이. 가끔은 마음을 말로 꺼내 줘야 해요.',
  '목화': '나무가 불을 키우듯, 새싹 기운이 불꽃 기운에 힘을 실어 줘요. 한 명이 시작하면 한 명이 크게 키우는 사이.',
  '화토': '불이 재가 되어 흙을 기름지게 하듯, 불꽃 기운이 대지 기운을 따뜻하게 채워요.',
  '토금': '흙 속에서 보석이 나오듯, 대지 기운이 보석 기운을 품어 빛나게 해요.',
  '금수': '바위 틈에서 샘물이 솟듯, 보석 기운이 물결 기운을 맑게 해 줘요.',
  '목수': '물이 나무를 키우듯, 물결 기운이 새싹 기운을 쑥쑥 자라게 해요.',
  '목토': '나무뿌리가 흙을 파고들듯, 새싹 기운이 대지 기운을 흔들 수 있어요. 속도를 맞추면 오히려 단단한 땅이 돼요.',
  '화금': '불이 쇠를 녹이듯, 불꽃 기운의 열정이 보석 기운의 원칙을 녹여요. 좋게 말하면 서로를 바꾸는 사이.',
  '토수': '흙이 물길을 막듯, 대지 기운이 물결 기운을 붙잡을 때가 있어요. 그래도 둑이 있어야 물이 모이죠.',
  '목금': '도끼가 나무를 다듬듯, 보석 기운이 새싹 기운을 다듬어요. 잔소리가 곧 관심일 수도.',
  '화수': '물이 불을 끄듯, 물결 기운이 불꽃 기운을 식혀 줘요. 흥분할 때 브레이크가 되어 주는 사이.',
};

String _pairKey(String a, String b) {
  final s = [a, b]..sort((x, y) => elements.indexOf(x) - elements.indexOf(y));
  return s.join();
}

class NameReading {
  final String name;
  final List<(String syllable, String element)> syllables;
  final String dominant; // 가장 많은 기운 (같으면 이름 첫 글자, 그다음 오행 순서)
  final int harmonyLinks; // 이웃한 글자끼리 상생인 곳
  final bool hasClash; // 이웃한 글자끼리 상극인 곳이 있는지

  const NameReading(this.name, this.syllables, this.dominant, this.harmonyLinks, this.hasClash);

  Map<String, int> get counts => {for (final e in elements) e: syllables.where((s) => s.$2 == e).length};

  String get flow => hasClash ? '한 번 꺾였다 이어지는 소리' : '술술 이어지는 소리';

  factory NameReading.of(String name) {
    final syl = [for (final c in name.characters) (c, soundElement(c)!)];
    final counts = {for (final e in elements) e: syl.where((s) => s.$2 == e).length};
    final top = counts.values.reduce((a, b) => a > b ? a : b);
    final tied = elements.where((e) => counts[e] == top).toList();
    // 성 다음 첫 글자(이름의 첫 글자)가 동점 안에 있으면 그 기운
    final firstGiven = syl.length > 1 ? syl[1].$2 : syl[0].$2;
    final dominant = tied.contains(firstGiven) ? firstGiven : tied.first;
    var links = 0;
    var clash = false;
    for (var i = 0; i + 1 < syl.length; i++) {
      final r = relationOf(syl[i].$2, syl[i + 1].$2);
      if (r == ElementRelation.harmony) links++;
      if (r == ElementRelation.clash) clash = true;
    }
    return NameReading(name, syl, dominant, links, clash);
  }
}

class NameChemiPart {
  final String label;
  final int points;
  final int max;
  final String text;
  const NameChemiPart(this.label, this.points, this.max, this.text);
}

class NameChemi {
  final NameReading a;
  final NameReading b;
  final ElementRelation relation;
  final int score;
  final List<NameChemiPart> parts; // 점수 근거 (더하면 score - 58)
  final String pairText;
  final List<String> aGetsFromB; // a에게 없는데 b가 채워 주는 기운
  final List<String> bGetsFromA;

  const NameChemi({
    required this.a,
    required this.b,
    required this.relation,
    required this.score,
    required this.parts,
    required this.pairText,
    required this.aGetsFromB,
    required this.bGetsFromA,
  });

  static const base = 58;

  String get title => switch (relation) {
        ElementRelation.harmony => '서로 살려 주는 상생 케미',
        ElementRelation.same => '닮은꼴 비화 케미',
        ElementRelation.clash => '서로 다듬어 주는 상극 케미',
      };

  String get relationLabel => switch (relation) {
        ElementRelation.harmony => '상생',
        ElementRelation.same => '비화',
        ElementRelation.clash => '상극',
      };

  /// 누가 누구를 살리는지 / 다듬는지 한 줄 ("민서의 보석 기운이 지우의 물결 기운을 살려요")
  String get direction {
    final pa = personas[a.dominant]!.name, pb = personas[b.dominant]!.name;
    final na = _given(a.name), nb = _given(b.name);
    if (relation == ElementRelation.same) return '${waGwa(na)} $nb 모두 $pa이에요';
    if (generates(a.dominant, b.dominant)) return '$na의 $pa이 $nb의 $pb을 살려요';
    if (generates(b.dominant, a.dominant)) return '$nb의 $pb이 $na의 $pa을 살려요';
    if (controls(a.dominant, b.dominant)) return '$na의 $pa이 $nb의 $pb을 다듬어요';
    return '$nb의 $pb이 $na의 $pa을 다듬어요';
  }

  List<String> get tags => [
        score >= 90 ? '#찰떡케미' : score >= 80 ? '#좋은케미' : '#알아가는케미',
        '#$relationLabel',
      ];

  /// 케미 올리는 법: 기운 관계에 맞는 한 가지 + 두 이름 모두에 없는 오행 채우기 (최대 3개)
  List<Improve> get improves {
    final na = _given(a.name), nb = _given(b.name);
    final rel = switch (relation) {
      ElementRelation.clash => Improve('다듬으려다 잔소리가 되기 쉬운 사이',
          '고쳐 주고 싶은 말은 "~해 줄래?" 부탁으로 바꿔 보세요. 같은 말도 명령이 아니라 부탁이면 다르게 들려요.'),
      ElementRelation.same => Improve('닮아서 같은 걸 함께 놓치는 사이',
          '둘 다 잘 못하는 일을 하나 정해 외부 도움(앱·알람·친구)을 빌려 보세요. 닮은 둘에게 없는 걸 채우는 게 핵심이에요.'),
      ElementRelation.harmony => Improve('한쪽만 계속 주는 흐름',
          '${generates(a.dominant, b.dominant) ? nb : na}도 받은 만큼 표현해 주세요. 살려 주는 쪽이 지치지 않게 "덕분이야" 한마디가 힘이 돼요.'),
    };
    final have = {...a.syllables.map((s) => s.$2), ...b.syllables.map((s) => s.$2)};
    final missing = [for (final e in elements) if (!have.contains(e)) elementActions[e]!];
    return [rel, ...missing].take(3).toList();
  }
}

/// 성을 뺀 이름 (3글자 이상이면 앞 한 글자를 성으로 본다). 조사가 붙는 자리에 쓴다.
String _given(String full) => full.characters.length >= 3 ? full.characters.skip(1).join() : full;

NameChemi nameChemi(String nameA, String nameB) {
  if (!isHangulName(nameA) || !isHangulName(nameB)) {
    throw ArgumentError('이름은 한글 2~4글자: $nameA, $nameB');
  }
  final a = NameReading.of(nameA), b = NameReading.of(nameB);
  final rel = relationOf(a.dominant, b.dominant);
  final relPoints = switch (rel) {
    ElementRelation.harmony => 22,
    ElementRelation.same => 14,
    ElementRelation.clash => 6,
  };
  final union = {...a.syllables.map((s) => s.$2), ...b.syllables.map((s) => s.$2)}.length;
  final variety = const {1: 0, 2: 3, 3: 7, 4: 11, 5: 15}[union]!;
  final flow = (a.harmonyLinks + b.harmonyLinks).clamp(0, 3);

  final aSet = a.syllables.map((s) => s.$2).toSet(), bSet = b.syllables.map((s) => s.$2).toSet();
  final aGets = [for (final e in elements) if (!aSet.contains(e) && bSet.contains(e)) e];
  final bGets = [for (final e in elements) if (!bSet.contains(e) && aSet.contains(e)) e];

  return NameChemi(
    a: a,
    b: b,
    relation: rel,
    score: NameChemi.base + relPoints + variety + flow,
    parts: [
      NameChemiPart('대표 기운', relPoints, 22,
          '${personas[a.dominant]!.name} × ${personas[b.dominant]!.name}, ${switch (rel) {
            ElementRelation.harmony => '서로 살려 주는 사이',
            ElementRelation.same => '닮은 기운',
            ElementRelation.clash => '서로 다듬는 사이',
          }}'),
      NameChemiPart('오행 다양성', variety, 15, '두 이름을 합치면 오행 다섯 가지 중 $union가지'),
      NameChemiPart('소리 흐름', flow, 3, '글자 소리가 상생으로 이어진 곳 ${a.harmonyLinks + b.harmonyLinks}군데 (한 곳에 1점, 최대 3점)'),
    ],
    pairText: _pairTexts[_pairKey(a.dominant, b.dominant)]!,
    aGetsFromB: aGets,
    bGetsFromA: bGets,
  );
}
