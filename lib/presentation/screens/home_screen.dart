// 홈 화면 - 생년월일시 + 성씨 입력
// 사주 기반 AI 작명 입력 폼

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/saju_constants.dart';
import '../../data/models/saju_input.dart';
import '../providers/naming_provider.dart';
import 'result_screen.dart';
import 'paywall_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 폼 상태
  String _surname = '김';
  Gender _gender = Gender.male;
  DateTime _selectedDate = DateTime(2024, 1, 1);
  int _selectedHour = -1; // -1 = 시간 모름
  bool _knowsHour = false;

  // 날짜 선택기에서 사용
  int get _selectedYear => _selectedDate.year;
  int get _selectedMonth => _selectedDate.month;
  int get _selectedDay => _selectedDate.day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 앱 타이틀 + 크레딧 잔액
              Center(
                child: Column(
                  children: [
                    Text(
                      '이름운',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'AI 사주 작명',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF8E8E93),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Consumer<NamingProvider>(
                      builder: (context, provider, _) {
                        if (provider.isFreeAvailable) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '무료 체험 1회 가능',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                          );
                        }
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PaywallScreen()),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.toll, size: 14, color: Color(0xFF1A1A2E)),
                                const SizedBox(width: 6),
                                Text(
                                  '크레딧 ${provider.credits}회',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // ── 성씨 선택 ──
              _buildSectionLabel('성씨'),
              const SizedBox(height: 8),
              _buildSurnameSelector(),

              const SizedBox(height: 24),

              // ── 성별 선택 ──
              _buildSectionLabel('성별'),
              const SizedBox(height: 8),
              _buildGenderSelector(),

              const SizedBox(height: 24),

              // ── 생년월일 ──
              _buildSectionLabel('생년월일 (양력)'),
              const SizedBox(height: 8),
              _buildDateSelector(),

              const SizedBox(height: 24),

              // ── 태어난 시간 ──
              _buildSectionLabel('태어난 시간'),
              const SizedBox(height: 8),
              _buildHourSelector(),

              const SizedBox(height: 40),

              // ── 작명 시작 버튼 ──
              _buildSubmitButton(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2C2C2E),
      ),
    );
  }

  // ============================================================
  // 성씨 선택
  // ============================================================
  Widget _buildSurnameSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _surname,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.person_outline, color: Color(0xFF8E8E93)),
        ),
        style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A2E)),
        dropdownColor: Colors.white,
        items: SajuConstants.commonSurnames.map((s) {
          return DropdownMenuItem(value: s, child: Text('$s씨'));
        }).toList(),
        onChanged: (v) => setState(() => _surname = v ?? '김'),
      ),
    );
  }

  // ============================================================
  // 성별 선택
  // ============================================================
  Widget _buildGenderSelector() {
    return Row(
      children: [
        _buildGenderChip('남아', Gender.male, Icons.male),
        const SizedBox(width: 12),
        _buildGenderChip('여아', Gender.female, Icons.female),
      ],
    );
  }

  Widget _buildGenderChip(String label, Gender value, IconData icon) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFF1A1A2E) : const Color(0xFFE5E5EA),
              width: 1.5,
            ),
            boxShadow: selected
                ? [BoxShadow(color: const Color(0xFF1A1A2E).withValues(alpha: 0.2), blurRadius: 8)]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: selected ? Colors.white : const Color(0xFF8E8E93)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
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

  // ============================================================
  // 생년월일 선택
  // ============================================================
  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: Color(0xFF8E8E93), size: 20),
            const SizedBox(width: 12),
            Text(
              '${_selectedYear}년 ${_selectedMonth}월 ${_selectedDay}일',
              style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A2E)),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Color(0xFFC7C7CC)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ============================================================
  // 시간 선택
  // ============================================================
  Widget _buildHourSelector() {
    return Column(
      children: [
        // 시간 알음/모름 토글
        Row(
          children: [
            _buildHourToggle('모름', false),
            const SizedBox(width: 12),
            _buildHourToggle('알고 있음', true),
          ],
        ),
        if (_knowsHour) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
                final isSelected = _selectedHour >= 0 &&
                    SajuConstants.getJijiForHour(_selectedHour) == jiji;

                return GestureDetector(
                  onTap: () => setState(() => _selectedHour = startHour == 23 ? 23 : startHour + 1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1A1A2E)
                          : const Color(0xFFF8F6F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$jiji시 ($animal)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF2C2C2E),
                          ),
                        ),
                        Text(
                          '${startHour.toString().padLeft(2, '0')}~${((startHour + 2) % 24).toString().padLeft(2, '0')}시',
                          style: TextStyle(
                            fontSize: 9,
                            color: isSelected
                                ? Colors.white70
                                : const Color(0xFF8E8E93),
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

  Widget _buildHourToggle(String label, bool value) {
    final selected = _knowsHour == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _knowsHour = value;
          if (!value) _selectedHour = -1;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFF1A1A2E) : const Color(0xFFE5E5EA),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
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
  // 작명 시작 버튼
  // ============================================================
  Widget _buildSubmitButton() {
    return Consumer<NamingProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.state == NamingState.loading;

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
                      Text('사주 분석 중...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
    // 시간 알고 있다고 했는데 선택 안한 경우
    if (_knowsHour && _selectedHour < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('태어난 시간을 선택해주세요.')),
      );
      return;
    }

    final provider = context.read<NamingProvider>();

    // 크레딧 부족 시 구매 화면으로
    if (!provider.canGenerate) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      return;
    }

    final input = SajuInput(
      year: _selectedYear,
      month: _selectedMonth,
      day: _selectedDay,
      hour: _selectedHour,
      gender: _gender,
      surname: _surname,
    );

    await provider.generateNames(input);

    if (!mounted) return;

    if (provider.state == NamingState.success) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ResultScreen()),
      );
    } else if (provider.state == NamingState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }
}
