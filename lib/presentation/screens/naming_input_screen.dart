// 신규 작명 입력 화면
// 아기 + 아빠 + 엄마 생년월일시 입력 폼

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/saju_constants.dart';
import '../../data/models/saju_input.dart';
import '../providers/naming_provider.dart';
import 'result_screen.dart';

class NamingInputScreen extends StatefulWidget {
  const NamingInputScreen({super.key});

  @override
  State<NamingInputScreen> createState() => _NamingInputScreenState();
}

class _NamingInputScreenState extends State<NamingInputScreen> {
  // 아기 정보
  String _surname = '김';
  Gender _babyGender = Gender.male;
  DateTime _babyDate = DateTime(2024, 1, 1);
  int _babyHour = -1;
  bool _babyKnowsHour = false;

  // 아빠 정보
  DateTime _fatherDate = DateTime(1990, 1, 1);
  int _fatherHour = -1;
  bool _fatherKnowsHour = false;

  // 엄마 정보
  DateTime _motherDate = DateTime(1990, 1, 1);
  int _motherHour = -1;
  bool _motherKnowsHour = false;

  // 현재 펼쳐진 섹션 (0=아기, 1=아빠, 2=엄마)
  int _expandedSection = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: const Text('신규 작명'),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 안내 문구
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: Color(0xFF8E8E93)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '아기와 부모님의 사주를 함께 분석하여\n가족 오행 균형에 맞는 이름을 추천합니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 아기 정보
            _buildAccordionSection(
              index: 0,
              icon: Icons.child_care,
              title: '아기 정보',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('성씨'),
                  const SizedBox(height: 8),
                  _buildSurnameSelector(),
                  const SizedBox(height: 16),
                  _buildLabel('성별'),
                  const SizedBox(height: 8),
                  _buildGenderSelector(),
                  const SizedBox(height: 16),
                  _buildLabel('생년월일 (양력)'),
                  const SizedBox(height: 8),
                  _buildDateSelector(_babyDate, (d) => setState(() => _babyDate = d)),
                  const SizedBox(height: 16),
                  _buildLabel('태어난 시간'),
                  const SizedBox(height: 8),
                  _buildHourSelector(
                    knowsHour: _babyKnowsHour,
                    selectedHour: _babyHour,
                    onKnowsHourChanged: (v) => setState(() {
                      _babyKnowsHour = v;
                      if (!v) _babyHour = -1;
                    }),
                    onHourChanged: (h) => setState(() => _babyHour = h),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 아빠 정보
            _buildAccordionSection(
              index: 1,
              icon: Icons.person,
              title: '아빠 정보',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('생년월일 (양력)'),
                  const SizedBox(height: 8),
                  _buildDateSelector(_fatherDate, (d) => setState(() => _fatherDate = d)),
                  const SizedBox(height: 16),
                  _buildLabel('태어난 시간'),
                  const SizedBox(height: 8),
                  _buildHourSelector(
                    knowsHour: _fatherKnowsHour,
                    selectedHour: _fatherHour,
                    onKnowsHourChanged: (v) => setState(() {
                      _fatherKnowsHour = v;
                      if (!v) _fatherHour = -1;
                    }),
                    onHourChanged: (h) => setState(() => _fatherHour = h),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 엄마 정보
            _buildAccordionSection(
              index: 2,
              icon: Icons.person,
              title: '엄마 정보',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('생년월일 (양력)'),
                  const SizedBox(height: 8),
                  _buildDateSelector(_motherDate, (d) => setState(() => _motherDate = d)),
                  const SizedBox(height: 16),
                  _buildLabel('태어난 시간'),
                  const SizedBox(height: 8),
                  _buildHourSelector(
                    knowsHour: _motherKnowsHour,
                    selectedHour: _motherHour,
                    onKnowsHourChanged: (v) => setState(() {
                      _motherKnowsHour = v;
                      if (!v) _motherHour = -1;
                    }),
                    onHourChanged: (h) => setState(() => _motherHour = h),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 작명 시작 버튼
            _buildSubmitButton(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 아코디언 섹션
  // ============================================================
  Widget _buildAccordionSection({
    required int index,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final isExpanded = _expandedSection == index;
    return Container(
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
      child: Column(
        children: [
          // 헤더
          GestureDetector(
            onTap: () => setState(() => _expandedSection = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: isExpanded
                    ? const Color(0xFF1A1A2E).withValues(alpha: 0.04)
                    : Colors.white,
                borderRadius: isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: const Color(0xFF1A1A2E)),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const Spacer(),
                  // 완료 체크 (해당 섹션 입력 완료 시)
                  if (_isSectionComplete(index))
                    const Icon(Icons.check_circle, size: 20, color: Color(0xFF4CAF50)),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF8E8E93),
                  ),
                ],
              ),
            ),
          ),
          // 내용
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
              child: child,
            ),
        ],
      ),
    );
  }

  bool _isSectionComplete(int index) {
    switch (index) {
      case 0: // 아기 - 항상 완료 (기본값 있음)
        return true;
      case 1: // 아빠
        return true;
      case 2: // 엄마
        return true;
      default:
        return false;
    }
  }

  // ============================================================
  // 공통 위젯들
  // ============================================================
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2C2C2E),
      ),
    );
  }

  Widget _buildSurnameSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _surname,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.person_outline, color: Color(0xFF8E8E93), size: 20),
        ),
        style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
        dropdownColor: Colors.white,
        items: SajuConstants.commonSurnames.map((s) {
          return DropdownMenuItem(value: s, child: Text('$s씨'));
        }).toList(),
        onChanged: (v) => setState(() => _surname = v ?? '김'),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        _buildGenderChip('남아', Gender.male, Icons.male),
        const SizedBox(width: 10),
        _buildGenderChip('여아', Gender.female, Icons.female),
      ],
    );
  }

  Widget _buildGenderChip(String label, Gender value, IconData icon) {
    final selected = _babyGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _babyGender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1A1A2E) : const Color(0xFFF8F6F0),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF1A1A2E) : const Color(0xFFE5E5EA),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : const Color(0xFF8E8E93)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : const Color(0xFF2C2C2E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(DateTime date, ValueChanged<DateTime> onChanged) {
    return GestureDetector(
      onTap: () => _pickDate(date, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F6F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: Color(0xFF8E8E93), size: 18),
            const SizedBox(width: 10),
            Text(
              '${date.year}년 ${date.month}월 ${date.day}일',
              style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Color(0xFFC7C7CC), size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(DateTime initial, ValueChanged<DateTime> onChanged) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A1A2E),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) onChanged(picked);
  }

  Widget _buildHourSelector({
    required bool knowsHour,
    required int selectedHour,
    required ValueChanged<bool> onKnowsHourChanged,
    required ValueChanged<int> onHourChanged,
  }) {
    return Column(
      children: [
        Row(
          children: [
            _buildToggleChip('모름', !knowsHour, () => onKnowsHourChanged(false)),
            const SizedBox(width: 10),
            _buildToggleChip('알고 있음', knowsHour, () => onKnowsHourChanged(true)),
          ],
        ),
        if (knowsHour) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 2.2,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final startHour = (index * 2 + 23) % 24;
                final jiji = SajuConstants.jiji[index];
                final animal = SajuConstants.jijiAnimal[index];
                final isSelected = selectedHour >= 0 &&
                    SajuConstants.getJijiForHour(selectedHour) == jiji;

                return GestureDetector(
                  onTap: () => onHourChanged(startHour == 23 ? 23 : startHour + 1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1A1A2E) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$jiji시 ($animal)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF2C2C2E),
                          ),
                        ),
                        Text(
                          '${startHour.toString().padLeft(2, '0')}~${((startHour + 2) % 24).toString().padLeft(2, '0')}시',
                          style: TextStyle(
                            fontSize: 9,
                            color: isSelected ? Colors.white70 : const Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildToggleChip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1A1A2E) : const Color(0xFFF8F6F0),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0xFF1A1A2E) : const Color(0xFFE5E5EA),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF2C2C2E),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 제출
  // ============================================================
  Widget _buildSubmitButton() {
    return Consumer<NamingProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.state == AppState.loading;

        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A2E),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFC7C7CC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('가족 사주 분석 중...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  )
                : const Text(
                    '작명 시작',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
          ),
        );
      },
    );
  }

  void _onSubmit() async {
    // 아기 시간 검증
    if (_babyKnowsHour && _babyHour < 0) {
      _showSnackBar('아기의 태어난 시간을 선택해주세요.');
      return;
    }

    final provider = context.read<NamingProvider>();

    // 미결제 결과가 있으면 차단 → 결과 화면으로 보냄
    if (provider.hasUnpaidNaming) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ResultScreen()),
      );
      return;
    }

    // 무료 체험 가능 시 단일 입력으로 처리
    if (provider.isFreeAvailable) {
      final input = SajuInput(
        year: _babyDate.year,
        month: _babyDate.month,
        day: _babyDate.day,
        hour: _babyHour,
        gender: _babyGender,
        surname: _surname,
      );
      await provider.generateFreeNames(input);
    } else {
      // 유료 작명: API 먼저 호출 (결제는 결과 화면에서)
      final familyInput = FamilyNamingInput(
        baby: SajuInput(
          year: _babyDate.year,
          month: _babyDate.month,
          day: _babyDate.day,
          hour: _babyHour,
          gender: _babyGender,
          surname: _surname,
        ),
        father: SajuInput(
          year: _fatherDate.year,
          month: _fatherDate.month,
          day: _fatherDate.day,
          hour: _fatherHour,
          gender: Gender.male,
          surname: _surname,
        ),
        mother: SajuInput(
          year: _motherDate.year,
          month: _motherDate.month,
          day: _motherDate.day,
          hour: _motherHour,
          gender: Gender.female,
          surname: _surname,
        ),
      );

      await provider.generateFamilyNames(familyInput);
    }

    if (!mounted) return;

    if (provider.state == AppState.success) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ResultScreen()),
      );
    } else if (provider.state == AppState.error) {
      _showSnackBar(provider.errorMessage);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }
}
