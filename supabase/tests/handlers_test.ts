// 작명 미리보기 한도, 무료 체험, 결제 준비·검증 흐름
import { assert, assertEquals, assertRejects } from "jsr:@std/assert@1";
import { handleGenerate, handleMe, handlePrepare, handleVerify, type Deps } from "../functions/_shared/handlers.ts";
import { ApiError } from "../functions/_shared/http.ts";
import type { PlayPurchase } from "../functions/_shared/play.ts";
import { MemoryRepo } from "./memory_repo.ts";
import { onlyHanja } from "../functions/_shared/handlers.ts";

const SAJU = {
  yearPillar: "갑진", monthPillar: "병인", dayPillar: "무술", hourPillar: "미상", dayMaster: "무",
  ohengBalance: { 목: 2, 화: 3, 토: 3, 금: 0, 수: 0 }, weakElement: "금", strongElement: "토", summary: "요약",
};
const names = (n: number, prefix = "이름") =>
  Array.from({ length: n }, (_, i) => ({ name: `${prefix}${i}`, hanja: "漢字", score: 90 }));

const USER = { id: "11111111-1111-1111-1111-111111111111" };
const OTHER = { id: "22222222-2222-2222-2222-222222222222" };
const DEVICE = "a1b2c3d4e5f60718";

function setup(opts: { llm?: (p: string) => Promise<string>; purchases?: Record<string, PlayPurchase> } = {}) {
  const repo = new MemoryRepo();
  const llmCalls: string[] = [];
  const llmLabels: (string | undefined)[] = [];
  const deps: Deps = {
    repo,
    previewLimit: 3,
    llm: opts.llm ?? (async (prompt, label) => {
      llmCalls.push(prompt);
      llmLabels.push(label);
      if (prompt.includes("이름이 사주와 얼마나 잘 맞는지")) {
        return JSON.stringify({
          diagnosis: {
            currentName: "민수", currentHanja: "敏秀", overallScore: 72, summaryOneLine: "한 줄",
            detailAnalysis: "상세", problems: ["문제"], strengths: ["장점"], ohengCompat: { matchScore: 60 },
          },
          improvementNames: names(3, "개선"),
        });
      }
      if (prompt.includes("추가 개선 이름")) return JSON.stringify({ names: names(5, "추가") });
      return "```json\n" + JSON.stringify({ names: names(5), familyAnalysis: { recommendation: "가족" } }) + "\n```";
    }),
    play: async (_productId, token) => {
      const p = opts.purchases?.[token];
      if (!p) throw new ApiError(402, "purchase_invalid", "x");
      return p;
    },
  };
  return { repo, deps, llmCalls, llmLabels };
}

const simple = (over: Record<string, unknown> = {}) => ({
  type: "naming_simple", deviceId: DEVICE, surname: "김", gender: "남", saju: SAJU, birthInfo: "2024년 2월 4일", ...over,
});
const diagnosis = (over: Record<string, unknown> = {}) => ({
  type: "diagnosis", deviceId: DEVICE, surname: "김", gender: "남", saju: SAJU, birthInfo: "2024년 2월 4일",
  currentName: "민수", ...over,
});
const paid = (over: Partial<PlayPurchase> = {}): PlayPurchase => ({
  purchaseState: 0, orderId: "GPA.1", obfuscatedExternalAccountId: USER.id, ...over,
});

async function code(p: Promise<unknown>): Promise<string> {
  const e = await assertRejects(() => p, ApiError);
  return (e as ApiError).code;
}

Deno.test("작명 미리보기: 첫 이름만 내보내고 나머지는 서버에 남긴다", async () => {
  const { deps, repo } = setup();
  const { result } = await handleGenerate(deps, USER, simple());
  assertEquals(result.unlocked, false);
  assertEquals((result.content.names as unknown[]).length, 1);
  assertEquals(result.lockedCount, 4);
  assertEquals(result.content.familyAnalysis, null);
  assertEquals(repo.results[0].content.names.length, 5);
});

Deno.test("앱이 보낸 nameCount는 무시하고 서버가 5개로 고정", async () => {
  const { deps, llmCalls } = setup();
  await handleGenerate(deps, USER, simple({ nameCount: 50 }));
  assert(llmCalls[0].includes("이름 5개"));
});

Deno.test("토큰 기록용: AI 호출마다 요청 종류가 붙는다 (무료 미리보기 비용을 따로 보려고)", async () => {
  const { deps, llmLabels } = setup();
  await handleGenerate(deps, USER, simple());
  await handleGenerate(deps, USER, diagnosis());
  assertEquals(llmLabels, ["naming_simple", "diagnosis"]);
});

Deno.test("무료 체험: 기기당 한 번. 재설치(새 익명 계정)해도 다시 생기지 않는다", async () => {
  const { deps } = setup();
  assertEquals((await handleGenerate(deps, USER, simple())).result.isFreeTrial, true);
  assertEquals((await handleGenerate(deps, USER, simple())).result.isFreeTrial, false);
  const me = await handleMe(deps, OTHER, { deviceId: DEVICE });
  assertEquals(me.freeTrialAvailable, false);
  assertEquals((await handleMe(deps, OTHER, { deviceId: "ffffffffffffffff" })).freeTrialAvailable, true);
});

Deno.test("미리보기 한도: 기기당 24시간 3회. 새 계정으로 바꿔도 같은 기기면 막힌다", async () => {
  const { deps } = setup();
  for (let i = 0; i < 3; i++) await handleGenerate(deps, USER, simple());
  assertEquals(await code(handleGenerate(deps, USER, simple())), "quota_exceeded");
  assertEquals(await code(handleGenerate(deps, OTHER, simple())), "quota_exceeded");
  // 같은 계정이 기기 ID만 바꿔도 막힌다
  assertEquals(await code(handleGenerate(deps, USER, simple({ deviceId: "0000000000000000" }))), "quota_exceeded");
});

Deno.test("미리보기 한도: 24시간이 지나면 다시 열린다", async () => {
  const { deps, repo } = setup();
  for (let i = 0; i < 3; i++) await handleGenerate(deps, USER, simple());
  const t = Date.now();
  repo.now = () => t + 24 * 3600 * 1000 + 1;
  await handleGenerate(deps, USER, simple());
});

Deno.test("미리보기 한도: AI가 실패한 호출은 세지 않는다", async () => {
  const { deps, repo } = setup({ llm: () => Promise.resolve("not json") });
  assertEquals(await code(handleGenerate(deps, USER, simple())), "ai_failed");
  assertEquals(repo.claims.length, 0);
  assertEquals(repo.trialUsed.size, 0);
});

Deno.test("미리보기 한도: 결제한 결과는 한도에서 빠진다", async () => {
  const { deps } = setup({ purchases: { "tok-aaaaaaaaaa": paid() } });
  const { result } = await handleGenerate(deps, USER, simple());
  await handleGenerate(deps, USER, simple());
  await handleGenerate(deps, USER, simple());
  await handleVerify(deps, USER, { productId: "naming_new", purchaseToken: "tok-aaaaaaaaaa", resultIds: [result.id] });
  await handleGenerate(deps, USER, simple());
});

Deno.test("입력 검사: 형식이 틀린 사주는 AI를 부르기 전에 거절", async () => {
  const { deps, llmCalls } = setup();
  assertEquals(await code(handleGenerate(deps, USER, simple({ saju: { ...SAJU, ohengBalance: {} } }))), "invalid_input");
  assertEquals(await code(handleGenerate(deps, USER, simple({ deviceId: "x" }))), "invalid_input");
  assertEquals(await code(handleGenerate(deps, USER, simple({ type: "diagnosis_upgrade" }))), "invalid_input");
  assertEquals(llmCalls.length, 0);
});

Deno.test("진단 미리보기: 점수·한 줄 요약만. 상세·개선 이름은 잠김", async () => {
  const { deps } = setup();
  const { result } = await handleGenerate(deps, USER, diagnosis());
  const d = result.content.diagnosis as Record<string, unknown>;
  assertEquals(d.overallScore, 72);
  assertEquals(d.summaryOneLine, "한 줄");
  assertEquals(d.detailAnalysis, undefined);
  assertEquals(d.problems, undefined);
  assertEquals(result.content.improvementNames, []);
  assertEquals(result.lockedCount, 3);
  assertEquals(result.isFreeTrial, false);
});

Deno.test("B-2 결제 준비: 풀어줄 결과가 없으면 결제 창을 못 띄운다", async () => {
  const { deps } = setup();
  assertEquals(await code(handlePrepare(deps, USER, { productId: "bundle", resultIds: [] })), "nothing_to_unlock");
  const n = (await handleGenerate(deps, USER, simple())).result;
  assertEquals(await code(handlePrepare(deps, USER, { productId: "bundle", resultIds: [n.id] })), "nothing_to_unlock");
  const d = (await handleGenerate(deps, USER, diagnosis())).result;
  await handlePrepare(deps, USER, { productId: "bundle", resultIds: [n.id, d.id] });
  // 남의 결과는 못 고른다
  assertEquals(await code(handlePrepare(deps, OTHER, { productId: "naming_new", resultIds: [n.id] })), "nothing_to_unlock");
  // 추가 이름은 진단 결제 뒤에만
  assertEquals(await code(handlePrepare(deps, USER, { productId: "diagnosis_upgrade", resultIds: [d.id] })), "nothing_to_unlock");
});

Deno.test("B-1 결제 검증: Play 확인 뒤에만 전체 공개, 같은 영수증을 다시 보내도 결과가 같다", async () => {
  const { deps, repo } = setup({ purchases: { "tok-1234567890": paid() } });
  const n = (await handleGenerate(deps, USER, simple())).result;
  const body = { productId: "naming_new", purchaseToken: "tok-1234567890", resultIds: [n.id] };
  const first = await handleVerify(deps, USER, body);
  assertEquals(first.results[0].unlocked, true);
  assertEquals((first.results[0].content.names as unknown[]).length, 5);
  assertEquals(repo.purchases[0].status, "delivered");
  const again = await handleVerify(deps, USER, body);
  assertEquals(again.results[0].paidProducts, ["naming_new"]);
});

Deno.test("결제 검증: 대기·취소·다른 계정 영수증은 거절", async () => {
  const { deps } = setup({
    purchases: {
      "tok-pending00": paid({ purchaseState: 2 }),
      "tok-canceled0": paid({ purchaseState: 1 }),
      "tok-otheracct": paid({ obfuscatedExternalAccountId: OTHER.id }),
      "tok-noaccount": paid({ obfuscatedExternalAccountId: undefined }),
    },
  });
  const n = (await handleGenerate(deps, USER, simple())).result;
  const v = (t: string) => handleVerify(deps, USER, { productId: "naming_new", purchaseToken: t, resultIds: [n.id] });
  assertEquals(await code(v("tok-pending00")), "purchase_pending");
  assertEquals(await code(v("tok-canceled0")), "purchase_invalid");
  assertEquals(await code(v("tok-otheracct")), "purchase_invalid");
  assertEquals(await code(v("tok-noaccount")), "purchase_invalid");
  assertEquals(await code(v("tok-unknown00")), "purchase_invalid");
});

Deno.test("결제 검증: 이미 쓴 영수증을 다른 사용자가 가져와도 안 열린다", async () => {
  const { deps } = setup({ purchases: { "tok-1234567890": paid() } });
  const n = (await handleGenerate(deps, USER, simple())).result;
  await handleVerify(deps, USER, { productId: "naming_new", purchaseToken: "tok-1234567890", resultIds: [n.id] });
  const o = (await handleGenerate(deps, OTHER, simple({ deviceId: "9999999999999999" }))).result;
  assertEquals(
    await code(handleVerify(deps, OTHER, { productId: "naming_new", purchaseToken: "tok-1234567890", resultIds: [o.id] })),
    "purchase_invalid",
  );
});

Deno.test("결제 검증: 앱이 결제 중 꺼져 대상이 없으면 가장 최근 미결제 결과를 연다", async () => {
  const { deps } = setup({ purchases: { "tok-1234567890": paid() } });
  await handleGenerate(deps, USER, simple());
  const latest = (await handleGenerate(deps, USER, simple())).result;
  const res = await handleVerify(deps, USER, { productId: "naming_new", purchaseToken: "tok-1234567890" });
  assertEquals(res.results.map((r) => r.id), [latest.id]);
});

Deno.test("묶음: 작명·진단 둘 다 열린다", async () => {
  const { deps } = setup({ purchases: { "tok-bundle0000": paid() } });
  const n = (await handleGenerate(deps, USER, simple())).result;
  const d = (await handleGenerate(deps, USER, diagnosis())).result;
  const res = await handleVerify(deps, USER, { productId: "bundle", purchaseToken: "tok-bundle0000", resultIds: [n.id, d.id] });
  assert(res.results.every((r) => r.unlocked));
});

Deno.test("추가 개선 이름: 결제 검증 뒤에 한 번만 생성, 실패하면 같은 영수증으로 다시 받는다", async () => {
  let failUpgrade = true;
  const base = setup().deps.llm;
  const { deps, repo } = setup({
    purchases: { "tok-diag000000": paid(), "tok-upgrade000": paid() },
    llm: (p) => {
      if (p.includes("추가 개선 이름") && failUpgrade) return Promise.resolve("oops");
      return base(p);
    },
  });
  const d = (await handleGenerate(deps, USER, diagnosis())).result;
  await handleVerify(deps, USER, { productId: "diagnosis", purchaseToken: "tok-diag000000", resultIds: [d.id] });
  const up = { productId: "diagnosis_upgrade", purchaseToken: "tok-upgrade000", resultIds: [d.id] };
  assertEquals(await code(handleVerify(deps, USER, up)), "ai_failed");
  assertEquals(repo.purchases.find((p) => p.purchase_token === "tok-upgrade000")!.status, "verified");

  failUpgrade = false;
  const res = await handleVerify(deps, USER, up);
  assertEquals((res.results[0].content.improvementNames as unknown[]).length, 8);
  const again = await handleVerify(deps, USER, up);
  assertEquals((again.results[0].content.improvementNames as unknown[]).length, 8);
});

Deno.test("내 결과 복원: 결제한 건 전체, 안 한 건 미리보기", async () => {
  const { deps } = setup({ purchases: { "tok-1234567890": paid() } });
  const a = (await handleGenerate(deps, USER, simple())).result;
  await handleGenerate(deps, USER, simple());
  await handleVerify(deps, USER, { productId: "naming_new", purchaseToken: "tok-1234567890", resultIds: [a.id] });
  const me = await handleMe(deps, USER, { deviceId: DEVICE });
  const byId = Object.fromEntries(me.results.map((r) => [r.id, r]));
  assertEquals((byId[a.id].content.names as unknown[]).length, 5);
  assertEquals(me.results.filter((r) => !r.unlocked).length, 1);
  assertEquals(me.previewsLeft, 2);
});

Deno.test("한자 칸 정리: AI가 설명 문장을 붙여 보내도 한자만 최대 3자", () => {
  assertEquals(onlyHanja("旻 (하늘 민) — 한자 미입력으로 AI 추정: 음차 '민'에 가장 자주 쓰이는 吉字 선택"), "旻");
  assertEquals(onlyHanja("추정: 敏"), "");
  assertEquals(onlyHanja("敏秀"), "敏秀");
  assertEquals(onlyHanja(null), "");
});
