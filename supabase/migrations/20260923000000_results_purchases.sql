-- 결과·구매·무료 미리보기 제한
-- 앱은 이 테이블에 직접 접근하지 않는다. Edge Function(service role)만 읽고 쓴다.
-- 그래서 RLS를 켜고 정책을 두지 않는다 (anon/authenticated 전부 차단).

-- 기기 (ANDROID_ID). 재설치해도 같은 값이라 무료 체험 기록이 유지된다.
create table public.devices (
  device_id text primary key check (length(device_id) between 8 and 128),
  free_trial_used_at timestamptz,
  created_at timestamptz not null default now()
);

-- 작명·진단 결과. content는 전체 결과이고, 결제 전에는 서버가 미리보기만 잘라서 내보낸다.
create table public.results (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  device_id text not null,
  kind text not null check (kind in ('naming', 'diagnosis')),
  request_type text not null,
  input jsonb not null,
  content jsonb not null,
  paid_products text[] not null default '{}',
  is_free_trial boolean not null default false,
  created_at timestamptz not null default now()
);
create index results_user_created on public.results (user_id, created_at desc);

-- 무료 미리보기 사용 기록. AI 호출 전에 먼저 잡고, 실패하면 지운다.
create table public.preview_claims (
  id uuid primary key default gen_random_uuid(),
  device_id text not null,
  user_id uuid not null references auth.users (id) on delete cascade,
  result_id uuid references public.results (id) on delete set null,
  created_at timestamptz not null default now()
);
create index preview_claims_device_created on public.preview_claims (device_id, created_at);
create index preview_claims_user_created on public.preview_claims (user_id, created_at);

-- Google Play 구매. purchase_token이 키라서 같은 영수증을 두 번 쓸 수 없다.
create table public.purchases (
  purchase_token text primary key,
  order_id text,
  user_id uuid not null references auth.users (id) on delete cascade,
  product_id text not null,
  result_ids uuid[] not null,
  status text not null check (status in ('verified', 'delivered')),
  created_at timestamptz not null default now(),
  delivered_at timestamptz
);

alter table public.devices enable row level security;
alter table public.results enable row level security;
alter table public.preview_claims enable row level security;
alter table public.purchases enable row level security;
revoke all on public.devices, public.results, public.preview_claims, public.purchases
  from anon, authenticated;

-- 미리보기 한 칸 잡기. 최근 24시간 동안 이 기기 또는 이 사용자가 만든 것 중
-- 아직 결제되지 않은 것만 센다 (결제한 결과는 한도에서 빠짐).
-- 같은 기기의 동시 요청은 advisory lock으로 줄 세운다.
create function public.claim_preview(p_device text, p_user uuid, p_limit int)
returns table (ok boolean, claim_id uuid, used int)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_used int;
  v_id uuid;
begin
  perform pg_advisory_xact_lock(hashtext('preview:' || p_device));

  select count(*) into v_used
  from preview_claims c
  left join results r on r.id = c.result_id
  where (c.device_id = p_device or c.user_id = p_user)
    and c.created_at > now() - interval '24 hours'
    and (r.id is null or cardinality(r.paid_products) = 0);

  if v_used >= p_limit then
    return query select false, null::uuid, v_used;
    return;
  end if;

  insert into preview_claims (device_id, user_id) values (p_device, p_user)
  returning id into v_id;
  return query select true, v_id, v_used + 1;
end;
$$;

-- 이 기기의 첫 작명이면 무료 체험으로 기록하고 true를 돌려준다.
create function public.use_free_trial(p_device text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_updated int;
begin
  insert into devices (device_id) values (p_device) on conflict (device_id) do nothing;
  update devices set free_trial_used_at = now()
  where device_id = p_device and free_trial_used_at is null;
  get diagnostics v_updated = row_count;
  return v_updated = 1;
end;
$$;

-- 결제 반영. 이미 들어 있는 상품은 다시 넣지 않는다.
create function public.add_paid_product(p_result_ids uuid[], p_product text)
returns void
language sql
security definer
set search_path = public
as $$
  update results
  set paid_products = array_append(paid_products, p_product)
  where id = any (p_result_ids) and not (p_product = any (paid_products));
$$;

-- 최근 24시간 미리보기 사용 수 (claim_preview와 같은 기준)
create function public.preview_usage(p_device text, p_user uuid)
returns int
language sql
stable
security definer
set search_path = public
as $$
  select count(*)::int
  from preview_claims c
  left join results r on r.id = c.result_id
  where (c.device_id = p_device or c.user_id = p_user)
    and c.created_at > now() - interval '24 hours'
    and (r.id is null or cardinality(r.paid_products) = 0);
$$;

revoke execute on function public.claim_preview(text, uuid, int) from public, anon, authenticated;
revoke execute on function public.use_free_trial(text) from public, anon, authenticated;
revoke execute on function public.add_paid_product(uuid[], text) from public, anon, authenticated;
revoke execute on function public.preview_usage(text, uuid) from public, anon, authenticated;
