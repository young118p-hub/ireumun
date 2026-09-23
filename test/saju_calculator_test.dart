// 사주 계산기 테스트
// - 절기 경계: 절입일에 출생 시각을 반영하는지 (2026-09 버그 수정)
// - 회귀: 절입일이 아닌 날은 수정 전 코드와 결과가 같아야 한다 (알고리즘 변경 금지)
//   아래 표는 수정 전 코드로 뽑은 값이다.

import 'package:flutter_test/flutter_test.dart';
import 'package:ireumun/data/services/saju_calculator.dart';

String pillars(SajuResult r) => '${r.yearPillar} ${r.monthPillar} ${r.dayPillar} ${r.hourPillar}';

SajuResult calc(int y, int m, int d, int h) =>
    SajuCalculator.calculate(year: y, month: m, day: d, hour: h);

void main() {
  group('절기 경계 (한국천문연구원 절입 시각 기준)', () {
    // 2021 입춘 2021-02-03 23:59 KST
    test('2021 입춘 당일 입춘 전 출생은 전년도(경자년) 축월', () {
      expect(calc(2021, 2, 3, 10).yearPillar, '경자');
      expect(calc(2021, 2, 3, 10).monthPillar, '기축');
      expect(calc(2021, 2, 3, 23).yearPillar, '경자');
    });
    test('2021 입춘 다음날 출생은 신축년 인월', () {
      expect(calc(2021, 2, 4, 0).yearPillar, '신축');
      expect(calc(2021, 2, 4, 0).monthPillar, '경인');
    });

    // 2024 입춘 2024-02-04 17:27 KST
    test('2024 입춘 당일, 입춘 전후로 연주·월주가 갈린다', () {
      expect('${calc(2024, 2, 4, 10).yearPillar} ${calc(2024, 2, 4, 10).monthPillar}', '계묘 을축');
      expect('${calc(2024, 2, 4, 18).yearPillar} ${calc(2024, 2, 4, 18).monthPillar}', '갑진 병인');
    });

    // 2023 입춘 2023-02-04 11:43 KST
    test('2023 입춘 당일', () {
      expect(calc(2023, 2, 4, 10).yearPillar, '임인');
      expect(calc(2023, 2, 4, 12).yearPillar, '계묘');
    });

    // 2024 경칩 2024-03-05 11:23 KST
    test('2024 경칩 당일, 경칩 전후로 월주가 갈린다', () {
      expect(calc(2024, 3, 5, 9).monthPillar, '병인');
      expect(calc(2024, 3, 5, 13).monthPillar, '정묘');
    });

    test('연주와 월주가 어긋난 조합(예: 신축년 신축월)이 나오지 않는다', () {
      for (final h in [-1, 0, 6, 12, 18, 23]) {
        final r = calc(2021, 2, 3, h);
        // 축월의 천간은 연간을 따른다: 경자년 축월 = 기축
        if (r.yearPillar == '경자') expect(r.monthPillar, '기축');
        if (r.yearPillar == '신축') expect(r.monthPillar, '경인');
      }
    });
  });

  test('기준값: 2000-01-01은 기묘년 병자월 무오일', () {
    expect(pillars(calc(2000, 1, 1, 12)), '기묘 병자 무오 무오');
  });

  test('시간 미상이면 시주는 미상, 오행은 6글자로 센다', () {
    final r = calc(1990, 5, 15, -1);
    expect(r.hourPillar, '미상');
    expect(r.ohengBalance.values.fold<int>(0, (a, b) => a + b), 6);
  });

  group('회귀: 절입일이 아닌 날은 수정 전과 같다', () {
    const cases = [
      (1950, 11, 12, 23, '경인 정해 신해 무자', '금', false),
      (1931, 3, 23, 15, '신미 신묘 정축 무신', '목', false),
      (2029, 2, 17, 10, '기유 병인 무인 정사', '금', true),
      (1996, 3, 18, 3, '병자 신묘 갑인 병인', '금', true),
      (1965, 8, 26, 15, '을사 갑신 임자 무신', '토', true),
      (1976, 1, 24, 20, '을묘 기축 을해 병술', '금', true),
      (1952, 1, 20, 6, '신묘 신축 을축 기묘', '목', false),
      (1988, 6, 27, 17, '무진 무오 계축 신유', '금', false),
      (1963, 2, 15, 10, '계묘 갑인 기축 기사', '토', false),
      (1937, 7, 19, 14, '정축 정미 정미 정미', '화', false),
      (1987, 7, 24, 21, '정묘 정미 갑술 을해', '금', true),
      (1966, 10, 19, 5, '병오 무술 신해 신묘', '수', true),
      (1999, 12, 18, 0, '기묘 병자 갑진 갑자', '금', true),
      (1976, 12, 27, 18, '병진 경자 계축 신유', '목', true),
      (2021, 3, 21, 11, '신축 신묘 무진 무오', '목', true),
      (1951, 11, 10, 12, '신묘 기해 갑인 경오', '화', true),
      (1961, 10, 30, 22, '신축 무술 병신 기해', '목', false),
      (2004, 11, 17, -1, '갑신 을해 경자 미상', '금', false),
      (1939, 10, 21, 12, '기묘 갑술 신묘 갑오', '수', true),
      (2028, 1, 20, 2, '정미 계축 갑진 을축', '금', true),
      (1972, 4, 21, 6, '임자 갑진 임오 계묘', '수', false),
      (1959, 9, 19, 23, '기해 계유 갑진 갑자', '화', true),
      (1987, 11, 25, 23, '정묘 신해 무인 임자', '화', false),
      (1960, 9, 23, 12, '경자 을유 갑인 경오', '목', false),
      (1935, 7, 1, 12, '을해 임오 무인 무오', '금', true),
      (2001, 12, 28, 18, '신사 경자 을축 을유', '목', false),
      (1948, 1, 15, 18, '정해 계축 기해 계유', '목', true),
      (1999, 11, 1, 6, '기묘 갑술 정사 계묘', '수', true),
      (1969, 2, 20, 5, '기유 병인 병인 신묘', '수', true),
      (1935, 2, 13, 6, '을해 무인 경신 기묘', '화', true),
      (1968, 2, 12, 19, '무신 갑인 임자 경술', '수', false),
      (2008, 9, 14, 18, '무자 신유 정사 기유', '화', false),
      (1992, 7, 27, 4, '임신 정미 갑진 병인', '목', false),
      (1937, 6, 19, 10, '정축 병오 정축 을사', '수', true),
      (1971, 4, 22, 6, '신해 임진 정축 계묘', '목', false),
      (2028, 10, 14, 20, '무신 임술 임신 경술', '목', true),
      (1980, 5, 18, 5, '경신 신사 신묘 신묘', '수', true),
      (1997, 2, 24, 7, '정축 임인 정유 갑진', '수', true),
      (2006, 5, 21, 17, '병술 계사 경술 을유', '금', false),
      (1973, 3, 28, 11, '계축 을묘 계해 무오', '수', false),
    ];
    for (final (y, m, d, h, p, yongsin, strong) in cases) {
      test('$y-$m-$d ${h}h', () {
        final r = calc(y, m, d, h);
        expect(pillars(r), p);
        expect(r.yongsin, yongsin);
        expect(r.isDayMasterStrong, strong);
      });
    }
  });
}
