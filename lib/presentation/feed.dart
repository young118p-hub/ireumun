// 결과 카드 목록 (홈 "내 실험 기록"과 내 결과 탭이 같이 쓴다)
// 점수는 전부 실제 결과: MBTI는 규칙표, 내 이름 케미는 서버 진단 점수, 아기 이름은 첫 이름 점수.
// 결과가 없거나 점수를 아직 모르면 숫자를 지어내지 않고 비워 둔다.

import 'package:flutter/material.dart';
import '../data/mbti/mbti_history.dart';
import '../data/name_chemi/name_chemi_history.dart';
import '../data/models/saved_result.dart';
import 'providers/chemi_provider.dart';
import 'providers/naming_provider.dart';
import 'screens/diagnosis_result_screen.dart';
import 'screens/mbti_result_screen.dart';
import 'screens/name_chemi_result_screen.dart';
import 'screens/result_screen.dart';

enum FeedKind { mbti, nameMatch, nameChemi, babyName }

class FeedItem {
  final String id;
  final FeedKind kind;
  final String label; // "MBTI 케미"
  final String headline; // "INFP × ENTJ", "김민서"
  final int? score; // 모르면 null
  final String summary; // 한 줄
  final DateTime at;
  final bool isPreview; // 결제 전 (미리보기만)
  final void Function(BuildContext context) open;
  final Future<void> Function() delete;

  const FeedItem({
    required this.id,
    required this.kind,
    required this.label,
    required this.headline,
    required this.score,
    required this.summary,
    required this.at,
    required this.isPreview,
    required this.open,
    required this.delete,
  });
}

List<FeedItem> buildFeed(NamingProvider naming, ChemiProvider chemi) {
  final items = <FeedItem>[
    for (final r in chemi.mbtiRecords) _fromMbti(r, chemi),
    for (final r in chemi.nameRecords) _fromName(r, chemi),
    for (final r in naming.savedResults) _fromSaved(r, naming),
  ];
  items.sort((a, b) => b.at.compareTo(a.at));
  return items;
}

FeedItem _fromMbti(MbtiRecord r, ChemiProvider chemi) {
  final c = r.chemi;
  return FeedItem(
    id: r.id,
    kind: FeedKind.mbti,
    label: 'MBTI 케미',
    headline: '${r.me} × ${r.you}',
    score: c.score,
    summary: c.title,
    at: r.at,
    isPreview: false,
    open: (context) => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MbtiResultScreen(me: r.me, you: r.you, record: false)),
    ),
    delete: () => chemi.deleteMbti(r.id),
  );
}

FeedItem _fromName(NameChemiRecord r, ChemiProvider chemi) {
  final c = r.chemi;
  return FeedItem(
    id: r.id,
    kind: FeedKind.nameMatch,
    label: '이름 케미',
    headline: '${r.a} × ${r.b}',
    score: c.score,
    summary: c.title,
    at: r.at,
    isPreview: false,
    open: (context) => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NameChemiResultScreen(me: r.a, you: r.b, record: false)),
    ),
    delete: () => chemi.deleteName(r.id),
  );
}

FeedItem _fromSaved(SavedResult r, NamingProvider naming) {
  final isNaming = r.type == SavedResultType.naming;
  int? score;
  var headline = r.displayTitle;
  var summary = '';
  if (isNaming) {
    final names = r.namingResult?.names ?? const [];
    if (names.isNotEmpty) {
      headline = '${r.surname}${names.first.name}';
      if (names.first.score > 0) score = names.first.score;
      summary = '추천 이름 ${names.length + r.lockedCount}개 중 1위';
    }
  } else {
    final d = r.diagnosisResult?.diagnosis;
    if (d != null && d.overallScore > 0) score = d.overallScore;
    summary = d?.summaryOneLine ?? '';
  }
  return FeedItem(
    id: r.id,
    kind: isNaming ? FeedKind.babyName : FeedKind.nameChemi,
    label: isNaming ? '아기 이름' : '내 이름 케미',
    headline: headline,
    score: score,
    summary: summary,
    at: r.savedAt,
    isPreview: !r.isPaid,
    open: (context) {
      naming.openSaved(r);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => isNaming ? const ResultScreen() : const DiagnosisResultScreen()),
      );
    },
    delete: () => naming.deleteSavedResult(r.id),
  );
}
