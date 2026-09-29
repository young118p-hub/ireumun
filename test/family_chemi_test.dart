import 'package:flutter_test/flutter_test.dart';
import 'package:chemilab/data/family_chemi/family_chemi.dart';
import 'package:chemilab/data/family_chemi/family_chemi_history.dart';
import 'package:chemilab/data/models/birth_value.dart';

FamilyInput m(FamilyRole r, String n, int y, int mo, int d, [int h = -1]) => FamilyInput(r, n, BirthValue(DateTime(y, mo, d), h));

final family = [
  m(FamilyRole.me, '민서', 1998, 3, 14, 10),
  m(FamilyRole.mom, '엄마', 1970, 8, 2),
  m(FamilyRole.dad, '아빠', 1968, 11, 20, 6),
  m(FamilyRole.sibling, '동생', 2002, 5, 9),
];

void main() {
  test('가족 점수: 두 사람 평균 × 0.85 + 오행 보너스, 근거가 점수와 맞는다', () {
    final c = FamilyChemiRecord(members: family, at: DateTime(2026)).chemi;
    expect(c.pairs.length, 6); // 4명 → 6쌍
    final avg = c.pairs.map((p) => p.chemi.score).reduce((a, b) => a + b) / c.pairs.length;
    const bonus = [0, 0, 3, 7, 11, 15];
    expect(c.bonus, bonus[c.coverage]);
    expect(c.score, (avg * 0.85 + c.bonus).round().clamp(0, 99));
    expect(c.best.chemi.score >= c.worst.chemi.score, isTrue);
    for (final p in c.pairs) {
      expect(p.chemi.relation.label, '가족');
    }
    // ignore: avoid_print
    print('${c.score} ${c.title} / ${c.scoreBasis} / 없는 오행 ${c.missing}');
    for (final w in c.who) {
      // ignore: avoid_print
      print('${w.question}: ${w.winner} (${w.reason})');
    }
    for (final i in c.improves) {
      // ignore: avoid_print
      print('- ${i.title}: ${i.action}');
    }
    for (final mem in c.members) {
      // ignore: avoid_print
      print('${mem.name} ${mem.element} ${familyPositions[mem.element]!.title}');
    }
  });

  test('순서를 바꿔도 가족 점수는 같다', () {
    final a = FamilyChemiRecord(members: family, at: DateTime(2026)).chemi;
    final b = FamilyChemiRecord(members: family.reversed.toList(), at: DateTime(2026)).chemi;
    expect(a.score, b.score);
  });

  test('우리 가족 중 누가?: 이긴 사람은 그 오행이 가장 많거나(같으면) 공동', () {
    final c = FamilyChemiRecord(members: family, at: DateTime(2026)).chemi;
    expect(c.who.length, 5);
    for (final (i, w) in c.who.indexed) {
      final el = familyWhoQuestions[i].$2;
      final top = c.members.map((x) => x.person.saju.ohengBalance[el] ?? 0).reduce((a, b) => a > b ? a : b);
      if (w.winner != null) {
        final winner = c.members.firstWhere((x) => x.name == w.winner);
        expect(winner.person.saju.ohengBalance[el] ?? 0, top);
      }
    }
  });

  test('케미 올리는 법은 1~3개', () {
    final c = FamilyChemiRecord(members: family, at: DateTime(2026)).chemi;
    expect(c.improves.length, inInclusiveRange(1, 3));
  });

  test('기록 저장·복원 (JSON)', () {
    final r = FamilyChemiRecord(members: family, at: DateTime(2026, 9, 28), remoteId: 'x', paid: true, report: {'a': 1});
    final back = FamilyChemiRecord.fromJson(r.toJson())!;
    expect(back.id, r.id);
    expect(back.remoteId, 'x');
    expect(back.paid, isTrue);
    expect(back.members.first.role, FamilyRole.me);
    expect(FamilyChemiRecord.fromJson({'members': [], 'at': 'x'}), isNull);
  });
}
