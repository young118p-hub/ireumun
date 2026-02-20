# 이름운 - AI 사주 작명 앱

## Stack
- Flutter 3.38.9, Dart 3.10.8
- Provider (상태관리)
- Claude API via 백엔드 서버 (앱에서 직접 호출 X)
- in_app_purchase (소모성 크레딧)
- Supabase Edge Functions (백엔드)
- Package: com.ireumun.ireumun

## Flutter SDK 경로
- `C:\Users\com\flutter_sdk` (전역 공유)

## Build & Run
```bash
flutter run
flutter build appbundle
```

## Architecture
```
lib/
├── core/constants/     ← 사주 상수 (천간지지/오행)
├── data/
│   ├── models/         ← SajuInput, NamingResult
│   └── services/       ← API 서비스, 크레딧 서비스
└── presentation/
    ├── providers/      ← NamingProvider
    ├── screens/        ← Home, Result, Paywall
    └── widgets/        ← NameCard, SajuCard

backend/                ← Supabase Edge Function (Claude API 프록시)
```

## Key Files
- `lib/data/services/claude_service.dart` - 백엔드 서버 호출 + 재시도 + JSON 파싱
- `lib/data/services/credit_service.dart` - 크레딧 관리 (구매/차감/잔액)
- `lib/presentation/providers/naming_provider.dart` - 상태관리
- `lib/core/constants/saju_constants.dart` - 천간지지/오행 상수
- `lib/data/models/naming_result.dart` - AI 응답 모델

## 비즈니스 모델 (크레딧 방식)
- **무료**: 첫 1회 작명 무료, 결과 중 1번 이름만 공개 (나머지 블러)
- **크레딧 구매** (소모성 인앱결제):
  - `credits_3` → 3회 / ₩1,900
  - `credits_10` → 10회 / ₩3,900 (가성비)
  - `credits_30` → 30회 / ₩6,900 (대량)
- 크레딧 1회 = 작명 1회 (전체 7개 이름 공개)
- 무료 체험에서는 1번 이름만 보여주고, 크레딧 사용 시 전체 해금

## 서버 구조
- 앱 → Supabase Edge Function → Claude API
- Claude API 키는 서버 환경변수에만 보관
- 앱에는 API 키 포함되지 않음

## 디자인
- 모던 미니멀 (전통 사주앱 느낌 X)
- Primary: #1A1A2E (네이비)
- Background: #F8F6F0 (크림)
- 갈색/한지/구닥다리 느낌 사용하지 않음
