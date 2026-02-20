// 작명 상태 관리 Provider
// 입력 → API 호출 → 결과 관리 + 크레딧 연동

import 'package:flutter/foundation.dart';
import '../../data/models/saju_input.dart';
import '../../data/models/naming_result.dart';
import '../../data/services/claude_service.dart';
import '../../data/services/credit_service.dart';

enum NamingState { idle, loading, success, error }

class NamingProvider extends ChangeNotifier {
  final CreditService creditService;

  NamingProvider({required this.creditService}) {
    creditService.onCreditUpdated = () {
      notifyListeners();
    };
  }

  // 상태
  NamingState _state = NamingState.idle;
  NamingState get state => _state;

  NamingResult? _result;
  NamingResult? get result => _result;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  SajuInput? _lastInput;
  SajuInput? get lastInput => _lastInput;

  // 크레딧 상태 프록시
  int get credits => creditService.credits;
  bool get canGenerate => creditService.canGenerate;
  bool get isFreeAvailable => creditService.isFreeAvailable;

  // 현재 결과가 크레딧으로 해금됐는지 (무료 체험은 1번만 공개)
  bool _currentResultUnlocked = false;
  bool get isCurrentResultUnlocked => _currentResultUnlocked;

  /// 이름 생성 요청
  Future<void> generateNames(SajuInput input) async {
    if (!canGenerate) {
      _errorMessage = '크레딧이 부족합니다. 크레딧을 구매해주세요.';
      _state = NamingState.error;
      notifyListeners();
      return;
    }

    _state = NamingState.loading;
    _errorMessage = '';
    _lastInput = input;
    _currentResultUnlocked = false;
    notifyListeners();

    try {
      _result = await ClaudeService.generateNames(input);
      _state = NamingState.success;

      // 크레딧 차감
      if (isFreeAvailable) {
        await creditService.useFreeTrialCredit();
        // 무료 체험: 1번 이름만 공개
        _currentResultUnlocked = false;
      } else {
        await creditService.useCredit();
        // 크레딧 사용: 전체 이름 공개
        _currentResultUnlocked = true;
      }
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = NamingState.error;
    }

    notifyListeners();
  }

  /// 크레딧으로 현재 결과 해금 (무료 체험 후 추가 해금)
  Future<bool> unlockCurrentResult() async {
    if (_currentResultUnlocked) return true;
    if (credits <= 0) return false;

    final success = await creditService.useCredit();
    if (success) {
      _currentResultUnlocked = true;
      notifyListeners();
    }
    return success;
  }

  /// 크레딧 패키지 구매
  Future<bool> purchaseCredits(CreditPackage package) async {
    return await creditService.purchase(package);
  }

  /// 크레딧 패키지 목록
  List<CreditPackage> get packages => creditService.packages;

  /// 상태 초기화 (새로운 작명 시작)
  void reset() {
    _state = NamingState.idle;
    _result = null;
    _errorMessage = '';
    _lastInput = null;
    _currentResultUnlocked = false;
    notifyListeners();
  }

  @override
  void dispose() {
    creditService.dispose();
    super.dispose();
  }
}
