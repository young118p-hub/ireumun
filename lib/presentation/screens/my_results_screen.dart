// 내 결과 화면
// Hive에 저장된 작명/진단 결과 목록

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/saved_result.dart';
import '../providers/naming_provider.dart';

class MyResultsScreen extends StatelessWidget {
  const MyResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: const Text('내 결과'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<NamingProvider>(
        builder: (context, provider, _) {
          final results = provider.savedResults;

          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 64,
                    color: const Color(0xFF1A1A2E).withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '저장된 결과가 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '작명 또는 진단 결과가 자동으로 저장됩니다.',
                    style: TextStyle(fontSize: 13, color: Color(0xFFB0B0B0)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return _buildResultTile(context, result, provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildResultTile(BuildContext context, SavedResult result, NamingProvider provider) {
    final isNaming = result.type == SavedResultType.naming;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (isNaming ? const Color(0xFF1A1A2E) : const Color(0xFF0984E3))
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isNaming ? Icons.auto_awesome : Icons.search,
            color: isNaming ? const Color(0xFF1A1A2E) : const Color(0xFF0984E3),
            size: 22,
          ),
        ),
        title: Text(
          result.displayTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A2E),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              result.displaySubtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
            ),
            const SizedBox(height: 2),
            Text(
              _formatDate(result.savedAt),
              style: const TextStyle(fontSize: 11, color: Color(0xFFB0B0B0)),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (isNaming ? const Color(0xFF1A1A2E) : const Color(0xFF0984E3))
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isNaming ? '작명' : '진단',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isNaming ? const Color(0xFF1A1A2E) : const Color(0xFF0984E3),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _confirmDelete(context, result, provider),
              child: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFB0B0B0)),
            ),
          ],
        ),
        onTap: () => _viewResult(context, result, provider),
      ),
    );
  }

  void _viewResult(BuildContext context, SavedResult result, NamingProvider provider) {
    // TODO: 저장된 결과 상세 보기 (결과 화면으로 이동)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${result.displayTitle} - 상세 보기 기능 준비 중'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SavedResult result, NamingProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('${result.displayTitle} 결과를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteSavedResult(result.id);
              Navigator.pop(ctx);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
