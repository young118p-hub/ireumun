// 이름운 백엔드 - Claude API 프록시
// Supabase Edge Function (Deno)
//
// 환경변수 (supabase secrets set):
//   CLAUDE_API_KEY - Anthropic API 키
//   API_SECRET     - 앱에서 보내는 인증 토큰
//
// 배포: supabase functions deploy naming
//
// 4가지 type:
//   naming           - 가족 사주 기반 작명 (아기+아빠+엄마)
//   naming_simple    - 단일 사주 작명 (무료 체험)
//   diagnosis        - 이름 진단
//   diagnosis_upgrade - 진단 후 추가 개선 이름

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const CLAUDE_API_URL = "https://api.anthropic.com/v1/messages";
const CLAUDE_MODEL = "claude-sonnet-4-6";

Deno.serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: corsHeaders(),
    });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  // 인증 확인
  const authHeader = req.headers.get("Authorization");
  const apiSecret = Deno.env.get("API_SECRET");
  if (!apiSecret || authHeader !== `Bearer ${apiSecret}`) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  try {
    const body = await req.json();
    const type = body.type as string;

    if (!type) {
      return jsonResponse({ error: "type 필드가 누락되었습니다." }, 400);
    }

    let prompt: string;

    switch (type) {
      case "naming":
        prompt = buildNamingPrompt(body);
        break;
      case "naming_simple":
        prompt = buildNamingSimplePrompt(body);
        break;
      case "diagnosis":
        prompt = buildDiagnosisPrompt(body);
        break;
      case "diagnosis_upgrade":
        prompt = buildDiagnosisUpgradePrompt(body);
        break;
      default:
        return jsonResponse({ error: `알 수 없는 type: ${type}` }, 400);
    }

    const claudeText = await callClaude(prompt);

    // JSON 추출 (마크다운 코드블럭 제거)
    const rawText = claudeText
      .replace(/```json\s*/g, "")
      .replace(/```\s*/g, "")
      .trim();

    let parsed;
    try {
      parsed = JSON.parse(rawText);
    } catch {
      // JSON 파싱 실패 시 텍스트에서 { } 블록 추출 시도
      const jsonMatch = rawText.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        parsed = JSON.parse(jsonMatch[0]);
      } else {
        throw new Error("AI 응답을 파싱할 수 없습니다.");
      }
    }

    return jsonResponse(parsed);
  } catch (e) {
    console.error("Error:", e);
    const message =
      e instanceof Error ? e.message : "처리 중 오류가 발생했습니다.";
    return jsonResponse({ error: message }, 500);
  }
});

// ============================================================
// Claude API 호출
// ============================================================
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
    const err = await response.json().catch(() => null);
    throw new Error(
      `Claude API error: ${err?.error?.message || response.status}`
    );
  }

  const data = await response.json();
  return data.content[0].text;
}

// ============================================================
// 프롬프트: 가족 사주 기반 작명 (naming)
// ============================================================
function buildNamingPrompt(body: Record<string, any>): string {
  const {
    surname,
    gender,
    nameCount,
    babySaju,
    fatherSaju,
    motherSaju,
    babyBirth,
    fatherBirth,
    motherBirth,
  } = body;

  return `당신은 한국 전통 작명학과 사주명리학의 전문가입니다.
아래의 가족 사주 분석 결과를 바탕으로, 가족 오행 균형을 고려한 최적의 이름 ${nameCount}개를 추천해주세요.

## 가족 사주 (코드로 계산된 정확한 결과)

### 아기 (${babyBirth}, ${gender})
- 사주: ${babySaju.yearPillar} / ${babySaju.monthPillar} / ${babySaju.dayPillar} / ${babySaju.hourPillar}
- 일간: ${babySaju.dayMaster}
- 오행: 목${babySaju.ohengBalance.목} 화${babySaju.ohengBalance.화} 토${babySaju.ohengBalance.토} 금${babySaju.ohengBalance.금} 수${babySaju.ohengBalance.수}
- 부족: ${babySaju.weakElement}, 강함: ${babySaju.strongElement}

### 아빠 (${fatherBirth})
- 사주: ${fatherSaju.yearPillar} / ${fatherSaju.monthPillar} / ${fatherSaju.dayPillar} / ${fatherSaju.hourPillar}
- 일간: ${fatherSaju.dayMaster}
- 오행: 목${fatherSaju.ohengBalance.목} 화${fatherSaju.ohengBalance.화} 토${fatherSaju.ohengBalance.토} 금${fatherSaju.ohengBalance.금} 수${fatherSaju.ohengBalance.수}

### 엄마 (${motherBirth})
- 사주: ${motherSaju.yearPillar} / ${motherSaju.monthPillar} / ${motherSaju.dayPillar} / ${motherSaju.hourPillar}
- 일간: ${motherSaju.dayMaster}
- 오행: 목${motherSaju.ohengBalance.목} 화${motherSaju.ohengBalance.화} 토${motherSaju.ohengBalance.토} 금${motherSaju.ohengBalance.금} 수${motherSaju.ohengBalance.수}

## 분석 요청
1. 가족 3인의 오행을 종합 분석하여, 가족 전체에 부족한 오행과 과잉 오행을 판단하세요.
2. 아기 사주의 부족 오행 + 가족 종합 부족 오행을 함께 보완하는 이름을 추천하세요.

## 이름 추천 규칙
- 성씨 "${surname}" 기준 한글 2글자 이름 (성씨 제외)
- 실존하는 한자(CJK U+4E00~U+9FFF)만 사용
- 부족 오행 보완 한자 우선
- 발음 자연스럽고 현대적이며 품격 있는 이름
- 점수: 종합 1~100점

## 응답 형식 (반드시 JSON만 출력)
\`\`\`json
{
  "familyAnalysis": {
    "combinedBalance": {"목": 6, "화": 3, "토": 5, "금": 4, "수": 6},
    "familyWeakElement": "화",
    "familyStrongElement": "수",
    "recommendation": "가족 전체적으로 화 기운이 부족하여..."
  },
  "names": [
    {
      "name": "민준",
      "hanja": "民俊",
      "reading": "民(백성 민) 俊(준걸 준)",
      "meaning": "백성을 이끄는 준걸이 되라는 뜻",
      "ohengMatch": "부족한 화를 보완",
      "score": 92,
      "pronunciation": "발음 평가"
    }
  ]
}
\`\`\`

중요: JSON만 출력. 이름 정확히 ${nameCount}개. 한자는 실존 한자만 사용.`;
}

// ============================================================
// 프롬프트: 단일 사주 작명 (naming_simple, 무료 체험)
// ============================================================
function buildNamingSimplePrompt(body: Record<string, any>): string {
  const { surname, gender, nameCount, saju, birthInfo } = body;

  return `당신은 한국 전통 작명학과 사주명리학의 전문가입니다.
다음 사주를 바탕으로 최적의 이름 ${nameCount}개를 추천해주세요.

## 사주 정보 (코드 계산 결과)
- 출생: ${birthInfo}, ${gender}
- 사주: ${saju.yearPillar} / ${saju.monthPillar} / ${saju.dayPillar} / ${saju.hourPillar}
- 일간: ${saju.dayMaster}
- 오행: 목${saju.ohengBalance.목} 화${saju.ohengBalance.화} 토${saju.ohengBalance.토} 금${saju.ohengBalance.금} 수${saju.ohengBalance.수}
- 부족: ${saju.weakElement}, 강함: ${saju.strongElement}

## 이름 추천 규칙
- 성씨 "${surname}" 기준 한글 2글자 이름 (성씨 제외)
- 실존하는 한자(CJK U+4E00~U+9FFF)만 사용
- 부족 오행 보완 한자 우선
- 발음 자연스럽고 현대적이며 품격 있는 이름
- 점수: 종합 1~100점

## 응답 형식 (반드시 JSON만 출력)
\`\`\`json
{
  "names": [
    {
      "name": "민준",
      "hanja": "民俊",
      "reading": "民(백성 민) 俊(준걸 준)",
      "meaning": "뜻 풀이",
      "ohengMatch": "오행 보완 설명",
      "score": 92,
      "pronunciation": "발음 평가"
    }
  ]
}
\`\`\`

중요: JSON만 출력. 이름 정확히 ${nameCount}개.`;
}

// ============================================================
// 프롬프트: 이름 진단 (diagnosis)
// ============================================================
function buildDiagnosisPrompt(body: Record<string, any>): string {
  const { surname, currentName, currentHanja, gender, saju, birthInfo } = body;
  const hanjaInfo = currentHanja
    ? `현재 이름 한자: ${currentHanja}`
    : "현재 이름 한자: 미입력 (AI가 추정)";

  return `당신은 한국 전통 작명학과 사주명리학의 전문가입니다.
현재 이름이 사주와 얼마나 잘 맞는지 진단해주세요.

## 진단 대상
- 이름: ${surname}${currentName}
- ${hanjaInfo}
- 출생: ${birthInfo}, ${gender}
- 사주: ${saju.yearPillar} / ${saju.monthPillar} / ${saju.dayPillar} / ${saju.hourPillar}
- 일간: ${saju.dayMaster}
- 오행: 목${saju.ohengBalance.목} 화${saju.ohengBalance.화} 토${saju.ohengBalance.토} 금${saju.ohengBalance.금} 수${saju.ohengBalance.수}
- 부족: ${saju.weakElement}, 강함: ${saju.strongElement}

## 분석 항목
1. 이름 글자별 한자 추정 (한자 미입력 시) 및 오행 분석
2. 사주와 이름의 오행 적합도 (보완 vs 충돌)
3. 획수 길흉 분석
4. 발음 분석 (성씨 "${surname}"과의 조합)
5. 종합 점수 (1-100)
6. 문제점과 장점 분리
7. 개선 이름 3개 추천

## 응답 형식 (반드시 JSON만 출력)
\`\`\`json
{
  "diagnosis": {
    "currentName": "${currentName}",
    "currentHanja": "推定한자",
    "overallScore": 72,
    "summaryOneLine": "오행 보완은 양호하나 획수 배합에 개선 여지가 있습니다",
    "ohengCompat": {
      "nameOheng": {"목": 1, "화": 0, "토": 1, "금": 0, "수": 0},
      "sajuOheng": {"목": 2, "화": 1, "토": 2, "금": 1, "수": 2},
      "matchDescription": "이름의 목 기운이 사주의 부족한 화를 부분 보완",
      "matchScore": 68
    },
    "strokeAnalysis": "총획 18획으로 중길 배합",
    "pronunciationAnalysis": "성씨와 첫 글자 발음이 자연스러움",
    "detailAnalysis": "상세 분석 내용...",
    "problems": ["획수 배합이 최적이 아님", "..."],
    "strengths": ["오행 보완이 적절함", "..."]
  },
  "improvementNames": [
    {
      "name": "민서",
      "hanja": "敏瑞",
      "reading": "敏(민첩할 민) 瑞(상서로울 서)",
      "meaning": "뜻 풀이",
      "ohengMatch": "오행 보완 설명",
      "score": 95,
      "pronunciation": "발음 평가"
    }
  ]
}
\`\`\`

중요: JSON만 출력. 개선 이름 정확히 3개. 한자는 실존 한자만 사용.`;
}

// ============================================================
// 프롬프트: 진단 후 추가 개선 이름 (diagnosis_upgrade)
// ============================================================
function buildDiagnosisUpgradePrompt(body: Record<string, any>): string {
  const { surname, gender, nameCount, saju, birthInfo, previousDiagnosis } =
    body;

  return `당신은 한국 전통 작명학과 사주명리학의 전문가입니다.
이전 이름 진단 결과를 바탕으로, 추가 개선 이름 ${nameCount}개를 추천해주세요.

## 사주 정보
- 성씨: ${surname}, ${gender}
- 출생: ${birthInfo}
- 사주: ${saju.yearPillar} / ${saju.monthPillar} / ${saju.dayPillar} / ${saju.hourPillar}
- 일간: ${saju.dayMaster}
- 오행: 목${saju.ohengBalance.목} 화${saju.ohengBalance.화} 토${saju.ohengBalance.토} 금${saju.ohengBalance.금} 수${saju.ohengBalance.수}
- 부족: ${saju.weakElement}, 강함: ${saju.strongElement}

## 이전 진단 결과
- 현재 이름: ${surname}${previousDiagnosis.currentName}
- 종합 점수: ${previousDiagnosis.overallScore}점
- 문제점: ${(previousDiagnosis.problems || []).join(", ")}

## 이름 추천 규칙
- 성씨 "${surname}" 기준 한글 2글자 이름 (성씨 제외)
- 이전 진단에서 발견된 문제점을 해결하는 이름
- 실존하는 한자만 사용
- 부족 오행 보완 + 획수 길 + 발음 자연스러움
- 기존에 추천된 이름과 중복되지 않는 새로운 이름
- 점수: 종합 1~100점

## 응답 형식 (반드시 JSON만 출력)
\`\`\`json
{
  "names": [
    {
      "name": "이름",
      "hanja": "漢字",
      "reading": "음독",
      "meaning": "의미",
      "ohengMatch": "오행 설명",
      "score": 95,
      "pronunciation": "발음 평가"
    }
  ]
}
\`\`\`

중요: JSON만 출력. 이름 정확히 ${nameCount}개.`;
}

// ============================================================
// 유틸
// ============================================================
function corsHeaders(): Record<string, string> {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, apikey, x-client-info",
  };
}

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders(),
    },
  });
}
