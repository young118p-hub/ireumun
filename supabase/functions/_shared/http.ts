// 응답·에러 공통
// 에러는 { error: 코드, message: 사용자용 문구 }로 내보낸다. 내부 사정(AI 오류 원문 등)은 로그에만 남긴다.

export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
  ) {
    super(message);
  }
}

export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, apikey, x-client-info",
};

export function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json", ...corsHeaders },
  });
}

export function errorResponse(e: unknown): Response {
  if (e instanceof ApiError) {
    return json({ error: e.code, message: e.message }, e.status);
  }
  console.error("unexpected error:", e);
  return json(
    { error: "internal", message: "잠시 문제가 생겼어요. 조금 뒤에 다시 시도해 주세요." },
    500,
  );
}

/** POST JSON 요청만 받는 핸들러 래퍼 (CORS preflight 포함) */
export function serveJson(
  handler: (req: Request, body: Record<string, unknown>) => Promise<unknown>,
) {
  return async (req: Request): Promise<Response> => {
    if (req.method === "OPTIONS") return new Response(null, { headers: corsHeaders });
    if (req.method !== "POST") return json({ error: "method_not_allowed" }, 405);
    try {
      let body: Record<string, unknown>;
      try {
        body = await req.json();
      } catch {
        throw new ApiError(400, "invalid_input", "요청 형식이 올바르지 않아요.");
      }
      return json(await handler(req, body));
    } catch (e) {
      return errorResponse(e);
    }
  };
}

/** ANDROID_ID 형식 확인 (16자리 hex가 보통, 여유 있게 허용) */
export function requireDeviceId(value: unknown): string {
  if (typeof value !== "string" || !/^[A-Za-z0-9_-]{8,128}$/.test(value)) {
    throw new ApiError(400, "invalid_input", "기기 정보를 확인할 수 없어요.");
  }
  return value;
}
