# 서버 (Supabase)

앱은 테이블에 직접 접근하지 않는다. Edge Function만 service role로 읽고 쓴다.

| 함수 | 하는 일 |
|---|---|
| `naming` | 작명·진단 생성 (무료 미리보기, 기기·계정당 24시간 한도) |
| `purchase` | `prepare`: 풀어줄 결과가 있는지 / `verify`: Play 영수증 검증 → 결과 열기 |
| `me` | 무료 체험 가능 여부, 남은 미리보기, 저장된 결과 |

## 처음 배포

```bash
supabase login
supabase link --project-ref <project-ref>
supabase db push                                   # migrations 적용
supabase secrets set CLAUDE_API_KEY=...            # Anthropic
supabase secrets set ANDROID_PACKAGE_NAME=com.chemilab.chemilab
supabase secrets set GOOGLE_PLAY_SERVICE_ACCOUNT="$(cat service-account.json)"
supabase secrets unset API_SECRET                  # 예전 공용 키 폐기
supabase functions deploy naming purchase me
```

대시보드에서 **Authentication > Sign In / Providers > Allow anonymous sign-ins**를 켠다.
(익명 가입은 IP당 시간당 30회로 기본 제한됨)

### Play 영수증 검증 준비
1. Google Cloud에서 서비스 계정 생성 → JSON 키 발급
2. Play Console > 사용자 및 권한 > 서비스 계정 초대, **재무 데이터 보기 / 주문 관리** 권한
3. 인앱 상품 `naming_new`, `diagnosis`, `bundle`, `diagnosis_upgrade`를 **소모성**으로 등록 (가격은 `lib/data/services/purchase_service.dart`의 `Prices`와 같게)

`GOOGLE_PLAY_SERVICE_ACCOUNT`나 `ANDROID_PACKAGE_NAME`이 없으면 모든 영수증을 거절한다 (실패 시 닫힘).

## 테스트

```bash
deno test -A tests/      # 핸들러(메모리 DB), Play 서명, SQL(PGlite)
```
