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

  group('MBTI 케미 상세', () {
    test('케미 해부 네 줄의 점수를 더하면 결과 점수 (점수의 근거가 화면과 맞는다)', () {
      for (final a in mbtiTypes) {
        for (final b in mbtiTypes) {
          final c = mbtiChemi(a, b);
          expect(40 + c.axes.fold<int>(0, (s, x) => s + x.points), c.score, reason: '$a×$b');
          expect(c.axes.map((x) => x.label), ['에너지', '대화 코드', '결정 방식', '생활 리듬']);
          for (final text in [...c.axes.map((x) => x.text), c.love, c.friend, c.work]) {
            expect(text, isNotEmpty);
            expect(text.contains('{'), isFalse, reason: '$a×$b: $text');
          }
        }
      }
    });

    test('케미 올리는 법: 3개, 점수가 낮은 축부터, 자리표시가 남지 않는다', () {
      for (final a in mbtiTypes) {
        for (final b in mbtiTypes) {
          final c = mbtiChemi(a, b);
          expect(c.improves.length, 3);
          for (final i in c.improves) {
            expect('${i.title}${i.action}'.contains('{'), isFalse, reason: '$a×$b ${i.action}');
          }
        }
      }
      // INFP×ENTJ: T/F 다름이 가장 약한 축(8/10)이라 첫 번째
      expect(mbtiChemi('INFP', 'ENTJ').improves.first.title, '위로하는 방식의 차이');
      expect(mbtiChemi('INFP', 'INFJ').improves.map((i) => i.action).join(), contains('INFP'));
    });

    test('둘 중 누가: 다른 글자면 그 글자를 가진 쪽, 같으면 한마디', () {
      final c = mbtiChemi('ENFP', 'INTJ');
      expect(c.who.first.winner, 'ENFP'); // 먼저 연락 = E
      expect(c.who.first.reason, 'E vs I');
      expect(c.who[1].winner, 'INTJ'); // 일정표 = J
      final same = mbtiChemi('INFP', 'INFJ');
      expect(same.who.first.winner, isNull); // 둘 다 I
      expect(same.who.first.reason, contains('눈치 싸움'));
    });

    test('16유형 모두 별명·특징·연애 스타일·듣고 싶은 말이 있다', () {
      for (final t in mbtiTypes) {
        final p = mbtiProfiles[t]!;
        expect([p.nick, p.vibe, p.love, p.wantsToHear].every((x) => x.isNotEmpty), isTrue, reason: t);
      }
      expect(mbtiProfiles.values.map((p) => p.nick).toSet().length, 16); // 별명 겹치지 않게
    });

    test('최고 케미 TOP 3: 점수 높은 순, 결과 화면 점수와 같다', () {
      for (final t in mbtiTypes) {
        final top = bestMatches(t);
        expect(top.length, 3);
        final best = mbtiTypes.map((x) => mbtiChemi(t, x).score).reduce((a, b) => a > b ? a : b);
        expect(top.first.score, best, reason: t);
        for (final m in top) {
          expect(m.score, mbtiChemi(t, m.you).score);
        }
        expect(top[0].score >= top[1].score && top[1].score >= top[2].score, isTrue);
      }
      expect(bestMatches('INFP').map((m) => m.you), ['ENFJ', 'ENTJ', 'ENFP']);
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
