// 요청 처리 로직. DB·AI·Play는 deps로 받아서 테스트에서 가짜로 바꿀 수 있게 한다.
// deno-lint-ignore-file no-explicit-any

import { ApiError, requireDeviceId } from "./http.ts";
import { generateJson, type Llm, validNames } from "./claude.ts";
import type { PlayVerifier } from "./play.ts";
import type { Repo } from "./repo.ts";
import type { AuthUser } from "./auth.ts";
import {
  assertUnlockable,
  defaultTargets,
  isProductId,
  type Kind,
  type ProductId,
  type ResultRow,
  viewOf,
} from "./catalog.ts";
import {
  buildDiagnosisPrompt,
  buildDiagnosisUpgradePrompt,
  buildNamingPrompt,
  buildNamingSimplePrompt,
  buildPairReportPrompt,
} from "./prompts.ts";

export interface Deps {
  repo: Repo;
  llm: Llm;
  play: PlayVerifier;
  /** 기기·사용자당 24시간 무료 미리보기 수 */
  previewLimit: number;
}

// 서버가 정하는 개수 (앱이 보낸 nameCount는 무시)
const NAMING_COUNT = 5;
const DIAGNOSIS_UPGRADE_COUNT = 5;

// ============================================================
// 입력 검사
// ============================================================

const OHENG = ["목", "화", "토", "금", "수"];

/** 맨 앞에 이어진 한자만, 최대 3자 ("旻 (하늘 민) — …吉字…" → "旻") */
export function onlyHanja(v: unknown): string {
  if (typeof v !== "string") return "";
  const m = v.trim().match(/^[\u3400-\u4DBF\u4E00-\u9FFF]+/);
  return m ? [...m[0]].slice(0, 3).join("") : "";
}

function str(v: unknown, field: string, min: number, max: number): string {
  if (typeof v !== "string" || v.length < min || v.length > max) {
    throw new ApiError(400, "invalid_input", `입력값을 확인해 주세요 (${field}).`);
  }
  return v;
}

function saju(v: any, field: string): Record<string, unknown> {
  if (!v || typeof v !== "object") throw new ApiError(400, "invalid_input", `입력값을 확인해 주세요 (${field}).`);
  const balance: Record<string, number> = {};
  for (const k of OHENG) {
    const n = v.ohengBalance?.[k];
    if (typeof n !== "number" || n < 0 || n > 8) {
      throw new ApiError(400, "invalid_input", `입력값을 확인해 주세요 (${field}).`);
    }
    balance[k] = n;
  }
  return {
    yearPillar: str(v.yearPillar, field, 2, 2),
    monthPillar: str(v.monthPillar, field, 2, 2),
    dayPillar: str(v.dayPillar, field, 2, 2),
    hourPillar: str(v.hourPillar, field, 2, 2),
    dayMaster: str(v.dayMaster, field, 1, 1),
    ohengBalance: balance,
    weakElement: str(v.weakElement, field, 1, 1),
    strongElement: str(v.strongElement, field, 1, 1),
    summary: typeof v.summary === "string" ? v.summary.slice(0, 400) : "",
  };
}

type RequestType = "naming" | "naming_simple" | "diagnosis";

function parseGenerateInput(body: Record<string, unknown>): { type: RequestType; kind: Kind; input: Record<string, any> } {
  const type = body.type;
  const common = {
    surname: str(body.surname, "성씨", 1, 2),
    gender: body.gender === "남" || body.gender === "여"
      ? body.gender
      : (() => {
        throw new ApiError(400, "invalid_input", "입력값을 확인해 주세요 (성별).");
      })(),
  };
  switch (type) {
    case "naming_simple":
      return {
        type,
        kind: "naming",
        input: { ...common, saju: saju(body.saju, "사주"), birthInfo: str(body.birthInfo, "생일", 4, 40) },
      };
    case "naming":
      return {
        type,
        kind: "naming",
        input: {
          ...common,
          babySaju: saju(body.babySaju, "사주"),
          fatherSaju: saju(body.fatherSaju, "아빠 사주"),
          motherSaju: saju(body.motherSaju, "엄마 사주"),
          babyBirth: str(body.babyBirth, "생일", 4, 40),
          fatherBirth: str(body.fatherBirth, "아빠 생일", 4, 40),
          motherBirth: str(body.motherBirth, "엄마 생일", 4, 40),
        },
      };
    case "diagnosis":
      return {
        type,
        kind: "diagnosis",
        input: {
          ...common,
          saju: saju(body.saju, "사주"),
          birthInfo: str(body.birthInfo, "생일", 4, 40),
          currentName: str(body.currentName, "이름", 1, 3),
          currentHanja: typeof body.currentHanja === "string" ? str(body.currentHanja, "한자", 0, 3) : "",
        },
      };
    default:
      throw new ApiError(400, "invalid_input", "알 수 없는 요청이에요.");
  }
}

// ============================================================
// 작명·진단 생성 (무료 미리보기)
// ============================================================

export async function handleGenerate(deps: Deps, user: AuthUser, body: Record<string, unknown>) {
  if (body.type === "pair") return await handleCreatePair(deps, user, body);
  const deviceId = requireDeviceId(body.deviceId);
  const { type, kind, input } = parseGenerateInput(body);

  const claim = await deps.repo.claimPreview(deviceId, user.id, deps.previewLimit);
  if (!claim.ok || !claim.claimId) {
    throw new ApiError(
      429,
      "quota_exceeded",
      "오늘 받을 수 있는 무료 미리보기를 모두 썼어요. 내일 다시 시도하거나, 받아 둔 결과를 결제해서 확인해 주세요.",
    );
  }

  try {
    let content: Record<string, unknown>;
    if (type === "diagnosis") {
      const json = await generateJson(
        deps.llm,
        buildDiagnosisPrompt(input),
        (j: any) => typeof j.diagnosis === "object" && j.diagnosis !== null && typeof j.diagnosis.overallScore === "number",
        type,
      );
      // AI가 한자 칸에 설명 문장을 붙여 보내는 경우가 있어서 한자만 남긴다 (최대 3자)
      const diagnosis = { ...(json.diagnosis as Record<string, unknown>) };
      diagnosis.currentHanja = onlyHanja(diagnosis.currentHanja);
      content = { saju: input.saju, diagnosis, improvementNames: json.improvementNames ?? [] };
    } else {
      const prompt = type === "naming"
        ? buildNamingPrompt({ ...input, nameCount: NAMING_COUNT })
        : buildNamingSimplePrompt({ ...input, nameCount: NAMING_COUNT });
      const json = await generateJson(deps.llm, prompt, (j: any) => validNames(j.names), type);
      content = {
        babySaju: type === "naming" ? input.babySaju : input.saju,
        fatherSaju: input.fatherSaju ?? null,
        motherSaju: input.motherSaju ?? null,
        familyAnalysis: json.familyAnalysis ?? null,
        names: json.names,
      };
    }

    const isFreeTrial = kind === "naming" ? await deps.repo.useFreeTrial(deviceId) : false;
    const row = await deps.repo.insertResult({
      user_id: user.id,
      device_id: deviceId,
      kind,
      request_type: type,
      input,
      content,
      is_free_trial: isFreeTrial,
    });
    await deps.repo.attachClaim(claim.claimId, row.id);
    return { result: viewOf(row), previewsLeft: Math.max(0, deps.previewLimit - claim.used) };
  } catch (e) {
    // 실패한 호출은 한도에서 빼 준다
    await deps.repo.releaseClaim(claim.claimId).catch((err) => console.error("releaseClaim failed", err));
    throw e;
  }
}

// ============================================================
// 우리 케미: 결제할 결과 자리 만들기 (AI 없음, 미리보기 한도도 쓰지 않음)
// 무료 점수·해설은 앱이 규칙으로 만들고, 여기에는 그 입력과 규칙 결과만 저장한다.
// AI 전체 리포트는 결제 검증 뒤(deliver)에만 만든다.
// ============================================================

const PAIR_RELATIONS = ["lover", "friend", "coworker"];

function int(v: unknown, field: string, min: number, max: number): number {
  if (typeof v !== "number" || !Number.isInteger(v) || v < min || v > max) {
    throw new ApiError(400, "invalid_input", `입력값을 확인해 주세요 (${field}).`);
  }
  return v;
}

function list(v: unknown, field: string, max: number): any[] {
  if (!Array.isArray(v) || v.length === 0 || v.length > max) {
    throw new ApiError(400, "invalid_input", `입력값을 확인해 주세요 (${field}).`);
  }
  return v;
}

export function parsePairInput(body: Record<string, unknown>): Record<string, unknown> {
  if (!PAIR_RELATIONS.includes(body.relation as string)) {
    throw new ApiError(400, "invalid_input", "입력값을 확인해 주세요 (관계).");
  }
  const people = list(body.people, "두 사람", 2);
  if (people.length !== 2) throw new ApiError(400, "invalid_input", "입력값을 확인해 주세요 (두 사람).");
  const rules = (body.rules ?? {}) as Record<string, any>;
  return {
    relation: body.relation,
    people: people.map((p: any, i: number) => ({
      name: str(p?.name, `이름 ${i + 1}`, 1, 6),
      birthInfo: str(p?.birthInfo, `생일 ${i + 1}`, 4, 40),
      saju: saju(p?.saju, `사주 ${i + 1}`),
      // 재설치 뒤 기기 기록을 되살리는 용도 (앱이 규칙 결과를 다시 계산한다)
      birth: {
        y: int(p?.birth?.y, `생일 ${i + 1}`, 1900, 2100),
        m: int(p?.birth?.m, `생일 ${i + 1}`, 1, 12),
        d: int(p?.birth?.d, `생일 ${i + 1}`, 1, 31),
        h: int(p?.birth?.h, `생일 ${i + 1}`, -1, 23),
      },
    })),
    rules: {
      score: int(rules.score, "점수", 0, 100),
      title: str(rules.title, "제목", 1, 60),
      parts: list(rules.parts, "점수 근거", 6).map((x: any) => ({
        label: str(x?.label, "점수 근거", 1, 40),
        badge: str(x?.badge, "점수 근거", 0, 40),
        points: int(x?.points, "점수 근거", 0, 30),
        max: int(x?.max, "점수 근거", 1, 30),
        text: str(x?.text, "점수 근거", 1, 600),
      })),
      tenGods: list(rules.tenGods, "십신", 2).map((x: any) => ({
        from: str(x?.from, "십신", 1, 6),
        to: str(x?.to, "십신", 1, 6),
        name: str(x?.name, "십신", 2, 2),
      })),
    },
  };
}

export async function handleCreatePair(deps: Deps, user: AuthUser, body: Record<string, unknown>) {
  const deviceId = requireDeviceId(body.deviceId);
  const input = parsePairInput(body);
  const row = await deps.repo.insertResult({
    user_id: user.id,
    device_id: deviceId,
    kind: "pair",
    request_type: "pair",
    input,
    content: {},
    is_free_trial: false,
  });
  return { result: viewOf(row) };
}

// ============================================================
// 내 상태 (무료 체험·남은 미리보기·결과 복원)
// ============================================================

export async function handleMe(deps: Deps, user: AuthUser, body: Record<string, unknown>) {
  const deviceId = requireDeviceId(body.deviceId);
  const [trialUsed, used, rows] = await Promise.all([
    deps.repo.isFreeTrialUsed(deviceId),
    deps.repo.previewUsage(deviceId, user.id),
    deps.repo.listResults(user.id, 50),
  ]);
  return {
    freeTrialAvailable: !trialUsed,
    previewsLeft: Math.max(0, deps.previewLimit - used),
    results: rows.map(viewOf),
  };
}

// ============================================================
// 결제: 준비(결제 창 띄우기 전) / 검증(영수증 받은 뒤)
// ============================================================

function idList(v: unknown): string[] {
  if (v === undefined || v === null) return [];
  if (!Array.isArray(v) || v.length > 2 || !v.every((x) => typeof x === "string" && x.length <= 64)) {
    throw new ApiError(400, "invalid_input", "결제 대상을 확인해 주세요.");
  }
  return v as string[];
}

function productOf(v: unknown): ProductId {
  if (!isProductId(v)) throw new ApiError(400, "invalid_input", "알 수 없는 상품이에요.");
  return v;
}

/** 결제 창을 띄워도 되는지. 풀어줄 결과가 없으면 여기서 막는다 (B-2) */
export async function handlePrepare(deps: Deps, user: AuthUser, body: Record<string, unknown>) {
  const productId = productOf(body.productId);
  const rows = await deps.repo.getResults(user.id, idList(body.resultIds));
  assertUnlockable(productId, rows);
  return { ok: true };
}

/**
 * 영수증 검증 → 구매 기록 → 결과 열기 → (추가 이름이면 생성) → 전체 결과 반환.
 * 앱은 이 응답을 저장한 다음에만 completePurchase(소비)를 부른다.
 * 여기서 실패하면 앱은 소비하지 않고, 다음 실행 때 같은 영수증으로 다시 부른다 (같은 토큰은 이어서 처리).
 */
export async function handleVerify(deps: Deps, user: AuthUser, body: Record<string, unknown>) {
  const productId = productOf(body.productId);
  const token = str(body.purchaseToken, "영수증", 10, 4096);

  const existing = await deps.repo.getPurchase(token);
  if (existing) {
    if (existing.user_id !== user.id || existing.product_id !== productId) {
      throw new ApiError(403, "purchase_invalid", "결제 정보를 확인하지 못했어요.");
    }
    return await deliver(deps, user, productId, token, existing.result_ids);
  }

  const p = await deps.play(productId, token);
  if (p.purchaseState === 2) {
    throw new ApiError(409, "purchase_pending", "결제가 아직 처리 중이에요. 완료되면 자동으로 열려요.");
  }
  if (p.purchaseState !== 0) {
    throw new ApiError(402, "purchase_invalid", "취소되었거나 확인되지 않은 결제예요.");
  }
  // 결제할 때 앱이 넣은 계정 ID와 같아야 한다 (남의 영수증 재사용 방지)
  if (p.obfuscatedExternalAccountId !== user.id) {
    throw new ApiError(403, "purchase_invalid", "결제 정보를 확인하지 못했어요.");
  }

  const requested = idList(body.resultIds);
  const all = requested.length > 0
    ? await deps.repo.getResults(user.id, requested)
    : defaultTargets(productId, await deps.repo.listResults(user.id, 50));
  // 풀어줄 게 없으면 여기서 멈춘다. 앱은 소비하지 않고, Play가 3일 뒤 미확인 결제를 자동 환불한다.
  assertUnlockable(productId, all);

  const resultIds = all.map((r) => r.id);
  const inserted = await deps.repo.insertPurchase({
    purchase_token: token,
    order_id: p.orderId ?? null,
    user_id: user.id,
    product_id: productId,
    result_ids: resultIds,
    status: "verified",
  });
  if (!inserted) {
    // 동시에 같은 영수증이 들어온 경우: 먼저 기록된 쪽 기준으로 이어서 처리
    const again = await deps.repo.getPurchase(token);
    if (!again || again.user_id !== user.id) throw new ApiError(403, "purchase_invalid", "결제 정보를 확인하지 못했어요.");
    return await deliver(deps, user, productId, token, again.result_ids);
  }
  return await deliver(deps, user, productId, token, resultIds);
}

/** 여러 번 불려도 결과가 같다 (이미 열린 건 그대로, 추가 이름은 한 번만 생성) */
async function deliver(deps: Deps, user: AuthUser, productId: ProductId, token: string, resultIds: string[]) {
  await deps.repo.addPaidProduct(resultIds, productId);

  if (productId === "diagnosis_upgrade") {
    const [row] = await deps.repo.getResults(user.id, resultIds);
    if (row && !row.content.upgraded) {
      await generateUpgrade(deps, row);
    }
  }
  if (productId === "chemi_pair") {
    const [row] = await deps.repo.getResults(user.id, resultIds);
    if (row && !row.content.report) {
      await generatePairReport(deps, row);
    }
  }

  await deps.repo.markDelivered(token);
  const rows = await deps.repo.getResults(user.id, resultIds);
  return { results: rows.map(viewOf) };
}

async function generateUpgrade(deps: Deps, row: ResultRow) {
  const input = row.input as Record<string, any>;
  const prompt = buildDiagnosisUpgradePrompt({
    surname: input.surname,
    gender: input.gender,
    nameCount: DIAGNOSIS_UPGRADE_COUNT,
    saju: input.saju,
    birthInfo: input.birthInfo,
    previousDiagnosis: row.content.diagnosis,
  });
  const json = await generateJson(deps.llm, prompt, (j: any) => validNames(j.names), "diagnosis_upgrade");
  await deps.repo.updateContent(row.id, {
    ...row.content,
    improvementNames: [...(row.content.improvementNames ?? []), ...(json.names as unknown[])],
    upgraded: true,
  });
}

/** 우리 케미 전체 리포트 (결제 검증 뒤 한 번). 실패하면 verify가 실패하고 앱은 소비하지 않아 다시 받는다 */
async function generatePairReport(deps: Deps, row: ResultRow) {
  const valid = (j: any) =>
    Array.isArray(j.goodPoints) && j.goodPoints.length >= 3 &&
    Array.isArray(j.clashPoints) && j.clashPoints.length >= 2 &&
    typeof j.yearFlow === "string" && j.yearFlow.length > 0 &&
    Array.isArray(j.advice) && j.advice.length >= 2;
  const json = await generateJson(deps.llm, buildPairReportPrompt(row.input as any), valid, "pair_report");
  await deps.repo.updateContent(row.id, {
    ...row.content,
    report: {
      goodPoints: (json.goodPoints as unknown[]).slice(0, 3),
      clashPoints: (json.clashPoints as unknown[]).slice(0, 2),
      yearFlow: json.yearFlow,
      advice: (json.advice as unknown[]).slice(0, 3),
    },
  });
}
