// 결제
//   action: "prepare" - 결제 창을 띄우기 전에 풀어줄 결과가 있는지 확인
//   action: "verify"  - Google Play 영수증 검증 후 결과를 열고 전체 내용을 돌려줌

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { productionDeps } from "../_shared/deps.ts";
import { handlePrepare, handleVerify } from "../_shared/handlers.ts";
import { ApiError, serveJson } from "../_shared/http.ts";

const { deps, authenticate } = productionDeps();

Deno.serve(serveJson(async (req, body) => {
  const user = await authenticate(req);
  switch (body.action) {
    case "prepare":
      return handlePrepare(deps, user, body);
    case "verify":
      return handleVerify(deps, user, body);
    default:
      throw new ApiError(400, "invalid_input", "알 수 없는 요청이에요.");
  }
}));
