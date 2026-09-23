// 요청한 사용자 확인
// 앱은 Supabase 익명 계정으로 로그인하고, 그 access token을 Authorization에 실어 보낸다.
// 예전의 공용 비밀키(API_SECRET)는 앱 파일에서 누구나 꺼낼 수 있어서 폐기했다.

import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import { ApiError } from "./http.ts";

export interface AuthUser {
  id: string;
}

export type Authenticator = (req: Request) => Promise<AuthUser>;

export function supabaseAuthenticator(db: SupabaseClient): Authenticator {
  return async (req) => {
    const header = req.headers.get("Authorization") ?? "";
    const jwt = header.startsWith("Bearer ") ? header.slice(7) : "";
    // anon key 자체도 JWT라서 게이트웨이 검사는 통과한다. 실제 사용자(sub)가 있는지 여기서 본다.
    const { data, error } = jwt ? await db.auth.getUser(jwt) : { data: null, error: true };
    if (error || !data?.user) {
      throw new ApiError(401, "unauthorized", "다시 접속해 주세요.");
    }
    return { id: data.user.id };
  };
}
