// 테스트용 메모리 DB (migrations의 SQL 함수와 같은 규칙)

import type { ResultRow } from "../functions/_shared/catalog.ts";
import type { NewResult, PurchaseRow, Repo } from "../functions/_shared/repo.ts";

interface Claim {
  id: string;
  device_id: string;
  user_id: string;
  result_id: string | null;
  created_at: number;
}

export class MemoryRepo implements Repo {
  results: ResultRow[] = [];
  claims: Claim[] = [];
  purchases: PurchaseRow[] = [];
  trialUsed = new Set<string>();
  now = () => Date.now();

  private counted(deviceId: string, userId: string) {
    return this.claims.filter((c) => {
      if (c.device_id !== deviceId && c.user_id !== userId) return false;
      if (c.created_at <= this.now() - 24 * 3600 * 1000) return false;
      const r = this.results.find((x) => x.id === c.result_id);
      return !r || r.paid_products.length === 0;
    }).length;
  }

  claimPreview(deviceId: string, userId: string, limit: number) {
    const used = this.counted(deviceId, userId);
    if (used >= limit) return Promise.resolve({ ok: false, claimId: null, used });
    const id = crypto.randomUUID();
    this.claims.push({ id, device_id: deviceId, user_id: userId, result_id: null, created_at: this.now() });
    return Promise.resolve({ ok: true, claimId: id, used: used + 1 });
  }
  releaseClaim(claimId: string) {
    this.claims = this.claims.filter((c) => c.id !== claimId);
    return Promise.resolve();
  }
  attachClaim(claimId: string, resultId: string) {
    const c = this.claims.find((x) => x.id === claimId);
    if (c) c.result_id = resultId;
    return Promise.resolve();
  }
  previewUsage(deviceId: string, userId: string) {
    return Promise.resolve(this.counted(deviceId, userId));
  }
  useFreeTrial(deviceId: string) {
    if (this.trialUsed.has(deviceId)) return Promise.resolve(false);
    this.trialUsed.add(deviceId);
    return Promise.resolve(true);
  }
  isFreeTrialUsed(deviceId: string) {
    return Promise.resolve(this.trialUsed.has(deviceId));
  }
  insertResult(r: NewResult) {
    const row: ResultRow = {
      ...r,
      id: crypto.randomUUID(),
      paid_products: [],
      created_at: new Date(this.now() + this.results.length).toISOString(),
    } as ResultRow;
    this.results.push(row);
    return Promise.resolve(structuredClone(row));
  }
  getResults(userId: string, ids: string[]) {
    return Promise.resolve(structuredClone(this.results.filter((r) => r.user_id === userId && ids.includes(r.id))));
  }
  listResults(userId: string, limit: number) {
    return Promise.resolve(
      structuredClone(
        this.results.filter((r) => r.user_id === userId).sort((a, b) => b.created_at.localeCompare(a.created_at))
          .slice(0, limit),
      ),
    );
  }
  updateContent(id: string, content: Record<string, unknown>) {
    this.results.find((r) => r.id === id)!.content = structuredClone(content);
    return Promise.resolve();
  }
  addPaidProduct(resultIds: string[], productId: string) {
    for (const r of this.results) {
      if (resultIds.includes(r.id) && !r.paid_products.includes(productId)) r.paid_products.push(productId);
    }
    return Promise.resolve();
  }
  getPurchase(token: string) {
    return Promise.resolve(structuredClone(this.purchases.find((p) => p.purchase_token === token) ?? null));
  }
  insertPurchase(p: PurchaseRow) {
    if (this.purchases.some((x) => x.purchase_token === p.purchase_token)) return Promise.resolve(false);
    this.purchases.push(structuredClone(p));
    return Promise.resolve(true);
  }
  markDelivered(token: string) {
    const p = this.purchases.find((x) => x.purchase_token === token);
    if (p) p.status = "delivered";
    return Promise.resolve();
  }
}
