// Google Play 영수증 검증 (Play Developer API, 서비스 계정)
//
// 필요한 secrets:
//   GOOGLE_PLAY_SERVICE_ACCOUNT - 서비스 계정 JSON 전체 (Play Console에서 '재무 데이터 보기' 권한 부여)
//   ANDROID_PACKAGE_NAME        - 앱 패키지 ID (리브랜딩 때 바뀌므로 코드에 박지 않음)
// 둘 중 하나라도 없으면 검증을 전부 거절한다 (실패 시 닫힘).

import { ApiError } from "./http.ts";

export interface PlayPurchase {
  purchaseState: number; // 0 결제 완료, 1 취소, 2 대기
  consumptionState?: number;
  acknowledgementState?: number;
  orderId?: string;
  obfuscatedExternalAccountId?: string;
}

export type PlayVerifier = (productId: string, token: string) => Promise<PlayPurchase>;

interface ServiceAccount {
  client_email: string;
  private_key: string;
  token_uri?: string;
}

function b64url(bytes: Uint8Array): string {
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToDer(pem: string): Uint8Array<ArrayBuffer> {
  const body = pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  return Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
}

export async function signServiceAccountJwt(sa: ServiceAccount, nowSec: number): Promise<string> {
  const enc = (o: unknown) => b64url(new TextEncoder().encode(JSON.stringify(o)));
  const unsigned = `${enc({ alg: "RS256", typ: "JWT" })}.${
    enc({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/androidpublisher",
      aud: sa.token_uri ?? "https://oauth2.googleapis.com/token",
      iat: nowSec,
      exp: nowSec + 3600,
    })
  }`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned));
  return `${unsigned}.${b64url(new Uint8Array(sig))}`;
}

export function googlePlayVerifier(
  serviceAccountJson: string | undefined,
  packageName: string | undefined,
  fetchFn: typeof fetch = fetch,
): PlayVerifier {
  let cached: { token: string; exp: number } | null = null;

  async function accessToken(sa: ServiceAccount): Promise<string> {
    const now = Math.floor(Date.now() / 1000);
    if (cached && cached.exp - 60 > now) return cached.token;
    const assertion = await signServiceAccountJwt(sa, now);
    const res = await fetchFn(sa.token_uri ?? "https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion }),
    });
    if (!res.ok) throw new Error(`google token error ${res.status}`);
    const data = await res.json();
    cached = { token: data.access_token, exp: now + (data.expires_in ?? 3600) };
    return cached.token;
  }

  return async (productId, token) => {
    if (!serviceAccountJson || !packageName) {
      console.error("Play verification is not configured");
      throw new ApiError(503, "verify_unavailable", "결제 확인을 할 수 없어요. 잠시 뒤에 다시 시도해 주세요.");
    }
    const sa = JSON.parse(serviceAccountJson) as ServiceAccount;
    const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${
      encodeURIComponent(packageName)
    }/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(token)}`;
    const res = await fetchFn(url, { headers: { Authorization: `Bearer ${await accessToken(sa)}` } });
    if (res.status === 400 || res.status === 404 || res.status === 410) {
      throw new ApiError(402, "purchase_invalid", "결제 정보를 확인하지 못했어요.");
    }
    if (!res.ok) {
      console.error("Play API error", res.status, await res.text().catch(() => ""));
      throw new ApiError(503, "verify_unavailable", "결제 확인이 지연되고 있어요. 잠시 뒤에 다시 시도해 주세요.");
    }
    return await res.json() as PlayPurchase;
  };
}
