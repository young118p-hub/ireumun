// 만세력 데이터 - 절기(節氣) 태양 황경 데이터
// 사주 월주/년주 경계 계산에 사용

class ManseryeokData {
  ManseryeokData._();

  // ============================================================
  // 12절기 - 사주 월(月) 경계
  // 절(節)만 사용 (기(氣)는 월 중간이므로 제외)
  // ============================================================

  /// 절기명, 태양 황경(도), 사주 월번호, 근사 월/일
  static const List<SolarTermInfo> monthBoundaries = [
    SolarTermInfo(name: '입춘', longitude: 315.0, sajuMonth: 1, approxMonth: 2, approxDay: 4),
    SolarTermInfo(name: '경칩', longitude: 345.0, sajuMonth: 2, approxMonth: 3, approxDay: 6),
    SolarTermInfo(name: '청명', longitude: 15.0, sajuMonth: 3, approxMonth: 4, approxDay: 5),
    SolarTermInfo(name: '입하', longitude: 45.0, sajuMonth: 4, approxMonth: 5, approxDay: 6),
    SolarTermInfo(name: '망종', longitude: 75.0, sajuMonth: 5, approxMonth: 6, approxDay: 6),
    SolarTermInfo(name: '소서', longitude: 105.0, sajuMonth: 6, approxMonth: 7, approxDay: 7),
    SolarTermInfo(name: '입추', longitude: 135.0, sajuMonth: 7, approxMonth: 8, approxDay: 7),
    SolarTermInfo(name: '백로', longitude: 165.0, sajuMonth: 8, approxMonth: 9, approxDay: 8),
    SolarTermInfo(name: '한로', longitude: 195.0, sajuMonth: 9, approxMonth: 10, approxDay: 8),
    SolarTermInfo(name: '입동', longitude: 225.0, sajuMonth: 10, approxMonth: 11, approxDay: 7),
    SolarTermInfo(name: '대설', longitude: 255.0, sajuMonth: 11, approxMonth: 12, approxDay: 7),
    SolarTermInfo(name: '소한', longitude: 285.0, sajuMonth: 12, approxMonth: 1, approxDay: 6),
  ];

  /// 입춘(立春) 태양 황경
  static const double ipchunLongitude = 315.0;

  /// 사주 월번호 → 지지 인덱스 매핑
  /// 1(인월)→2, 2(묘월)→3, ..., 11(자월)→0, 12(축월)→1
  static int sajuMonthToJijiIndex(int sajuMonth) {
    return (sajuMonth + 1) % 12;
  }

  /// 사주 월번호 → 절기명
  static String sajuMonthToTermName(int sajuMonth) {
    return monthBoundaries
        .firstWhere((t) => t.sajuMonth == sajuMonth)
        .name;
  }
}

/// 절기 정보 데이터 클래스
class SolarTermInfo {
  final String name;
  final double longitude; // 태양 황경 (도)
  final int sajuMonth; // 사주 월번호 (1=인월 ~ 12=축월)
  final int approxMonth; // 근사 양력 월
  final int approxDay; // 근사 양력 일

  const SolarTermInfo({
    required this.name,
    required this.longitude,
    required this.sajuMonth,
    required this.approxMonth,
    required this.approxDay,
  });
}
