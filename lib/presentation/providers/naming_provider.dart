// 작명/진단 상태 관리 Provider
// B 방식: API 먼저 호출 → 1개 공개 → 결제 후 전체 공개
// 미결제 결과 캐싱으로 악용 방지

import 'package:flutter/foundation.dart';
import '../../data/models/saju_input.dart';
import '../../data/models/naming_result.dart';
import '../../data/models/diagnosis_result.dart';
import '../../data/models/saved_result.dart';
import '../../data/services/claude_service.dart';
import '../../data/services/purchase_service.dart';
import '../../data/services/result_storage_service.dart';

enum AppState { idle, loading, success, error }

class NamingProvider extends ChangeNotifier {
  final PurchaseService purchaseService;
  final ResultStorageService storageService;

  NamingProvider({
    required this.purchaseService,
    required this.storageService,
  }) {
    purchaseService.onStateUpdated = () => notifyListeners();
    purchaseService.onPurchaseCompleted = _onPurchaseCompleted;
    _loadCachedResults();
  }

  // ============================================================
  // 상태
  // ============================================================
  AppState _state = AppState.idle;
  AppState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // 작명 결과
  NamingResult? _namingResult;
  NamingResult? get namingResult => _namingResult;
  FamilyNamingInput? _lastFamilyInput;
  FamilyNamingInput? get lastFamilyInput => _lastFamilyInput;
  SajuInput? _lastSimpleInput;
  SajuInput? get lastSimpleInput => _lastSimpleInput;

  // 진단 결과
  DiagnosisResult? _diagnosisResult;
  DiagnosisResult? get diagnosisResult => _diagnosisResult;
  DiagnosisInput? _lastDiagnosisInput;
  DiagnosisInput? get lastDiagnosisInput => _lastDiagnosisInput;

  // 결제 상태
  bool _isNamingPaid = false;
  bool get isNamingPaid => _isNamingPaid;

  bool _isDiagnosisPaid = false;
  bool get isDiagnosisPaid => _isDiagnosisPaid;

  // 무료 체험
  bool get isFreeAvailable => purchaseService.isFreeAvailable;
  bool _isFreeTrial = false;
  bool get isFreeTrial => _isFreeTrial;

  // 저장 결과
  List<SavedResult> get savedResults => storageService.getAll();

  // ============================================================
  // 미결제 결과 캐시 로드 (앱 시작 시)
  // ============================================================
  void _loadCachedResults() {
    // 미결제 작명 결과가 있으면 복원
    final unpaidNaming = storageService.getUnpaid(SavedResultType.naming);
    if (unpaidNaming != null) {
      _namingResult = unpaidNaming.namingResult;
      _lastFamilyInput = unpaidNaming.familyInput;
      _lastSimpleInput = unpaidNaming.simpleInput;
      _isNamingPaid = false;
    }

    // 미결제 진단 결과가 있으면 복원
    final unpaidDiagnosis = storageService.getUnpaid(SavedResultType.diagnosis);
    if (unpaidDiagnosis != null) {
      _diagnosisResult = unpaidDiagnosis.diagnosisResult;
      _lastDiagnosisInput = unpaidDiagnosis.diagnosisInput;
      _isDiagnosisPaid = false;
    }
  }

  // ============================================================
  // 미결제 결과 존재 여부 (새 요청 차단용)
  // ============================================================
  bool get hasUnpaidNaming => storageService.hasUnpaid(SavedResultType.naming);
  bool get hasUnpaidDiagnosis => storageService.hasUnpaid(SavedResultType.diagnosis);

  // ============================================================
  // 신규 작명 (가족 사주 기반)
  // B 방식: 먼저 API 호출 → 미결제로 저장 → 결제 후 전체 공개
  // ============================================================

  /// 무료 체험 작명 (단일 입력, 1회만)
  Future<void> generateFreeNames(SajuInput input) async {
    if (!isFreeAvailable) {
      _setError('무료 체험은 1회만 가능합니다.');
      return;
    }

    _setLoading();

    try {
      _namingResult = await ClaudeService.generateNames(input);
      _lastSimpleInput = input;
      _lastFamilyInput = null;
      _isFreeTrial = true;
      _isNamingPaid = false;
      await purchaseService.useFreeTrial();

      // 미결제 상태로 저장 (껐다 켜도 같은 결과)
      await _saveUnpaidNaming();

      _state = AppState.success;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
    }

    notifyListeners();
  }

  /// 유료 작명 - API 먼저 호출 (결제는 결과 화면에서)
  Future<void> generateFamilyNames(FamilyNamingInput input) async {
    // 미결제 결과가 있으면 차단
    if (hasUnpaidNaming) {
      _setError('이전 작명 결과가 미결제 상태입니다. 결제 후 새로운 작명이 가능합니다.');
      return;
    }

    _setLoading();
    _lastFamilyInput = input;
    _lastSimpleInput = null;

    try {
      _namingResult = await ClaudeService.generateFamilyNames(
        familyInput: input,
        nameCount: 5,
      );
      _isFreeTrial = false;
      _isNamingPaid = false;
      _state = AppState.success;

      // 미결제 상태로 저장
      await _saveUnpaidNaming();
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
    }

    notifyListeners();
  }

  // ============================================================
  // 이름 진단
  // ============================================================

  /// 이름 진단 - API 먼저 호출
  Future<void> diagnoseName(DiagnosisInput input) async {
    if (hasUnpaidDiagnosis) {
      _setError('이전 진단 결과가 미결제 상태입니다. 결제 후 새로운 진단이 가능합니다.');
      return;
    }

    _setLoading();
    _lastDiagnosisInput = input;

    try {
      _diagnosisResult = await ClaudeService.diagnoseName(input: input);
      _isDiagnosisPaid = false;
      _state = AppState.success;

      // 미결제 상태로 저장
      await _saveUnpaidDiagnosis(input);
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
    }

    notifyListeners();
  }

  /// 진단 후 업그레이드 (추가 개선 이름 5개)
  Future<void> upgradeFromDiagnosis() async {
    if (_diagnosisResult == null || _lastDiagnosisInput == null) return;

    _setLoading();

    try {
      final additionalNames = await ClaudeService.generateImprovementNames(
        input: _lastDiagnosisInput!,
        previousResult: _diagnosisResult!,
        nameCount: 5,
      );

      _diagnosisResult = DiagnosisResult(
        saju: _diagnosisResult!.saju,
        diagnosis: _diagnosisResult!.diagnosis,
        improvementNames: [
          ..._diagnosisResult!.improvementNames,
          ...additionalNames,
        ],
      );

      _state = AppState.success;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
    }

    notifyListeners();
  }

  // ============================================================
  // 결제 흐름 (결과 화면에서 호출)
  // ============================================================

  /// 결제 시작
  Future<bool> purchaseProduct(ProductType type) async {
    final product = purchaseService.getProduct(type);
    return await purchaseService.purchase(product);
  }

  void _onPurchaseCompleted(ProductType type) {
    switch (type) {
      case ProductType.naming:
        _unlockNaming();
        break;
      case ProductType.diagnosis:
        _unlockDiagnosis();
        break;
      case ProductType.bundle:
        _unlockNaming();
        _unlockDiagnosis();
        break;
      case ProductType.diagnosisUpgrade:
        break;
    }
    notifyListeners();
  }

  /// 작명 결과 전체 공개
  Future<void> _unlockNaming() async {
    _isNamingPaid = true;
    final unpaid = storageService.getUnpaid(SavedResultType.naming);
    if (unpaid != null) {
      await storageService.markAsPaid(unpaid.id);
    }
  }

  /// 진단 결과 전체 공개
  Future<void> _unlockDiagnosis() async {
    _isDiagnosisPaid = true;
    final unpaid = storageService.getUnpaid(SavedResultType.diagnosis);
    if (unpaid != null) {
      await storageService.markAsPaid(unpaid.id);
    }
  }

  // ============================================================
  // 미결제 결과 저장
  // ============================================================

  Future<void> _saveUnpaidNaming() async {
    if (_namingResult == null) return;

    final saved = SavedResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: SavedResultType.naming,
      savedAt: DateTime.now(),
      isPaid: false,
      familyInput: _lastFamilyInput,
      simpleInput: _lastSimpleInput,
      namingResult: _namingResult,
    );

    await storageService.save(saved);
  }

  Future<void> _saveUnpaidDiagnosis(DiagnosisInput input) async {
    if (_diagnosisResult == null) return;

    final saved = SavedResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: SavedResultType.diagnosis,
      savedAt: DateTime.now(),
      isPaid: false,
      diagnosisInput: input,
      diagnosisResult: _diagnosisResult,
    );

    await storageService.save(saved);
  }

  // ============================================================
  // 결과 관리
  // ============================================================

  /// 저장 결과 삭제
  Future<void> deleteSavedResult(String id) async {
    await storageService.delete(id);
    notifyListeners();
  }

  // ============================================================
  // 유틸
  // ============================================================

  void _setLoading() {
    _state = AppState.loading;
    _errorMessage = '';
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _state = AppState.error;
  }

  /// 상태 초기화 (새로운 세션)
  void reset() {
    _state = AppState.idle;
    _namingResult = null;
    _diagnosisResult = null;
    _lastFamilyInput = null;
    _lastSimpleInput = null;
    _lastDiagnosisInput = null;
    _isNamingPaid = false;
    _isDiagnosisPaid = false;
    _isFreeTrial = false;
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    purchaseService.dispose();
    super.dispose();
  }
}
