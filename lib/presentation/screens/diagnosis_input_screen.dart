// 이름 진단 입력 화면
// 현재 이름 + 생년월일시 입력

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/saju_constants.dart';
import '../../core/constants/hanja_data.dart';
import '../../data/models/saju_input.dart';
import '../providers/naming_provider.dart';
import 'diagnosis_result_screen.dart';

class DiagnosisInputScreen extends StatefulWidget {
  const DiagnosisInputScreen({super.key});

  @override
  State<DiagnosisInputScreen> createState() => _DiagnosisInputScreenState();
}

class _DiagnosisInputScreenState extends State<DiagnosisInputScreen> {
  final _nameController = TextEditingController();

  String _surname = '김';
  Gender _gender = Gender.male;
  DateTime _selectedDate = DateTime(1995, 1, 1);
  int _selectedHour = -1;
  bool _knowsHour = false;

  // 한자 피커: 이름 각 글자별 선택된 한자 (null = 모름)
  List<String?> _selectedHanja = [];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final syllables = _nameController.text.trim().characters.toList();
    setState(() {
      if (syllables.length > _selectedHanja.length) {
        _selectedHanja.addAll(List.filled(syllables.length - _selectedHanja.length, null));
      } else if (syllables.length < _selectedHanja.length) {
        _selectedHanja = _selectedHanja.sublist(0, syllables.length);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: const Text('이름 진단'),
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
                color: const Color(0xFF0984E3).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, size: 20, color: Color(0xFF0984E3)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '현재 이름과 사주의 궁합을 분석하고\n더 나은 이름을 추천해드립니다.',
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

            const SizedBox(height: 24),

            // 현재 이름 입력
            _buildLabel('현재 이름'),
            const SizedBox(height: 8),
            Row(
              children: [
                // 성씨
                SizedBox(
                  width: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
                      dropdownColor: Colors.white,
                      items: SajuConstants.commonSurnames.map((s) {
                        return DropdownMenuItem(value: s, child: Text('$s씨'));
                      }).toList(),
                      onChanged: (v) => setState(() => _surname = v ?? '김'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 이름 (성씨 제외)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: '이름 (예: 민수)',
                        hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A2E)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 한자 피커
            _buildHanjaPicker(),

            const SizedBox(height: 24),

            // 성별
            _buildLabel('성별'),
            const SizedBox(height: 8),
            _buildGenderSelector(),

            const SizedBox(height: 24),

            // 생년월일
            _buildLabel('생년월일 (양력)'),
            const SizedBox(height: 8),
            _buildDateSelector(),

            const SizedBox(height: 24),

            // 태어난 시간
            _buildLabel('태어난 시간'),
            const SizedBox(height: 8),
            _buildHourSelector(),

            const SizedBox(height: 36),

            // 진단 시작 버튼
            _buildSubmitButton(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

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

  Widget _buildHanjaPicker() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return const SizedBox.shrink();

    final syllables = name.characters.toList();
    if (_selectedHanja.length != syllables.length) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildLabel('한자 선택'),
            const SizedBox(width: 8),
            const Text(
              '선택',
              style: TextStyle(fontSize: 12, color: Color(0xFF0984E3), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '한자를 모르시면 선택 안 하셔도 됩니다',
          style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
        ),
        const SizedBox(height: 12),
        ...syllables.asMap().entries.map((entry) {
          final idx = entry.key;
          final syllable = entry.value;
          final options = HanjaData.hanjaByKorean[syllable] ?? [];

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 글자 + 선택된 한자 표시
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            syllable,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 14, color: Color(0xFFB0B0B0)),
                      const SizedBox(width: 8),
                      if (_selectedHanja[idx] != null) ...[
                        Text(
                          HanjaData.getChar(_selectedHanja[idx]!),
                          style: const TextStyle(
                            fontSize: 22,
                            color: Color(0xFF1A1A2E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          HanjaData.getMeaning(_selectedHanja[idx]!),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() => _selectedHanja[idx] = null),
                          child: const Icon(Icons.close, size: 16, color: Color(0xFF8E8E93)),
                        ),
                      ] else
                        const Text(
                          '선택 안 함',
                          style: TextStyle(fontSize: 13, color: Color(0xFFB0B0B0)),
                        ),
                    ],
                  ),
                  if (options.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        '이 글자의 한자 정보가 없습니다',
                        style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                      ),
                    )
                  else ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: options.map((entry) {
                        final hanjaChar = HanjaData.getChar(entry);
                        final meaning = HanjaData.getMeaning(entry);
                        final selectedChar = _selectedHanja[idx] != null
                            ? HanjaData.getChar(_selectedHanja[idx]!)
                            : null;
                        final isSelected = selectedChar == hanjaChar;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedHanja[idx] = isSelected ? null : entry;
                          }),
                          child: Container(
                            width: 64,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1A1A2E) : const Color(0xFFF8F6F0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF1A1A2E) : const Color(0xFFE5E5EA),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  hanjaChar,
                                  style: TextStyle(
                                    fontSize: 22,
                                    color: isSelected ? Colors.white : const Color(0xFF1A1A2E),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (meaning.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    meaning,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isSelected ? Colors.white70 : const Color(0xFF8E8E93),
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Row(
      children: [
        _buildGenderChip('남', Gender.male, Icons.male),
        const SizedBox(width: 10),
        _buildGenderChip('여', Gender.female, Icons.female),
      ],
    );
  }

  Widget _buildGenderChip(String label, Gender value, IconData icon) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1A1A2E) : Colors.white,
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

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            const Icon(Icons.calendar_today_outlined, color: Color(0xFF8E8E93), size: 18),
            const SizedBox(width: 10),
            Text(
              '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
              style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Color(0xFFC7C7CC), size: 20),
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
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Widget _buildHourSelector() {
    return Column(
      children: [
        Row(
          children: [
            _buildToggle('모름', !_knowsHour, () => setState(() {
              _knowsHour = false;
              _selectedHour = -1;
            })),
            const SizedBox(width: 10),
            _buildToggle('알고 있음', _knowsHour, () => setState(() => _knowsHour = true)),
          ],
        ),
        if (_knowsHour) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                      color: isSelected ? const Color(0xFF1A1A2E) : const Color(0xFFF8F6F0),
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

  Widget _buildToggle(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1A1A2E) : Colors.white,
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
              backgroundColor: const Color(0xFF0984E3),
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
                      Text('이름 분석 중...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  )
                : const Text(
                    '진단 시작',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
          ),
        );
      },
    );
  }

  void _onSubmit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('이름을 입력해주세요.');
      return;
    }
    if (name.characters.length > 3) {
      _showSnackBar('이름은 1~3글자로 입력해주세요.');
      return;
    }
    if (_knowsHour && _selectedHour < 0) {
      _showSnackBar('태어난 시간을 선택해주세요.');
      return;
    }

    // 선택된 한자 조합 (null은 빈칸으로, "char:meaning" 형식에서 char만 추출)
    final hanjaStr = _selectedHanja.map((h) => h != null ? HanjaData.getChar(h) : '').join('');

    final provider = context.read<NamingProvider>();

    // 미결제 결과가 있으면 차단 → 결과 화면으로 보냄
    if (provider.hasUnpaidDiagnosis) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DiagnosisResultScreen()),
      );
      return;
    }

    final input = DiagnosisInput(
      currentName: name,
      currentHanja: hanjaStr,
      person: SajuInput(
        year: _selectedDate.year,
        month: _selectedDate.month,
        day: _selectedDate.day,
        hour: _selectedHour,
        gender: _gender,
        surname: _surname,
      ),
    );

    // API 먼저 호출 (결제는 결과 화면에서)
    await provider.diagnoseName(input);

    if (!mounted) return;

    if (provider.state == AppState.success) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DiagnosisResultScreen()),
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
