// 작명/진단 상태 관리 Provider
// 흐름: 서버가 AI로 결과를 만들어 저장 → 앱은 미리보기(첫 이름 / 점수·한 줄 요약)만 받음
//      → 결제(서버 영수증 검증) 뒤에 전체를 받아 기기에 저장 → '내 결과'에서 언제든 다시 보기
// 무료 체험·미리보기 한도는 서버가 기기 단위로 관리한다 (재설치해도 유지).

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/saju_input.dart';
import '../../data/models/naming_result.dart';
import '../../data/models/diagnosis_result.dart';
import '../../data/models/saved_result.dart';
import '../../data/services/api_service.dart';
import '../../data/services/purchase_service.dart';
import '../../data/services/result_storage_service.dart';

enum AppState { idle, loading, success, error }

class NamingProvider extends ChangeNotifier {
  static const _freeTrialKey = 'free_trial_available';

  final PurchaseService purchaseService;
  final ResultStorageService storageService;
  final Api api;

  /// 화면 어디서든 띄우는 안내 (결제 완료·취소 등). main에서 스낵바로 연결.
  void Function(String message)? onNotice;

  /// 우리 케미·가족 케미 서버 결과 (동기화·결제 완료). 작명·진단 저장소가 아니라 케미 기록이 받는다. main에서 연결.
  Future<void> Function(RemoteResult result)? onChemiResult;

  NamingProvider({
    required this.purchaseService,
    required this.storageService,
    required this.api,
  }) {
    purchaseService.onDelivered = _onDelivered;
    purchaseService.onEvent = _onPurchaseEvent;
    _loadCachedResults();
  }

  // ============================================================
  // 상태
  // ============================================================
  AppState _state = AppState.idle;
  AppState get state => _state;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  /// 지금 보고 있는 작명 / 진단 결과
  SavedResult? _naming;
  SavedResult? _diagnosis;

  NamingResult? get namingResult => _naming?.namingResult;
  FamilyNamingInput? get lastFamilyInput => _naming?.familyInput;
  SajuInput? get lastSimpleInput => _naming?.simpleInput;
  String get namingSurname => _naming?.surname ?? '';
  bool get isNamingPaid => _naming?.isPaid ?? false;
  bool get isFreeTrial => _naming?.isFreeTrial ?? false;
  int get lockedNamingCount => _naming?.lockedCount ?? 0;

  DiagnosisResult? get diagnosisResult => _diagnosis?.diagnosisResult;
  DiagnosisInput? get lastDiagnosisInput => _diagnosis?.diagnosisInput;
  String get diagnosisSurname => _diagnosis?.surname ?? '';
  bool get isDiagnosisPaid => _diagnosis?.isPaid ?? false;
  int get lockedDiagnosisCount => _diagnosis?.lockedCount ?? 0;
  bool get hasDiagnosisUpgrade => _diagnosis?.hasDiagnosisUpgrade ?? false;

  // 무료 체험 (서버 기준, 기기에는 마지막으로 받은 값만 캐시)
  bool _freeTrialAvailable = true;
  bool get isFreeAvailable => _freeTrialAvailable;

  /// 오늘 남은 무료 미리보기 (모르면 null)
  int? _previewsLeft;
  int? get previewsLeft => _previewsLeft;

  // 결제 진행 중 (버튼 중복 탭 방지)
  bool _purchaseBusy = false;
  bool get purchaseBusy => _purchaseBusy;
  String? _purchaseStatus;
  String? get purchaseStatus => _purchaseStatus;

  // 저장 결과
  List<SavedResult> get savedResults => storageService.getAll();

  bool get hasUnpaidNaming =>
      storageService.getUnpaid(SavedResultType.naming) != null;
  bool get hasUnpaidDiagnosis =>
      storageService.getUnpaid(SavedResultType.diagnosis) != null;

  PlanProduct product(ProductType type) => purchaseService.getProduct(type);

  // ============================================================
  // 시작
  // ============================================================

  /// 미결제 결과가 있으면 이어서 보여준다 (껐다 켜도 같은 결과)
  void _loadCachedResults() {
    _naming = storageService.getUnpaid(SavedResultType.naming);
    _diagnosis = storageService.getUnpaid(SavedResultType.diagnosis);
  }

  /// 앱 시작 시: 로그인 → 서버 상태 동기화 → 덜 끝난 결제 이어받기.
  /// 오프라인이면 조용히 넘어간다 (기기에 저장된 결과는 그대로 볼 수 있음).
  Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    _freeTrialAvailable = prefs.getBool(_freeTrialKey) ?? true;
    notifyListeners();

    try {
      await api.ensureSignedIn();
      final me = await api.me();
      _freeTrialAvailable = me.freeTrialAvailable;
      _previewsLeft = me.previewsLeft;
      await prefs.setBool(_freeTrialKey, me.freeTrialAvailable);
      for (final r in me.results) {
        if (r.isChemi) {
          await onChemiResult?.call(r);
          continue;
        }
        if (r.kind == null || storageService.isHidden(r.id)) continue; // 모르는 종류는 건너뜀
        await _store(r);
      }
      notifyListeners();
      await purchaseService.recoverUnfinished();
    } catch (_) {
      // 오프라인 등: 다음 요청 때 다시 시도
    }
  }

  // ============================================================
  // 작명 / 진단 생성 (무료 미리보기)
  // ============================================================

  /// 무료 체험 작명 (본인 사주, 기기당 1회)
  Future<void> generateFreeNames(SajuInput input) async {
    if (!isFreeAvailable) {
      _setError('무료 체험은 1회만 가능합니다.');
      notifyListeners();
      return;
    }
    await _generateNaming(ApiRequests.simpleNaming(input), simpleInput: input);
  }

  /// 작명 - 본인 사주만 (부모 미포함)
  Future<void> generatePaidSimpleNames(SajuInput input) =>
      _generateNaming(ApiRequests.simpleNaming(input), simpleInput: input);

  /// 작명 - 가족 사주 (아기 + 아빠 + 엄마)
  Future<void> generateFamilyNames(FamilyNamingInput input) =>
      _generateNaming(ApiRequests.familyNaming(input), familyInput: input);

  Future<void> _generateNaming(
    Map<String, dynamic> body, {
    SajuInput? simpleInput,
    FamilyNamingInput? familyInput,
  }) async {
    if (hasUnpaidNaming) await discardUnpaidNaming();
    _setLoading();
    try {
      final remote = await api.generate(body);
      final saved =
          remote.toSaved(simpleInput: simpleInput, familyInput: familyInput);
      await storageService.save(saved);
      _naming = saved;
      await _markFreeTrialUsed();
      _state = AppState.success;
    } on ApiException catch (e) {
      if (e.code == 'quota_exceeded') _previewsLeft = 0;
      _setError(e.message);
    }
    notifyListeners();
  }

  /// 이름 진단
  Future<void> diagnoseName(DiagnosisInput input) async {
    if (hasUnpaidDiagnosis) {
      _setError('결제 전인 내 이름 케미 결과가 있어요. 그 결과를 결제하거나 지운 뒤에 새로 측정할 수 있어요.');
      notifyListeners();
      return;
    }
    _setLoading();
    try {
      final remote = await api.generate(ApiRequests.diagnosis(input));
      final saved = remote.toSaved(diagnosisInput: input);
      await storageService.save(saved);
      _diagnosis = saved;
      _state = AppState.success;
    } on ApiException catch (e) {
      if (e.code == 'quota_exceeded') _previewsLeft = 0;
      _setError(e.message);
    }
    notifyListeners();
  }

  Future<void> _markFreeTrialUsed() async {
    if (!_freeTrialAvailable) return;
    _freeTrialAvailable = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_freeTrialKey, false);
  }

  // ============================================================
  // 결제
  // ============================================================

  /// 이 상품으로 지금 풀어줄 결과 (없으면 빈 목록 → 결제 불가)
  List<String> purchaseTargets(ProductType type) {
    switch (type) {
      case ProductType.naming:
        // 보고 있는 결과가 결제 전이면 그것, 아니면 가장 최근의 결제 전 결과
        final n = _naming != null && !_naming!.isPaid
            ? _naming
            : storageService.getUnpaid(SavedResultType.naming);
        return n != null ? [n.id] : const [];
      case ProductType.diagnosis:
        final d = _diagnosis != null && !_diagnosis!.isPaid
            ? _diagnosis
            : storageService.getUnpaid(SavedResultType.diagnosis);
        return d != null ? [d.id] : const [];
      case ProductType.bundle:
        // 결제 전인 작명·진단 결과가 둘 다 있어야 한다
        final n = storageService.getUnpaid(SavedResultType.naming);
        final d = storageService.getUnpaid(SavedResultType.diagnosis);
        return n != null && d != null ? [n.id, d.id] : const [];
      case ProductType.pairChemi:
      case ProductType.familyChemi:
        return const []; // 우리·가족 케미는 결과 ID를 직접 넘긴다 (purchaseResults)
      case ProductType.diagnosisUpgrade:
        final d = _diagnosis;
        return d != null && d.isPaid && !d.hasDiagnosisUpgrade
            ? [d.id]
            : const [];
    }
  }

  bool canPurchase(ProductType type) => purchaseTargets(type).isNotEmpty;

  /// 결제 시작. 결과는 _onDelivered로 오고, 안내는 onNotice로 뜬다.
  Future<void> purchase(ProductType type) async {
    final targets = purchaseTargets(type);
    if (targets.isEmpty) {
      onNotice?.call(type == ProductType.bundle
          ? '묶음 할인은 결제 전인 아기 이름과 내 이름 케미 결과가 하나씩 있을 때 쓸 수 있어요.'
          : '결제할 결과가 없어요. 먼저 결과를 받아 주세요.');
      return;
    }
    await purchaseResults(type, targets);
  }

  /// 결제할 결과를 직접 정해서 결제 (우리 케미처럼 작명·진단 저장소 밖의 결과)
  Future<void> purchaseResults(ProductType type, List<String> targets) async {
    if (_purchaseBusy || targets.isEmpty) return;
    _purchaseBusy = true;
    _purchaseStatus = null;
    notifyListeners();
    try {
      await purchaseService.buy(type, targets);
    } on ApiException catch (e) {
      _purchaseBusy = false;
      onNotice?.call(e.message);
    } on PurchaseFlowException catch (e) {
      _purchaseBusy = false;
      onNotice?.call(e.message);
    }
    notifyListeners();
  }

  /// 검증된 결제 결과를 기기에 저장 (이게 끝나야 구매가 소비된다)
  Future<void> _onDelivered(ProductType type, List<RemoteResult> results) async {
    for (final r in results) {
      if (r.isChemi) {
        await onChemiResult?.call(r);
      } else if (r.kind != null) {
        await _store(r);
      }
    }
    notifyListeners();
  }

  /// 서버 결과를 기기에 반영 (기기에만 있는 입력 원본은 유지)
  Future<void> _store(RemoteResult r) async {
    final local = storageService.getById(r.id);
    final saved = local != null ? r.applyTo(local) : r.toSaved();
    await storageService.save(saved);
    if (_naming?.id == r.id) _naming = saved;
    if (_diagnosis?.id == r.id) _diagnosis = saved;
  }

  void _onPurchaseEvent(PurchaseEvent e) {
    switch (e.kind) {
      case PurchaseEventKind.verifying:
        _purchaseBusy = true;
        _purchaseStatus = e.message;
        break;
      case PurchaseEventKind.pending:
      case PurchaseEventKind.delivered:
      case PurchaseEventKind.canceled:
      case PurchaseEventKind.failed:
        _purchaseBusy = false;
        _purchaseStatus = null;
        onNotice?.call(e.message);
        break;
    }
    notifyListeners();
  }

  // ============================================================
  // 결과 관리
  // ============================================================

  /// '내 결과'에서 고른 결과 열기
  void openSaved(SavedResult result) {
    final fresh = storageService.getById(result.id) ?? result;
    if (fresh.type == SavedResultType.naming) {
      _naming = fresh;
    } else {
      _diagnosis = fresh;
    }
    notifyListeners();
  }

  /// 결제 전인 진단 결과로 돌아가기 (새 진단 전에 먼저 결제하거나 버려야 함)
  void openUnpaidDiagnosis() {
    _diagnosis = storageService.getUnpaid(SavedResultType.diagnosis);
    notifyListeners();
  }

  /// 저장 결과 삭제
  Future<void> deleteSavedResult(String id) async {
    await storageService.delete(id);
    if (_naming?.id == id) _naming = null;
    if (_diagnosis?.id == id) _diagnosis = null;
    notifyListeners();
  }

  /// 미결제 작명 결과 버리고 새로 시작
  Future<void> discardUnpaidNaming() async {
    final unpaid = storageService.getUnpaid(SavedResultType.naming);
    if (unpaid != null) await storageService.delete(unpaid.id);
    _naming = null;
    _state = AppState.idle;
    notifyListeners();
  }

  /// 미결제 진단 결과 버리고 새로 시작
  Future<void> discardUnpaidDiagnosis() async {
    final unpaid = storageService.getUnpaid(SavedResultType.diagnosis);
    if (unpaid != null) await storageService.delete(unpaid.id);
    _diagnosis = null;
    _state = AppState.idle;
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
    _naming = null;
    _diagnosis = null;
    _errorMessage = '';
    notifyListeners();
  }

  @override
  void dispose() {
    purchaseService.dispose();
    super.dispose();
  }
}
