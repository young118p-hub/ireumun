-- AI 호출 토큰 기록
-- 무료 미리보기가 AI 비용을 얼마나 쓰는지 실제 숫자로 보려고 남긴다 (추정 ₩70/회).
-- label: naming / naming_simple / diagnosis (무료 미리보기 생성), diagnosis_upgrade (결제 뒤)
-- 형식이 틀려 다시 부른 호출도 한 줄씩 남는다.

create table public.ai_usage (
  id bigint generated always as identity primary key,
  label text not null,
  model text not null,
  input_tokens int not null,
  output_tokens int not null,
  stop_reason text,
  created_at timestamptz not null default now()
);
create index ai_usage_created on public.ai_usage (created_at);

alter table public.ai_usage enable row level security;
revoke all on public.ai_usage from anon, authenticated;

-- 대시보드 SQL 편집기에서 보는 용도: select * from ai_usage_daily;
create view public.ai_usage_daily with (security_invoker = true) as
select
  (created_at at time zone 'Asia/Seoul')::date as day,
  label,
  model,
  count(*) as calls,
  sum(input_tokens) as input_tokens,
  sum(output_tokens) as output_tokens,
  round(avg(output_tokens)) as avg_output_tokens
from public.ai_usage
group by 1, 2, 3
order by 1 desc, 2;

revoke all on public.ai_usage_daily from anon, authenticated;
