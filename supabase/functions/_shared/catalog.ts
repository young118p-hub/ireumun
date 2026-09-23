// 상품 → 무엇을 풀어주는지, 결제 전 미리보기를 어디까지 보여주는지
// 앱의 PurchaseService.products와 상품 ID가 같아야 한다.

import { ApiError } from "./http.ts";

export type Kind = "naming" | "diagnosis";

export type ProductId = "naming_new" | "diagnosis" | "bundle" | "diagnosis_upgrade";

export const PRODUCT_IDS: ProductId[] = ["naming_new", "diagnosis", "bundle", "diagnosis_upgrade"];

export interface ResultRow {
  id: string;
  user_id: string;
  device_id: string;
  kind: Kind;
  request_type: string;
  input: Record<string, unknown>;
  // deno-lint-ignore no-explicit-any
  content: Record<string, any>;
  paid_products: string[];
  is_free_trial: boolean;
  created_at: string;
}

export function isProductId(v: unknown): v is ProductId {
  return typeof v === "string" && (PRODUCT_IDS as string[]).includes(v);
}

/** 결과 본문이 열렸는지 (작명은 naming_new/bundle, 진단은 diagnosis/bundle) */
export function isUnlocked(row: Pick<ResultRow, "kind" | "paid_products">): boolean {
  const opener = row.kind === "naming" ? "naming_new" : "diagnosis";
  return row.paid_products.includes(opener) || row.paid_products.includes("bundle");
}

/**
 * 이 상품으로 이 결과들을 결제할 수 있는지. 안 되면 ApiError.
 * 결제 창을 띄우기 전(prepare)과 영수증 검증(verify) 때 둘 다 부른다.
 * → 풀어줄 게 없는 결제(예: 결과 없이 묶음 구매)를 막는다.
 */
export function assertUnlockable(productId: ProductId, rows: ResultRow[]): void {
  const naming = rows.filter((r) => r.kind === "naming");
  const diagnosis = rows.filter((r) => r.kind === "diagnosis");
  const fail = (message: string) => {
    throw new ApiError(409, "nothing_to_unlock", message);
  };

  switch (productId) {
    case "naming_new":
      if (rows.length !== 1 || naming.length !== 1) fail("결제할 작명 결과를 찾지 못했어요.");
      if (isUnlocked(naming[0])) fail("이미 결제한 결과예요.");
      return;
    case "diagnosis":
      if (rows.length !== 1 || diagnosis.length !== 1) fail("결제할 진단 결과를 찾지 못했어요.");
      if (isUnlocked(diagnosis[0])) fail("이미 결제한 결과예요.");
      return;
    case "bundle":
      if (rows.length !== 2 || naming.length !== 1 || diagnosis.length !== 1) {
        fail("묶음 할인은 결제 전인 작명 결과와 진단 결과가 하나씩 있을 때 쓸 수 있어요.");
      }
      if (isUnlocked(naming[0]) || isUnlocked(diagnosis[0])) fail("이미 결제한 결과가 섞여 있어요.");
      return;
    case "diagnosis_upgrade":
      if (rows.length !== 1 || diagnosis.length !== 1) fail("추가 이름을 받을 진단 결과를 찾지 못했어요.");
      if (!isUnlocked(diagnosis[0])) fail("진단 결과를 먼저 결제해 주세요.");
      if (diagnosis[0].paid_products.includes("diagnosis_upgrade")) fail("이미 추가 이름을 받은 결과예요.");
      return;
  }
}

/** 영수증에 대상 결과가 안 붙어 왔을 때(앱이 결제 중 꺼진 경우) 고를 기본 대상 */
export function defaultTargets(productId: ProductId, rows: ResultRow[]): ResultRow[] {
  const newest = (kind: Kind, pred: (r: ResultRow) => boolean) =>
    rows
      .filter((r) => r.kind === kind && pred(r))
      .sort((a, b) => Date.parse(b.created_at) - Date.parse(a.created_at))[0];
  const locked = (r: ResultRow) => !isUnlocked(r);
  const pick = (...xs: (ResultRow | undefined)[]) => xs.every(Boolean) ? (xs as ResultRow[]) : [];

  switch (productId) {
    case "naming_new":
      return pick(newest("naming", locked));
    case "diagnosis":
      return pick(newest("diagnosis", locked));
    case "bundle":
      return pick(newest("naming", locked), newest("diagnosis", locked));
    case "diagnosis_upgrade":
      return pick(newest("diagnosis", (r) => isUnlocked(r) && !r.paid_products.includes("diagnosis_upgrade")));
  }
}

export interface ResultView {
  id: string;
  kind: Kind;
  requestType: string;
  input: Record<string, unknown>;
  isFreeTrial: boolean;
  paidProducts: string[];
  unlocked: boolean;
  lockedCount: number;
  createdAt: string;
  content: Record<string, unknown>;
}

/** 앱에 내보낼 모양. 결제 전이면 미리보기만 (나머지 이름·상세 분석은 서버에만 있음) */
export function viewOf(row: ResultRow): ResultView {
  const unlocked = isUnlocked(row);
  const c = row.content;
  let content: Record<string, unknown> = c;
  let lockedCount = 0;

  if (!unlocked && row.kind === "naming") {
    const names = Array.isArray(c.names) ? c.names : [];
    content = { ...c, names: names.slice(0, 1), familyAnalysis: null };
    lockedCount = Math.max(0, names.length - 1);
  } else if (!unlocked && row.kind === "diagnosis") {
    const d = c.diagnosis ?? {};
    content = {
      saju: c.saju,
      diagnosis: {
        currentName: d.currentName,
        currentHanja: d.currentHanja,
        overallScore: d.overallScore,
        summaryOneLine: d.summaryOneLine,
      },
      improvementNames: [],
    };
    lockedCount = Array.isArray(c.improvementNames) ? c.improvementNames.length : 0;
  }

  return {
    id: row.id,
    kind: row.kind,
    requestType: row.request_type,
    input: row.input,
    isFreeTrial: row.is_free_trial,
    paidProducts: row.paid_products,
    unlocked,
    lockedCount,
    createdAt: row.created_at,
    content,
  };
}
