// MBTI 케미 규칙표 (서버·AI 없음, 무료)
// 네 축(E/I, S/N, T/F, J/P)마다 두 사람이 같은지 다른지로 점수와 문구를 정한다.
// - 같은 조합이면 항상 같은 결과. A×B와 B×A는 점수·제목이 같다 (랜덤 없음).
// - 점수는 64~98. 재미로 보는 궁합이라 낮게 깎지 않는다.
// - 문구의 "{E}" 같은 자리는 그 글자를 가진 쪽 유형으로 채운다. MBTI는 J/P로 끝나서
//   뒤에 오는 조사는 늘 모음 뒤 형태(가/는/를/의)다.

const mbtiTypes = [
  'INTJ', 'INTP', 'ENTJ', 'ENTP',
  'INFJ', 'INFP', 'ENFJ', 'ENFP',
  'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
  'ISTP', 'ISFP', 'ESTP', 'ESFP',
];

bool isMbti(String t) => mbtiTypes.contains(t);

/// 축: 글자 위치와 두 글자
enum _Axis {
  ei(0, 'E', 'I'),
  ns(1, 'N', 'S'),
  tf(2, 'T', 'F'),
  jp(3, 'J', 'P');

  const _Axis(this.pos, this.a, this.b);
  final int pos;
  final String a;
  final String b;
}

class MbtiChemi {
  final String me;
  final String you;
  final int score;
  final String title;
  final String strength;
  final String clash;
  final String tip;

  const MbtiChemi({
    required this.me,
    required this.you,
    required this.score,
    required this.title,
    required this.strength,
    required this.clash,
    required this.tip,
  });

  /// 공유 카드용 해시태그 (점수 구간 + 조합 성격)
  List<String> get tags => [
        score >= 90 ? '#찰떡케미' : score >= 80 ? '#좋은케미' : '#알아가는케미',
        '#$me×$you',
      ];
}

// 점수: 기본 40 + 축별 가산. 소통 방식(N/S)이 같을 때 가장 크게 올린다.
const _base = 40;
const _add = {
  _Axis.ns: (same: 25, diff: 0),
  _Axis.ei: (same: 8, diff: 13),
  _Axis.tf: (same: 10, diff: 8),
  _Axis.jp: (same: 8, diff: 10),
};

// 제목: 축 관계(같음 S / 다름 D)를 N/S, E/I, T/F, J/P 순서로 이은 키
const _titles = {
  'SSSS': '거울 보는 듯한 쌍둥이 케미',
  'SSSD': '생각은 같고 속도만 다른 사이',
  'SSDS': '같은 그림, 다른 온도',
  'SSDD': '통하지만 방식은 정반대',
  'SDSS': '말 잘 통하는 밀당 콤비',
  'SDSD': '서로의 빈칸을 채우는 짝꿍',
  'SDDS': '대화가 끝나지 않는 조합',
  'SDDD': '정반대라 끌리는 조합',
  'DSSS': '같은 속도, 다른 세상',
  'DSSD': '현실과 상상을 오가는 사이',
  'DSDS': '알아 가는 재미가 있는 사이',
  'DSDD': '배울 게 많은 낯선 조합',
  'DDSS': '안 맞을 것 같은데 은근 맞음',
  'DDSD': '케미는 노력으로 만드는 것',
  'DDDS': '다른 행성에서 온 둘',
  'DDDD': '모든 게 반대, 그래서 궁금한 사이',
};

// 잘 맞는 점: 우선순위대로 처음 해당하는 것 하나
// (축, 같음?, 같을 때 그 글자(null=상관없음), 문구)
const _strengths = <(_Axis, bool, String?, String)>[
  (_Axis.ns, true, 'N', "둘 다 N이라 상상과 '만약에' 이야기로 밤새 대화할 수 있어요."),
  (_Axis.ns, true, 'S', '둘 다 S라 현실 감각이 비슷해서 계획이 척척 맞아요.'),
  (_Axis.ei, false, null, '{E}가 분위기를 띄우고 {I}가 깊이를 더해요. 서로의 에너지를 채워 주는 사이.'),
  (_Axis.jp, false, null, '{J}가 계획을 세우고 {P}가 유연하게 채워서 일이 굴러가요.'),
  (_Axis.tf, true, 'T', '둘 다 T라 문제가 생기면 감정 소모 없이 해결책부터 찾아요.'),
  (_Axis.tf, true, 'F', '둘 다 F라 서로의 기분을 금방 알아채요.'),
  (_Axis.tf, false, null, '{T}의 판단과 {F}의 공감이 만나면 균형 잡힌 결정이 나와요.'),
  (_Axis.ei, true, 'E', '둘 다 E라 같이 있으면 심심할 틈이 없어요.'),
  (_Axis.ei, true, 'I', '둘 다 I라 조용히 같이 있어도 편한 사이예요.'),
  (_Axis.jp, true, 'J', '둘 다 J라 약속과 계획이 어긋날 일이 적어요.'),
  (_Axis.jp, true, 'P', '둘 다 P라 즉흥 여행도 즐겁게 떠나요.'),
  (_Axis.ns, false, null, '{N}의 아이디어를 {S}가 현실로 만들어요.'),
];

// 부딪히는 순간 + 그에 맞는 꿀팁: 우선순위대로 처음 해당하는 것 하나
const _clashes = <(_Axis, bool, String?, String, String)>[
  (_Axis.tf, false, null, '결론부터 말하는 {T}의 말투가 {F}에게는 차갑게 들릴 수 있어요.', "피드백 전에 '네 생각 좋아' 한마디부터."),
  (_Axis.ns, false, null, "{N}는 큰 그림, {S}는 구체적인 것부터 봐서 대화가 엇갈릴 수 있어요.", "{N}는 예시를 들어 말하고, {S}는 '그럼 어떻게 될까?'를 같이 상상해 주기."),
  (_Axis.ei, false, null, '{E}는 만나서 풀고 싶고, {I}는 혼자 정리할 시간이 필요해요.', "{I}가 '생각할 시간 줘'라고 하면 {E}는 기다려 주기."),
  (_Axis.jp, false, null, '{J}는 미리 정하고 싶고, {P}는 그때 가서 정하고 싶어요.', '큰 일정은 {J}가, 세부는 {P}가 정하기.'),
  (_Axis.ei, true, 'E', '둘 다 말하고 싶어서 들어 주는 사람이 없을 때가 있어요.', '번갈아 말하기 규칙 하나면 충분해요.'),
  (_Axis.ei, true, 'I', '둘 다 먼저 연락을 안 해서 거리가 생길 수 있어요.', '연락 담당 요일을 정해 보세요.'),
  (_Axis.tf, true, 'T', '논리로 부딪히면 둘 다 끝까지 안 져요.', '이기는 것보다 맞추는 게 목표라고 서로 말해 두기.'),
  (_Axis.tf, true, 'F', '상처 줄까 봐 말을 아끼다 서운함이 쌓일 수 있어요.', '서운한 건 그날 바로 말하기.'),
  (_Axis.jp, true, 'J', '둘 다 자기 계획이 맞다고 할 때 부딪혀요.', '계획이 부딪히면 가위바위보로 가볍게.'),
  (_Axis.jp, true, 'P', '둘 다 미루다 마감이 코앞에 올 수 있어요.', '마감 하루 전 알람을 같이 맞춰 두기.'),
  (_Axis.ns, true, 'N', '상상만 하다 실천이 늦어질 수 있어요.', '상상한 것 중 하나는 이번 주에 해 보기.'),
  (_Axis.ns, true, 'S', '익숙한 것만 하다 새로운 시도를 서로 미룰 수 있어요.', '한 달에 한 번은 처음 해 보는 것 하기.'),
];

MbtiChemi mbtiChemi(String me, String you) {
  if (!isMbti(me) || !isMbti(you)) {
    throw ArgumentError('MBTI 유형이 아니에요: $me, $you');
  }
  bool same(_Axis a) => me[a.pos] == you[a.pos];

  var score = _base;
  for (final a in _Axis.values) {
    score += same(a) ? _add[a]!.same : _add[a]!.diff;
  }

  final key = [_Axis.ns, _Axis.ei, _Axis.tf, _Axis.jp].map((a) => same(a) ? 'S' : 'D').join();

  // {E}, {I} … 자리를 그 글자를 가진 쪽 유형으로
  String fill(String text) {
    var out = text;
    for (final a in _Axis.values) {
      for (final letter in [a.a, a.b]) {
        final owner = me[a.pos] == letter ? me : you;
        out = out.replaceAll('{$letter}', owner);
      }
    }
    return out;
  }

  bool matches(_Axis axis, bool wantSame, String? letter) =>
      same(axis) == wantSame && (letter == null || me[axis.pos] == letter);

  final strength = _strengths.firstWhere((s) => matches(s.$1, s.$2, s.$3));
  final clash = _clashes.firstWhere((c) => matches(c.$1, c.$2, c.$3));

  return MbtiChemi(
    me: me,
    you: you,
    score: score,
    title: _titles[key]!,
    strength: fill(strength.$4),
    clash: fill(clash.$4),
    tip: fill(clash.$5),
  );
}
