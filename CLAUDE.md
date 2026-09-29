# 케미연구소 (구 이름운) - AI 사주 작명·궁합 앱 (미출시)

## Stack
- Flutter 3.38 / Dart 3.10, Provider (상태관리), Hive (기기 저장)
- Supabase: 익명 계정 인증 + Edge Functions(`naming` / `purchase` / `me`) + Postgres
- Claude API는 Edge Function에서만 호출 (앱에 키 없음)
- in_app_purchase (소모성, `autoConsume: false`)
- Package: com.chemilab.chemilab (Dart 패키지 `chemilab`). 저장소 폴더명·GitHub 저장소는 아직 ireumun

## Build & Run
```bash
cp env/example.json env/dev.json   # SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY 채우기 (커밋 금지)
flutter run --dart-define-from-file=env/dev.json
flutter test
cd supabase && deno test -A tests/
```
- `android/`는 커밋하지 않음 → 필요하면 `flutter create --platforms=android --org com.chemilab --project-name chemilab .` 후 `.metadata`·`README.md` 변경은 되돌리고, `AndroidManifest.xml`의 `android:label`을 "케미연구소"로
- 서버 배포·secrets: `supabase/README.md`

## 구조
- `lib/data/services/saju_calculator.dart` - 사주 계산 (검증된 로직, **알고리즘 변경 금지**, 버그 수정만). 절입일은 출생 시각으로 판정, 시간 미상은 21시 KST 기준
- `lib/data/services/api_service.dart` - 서버 호출 + 요청 본문(사주는 기기에서 계산해 보냄)
- `lib/data/services/purchase_service.dart` - 결제 흐름, 가격(`Prices`, 한 곳에서만)
- `lib/presentation/providers/naming_provider.dart` - 상태, 결과 보관·재열람
- `supabase/functions/_shared/` - 핸들러(`handlers.ts`), 상품 규칙(`catalog.ts`), Play 검증(`play.ts`), 프롬프트(`prompts.ts`)
- `docs/renewal-log.md` - 리뉴얼 단계별 무엇/왜 (작업하면 여기에 기록)

## 결제·결과 규칙
- 결제 전에는 서버가 미리보기만 보냄 (작명: 첫 이름, 진단: 점수·한 줄 요약). 나머지는 서버에만
- 순서: `prepare`(풀어줄 결과가 있어야 결제 창) → Play 결제 → `verify` → **기기 저장 → 소비**. 저장 전에 소비하면 안 됨
- 검증·저장 실패 시 소비하지 않음 → 다음 실행 때 `restorePurchases`로 이어받음 (verify는 같은 영수증에 같은 결과)
- 무료 미리보기: 기기(ANDROID_ID)·계정당 24시간 3회, 무료 체험은 기기당 1회 (서버 기준)
- 가격: 작명 ₩7,900 / 진단 ₩4,900 / 묶음 ₩10,900 / 추가 이름 ₩9,900 — Play Console과 맞출 것

## 디자인
- 모던 미니멀 (전통 사주앱 느낌 X), Primary #1A1A2E (네이비), Background #F8F6F0 (크림)
- 갈색/한지/구닥다리 느낌 사용하지 않음
- 디자인 토큰은 3단계에서 정리 예정 (지금은 화면마다 색이 직접 들어 있음)
