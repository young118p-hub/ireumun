import 'package:flutter_test/flutter_test.dart';
import 'package:chemilab/data/name_chemi/name_chemi.dart';

void main() {
  test('초성으로 소리 오행: ㄱㅋ 목 / ㄴㄷㄹㅌ 화 / ㅇㅎ 토 / ㅅㅈㅊ 금 / ㅁㅂㅍ 수', () {
    expect(['가', '카', '까'].map(soundElement), ['목', '목', '목']);
    expect(['나', '다', '라', '타'].map(soundElement), ['화', '화', '화', '화']);
    expect(['아', '하'].map(soundElement), ['토', '토']);
    expect(['사', '자', '차', '싸'].map(soundElement), ['금', '금', '금', '금']);
    expect(['마', '바', '파'].map(soundElement), ['수', '수', '수']);
    expect(soundElement('A'), isNull);
  });

  test('김민서 = 목·수·금, 대표 기운은 이름 첫 글자(민=수)', () {
    final r = NameReading.of('김민서');
    expect(r.syllables.map((s) => s.$2), ['목', '수', '금']);
    expect(r.dominant, '수');
    expect(r.harmonyLinks, 2); // 목-수(수생목), 수-금(금생수)
    expect(r.hasClash, isFalse);
  });

  test('순서를 바꿔도 같은 점수·관계, 점수 근거를 더하면 점수', () {
    const names = ['김민서', '이지우', '박하늘', '최도윤', '정서연', '한소희', '오태양', '남궁민수'];
    for (final x in names) {
      for (final y in names) {
        final ab = nameChemi(x, y), ba = nameChemi(y, x);
        expect(ba.score, ab.score, reason: '$x×$y');
        expect(ba.relation, ab.relation);
        expect(ab.score, inInclusiveRange(64, 98));
        expect(NameChemi.base + ab.parts.fold<int>(0, (s, p) => s + p.points), ab.score);
        expect(ab.pairText, isNotEmpty);
        expect(ab.direction, isNotEmpty);
      }
    }
  });

  test('상생·상극 방향과 조사', () {
    expect(generates('금', '수'), isTrue);
    expect(controls('목', '토'), isTrue);
    // 서연(정·서 금, 연 토 → 금) × 수진(조·수·진 모두 금): 둘 다 보석 기운
    expect(nameChemi('정서연', '조수진').relation, ElementRelation.same);
    expect(nameChemi('정서연', '조수진').direction, '서연과 수진 모두 보석 기운이에요');
    // 지우(이·우 토, 지 금 → 토)가 서연(금)을 살림: 토생금
    expect(nameChemi('정서연', '이지우').relation, ElementRelation.harmony);
    expect(nameChemi('김민서', '정서연').direction, '서연의 보석 기운이 민서의 물결 기운을 살려요');
  });

  test('한글 2~4글자가 아니면 거절', () {
    expect(() => nameChemi('Min', '이지우'), throwsArgumentError);
    expect(() => nameChemi('김', '이지우'), throwsArgumentError);
  });
}
