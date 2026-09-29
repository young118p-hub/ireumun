// 내 상태: 무료 체험 가능 여부, 남은 무료 미리보기, 저장된 결과 (같은 계정 복원용)

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { productionDeps } from "../_shared/deps.ts";
import { handleMe } from "../_shared/handlers.ts";
import { serveJson } from "../_shared/http.ts";

const { deps, authenticate } = productionDeps();

Deno.serve(serveJson(async (req, body) => handleMe(deps, await authenticate(req), body)));
