// DB 접근. 핸들러는 이 인터페이스만 알고, 테스트는 메모리 구현을 끼운다.

import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";
import type { Kind, ResultRow } from "./catalog.ts";

export interface PurchaseRow {
  purchase_token: string;
  order_id: string | null;
  user_id: string;
  product_id: string;
  result_ids: string[];
  status: "verified" | "delivered";
}

export interface NewResult {
  user_id: string;
  device_id: string;
  kind: Kind;
  request_type: string;
  input: Record<string, unknown>;
  content: Record<string, unknown>;
  is_free_trial: boolean;
}

export interface Repo {
  claimPreview(deviceId: string, userId: string, limit: number): Promise<{ ok: boolean; claimId: string | null; used: number }>;
  releaseClaim(claimId: string): Promise<void>;
  attachClaim(claimId: string, resultId: string): Promise<void>;
  previewUsage(deviceId: string, userId: string): Promise<number>;
  useFreeTrial(deviceId: string): Promise<boolean>;
  isFreeTrialUsed(deviceId: string): Promise<boolean>;
  insertResult(r: NewResult): Promise<ResultRow>;
  getResults(userId: string, ids: string[]): Promise<ResultRow[]>;
  listResults(userId: string, limit: number): Promise<ResultRow[]>;
  updateContent(id: string, content: Record<string, unknown>): Promise<void>;
  addPaidProduct(resultIds: string[], productId: string): Promise<void>;
  getPurchase(token: string): Promise<PurchaseRow | null>;
  /** 새로 넣었으면 true, 같은 토큰이 이미 있으면 false */
  insertPurchase(p: PurchaseRow): Promise<boolean>;
  markDelivered(token: string): Promise<void>;
}

export function serviceClient(): SupabaseClient {
  return createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

function check<T>(res: { data: T; error: unknown }): T {
  if (res.error) throw res.error;
  return res.data;
}

export class SupabaseRepo implements Repo {
  constructor(private db: SupabaseClient) {}

  async claimPreview(deviceId: string, userId: string, limit: number) {
    const rows = check(await this.db.rpc("claim_preview", { p_device: deviceId, p_user: userId, p_limit: limit }));
    const r = (rows as { ok: boolean; claim_id: string | null; used: number }[])[0];
    return { ok: r.ok, claimId: r.claim_id, used: r.used };
  }

  async releaseClaim(claimId: string) {
    check(await this.db.from("preview_claims").delete().eq("id", claimId));
  }

  async attachClaim(claimId: string, resultId: string) {
    check(await this.db.from("preview_claims").update({ result_id: resultId }).eq("id", claimId));
  }

  async previewUsage(deviceId: string, userId: string) {
    return check(await this.db.rpc("preview_usage", { p_device: deviceId, p_user: userId })) as number;
  }

  async useFreeTrial(deviceId: string) {
    return check(await this.db.rpc("use_free_trial", { p_device: deviceId })) as boolean;
  }

  async isFreeTrialUsed(deviceId: string) {
    const row = check(
      await this.db.from("devices").select("free_trial_used_at").eq("device_id", deviceId).maybeSingle(),
    ) as { free_trial_used_at: string | null } | null;
    return row?.free_trial_used_at != null;
  }

  async insertResult(r: NewResult) {
    return check(await this.db.from("results").insert(r).select().single()) as ResultRow;
  }

  async getResults(userId: string, ids: string[]) {
    if (ids.length === 0) return [];
    return check(await this.db.from("results").select().eq("user_id", userId).in("id", ids)) as ResultRow[];
  }

  async listResults(userId: string, limit: number) {
    return check(
      await this.db.from("results").select().eq("user_id", userId).order("created_at", { ascending: false }).limit(limit),
    ) as ResultRow[];
  }

  async updateContent(id: string, content: Record<string, unknown>) {
    check(await this.db.from("results").update({ content }).eq("id", id));
  }

  async addPaidProduct(resultIds: string[], productId: string) {
    check(await this.db.rpc("add_paid_product", { p_result_ids: resultIds, p_product: productId }));
  }

  async getPurchase(token: string) {
    return check(
      await this.db.from("purchases").select().eq("purchase_token", token).maybeSingle(),
    ) as PurchaseRow | null;
  }

  async insertPurchase(p: PurchaseRow) {
    const res = await this.db.from("purchases").insert(p);
    if (res.error && (res.error as { code?: string }).code === "23505") return false; // unique 위반 = 이미 있음
    check(res);
    return true;
  }

  async markDelivered(token: string) {
    check(
      await this.db.from("purchases").update({ status: "delivered", delivered_at: new Date().toISOString() })
        .eq("purchase_token", token),
    );
  }
}
