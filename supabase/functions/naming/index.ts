// 작명·진단 생성 (무료 미리보기)
// 로그인한 익명 사용자만, 기기당 24시간 한도 안에서. 결제 전에는 미리보기만 돌려준다.
// type: naming(가족 사주) / naming_simple(본인 사주) / diagnosis(이름 진단)

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { productionDeps } from "../_shared/deps.ts";
import { handleGenerate } from "../_shared/handlers.ts";
import { serveJson } from "../_shared/http.ts";

const { deps, authenticate } = productionDeps();

Deno.serve(serveJson(async (req, body) => handleGenerate(deps, await authenticate(req), body)));
