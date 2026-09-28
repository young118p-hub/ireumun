// "둘 중 누가?": 결과를 보는 두 사람이 "진짜 너네!" 할 만한 장면 예측. 근거를 같이 보여 준다.
// 비기면 억지로 고르지 않고 막상막하로.

class WhoAnswer {
  final String question; // 먼저 연락하는 사람
  final String? winner; // 이름 (비기면 null)
  final String reason; // (화 기운 3 : 1)
  const WhoAnswer(this.question, this.winner, this.reason);
}
