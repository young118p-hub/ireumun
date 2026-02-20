// 천간지지 / 오행 / 시주 상수 정의
// 사주팔자 계산에 필요한 모든 정적 데이터

class SajuConstants {
  SajuConstants._();

  // ============================================================
  // 천간 (天干) - 10개
  // ============================================================
  static const List<String> cheongan = [
    '갑', '을', '병', '정', '무', '기', '경', '신', '임', '계',
  ];

  static const List<String> cheonganHanja = [
    '甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸',
  ];

  // ============================================================
  // 지지 (地支) - 12개
  // ============================================================
  static const List<String> jiji = [
    '자', '축', '인', '묘', '진', '사', '오', '미', '신', '유', '술', '해',
  ];

  static const List<String> jijiHanja = [
    '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
  ];

  // 지지 띠 동물
  static const List<String> jijiAnimal = [
    '쥐', '소', '호랑이', '토끼', '용', '뱀', '말', '양', '원숭이', '닭', '개', '돼지',
  ];

  // ============================================================
  // 오행 (五行)
  // ============================================================
  static const List<String> oheng = ['목', '화', '토', '금', '수'];

  static const List<String> ohengHanja = ['木', '火', '土', '金', '水'];

  // 천간 → 오행 매핑 (갑을=목, 병정=화, 무기=토, 경신=금, 임계=수)
  static const Map<String, String> cheonganToOheng = {
    '갑': '목', '을': '목',
    '병': '화', '정': '화',
    '무': '토', '기': '토',
    '경': '금', '신': '금',
    '임': '수', '계': '수',
  };

  // 지지 → 오행 매핑
  static const Map<String, String> jijiToOheng = {
    '인': '목', '묘': '목',
    '사': '화', '오': '화',
    '진': '토', '술': '토', '축': '토', '미': '토',
    '신': '금', '유': '금',
    '해': '수', '자': '수',
  };

  // 오행 색상 (UI용)
  static const Map<String, int> ohengColor = {
    '목': 0xFF4CAF50, // 초록
    '화': 0xFFF44336, // 빨강
    '토': 0xFFFF9800, // 노랑/주황
    '금': 0xFFFFFFFF, // 흰색
    '수': 0xFF2196F3, // 파랑
  };

  // ============================================================
  // 시주 (時柱) - 시간대별 지지
  // ============================================================
  static const Map<String, String> hourToJiji = {
    '23-01': '자',
    '01-03': '축',
    '03-05': '인',
    '05-07': '묘',
    '07-09': '진',
    '09-11': '사',
    '11-13': '오',
    '13-15': '미',
    '15-17': '신',
    '17-19': '유',
    '19-21': '술',
    '21-23': '해',
  };

  // 시간(hour) → 지지 인덱스 변환
  static String getJijiForHour(int hour) {
    if (hour == 23 || hour == 0) return '자';
    if (hour >= 1 && hour < 3) return '축';
    if (hour >= 3 && hour < 5) return '인';
    if (hour >= 5 && hour < 7) return '묘';
    if (hour >= 7 && hour < 9) return '진';
    if (hour >= 9 && hour < 11) return '사';
    if (hour >= 11 && hour < 13) return '오';
    if (hour >= 13 && hour < 15) return '미';
    if (hour >= 15 && hour < 17) return '신';
    if (hour >= 17 && hour < 19) return '유';
    if (hour >= 19 && hour < 21) return '술';
    return '해'; // 21-23
  }

  // 시간대 표시 문자열
  static String getHourRangeLabel(int hour) {
    final jiji = getJijiForHour(hour);
    final idx = SajuConstants.jiji.indexOf(jiji);
    final startHour = (idx * 2 + 23) % 24;
    final endHour = (startHour + 2) % 24;
    final sh = startHour.toString().padLeft(2, '0');
    final eh = endHour.toString().padLeft(2, '0');
    return '$sh:00 ~ $eh:00 ($jiji시)';
  }

  // ============================================================
  // 60갑자 (六十甲子)
  // ============================================================
  static String getGapja(int index) {
    final cIdx = index % 10;
    final jIdx = index % 12;
    return '${cheongan[cIdx]}${jiji[jIdx]}';
  }

  static String getGapjaHanja(int index) {
    final cIdx = index % 10;
    final jIdx = index % 12;
    return '${cheonganHanja[cIdx]}${jijiHanja[jIdx]}';
  }

  // ============================================================
  // 성씨 목록 (한국 주요 성씨)
  // ============================================================
  static const List<String> commonSurnames = [
    '김', '이', '박', '최', '정', '강', '조', '윤', '장', '임',
    '한', '오', '서', '신', '권', '황', '안', '송', '류', '전',
    '홍', '고', '문', '양', '손', '배', '백', '허', '유', '남',
    '심', '노', '하', '곽', '성', '차', '주', '우', '구', '민',
    '진', '나', '지', '엄', '채', '원', '천', '방', '공', '현',
  ];

  // ============================================================
  // 음력/양력 참고 (AI에게 전달용)
  // ============================================================
  static const String calendarNote = '양력 기준';
}
