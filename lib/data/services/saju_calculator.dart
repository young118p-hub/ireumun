// 사주팔자 계산 엔진
// 양력 생년월일시 → 사주팔자 + 오행 분석 + 용신 도출
//
// 알고리즘:
//   - 일주: JDN(Julian Day Number) 기반 60갑자 인덱스
//   - 년주: (년-4)%60, 입춘(315°) 기준 연도 보정
//   - 월주: 태양 황경 기반 절기 월 판정 + 오호결월법
//   - 시주: 시간→지지 + 오자결시법
//   - 오행: 8글자(4천간+4지지) 오행 카운팅
//   - 용신: 일간 강약 판단 후 보충 오행 결정

import 'dart:math';
import '../../core/constants/saju_constants.dart';
import '../../core/constants/manseryeok_data.dart';

/// 사주팔자 계산 결과
class SajuResult {
  final String yearPillar;
  final String monthPillar;
  final String dayPillar;
  final String hourPillar;
  final String dayMaster;
  final String dayMasterOheng;
  final Map<String, int> ohengBalance;
  final String weakElement;
  final String strongElement;
  final String yongsin;
  final bool isDayMasterStrong;
  final String summary;

  const SajuResult({
    required this.yearPillar,
    required this.monthPillar,
    required this.dayPillar,
    required this.hourPillar,
    required this.dayMaster,
    required this.dayMasterOheng,
    required this.ohengBalance,
    required this.weakElement,
    required this.strongElement,
    required this.yongsin,
    required this.isDayMasterStrong,
    required this.summary,
  });

  /// 기존 SajuAnalysis JSON 형식으로 변환 (호환용)
  Map<String, dynamic> toSajuAnalysisJson() => {
        'yearPillar': yearPillar,
        'monthPillar': monthPillar,
        'dayPillar': dayPillar,
        'hourPillar': hourPillar,
        'dayMaster': dayMaster,
        'ohengBalance': ohengBalance,
        'weakElement': weakElement,
        'strongElement': strongElement,
        'summary': summary,
      };
}

/// 사주팔자 계산기
class SajuCalculator {
  SajuCalculator._();

  // ============================================================
  // 메인 계산 함수
  // ============================================================

  /// 양력 생년월일시 → 사주팔자 계산
  /// [hour]: 0-23, -1이면 시간 미상 (시주 제외)
  static SajuResult calculate({
    required int year,
    required int month,
    required int day,
    int hour = -1,
  }) {
    // 1. 일주 계산 (JDN 기반 - 가장 정확)
    final jdn = _julianDayNumber(year, month, day);
    final dayIdx = _dayGapjaIndex(jdn);
    final dayStem = dayIdx % 10;
    final dayBranch = dayIdx % 12;

    // 2. 년주 계산 (입춘 기준)
    final sajuYear = _getSajuYear(year, month, day);
    final yearIdx = ((sajuYear - 4) % 60 + 60) % 60;
    final yearStem = yearIdx % 10;
    final yearBranch = yearIdx % 12;

    // 3. 월주 계산 (절기 기준 + 오호결월법)
    final sajuMonth = _getSajuMonth(year, month, day);
    final monthStem = _monthStemIndex(yearStem, sajuMonth);
    final monthBranch = ManseryeokData.sajuMonthToJijiIndex(sajuMonth);

    // 4. 시주 계산 (오자결시법)
    int hourStem = -1;
    int hourBranch = -1;
    if (hour >= 0) {
      hourBranch = _hourToJijiIndex(hour);
      hourStem = _hourStemIndex(dayStem, hourBranch);
    }

    // 5. 사주 문자열 생성
    final yearPillar =
        '${SajuConstants.cheongan[yearStem]}${SajuConstants.jiji[yearBranch]}';
    final monthPillar =
        '${SajuConstants.cheongan[monthStem]}${SajuConstants.jiji[monthBranch]}';
    final dayPillar =
        '${SajuConstants.cheongan[dayStem]}${SajuConstants.jiji[dayBranch]}';
    final hourPillar = hour >= 0
        ? '${SajuConstants.cheongan[hourStem]}${SajuConstants.jiji[hourBranch]}'
        : '미상';

    // 6. 오행 분포 분석
    final ohengBalance = _analyzeOheng(
      yearStem: yearStem,
      yearBranch: yearBranch,
      monthStem: monthStem,
      monthBranch: monthBranch,
      dayStem: dayStem,
      dayBranch: dayBranch,
      hourStem: hourStem,
      hourBranch: hourBranch,
    );

    // 7. 부족/강한 오행 판별
    final dayMasterOheng =
        SajuConstants.cheonganToOheng[SajuConstants.cheongan[dayStem]]!;

    final sorted = ohengBalance.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final weakElement = sorted.first.key;
    final strongElement = sorted.last.key;

    // 8. 일간 강약 판단
    final isStrong = _isDayMasterStrong(
      dayMasterOheng: dayMasterOheng,
      ohengBalance: ohengBalance,
      monthBranch: monthBranch,
    );

    // 9. 용신 도출
    final yongsin = _deriveYongsin(
      dayMasterOheng: dayMasterOheng,
      ohengBalance: ohengBalance,
      isStrong: isStrong,
    );

    // 10. 요약 생성
    final summary = _generateSummary(
      dayMaster: SajuConstants.cheongan[dayStem],
      dayMasterOheng: dayMasterOheng,
      weakElement: weakElement,
      strongElement: strongElement,
      yongsin: yongsin,
      isStrong: isStrong,
    );

    return SajuResult(
      yearPillar: yearPillar,
      monthPillar: monthPillar,
      dayPillar: dayPillar,
      hourPillar: hourPillar,
      dayMaster: SajuConstants.cheongan[dayStem],
      dayMasterOheng: dayMasterOheng,
      ohengBalance: ohengBalance,
      weakElement: weakElement,
      strongElement: strongElement,
      yongsin: yongsin,
      isDayMasterStrong: isStrong,
      summary: summary,
    );
  }

  // ============================================================
  // JDN (Julian Day Number) 계산
  // ============================================================

  /// 그레고리력 날짜 → JDN (정수)
  static int _julianDayNumber(int year, int month, int day) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
  }

  /// JDN → 60갑자 일주 인덱스 (0=갑자, 1=을축, ..., 59=계해)
  static int _dayGapjaIndex(int jdn) {
    return (jdn + 49) % 60;
  }

  // ============================================================
  // 년주 계산
  // ============================================================

  /// 입춘 기준 사주 연도
  /// 입춘(양력 2/3~5일경) 이전이면 전년도
  static int _getSajuYear(int year, int month, int day) {
    if (month >= 3) return year;
    if (month == 1) return year - 1;

    // month == 2: 입춘 날짜와 비교
    final ipchunJDE = _findSolarTermJDE(year, ManseryeokData.ipchunLongitude);
    final ipchunDate = _jdeToDateTime(ipchunJDE);
    final birthDate = DateTime(year, month, day);

    return birthDate.isBefore(ipchunDate) ? year - 1 : year;
  }

  // ============================================================
  // 월주 계산
  // ============================================================

  /// 태양 황경 기반 사주 월 판정 (1=인월 ~ 12=축월)
  static int _getSajuMonth(int year, int month, int day) {
    final jdn = _julianDayNumber(year, month, day);
    final jde = jdn.toDouble();
    final sunLon = _solarLongitude(jde);

    // 태양 황경 구간 → 사주 월
    // 345°~15°(0° 통과): 묘월(2)
    if (sunLon >= 345.0 || sunLon < 15.0) return 2;
    if (sunLon >= 315.0) return 1; // 인월 (입춘~경칩)
    if (sunLon >= 285.0) return 12; // 축월 (소한~입춘)
    if (sunLon >= 255.0) return 11; // 자월 (대설~소한)
    if (sunLon >= 225.0) return 10; // 해월 (입동~대설)
    if (sunLon >= 195.0) return 9; // 술월 (한로~입동)
    if (sunLon >= 165.0) return 8; // 유월 (백로~한로)
    if (sunLon >= 135.0) return 7; // 신월 (입추~백로)
    if (sunLon >= 105.0) return 6; // 미월 (소서~입추)
    if (sunLon >= 75.0) return 5; // 오월 (망종~소서)
    if (sunLon >= 45.0) return 4; // 사월 (입하~망종)
    return 3; // 진월 (청명~입하)
  }

  /// 오호결월법(五虎訣月法) - 년간에 따른 월간 결정
  /// yearStem: 년주 천간 인덱스 (0=갑 ~ 9=계)
  /// sajuMonth: 사주 월 (1=인월 ~ 12=축월)
  static int _monthStemIndex(int yearStem, int sajuMonth) {
    // 갑(0)/기(5)년 → 1월 병(2), 을(1)/경(6)년 → 1월 무(4), ...
    final baseStem = ((yearStem % 5) * 2 + 2) % 10;
    return (baseStem + sajuMonth - 1) % 10;
  }

  // ============================================================
  // 시주 계산
  // ============================================================

  /// 시간(0-23) → 지지 인덱스
  static int _hourToJijiIndex(int hour) {
    // 자시(23~01)=0, 축시(01~03)=1, ..., 해시(21~23)=11
    if (hour == 23 || hour == 0) return 0; // 자
    return ((hour + 1) ~/ 2) % 12;
  }

  /// 오자결시법(五子訣時法) - 일간에 따른 시간 천간 결정
  static int _hourStemIndex(int dayStem, int hourBranch) {
    // 갑(0)/기(5)일 → 자시 갑(0), 을(1)/경(6)일 → 자시 병(2), ...
    final baseStem = (dayStem % 5) * 2;
    return (baseStem + hourBranch) % 10;
  }

  // ============================================================
  // 태양 황경 계산 (Jean Meeus 알고리즘)
  // ============================================================

  /// JDE → 태양의 겉보기 황경 (도, 0~360)
  /// 정확도: ~0.01° (약 15분 이내)
  static double _solarLongitude(double jde) {
    // 율리우스 세기 (J2000.0 기준)
    final T = (jde - 2451545.0) / 36525.0;

    // 태양 평균 황경
    final L0 = _normalize(280.46646 + 36000.76983 * T + 0.0003032 * T * T);

    // 태양 평균 근점이각
    final M = _normalize(357.52911 + 35999.05029 * T - 0.0001537 * T * T);
    final Mrad = M * pi / 180.0;

    // 중심차 (equation of center)
    final C = (1.914602 - 0.004817 * T - 0.000014 * T * T) * sin(Mrad) +
        (0.019993 - 0.000101 * T) * sin(2 * Mrad) +
        0.000289 * sin(3 * Mrad);

    // 태양 진황경
    final sunTrueLon = L0 + C;

    // 장동 + 광행차 보정
    final omega = 125.04 - 1934.136 * T;
    final omegaRad = omega * pi / 180.0;
    final apparentLon = sunTrueLon - 0.00569 - 0.00478 * sin(omegaRad);

    return _normalize(apparentLon);
  }

  /// 특정 연도에 태양이 목표 황경에 도달하는 JDE 계산
  /// Newton's method로 수렴 (3~5회 반복으로 충분)
  static double _findSolarTermJDE(int year, double targetLon) {
    // 근사 날짜에서 시작
    final approx = _approxDateForLongitude(year, targetLon);
    double jde = _julianDayNumber(approx[0], approx[1], approx[2]).toDouble();

    // Newton's iteration
    for (int i = 0; i < 20; i++) {
      final currentLon = _solarLongitude(jde);
      var diff = targetLon - currentLon;

      // -180 ~ +180 범위로 정규화
      while (diff > 180) {
        diff -= 360;
      }
      while (diff < -180) {
        diff += 360;
      }

      if (diff.abs() < 0.0001) break; // ~0.01° 정확도 달성

      // 태양은 하루에 약 0.9856° 이동
      jde += diff / 0.9856;
    }

    return jde;
  }

  /// 태양 황경 → 근사 양력 날짜 [year, month, day]
  static List<int> _approxDateForLongitude(int year, double longitude) {
    for (final term in ManseryeokData.monthBoundaries) {
      if ((term.longitude - longitude).abs() < 0.1) {
        // 소한(1월)은 해당 연도, 나머지는 해당 연도
        return [year, term.approxMonth, term.approxDay];
      }
    }
    // fallback
    return [year, 3, 20];
  }

  /// JDE → DateTime 변환
  static DateTime _jdeToDateTime(double jde) {
    final jdn = jde.round();
    final a = jdn + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - (146097 * b) ~/ 4;
    final d = (4 * c + 3) ~/ 1461;
    final e = c - (1461 * d) ~/ 4;
    final m = (5 * e + 2) ~/ 153;

    final day = e - (153 * m + 2) ~/ 5 + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final yr = 100 * b + d - 4800 + m ~/ 10;

    return DateTime(yr, month, day);
  }

  /// 각도를 0~360° 범위로 정규화
  static double _normalize(double degrees) {
    var result = degrees % 360.0;
    if (result < 0) result += 360.0;
    return result;
  }

  // ============================================================
  // 오행 분석
  // ============================================================

  /// 사주 8글자의 오행 분포 카운팅
  static Map<String, int> _analyzeOheng({
    required int yearStem,
    required int yearBranch,
    required int monthStem,
    required int monthBranch,
    required int dayStem,
    required int dayBranch,
    int hourStem = -1,
    int hourBranch = -1,
  }) {
    final balance = {'목': 0, '화': 0, '토': 0, '금': 0, '수': 0};

    void addStem(int idx) {
      final oheng =
          SajuConstants.cheonganToOheng[SajuConstants.cheongan[idx]]!;
      balance[oheng] = balance[oheng]! + 1;
    }

    void addBranch(int idx) {
      final oheng = SajuConstants.jijiToOheng[SajuConstants.jiji[idx]]!;
      balance[oheng] = balance[oheng]! + 1;
    }

    addStem(yearStem);
    addBranch(yearBranch);
    addStem(monthStem);
    addBranch(monthBranch);
    addStem(dayStem);
    addBranch(dayBranch);

    if (hourStem >= 0 && hourBranch >= 0) {
      addStem(hourStem);
      addBranch(hourBranch);
    }

    return balance;
  }

  // ============================================================
  // 일간 강약 판단
  // ============================================================

  /// 일간이 신강(身強)인지 판단
  static bool _isDayMasterStrong({
    required String dayMasterOheng,
    required Map<String, int> ohengBalance,
    required int monthBranch,
  }) {
    // 1. 득령(得令) 여부: 월지가 일간을 생하거나 같은 오행인지
    final monthOheng =
        SajuConstants.jijiToOheng[SajuConstants.jiji[monthBranch]]!;
    final generatesMe = SajuConstants.ohengGeneratesMe[dayMasterOheng]!;
    final isDeukryeong =
        monthOheng == dayMasterOheng || monthOheng == generatesMe;

    // 2. 득세(得勢): 같은 오행 + 나를 생하는 오행 수
    final sameCount = ohengBalance[dayMasterOheng] ?? 0;
    final generatingCount = ohengBalance[generatesMe] ?? 0;
    final supportingCount = sameCount + generatingCount;

    // 3. 실세: 나를 극하는 오행 + 내가 생하는 오행(설기) 수
    final controlsMe = SajuConstants.ohengControlsMe[dayMasterOheng]!;
    final iGenerate = SajuConstants.ohengIGenerate[dayMasterOheng]!;
    final opposingCount =
        (ohengBalance[controlsMe] ?? 0) + (ohengBalance[iGenerate] ?? 0);

    // 득령이면 기본 신강, 아니면 기본 신약
    if (isDeukryeong) {
      return supportingCount >= opposingCount;
    } else {
      return supportingCount > opposingCount + 1;
    }
  }

  // ============================================================
  // 용신 도출
  // ============================================================

  /// 일간 강약에 따른 용신(用神) 결정
  static String _deriveYongsin({
    required String dayMasterOheng,
    required Map<String, int> ohengBalance,
    required bool isStrong,
  }) {
    if (isStrong) {
      // 신강 → 억부(抑扶): 나를 극하는 오행(관성) 또는 설기(식상)
      final controlsMe = SajuConstants.ohengControlsMe[dayMasterOheng]!;
      final iGenerate = SajuConstants.ohengIGenerate[dayMasterOheng]!;

      // 사주에 더 부족한 쪽을 용신으로
      if ((ohengBalance[controlsMe] ?? 0) <=
          (ohengBalance[iGenerate] ?? 0)) {
        return controlsMe;
      }
      return iGenerate;
    } else {
      // 신약 → 보강: 나를 생하는 오행(인성) 또는 같은 오행(비겁)
      final generatesMe = SajuConstants.ohengGeneratesMe[dayMasterOheng]!;

      // 일간이 매우 약하면 생해주는 오행, 아니면 같은 오행
      final dmCount = ohengBalance[dayMasterOheng] ?? 0;
      if (dmCount <= 1) {
        return generatesMe;
      }
      return dayMasterOheng;
    }
  }

  // ============================================================
  // 요약 생성
  // ============================================================

  static String _generateSummary({
    required String dayMaster,
    required String dayMasterOheng,
    required String weakElement,
    required String strongElement,
    required String yongsin,
    required bool isStrong,
  }) {
    final dmIdx = SajuConstants.oheng.indexOf(dayMasterOheng);
    final weakIdx = SajuConstants.oheng.indexOf(weakElement);
    final strongIdx = SajuConstants.oheng.indexOf(strongElement);
    final ysIdx = SajuConstants.oheng.indexOf(yongsin);

    final dmHanja = SajuConstants.ohengHanja[dmIdx];
    final weakHanja = SajuConstants.ohengHanja[weakIdx];
    final strongHanja = SajuConstants.ohengHanja[strongIdx];
    final ysHanja = SajuConstants.ohengHanja[ysIdx];

    final strengthDesc = isStrong ? '신강(身強)' : '신약(身弱)';

    return '일간 $dayMaster$dayMasterOheng($dmHanja)가 $strengthDesc하여, '
        '$yongsin($ysHanja) 기운을 보충하는 것이 좋습니다. '
        '오행 분포에서 $weakElement($weakHanja)이(가) 부족하고 '
        '$strongElement($strongHanja)이(가) 강합니다. '
        '이름에 $yongsin($ysHanja) 기운의 한자를 사용하면 '
        '사주의 균형을 맞추는 데 도움이 됩니다.';
  }
}
