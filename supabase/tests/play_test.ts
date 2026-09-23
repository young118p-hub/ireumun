// Play 영수증 검증: 서비스 계정 JWT 서명, 설정 없으면 거절, 응답 코드 처리
import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import { googlePlayVerifier } from "../functions/_shared/play.ts";
import { ApiError } from "../functions/_shared/http.ts";

async function serviceAccount() {
  const pair = await crypto.subtle.generateKey(
    { name: "RSASSA-PKCS1-v1_5", modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: "SHA-256" },
    true,
    ["sign", "verify"],
  );
  const der = new Uint8Array(await crypto.subtle.exportKey("pkcs8", pair.privateKey));
  const b64 = btoa(String.fromCharCode(...der)).replace(/(.{64})/g, "$1\n");
  const pem = `-----BEGIN PRIVATE KEY-----\n${b64}\n-----END PRIVATE KEY-----\n`;
  return { json: JSON.stringify({ client_email: "sa@x.iam.gserviceaccount.com", private_key: pem }), publicKey: pair.publicKey };
}

function b64urlDecode(s: string) {
  return Uint8Array.from(atob(s.replace(/-/g, "+").replace(/_/g, "/") + "===".slice((s.length + 3) % 4)), (c) => c.charCodeAt(0));
}

Deno.test("서비스 계정으로 서명한 토큰을 받아 Play API를 부른다", async () => {
  const sa = await serviceAccount();
  const seen: string[] = [];
  const fetchFn = (async (input: string | URL | Request, init?: RequestInit) => {
    const url = String(input);
    seen.push(url);
    if (url.startsWith("https://oauth2.googleapis.com/token")) {
      const assertion = new URLSearchParams(String(init!.body)).get("assertion")!;
      const [h, p, s] = assertion.split(".");
      const ok = await crypto.subtle.verify("RSASSA-PKCS1-v1_5", sa.publicKey, b64urlDecode(s), new TextEncoder().encode(`${h}.${p}`));
      assertEquals(ok, true);
      assertEquals(JSON.parse(new TextDecoder().decode(b64urlDecode(p))).scope, "https://www.googleapis.com/auth/androidpublisher");
      return Response.json({ access_token: "at", expires_in: 3600 });
    }
    assertEquals((init!.headers as Record<string, string>).Authorization, "Bearer at");
    return Response.json({ purchaseState: 0, orderId: "GPA.1", obfuscatedExternalAccountId: "u" });
  }) as typeof fetch;

  const verify = googlePlayVerifier(sa.json, "com.example.app", fetchFn);
  assertEquals((await verify("naming_new", "tok")).purchaseState, 0);
  await verify("naming_new", "tok2");
  assertEquals(seen.filter((u) => u.includes("oauth2")).length, 1); // 토큰은 캐시
  assertEquals(seen[1], "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/com.example.app/purchases/products/naming_new/tokens/tok");
});

Deno.test("설정이 없으면 모든 영수증을 거절한다", async () => {
  const e = await assertRejects(() => googlePlayVerifier(undefined, "com.example.app")("naming_new", "t"), ApiError);
  assertEquals((e as ApiError).code, "verify_unavailable");
});

Deno.test("없는 영수증은 purchase_invalid, 서버 오류는 verify_unavailable", async () => {
  const sa = await serviceAccount();
  const make = (status: number) =>
    googlePlayVerifier(sa.json, "p", (async (u: string | URL | Request) =>
      String(u).includes("oauth2") ? Response.json({ access_token: "a" }) : new Response("x", { status })) as typeof fetch);
  assertEquals(((await assertRejects(() => make(404)("x", "t"), ApiError)) as ApiError).code, "purchase_invalid");
  assertEquals(((await assertRejects(() => make(500)("x", "t"), ApiError)) as ApiError).code, "verify_unavailable");
});
