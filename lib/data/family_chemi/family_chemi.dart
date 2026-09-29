// 가족 케미: 3~5명 가족의 사주로 보는 케미 (무료로 보이는 부분은 전부 이 규칙, AI 없음)
// - 두 사람씩 모든 조합을 우리 케미 규칙(pairChemi, 관계: 가족)으로 계산
// - 가족 점수 = 두 사람 점수 평균 × 0.85 + 가족 오행 보너스(가족이 가진 오행 가짓수 5→15, 4→11, 3→7, 2→3, 1→0), 최대 99
//   → 두 사람씩 잘 맞는 것 + 가족이 모여 오행을 고루 갖췄는지를 함께 본다
// - 가족 안 역할: 각자 일간 오행 (목 새싹 / 화 햇살 / 토 기둥 / 금 정리 / 수 지혜)
// - 우리 가족 중 누가?: 그 오행이 가장 많은 사람. 같으면 일간 음양, 그래도 같으면 공동 1위
// - 케미 올리는 법: 가장 약한 두 사람의 약한 항목 + 가족에게 없는(가장 적은) 오행 채우기

import '../../core/constants/saju_constants.dart';
import '../chemi_common/improve.dart';
import '../pair_chemi/pair_chemi.dart';

export '../chemi_common/improve.dart' show Improve;
export '../chemi_common/who.dart' show WhoAnswer;

enum FamilyRole {
  me('나'),
  mom('엄마'),
  dad('아빠'),
  sibling('형제·자매'),
  child('자녀'),
  spouse('배우자'),
  other('가족');

  const FamilyRole(this.label);
  final String label;
}

class FamilyMember {
  final FamilyRole role;
  final PairPerson person;
  const FamilyMember(this.role, this.person);

  String get name => person.name;
  String get element => SajuConstants.cheonganToOheng[person.saju.dayPillar[0]]!;
}

/// 두 사람씩 본 케미
class FamilyPair {
  final int i;
  final int j;
  final PairChemi chemi;
  const FamilyPair(this.i, this.j, this.chemi);
}

/// 가족 안 역할 (일간 오행)
class FamilyPosition {
  final String title; // 새싹 담당
  final String text;
  const FamilyPosition(this.title, this.text);
}

const familyPositions = {
  '목': FamilyPosition('새싹 담당', '가족에게 새 바람을 불어넣어요. 새 취미, 새 계획, "우리 이거 해 보자"는 대부분 이 사람에게서 시작돼요.'),
  '화': FamilyPosition('햇살 담당', '집안 분위기를 데우는 사람이에요. 이 사람이 조용하면 집 전체가 조용해져요.'),
  '토': FamilyPosition('기둥 담당', '흔들릴 때 가족의 중심을 잡아요. 말없이 챙기는 일이 많아서, 고맙다는 말을 들으면 크게 힘이 나요.'),
  '금': FamilyPosition('정리 담당', '결정할 때 기준을 세워요. 돈·일정·규칙처럼 누군가는 해야 하는 일을 똑 부러지게 맡아요.'),
  '수': FamilyPosition('지혜 담당', '가족의 속마음을 가장 먼저 알아채요. 다툼이 생기면 조용히 사이를 이어 주는 사람이에요.'),
};

/// 우리 가족 중 누가? (질문, 오행, 양 일간이 더 그런지)
const familyWhoQuestions = [
  ('집안 분위기 메이커', '화', true),
  ('가족 여행 계획을 짜는 사람', '토', true),
  ('돈 관리·가계부를 챙기는 사람', '금', false),
  ('새로운 맛집을 찾아오는 사람', '목', true),
  ('싸우면 중간에서 풀어 주는 사람', '수', false),
];

/// 가족 모두에게 없는 오행을 함께 채우는 행동
const familyElementActions = {
  '목': Improve('새싹(목) 기운 채우기', '가족이 다 같이 처음 해 보는 걸 하나 정해 보세요. 캠핑, 원데이 클래스, 새 동네 산책처럼 "처음"이 목 기운을 채워요.'),
  '화': Improve('햇살(화) 기운 채우기', '가족 단톡방에 하루 한 번 사진이나 "오늘 고마웠어"를 올려 보세요. 표현이 늘면 집안 온도가 올라가요.'),
  '토': Improve('기둥(토) 기운 채우기', '가족만의 고정 약속을 만들어 보세요. 한 달에 한 번 같은 날 같이 밥 먹기처럼 작은 루틴이 중심을 잡아 줘요.'),
  '금': Improve('정리(금) 기운 채우기', '집안일·용돈·연락 규칙을 한 번 글로 정리해 보세요. 기준이 생기면 같은 일로 다투는 일이 줄어요.'),
  '수': Improve('지혜(수) 기운 채우기', '휴대폰 없이 이야기하는 시간을 만들어 보세요. 저녁 산책 20분이면 서로 속마음을 듣기에 충분해요.'),
};

class FamilyChemi {
  final List<FamilyMember> members;
  final List<FamilyPair> pairs;
  final int score;
  final int pairAverage; // 두 사람 점수 평균 (반올림)
  final Map<String, int> oheng; // 가족 전체 오행 개수
  final int bonus; // 가족 오행 보너스
  final List<Improve> improves;
  final List<WhoAnswer> who;

  const FamilyChemi({
    required this.members,
    required this.pairs,
    required this.score,
    required this.pairAverage,
    required this.oheng,
    required this.bonus,
    required this.improves,
    required this.who,
  });

  static const elements = ['목', '화', '토', '금', '수'];

  int get coverage => elements.where((e) => (oheng[e] ?? 0) > 0).length;
  List<String> get missing => [
    for (final e in elements)
      if ((oheng[e] ?? 0) == 0) e,
  ];

  FamilyPair get best => pairs.reduce((x, y) => y.chemi.score > x.chemi.score ? y : x);
  FamilyPair get worst => pairs.reduce((x, y) => y.chemi.score < x.chemi.score ? y : x);

  bool get allHoursKnown => members.every((m) => m.person.hourKnown);

  String get accuracy => allHoursKnown ? '가족 모두 여덟 글자로 봤어요' : '태어난 시간을 모르는 가족이 있어서 그 사람의 시주는 빼고 봤어요';

  String get title {
    if (score >= 88) return '서로를 꽉 채우는 드림팀 가족';
    if (score >= 80) return '따로 또 같이 잘 굴러가는 가족';
    if (score >= 70) return '티격태격해도 결국 한 팀인 가족';
    return '맞춰 갈수록 단단해지는 가족';
  }

  List<String> get tags => [
    score >= 88
        ? '#드림팀가족'
        : score >= 80
        ? '#좋은케미가족'
        : '#알아가는가족',
    '#오행$coverage가지',
  ];

  String get scoreBasis => '두 사람씩 본 케미 평균 $pairAverage점 × 0.85 + 가족 오행 $coverage가지 보너스 $bonus점';
}

const _coverageBonus = [0, 0, 3, 7, 11, 15]; // 가족이 가진 오행 가짓수 → 보너스

FamilyChemi familyChemi(List<FamilyMember> members) {
  assert(members.length >= 2);
  final pairs = [
    for (var i = 0; i < members.length; i++)
      for (var j = i + 1; j < members.length; j++)
        FamilyPair(i, j, pairChemi(members[i].person, members[j].person, relation: PairRelation.family)),
  ];
  final sum = pairs.fold<int>(0, (s, p) => s + p.chemi.score);
  final avg = sum / pairs.length;
  final oheng = {
    for (final e in FamilyChemi.elements) e: members.fold<int>(0, (s, m) => s + (m.person.saju.ohengBalance[e] ?? 0)),
  };
  final coverage = FamilyChemi.elements.where((e) => oheng[e]! > 0).length;
  final bonus = _coverageBonus[coverage];
  final raw = (avg * 0.85 + bonus).round();

  final draft = FamilyChemi(
    members: members,
    pairs: pairs,
    score: raw > 99 ? 99 : raw,
    pairAverage: avg.round(),
    oheng: oheng,
    bonus: bonus,
    improves: const [],
    who: const [],
  );
  return FamilyChemi(
    members: members,
    pairs: pairs,
    score: draft.score,
    pairAverage: draft.pairAverage,
    oheng: oheng,
    bonus: bonus,
    improves: _familyImproves(draft),
    who: familyWho(members),
  );
}

/// 가장 약한 두 사람의 약한 항목(최대 2개, 누구 이야기인지 붙여서) + 가족에게 가장 적은 오행 채우기
List<Improve> _familyImproves(FamilyChemi f) {
  final out = <Improve>[];
  final w = f.worst.chemi;
  if (w.score < 80) {
    for (final i in w.improves.where((i) => i != keepGoing).take(2)) {
      out.add(Improve('${w.a.name}·${w.b.name}: ${i.title}', i.action));
    }
  }
  final least = FamilyChemi.elements.reduce((x, y) => (f.oheng[y] ?? 0) < (f.oheng[x] ?? 0) ? y : x);
  if ((f.oheng[least] ?? 0) <= 1) out.add(familyElementActions[least]!);
  return out.isEmpty ? [keepGoing] : out;
}

/// 우리 가족 중 누가? 그 오행이 가장 많은 사람. 같으면 일간 음양, 그래도 같으면 공동.
List<WhoAnswer> familyWho(List<FamilyMember> members) {
  return [
    for (final (q, el, preferYang) in familyWhoQuestions)
      () {
        int count(FamilyMember m) => m.person.saju.ohengBalance[el] ?? 0;
        final top = members.map(count).reduce((x, y) => x > y ? x : y);
        var lead = members.where((m) => count(m) == top).toList();
        final hanja = elementHanjaOf(el);
        if (lead.length == 1) {
          final second = members.where((m) => m != lead.first).map(count).reduce((x, y) => x > y ? x : y);
          return WhoAnswer(q, lead.first.name, '$el($hanja) 기운 ${lead.first.name} $top개, 다음은 $second개');
        }
        final yang = lead.where((m) => (m.person.dayStem % 2 == 0) == preferYang).toList();
        if (yang.length == 1) {
          return WhoAnswer(
            q,
            yang.first.name,
            '$el($hanja) 기운은 ${lead.map((m) => m.name).join('·')} $top개로 같고, ${yang.first.name}의 일간이 ${preferYang ? '양(陽)이라 조금 더 적극적' : '음(陰)이라 조금 더 부드러운 편'}',
          );
        }
        if (yang.length > 1) lead = yang;
        return WhoAnswer(q, null, '${lead.map((m) => m.name).join('·')} 모두 $el($hanja) 기운 $top개. 공동 1위!');
      }(),
  ];
}

String elementHanjaOf(String el) => const {'목': '木', '화': '火', '토': '土', '금': '金', '수': '水'}[el]!;
