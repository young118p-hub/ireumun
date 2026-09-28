-- 우리 케미(pair)·가족 케미(family) 결과를 같은 results 테이블에 담는다.
-- 무료로 보이는 점수·해설은 앱이 규칙으로 계산하고, 서버에는 결제 뒤 AI 전체 리포트만 채운다.

alter table public.results drop constraint results_kind_check;
alter table public.results add constraint results_kind_check
  check (kind in ('naming', 'diagnosis', 'pair', 'family'));
