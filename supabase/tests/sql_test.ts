// 마이그레이션 SQL을 실제 Postgres(PGlite)에 적용해서 확인
import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import { PGlite } from "npm:@electric-sql/pglite@0.3";

const MIGRATIONS = new URL("../migrations/", import.meta.url);
const U1 = "11111111-1111-1111-1111-111111111111";
const U2 = "22222222-2222-2222-2222-222222222222";
const DEV = "a1b2c3d4e5f60718";

async function db() {
  const pg = new PGlite();
  // Supabase가 미리 만들어 두는 것들 흉내
  await pg.exec(`
    create role anon; create role authenticated;
    create schema auth; create table auth.users (id uuid primary key);
    insert into auth.users values ('${U1}'), ('${U2}');
    grant usage on schema public to anon, authenticated;
    alter default privileges in schema public grant all on tables to anon, authenticated;
    grant all on schema public to anon, authenticated;
  `);
  // 파일 이름(날짜) 순서대로 전부 적용 — 실제 db push와 같게
  const files = [...Deno.readDirSync(MIGRATIONS)].map((e) => e.name).filter((n) => n.endsWith(".sql")).sort();
  for (const f of files) await pg.exec(await Deno.readTextFile(new URL(f, MIGRATIONS)));
  return pg;
}

async function claim(pg: PGlite, dev: string, user: string, limit = 3) {
  const r = await pg.query<{ ok: boolean; claim_id: string | null; used: number }>(
    "select * from claim_preview($1, $2, $3)", [dev, user, limit]);
  return r.rows[0];
}

async function result(pg: PGlite, user: string, dev = DEV) {
  const r = await pg.query<{ id: string }>(
    `insert into results (user_id, device_id, kind, request_type, input, content)
     values ($1, $2, 'naming', 'naming_simple', '{}', '{}') returning id`, [user, dev]);
  return r.rows[0].id;
}

Deno.test("claim_preview: 기기 한도, 다른 계정이어도 같은 기기면 합산", async () => {
  const pg = await db();
  for (let i = 1; i <= 3; i++) assertEquals((await claim(pg, DEV, U1)).used, i);
  assertEquals((await claim(pg, DEV, U1)).ok, false);
  assertEquals((await claim(pg, DEV, U2)).ok, false);
  assertEquals((await claim(pg, "0000000000000000", U1)).ok, false); // 같은 계정, 다른 기기 ID
  assertEquals((await claim(pg, "0000000000000000", U2)).ok, true);
});

Deno.test("claim_preview: 24시간 지난 것, 결제된 결과는 세지 않는다", async () => {
  const pg = await db();
  const c1 = await claim(pg, DEV, U1);
  const c2 = await claim(pg, DEV, U1);
  await claim(pg, DEV, U1);
  await pg.query("update preview_claims set created_at = now() - interval '25 hours' where id = $1", [c1.claim_id]);
  const rid = await result(pg, U1);
  await pg.query("update preview_claims set result_id = $1 where id = $2", [rid, c2.claim_id]);
  await pg.query("select add_paid_product($1::uuid[], 'naming_new')", [[rid]]);
  assertEquals((await pg.query<{ n: number }>("select preview_usage($1, $2) n", [DEV, U1])).rows[0].n, 1);
  assertEquals((await claim(pg, DEV, U1)).ok, true);
});

Deno.test("use_free_trial: 기기당 처음 한 번만 true", async () => {
  const pg = await db();
  const use = async () => (await pg.query<{ v: boolean }>("select use_free_trial($1) v", [DEV])).rows[0].v;
  assertEquals(await use(), true);
  assertEquals(await use(), false);
});

Deno.test("add_paid_product: 같은 상품을 두 번 넣지 않는다", async () => {
  const pg = await db();
  const rid = await result(pg, U1);
  await pg.query("select add_paid_product($1::uuid[], 'naming_new')", [[rid]]);
  await pg.query("select add_paid_product($1::uuid[], 'naming_new')", [[rid]]);
  const r = await pg.query<{ p: string[] }>("select paid_products p from results where id = $1", [rid]);
  assertEquals(r.rows[0].p, ["naming_new"]);
});

Deno.test("purchases: 같은 영수증 토큰은 한 번만", async () => {
  const pg = await db();
  const rid = await result(pg, U1);
  const ins = () => pg.query(
    `insert into purchases (purchase_token, user_id, product_id, result_ids, status) values ('tok', $1, 'naming_new', $2::uuid[], 'verified')`,
    [U1, [rid]]);
  await ins();
  await assertRejects(ins);
});

Deno.test("앱 역할(anon/authenticated)은 테이블·함수에 직접 못 들어온다", async () => {
  const pg = await db();
  for (const role of ["anon", "authenticated"]) {
    await pg.exec(`set role ${role}`);
    for (const t of ["results", "purchases", "devices", "preview_claims"]) {
      await assertRejects(() => pg.query(`select * from ${t}`), Error, "permission denied");
    }
    await assertRejects(() => pg.query(`select * from claim_preview('${DEV}', '${U1}', 99)`), Error, "permission denied");
    await assertRejects(() => pg.query(`select use_free_trial('${DEV}')`), Error, "permission denied");
    await pg.exec("reset role");
  }
});

Deno.test("ai_usage: 기록이 날짜·요청별로 합산되고, 앱(anon·authenticated)은 못 읽는다", async () => {
  const pg = await db();
  await pg.exec(`
    insert into ai_usage (label, model, input_tokens, output_tokens) values
      ('naming_simple', 'm', 1500, 3000), ('naming_simple', 'm', 1500, 2000), ('diagnosis', 'm', 1200, 2500);
  `);
  const rows = (await pg.query<{ label: string; calls: number; output_tokens: number }>(
    "select label, calls::int, output_tokens::int from ai_usage_daily order by label")).rows;
  assertEquals(rows, [
    { label: "diagnosis", calls: 1, output_tokens: 2500 },
    { label: "naming_simple", calls: 2, output_tokens: 5000 },
  ]);
  for (const role of ["anon", "authenticated"]) {
    await pg.exec(`set role ${role}`);
    await assertRejects(() => pg.query("select * from ai_usage"));
    await assertRejects(() => pg.query("select * from ai_usage_daily"));
    await pg.exec("reset role");
  }
});
