// Claude 호출: 토큰 사용량 기록
import { assertEquals } from "jsr:@std/assert@1";
import { type AiUsage, claudeLlm } from "../functions/_shared/claude.ts";

function fakeFetch(body: Record<string, unknown>): typeof fetch {
  return () => Promise.resolve(new Response(JSON.stringify(body), { status: 200 }));
}

const REPLY = {
  model: "claude-sonnet-4-6",
  content: [{ type: "text", text: "{}" }],
  usage: { input_tokens: 1500, output_tokens: 3000 },
  stop_reason: "end_turn",
};

Deno.test("호출마다 요청 종류와 토큰 수를 남긴다", async () => {
  const logged: AiUsage[] = [];
  const llm = claudeLlm("k", fakeFetch(REPLY), async (u) => void logged.push(u));
  assertEquals(await llm("prompt", "naming_simple"), "{}");
  assertEquals(logged, [{
    label: "naming_simple", model: "claude-sonnet-4-6", inputTokens: 1500, outputTokens: 3000, stopReason: "end_turn",
  }]);
});

Deno.test("기록이 실패해도 결과는 돌려준다", async () => {
  const llm = claudeLlm("k", fakeFetch(REPLY), () => Promise.reject(new Error("db down")));
  assertEquals(await llm("prompt", "diagnosis"), "{}");
});
