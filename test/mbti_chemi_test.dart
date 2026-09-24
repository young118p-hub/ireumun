import 'package:flutter_test/flutter_test.dart';
import 'package:chemilab/data/mbti/mbti_chemi.dart';
import 'package:chemilab/data/mbti/mbti_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MBTI 케미 규칙표', () {
    test('256개 조합 모두 결과가 나오고 점수는 64~98', () {
      for (final a in mbtiTypes) {
        for (final b in mbtiTypes) {
          final c = mbtiChemi(a, b);
          expect(c.score, inInclusiveRange(64, 98), reason: '$a×$b');
          expect(c.title, isNotEmpty);
          // 채우지 못한 자리표시가 남으면 안 된다
          for (final text in [c.strength, c.clash, c.tip]) {
            expect(text.contains('{'), isFalse, reason: '$a×$b: $text');
          }
        }
      }
    });

    test('랜덤이 아니다: A×B는 몇 번을 봐도, 순서를 바꿔도 같은 점수·제목', () {
      for (final a in mbtiTypes) {
        for (final b in mbtiTypes) {
          final ab = mbtiChemi(a, b), ba = mbtiChemi(b, a);
          expect(mbtiChemi(a, b).score, ab.score);
          expect(ba.score, ab.score, reason: '$a×$b');
          expect(ba.title, ab.title, reason: '$a×$b');
        }
      }
    });

    test('문구의 유형 자리에 그 글자를 가진 쪽이 들어간다', () {
      final c = mbtiChemi('INFP', 'ENTJ');
      expect(c.score, 96); // N 같음 25 + E/I 다름 13 + T/F 다름 8 + J/P 다름 10 + 기본 40
      expect(c.title, '정반대라 끌리는 조합');
      expect(c.clash, contains('ENTJ의 말투가 INFP에게는'));
    });

    test('점수 구간이 실제로 나뉜다 (전부 같은 점수가 아님)', () {
      final scores = {for (final a in mbtiTypes) for (final b in mbtiTypes) mbtiChemi(a, b).score};
      expect(scores.length, greaterThanOrEqualTo(8));
      expect(scores.reduce((x, y) => x < y ? x : y), 64);
      expect(scores.reduce((x, y) => x > y ? x : y), 98);
    });

    test('유형이 아니면 거절', () {
      expect(() => mbtiChemi('ABCD', 'INFP'), throwsArgumentError);
    });
  });

  group('MBTI 기록', () {
    late MbtiHistory history;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      history = MbtiHistory(await SharedPreferences.getInstance());
    });

    test('같은 조합을 다시 보면 새로 쌓지 않고 맨 위로', () async {
      await history.add('INFP', 'ENTJ', now: DateTime(2026, 1, 1));
      await history.add('INFP', 'ISTJ', now: DateTime(2026, 1, 2));
      await history.add('INFP', 'ENTJ', now: DateTime(2026, 1, 3));
      final all = history.all();
      expect(all.map((r) => r.you), ['ENTJ', 'ISTJ']);
      expect(all.first.at, DateTime(2026, 1, 3));
    });

    test('최근 30개까지만', () async {
      var i = 0;
      for (final a in mbtiTypes) {
        for (final b in mbtiTypes.take(2)) {
          await history.add(a, b, now: DateTime(2026, 1, 1).add(Duration(minutes: i++)));
        }
      }
      expect(history.all().length, MbtiHistory.maxRecords);
    });

    test('지우기, 내 유형 기억, 깨진 저장값은 무시', () async {
      await history.add('INFP', 'ENTJ');
      await history.remove('mbti:INFP:ENTJ');
      expect(history.all(), isEmpty);

      expect(history.myType, isNull);
      await history.setMyType('ENFP');
      expect(history.myType, 'ENFP');

      SharedPreferences.setMockInitialValues({'mbti_history': '{broken', 'my_mbti': 'XXXX'});
      final broken = MbtiHistory(await SharedPreferences.getInstance());
      expect(broken.all(), isEmpty);
      expect(broken.myType, isNull);
    });
  });
}
