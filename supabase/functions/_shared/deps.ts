// 실제 운영용 의존성 조립
//
// secrets (supabase secrets set ...):
//   CLAUDE_API_KEY              - Anthropic API 키
//   GOOGLE_PLAY_SERVICE_ACCOUNT - Play 영수증 검증용 서비스 계정 JSON
//   ANDROID_PACKAGE_NAME        - 앱 패키지 ID
//   PREVIEW_DAILY_LIMIT         - (선택) 24시간 무료 미리보기 수, 기본 3
// SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY는 Supabase가 자동으로 넣어 준다.

import { supabaseAuthenticator } from "./auth.ts";
import { claudeLlm } from "./claude.ts";
import type { Deps } from "./handlers.ts";
import { googlePlayVerifier } from "./play.ts";
import { serviceClient, SupabaseRepo } from "./repo.ts";

export const DEFAULT_PREVIEW_LIMIT = 3;

export function productionDeps() {
  const db = serviceClient();
  const deps: Deps = {
    repo: new SupabaseRepo(db),
    llm: claudeLlm(Deno.env.get("CLAUDE_API_KEY") ?? "", fetch, async (u) => {
      const { error } = await db.from("ai_usage").insert({
        label: u.label,
        model: u.model,
        input_tokens: u.inputTokens,
        output_tokens: u.outputTokens,
        stop_reason: u.stopReason,
      });
      if (error) throw error;
    }),
    play: googlePlayVerifier(Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT"), Deno.env.get("ANDROID_PACKAGE_NAME")),
    previewLimit: Number(Deno.env.get("PREVIEW_DAILY_LIMIT") ?? DEFAULT_PREVIEW_LIMIT) || DEFAULT_PREVIEW_LIMIT,
  };
  return { deps, authenticate: supabaseAuthenticator(db) };
}
