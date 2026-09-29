import 'package:flutter_test/flutter_test.dart';
import 'package:chemilab/core/constants/saju_constants.dart';
import 'package:chemilab/data/pair_chemi/pair_chemi.dart';
import 'package:chemilab/data/services/saju_calculator.dart';

PairPerson person(String name, int y, int m, int d, [int hour = -1]) => PairPerson(
      name: name,
      saju: SajuCalculator.calculate(year: y, month: m, day: d, hour: hour),
      hourKnown: hour >= 0,
    );

int b(String jiji) => SajuConstants.jiji.indexOf(jiji);

void main() {
  test('지지 관계: 육합·삼합·충·원진·형·해·같음', () {
    expect(branchRelation(b('자'), b('축')), BranchRel.harmony);
    expect(branchRelation(b('인'), b('해')), BranchRel.harmony);
    expect(branchRelation(b('신'), b('진')), BranchRel.trine);
    expect(branchRelation(b('자'), b('오')), BranchRel.clash);
    expect(branchRelation(b('자'), b('미')), BranchRel.wonjin);
    expect(branchRelation(b('술'), b('미')), BranchRel.punish); // 키 순서 실수 방지
    expect(branchRelation(b('묘'), b('진')), BranchRel.harm);
    expect(branchRelation(b('오'), b('오')), BranchRel.punish); // 자형
    expect(branchRelation(b('자'), b('자')), BranchRel.same);
  });

  test('삼합 해설은 맞는 국으로 (신자진 = 수국, 사유축 = 금국)', () {
    expect(branchText(b('신'), b('자')), contains('물의 기운'));
    expect(branchText(b('사'), b('유')), contains('쇠의 기운'));
    expect(branchText(b('인'), b('술')), contains('불의 기운'));
    expect(branchText(b('해'), b('미')), contains('나무의 기운'));
  });

  test('모든 지지 쌍에 해설이 있고 자리표시가 남지 않는다', () {
    for (var x = 0; x < 12; x++) {
      for (var y = 0; y < 12; y++) {
        final t = branchText(x, y);
        expect(t, isNotEmpty);
        expect(t.contains('{'), isFalse);
      }
    }
  });

  test('받침 있는 띠도 조사가 맞다 (용이에요, 뱀은)', () {
    expect(branchText(b('자'), b('자')), startsWith('둘 다 쥐예요'));
    expect(branchText(b('축'), b('축')), startsWith('둘 다 소예요'));
    expect(branchText(b('자'), b('사')), contains('쥐와 뱀은'));
    expect(branchText(b('술'), b('해')), contains('개와 돼지는'));
  });

  test('십신: 갑 일간에게 신(辛)은 정관, 경은 편관, 기는 정재, 계는 정인', () {
    int s(String c) => SajuConstants.cheongan.indexOf(c);
    expect(tenGod(s('갑'), s('신')), '정관');
    expect(tenGod(s('갑'), s('경')), '편관');
    expect(tenGod(s('갑'), s('기')), '정재');
    expect(tenGod(s('갑'), s('계')), '정인');
    expect(tenGod(s('갑'), s('병')), '식신');
    expect(tenGod(s('갑'), s('을')), '겁재');
  });

  test('순서를 바꿔도 같은 점수, 점수 근거 합 = 점수, 범위 52~99', () {
    final people = [
      person('민서', 1998, 5, 11, 14),
      person('지우', 1997, 11, 3),
      person('하늘', 2001, 2, 4, 9),
      person('도윤', 1995, 8, 20, 23),
      person('서연', 1999, 12, 31),
      person('태양', 1990, 1, 1, 6),
    ];
    for (final x in people) {
      for (final y in people) {
        final ab = pairChemi(x, y), ba = pairChemi(y, x);
        expect(ba.score, ab.score, reason: '${x.name}×${y.name}');
        final sum = PairChemi.base + ab.parts.fold<int>(0, (s, p) => s + p.points);
        expect(ab.score, sum > 99 ? 99 : sum);
        expect(ab.score, inInclusiveRange(52, 99));
        for (final p in ab.parts) {
          expect(p.text, isNotEmpty);
          expect(p.text.contains('{'), isFalse);
        }
        expect(ab.tenGods.length, 2);
      }
    }
  });

  test('시간을 모르면 시주는 중간 점수(4)이고 정확도 안내', () {
    final c = pairChemi(person('민서', 1998, 5, 11), person('지우', 1997, 11, 3, 10));
    final hour = c.parts.firstWhere((p) => p.label == '시주 궁합');
    expect(hour.known, isFalse);
    expect(hour.points, 4);
    expect(c.bothHoursKnown, isFalse);
    expect(pairChemi(person('민서', 1998, 5, 11, 14), person('지우', 1997, 11, 3, 10)).bothHoursKnown, isTrue);
  });

  test('케미 올리는 법: 약한 항목부터 최대 3개, 없으면 지키는 법, 자리표시 없음', () {
    final people = [
      person('민서', 1998, 5, 11, 14), person('지우', 1997, 11, 3), person('하늘', 2001, 2, 4, 9),
      person('도윤', 1995, 8, 20, 23), person('서연', 1999, 12, 31), person('태양', 1990, 1, 1, 6),
    ];
    for (final x in people) {
      for (final y in people) {
        final c = pairChemi(x, y);
        expect(c.improves, isNotEmpty);
        expect(c.improves.length, lessThanOrEqualTo(3));
        for (final i in c.improves) {
          expect('${i.title}${i.action}'.contains('{'), isFalse);
        }
        // 약한 항목이 없을 때만 "지키기"
        final weak = c.parts.where((p) => p.known && p.points * 10 < p.max * 8);
        expect(c.improves.first.title == '지금 좋은 흐름 지키기', weak.isEmpty);
      }
    }
  });

  test('둘 중 누가: 다섯 문항, 이긴 쪽은 그 오행이 더 많거나 음양 규칙, 근거가 있다', () {
    final x = person('민서', 1998, 5, 11, 14), y = person('지우', 1997, 11, 3, 10);
    final c = pairChemi(x, y);
    expect(c.who.length, 5);
    for (final w in c.who) {
      expect(w.reason, isNotEmpty);
      expect(w.winner == null || w.winner == '민서' || w.winner == '지우', isTrue);
    }
    final fire = c.who.first; // 먼저 연락 = 화
    final fx = x.saju.ohengBalance['화']!, fy = y.saju.ohengBalance['화']!;
    if (fx != fy) expect(fire.winner, fx > fy ? '민서' : '지우');
  });

  test('나는 이런 사람: 일간 성격 + 기운 세기', () {
    final (name, symbol, text) = person('민서', 1998, 5, 11, 14).persona;
    expect(name, endsWith(')'));
    expect(symbol, isNotEmpty);
    expect(text, contains('기운이'));
  });

  test('관계(연인·친구·동료)는 말투만 바꾸고 점수는 같다', () {
    final x = person('민서', 1998, 5, 11, 14), y = person('지우', 1997, 11, 3, 8);
    final lover = pairChemi(x, y), friend = pairChemi(x, y, relation: PairRelation.friend);
    expect(friend.score, lover.score);
    expect(lover.parts[1].label, '배우자 자리(일지)');
    expect(friend.parts[1].label, '속마음 자리(일지)');
    expect(friend.title.endsWith('친구'), isTrue);
  });
}
