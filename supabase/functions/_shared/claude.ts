// Claude API 호출 + JSON 응답 파싱 (기존 naming/index.ts의 callClaude와 파싱을 옮김)

import { ApiError } from "./http.ts";

const CLAUDE_API_URL = "https://api.anthropic.com/v1/messages";
const CLAUDE_MODEL = "claude-sonnet-4-6";

export type Llm = (prompt: string) => Promise<string>;

export function claudeLlm(apiKey: string, fetchFn: typeof fetch = fetch): Llm {
  return async (prompt) => {
    const response = await fetchFn(CLAUDE_API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: CLAUDE_MODEL,
        max_tokens: 4096,
        temperature: 0.9,
        messages: [{ role: "user", content: prompt }],
      }),
    });
    if (!response.ok) {
      const err = await response.json().catch(() => null);
      throw new Error(`Claude API error: ${err?.error?.message || response.status}`);
    }
    const data = await response.json();
    return data.content[0].text;
  };
}

/** 마크다운 코드블럭을 걷어내고 JSON 객체를 꺼낸다 */
export function parseJsonText(text: string): Record<string, unknown> {
  const raw = text.replace(/```json\s*/g, "").replace(/```\s*/g, "").trim();
  try {
    return JSON.parse(raw);
  } catch {
    const m = raw.match(/\{[\s\S]*\}/);
    if (!m) throw new Error("AI 응답을 파싱할 수 없습니다.");
    return JSON.parse(m[0]);
  }
}

/**
 * AI 호출 → 파싱 → 검사. 형식이 틀리면 한 번 더 시도.
 * (앱이 재시도하면 미리보기 한도를 또 쓰게 되므로 재시도는 서버에서만 한다)
 */
export async function generateJson(
  llm: Llm,
  prompt: string,
  isValid: (json: Record<string, unknown>) => boolean,
  attempts = 2,
): Promise<Record<string, unknown>> {
  let last: unknown;
  for (let i = 0; i < attempts; i++) {
    try {
      const json = parseJsonText(await llm(prompt));
      if (isValid(json)) return json;
      last = new Error("invalid AI response shape");
    } catch (e) {
      last = e;
    }
  }
  console.error("AI generation failed:", last);
  throw new ApiError(502, "ai_failed", "이름을 만드는 중에 문제가 생겼어요. 잠시 뒤에 다시 시도해 주세요.");
}

// deno-lint-ignore no-explicit-any
export function validNames(names: any): boolean {
  return Array.isArray(names) && names.length > 0 &&
    names.every((n) => typeof n?.name === "string" && n.name.length >= 2);
}
