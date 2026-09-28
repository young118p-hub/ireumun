// 아직 만들지 않은 기능. false면 홈에서 "곧 열려요"로 눌리지 않고, 다른 화면의 연결 버튼은 숨긴다.
// 기능을 열 때 여기만 true로 바꾸고 docs/screen-map.md의 해당 줄도 고친다.

class Features {
  Features._();

  static const pairChemi = true; // 우리 케미 (연인·친구·동료). 전체 리포트 결제는 Play 상품 chemi_pair 등록 뒤 동작
  static const familyChemi = true; // 가족 케미 (3~5명). 전체 리포트 결제는 Play 상품 chemi_family 등록 뒤 동작
  static const nameChemi = true; // 이름 케미 (두 이름 소리 오행, 무료)
}
