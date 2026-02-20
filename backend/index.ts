// 이름운 백엔드 - Claude API 프록시
// Supabase Edge Function / Deno Deploy / Vercel Edge 등에서 사용 가능
//
// 환경변수:
//   CLAUDE_API_KEY - Anthropic API 키
//   API_SECRET - 앱에서 보내는 인증 토큰 (간단한 보안)

const CLAUDE_API_URL = "https://api.anthropic.com/v1/messages";
const CLAUDE_MODEL = "claude-sonnet-4-5-20250514";

// Supabase Edge Function 형식
Deno.serve(async (req: Request) => {
  // CORS
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  // 간단한 인증 (앱에서 보내는 시크릿 토큰)
  const authHeader = req.headers.get("Authorization");
  const apiSecret = Deno.env.get("API_SECRET") || "ireumun-secret-2024";
  if (authHeader !== `Bearer ${apiSecret}`) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  try {
    const body = await req.json();
    const { surname, year, month, day, hour, gender } = body;

    // 입력 검증
    if (!surname || !year || !month || !day || !gender) {
      return jsonResponse({ error: "필수 입력값이 누락되었습니다." }, 400);
    }

    // Claude API 호출
    const prompt = buildPrompt(surname, year, month, day, hour, gender);
    const claudeResponse = await callClaude(prompt);

    // JSON 추출 (마크다운 코드블록 제거)
    let rawText = claudeResponse;
    rawText = rawText.replace(/```json/g, "").replace(/```/g, "").trim();

    // JSON 파싱 검증
    const parsed = JSON.parse(rawText);
    if (!parsed.saju || !parsed.names || parsed.names.length < 5) {
      return jsonResponse({ error: "AI 응답이 유효하지 않습니다. 다시 시도해주세요." }, 502);
    }

    return jsonResponse(parsed);
  } catch (e) {
    console.error("Error:", e);
    return jsonResponse(
      { error: "작명 처리 중 오류가 발생했습니다. 다시 시도해주세요." },
      500
    );
  }
});

async function callClaude(prompt: string): Promise<string> {
  const apiKey = Deno.env.get("CLAUDE_API_KEY");
  if (!apiKey) throw new Error("CLAUDE_API_KEY not set");

  const response = await fetch(CLAUDE_API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: CLAUDE_MODEL,
      max_tokens: 4096,
      messages: [{ role: "user", content: prompt }],
    }),
  });

  if (!response.ok) {
    const err = await response.json();
    throw new Error(`Claude API error: ${err?.error?.message || response.status}`);
  }

  const data = await response.json();
  return data.content[0].text;
}

function buildPrompt(
  surname: string,
  year: number,
  month: number,
  day: number,
  hour: number,
  gender: string
): string {
  const hourInfo =
    hour >= 0
      ? `태어난 시간: ${hour}시`
      : "태어난 시간: 모름 (시주 제외하고 분석)";

  return `당신은 한국 전통 작명학과 사주명리학의 전문가입니다.
다음 정보를 바탕으로 사주를 분석하고, 최적의 이름 7개를 추천해주세요.

## 입력 정보
- 성씨: ${surname}
- 생년월일: ${year}년 ${month}월 ${day}일 (양력)
- ${hourInfo}
- 성별: ${gender}

## 분석 요청
1. 사주팔자(四柱八字)를 정확히 계산하세요.
   - 년주, 월주, 일주${hour >= 0 ? ", 시주" : ""}를 구합니다.
   - 각 기둥의 천간과 지지를 한글로 표기합니다.
2. 오행(五行) 분포를 분석하세요.
   - 목, 화, 토, 금, 수 각각의 개수를 세고,
   - 부족한 오행과 강한 오행을 판단합니다.
3. 일간(日干)을 기준으로 용신(用神)을 판단하세요.

## 이름 추천 규칙
- 반드시 한글 2글자 이름만 추천 (성씨 제외)
- 각 이름에 대응하는 한자(漢字)를 반드시 제시 (실존하는 한자만 사용)
- 부족한 오행을 보완하는 한자를 우선 선택
- 성씨 "${surname}"과 조합했을 때 발음이 자연스러운 이름
- 현대적이면서도 품격 있는 이름
- 획수 길흉도 고려
- 점수는 종합적으로 1~100점 (오행 보완, 획수, 발음, 의미)

## 응답 형식 (반드시 아래 JSON 형식으로만 응답)
\`\`\`json
{
  "saju": {
    "yearPillar": "갑자",
    "monthPillar": "을축",
    "dayPillar": "병인",
    "hourPillar": "정묘",
    "dayMaster": "병",
    "ohengBalance": {"목": 2, "화": 1, "토": 2, "금": 1, "수": 2},
    "weakElement": "화",
    "strongElement": "토",
    "summary": "일간 병화가 약하여..."
  },
  "names": [
    {
      "name": "민준",
      "hanja": "民俊",
      "reading": "民(백성 민) 俊(준걸 준)",
      "meaning": "백성을 이끄는 준걸이 되라는 뜻",
      "ohengMatch": "民은 수(水)기운, 俊은 화(火)기운으로 부족한 화를 보완",
      "score": 92,
      "pronunciation": "${surname}민준 - 성씨와 첫 글자 발음이 부드럽게 이어짐"
    }
  ]
}
\`\`\`

중요: 반드시 위 JSON 형식으로만 응답하세요. 추가 설명 없이 JSON만 출력하세요.
이름은 정확히 7개를 추천하세요.
한자는 반드시 실존하는 CJK 한자(U+4E00~U+9FFF)만 사용하세요.`;
}

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
}
