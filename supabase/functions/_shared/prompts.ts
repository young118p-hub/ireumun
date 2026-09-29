// 작명·진단 프롬프트 (기존 naming/index.ts에서 옮김 — 문구 변경 없음)
// deno-lint-ignore-file no-explicit-any

// ============================================================
// 프롬프트: 가족 사주 기반 작명 (naming)
// ============================================================
export function buildNamingPrompt(body: Record<string, any>): string {
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

## 이름 품질 필터 (반드시 준수)
- 현대 한국에서 실제로 쓰이는 자연스러운 이름 추천 (로하, 리아, 서아, 이서 같은 현대식 이름도 OK)
- 금지: 명백한 일상 명사(현금, 대박, 부자, 도둑 등), 성씨와 합쳤을 때 우스꽝스러운 단어가 되는 경우
- 한자의 뜻이 부정적인 경우 금지 (죽을 사, 병 병 등)

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
export function buildNamingSimplePrompt(body: Record<string, any>): string {
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

## 이름 품질 필터 (반드시 준수)
- 현대 한국에서 실제로 쓰이는 자연스러운 이름 추천 (로하, 리아, 서아, 이서 같은 현대식 이름도 OK)
- 금지: 명백한 일상 명사(현금, 대박, 부자, 도둑 등), 성씨와 합쳤을 때 우스꽝스러운 단어가 되는 경우
- 한자의 뜻이 부정적인 경우 금지 (죽을 사, 병 병 등)

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

중요: JSON만 출력. 이름 정확히 ${nameCount}개. 매번 다양하고 새로운 이름을 추천하세요. 이전에 추천했던 이름과 겹치지 않도록 창의적으로 작명하세요.`;
}

// ============================================================
// 프롬프트: 이름 진단 (diagnosis)
// ============================================================
export function buildDiagnosisPrompt(body: Record<string, any>): string {
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
export function buildDiagnosisUpgradePrompt(body: Record<string, any>): string {
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

중요: JSON만 출력. 이름 정확히 ${nameCount}개. 매번 다양하고 새로운 이름을 추천하세요. 이전에 추천했던 이름과 겹치지 않도록 창의적으로 작명하세요.`;
}


// ============================================================
// 프롬프트: 우리 케미 전체 리포트 (결제 뒤)
// 점수와 궁합 판정은 앱의 규칙표가 이미 정했다 → AI는 그 결과를 뒤집지 않고 구체적으로 풀어 쓴다.
// ============================================================
const RELATION_KO: Record<string, string> = { lover: "연인", friend: "친구", coworker: "동료" };

export function buildPairReportPrompt(input: Record<string, any>): string {
  const rel = RELATION_KO[input.relation] ?? "연인";
  const [a, b] = input.people as any[];
  const r = input.rules as any;
  const person = (p: any) =>
    `- ${p.name}: ${p.birthInfo} / 사주 ${p.saju.yearPillar} ${p.saju.monthPillar} ${p.saju.dayPillar} ${p.saju.hourPillar}` +
    ` / 일간 ${p.saju.dayMaster} / 오행 목${p.saju.ohengBalance.목} 화${p.saju.ohengBalance.화} 토${p.saju.ohengBalance.토} 금${p.saju.ohengBalance.금} 수${p.saju.ohengBalance.수}`;
  const parts = (r.parts as any[]).map((x) => `- ${x.label} (${x.points}/${x.max}점, ${x.badge}): ${x.text}`).join("\n");
  const gods = (r.tenGods as any[]).map((g) => `- ${g.from}에게 ${g.to}는 ${g.name}`).join("\n");
  const year = new Date().getFullYear();

  return `당신은 사주명리학 궁합 전문가입니다. 두 사람(${rel} 사이)의 궁합 전체 리포트를 써 주세요.

## 두 사람
${person(a)}
${person(b)}

## 이미 계산된 궁합 (이 판정과 점수를 바꾸거나 반대로 말하지 마세요)
- 케미 점수: ${r.score}점, "${r.title}"
${parts}
## 서로에게 어떤 사람인지 (십신)
${gods}

## 쓰는 법
- ${rel} 관계에 맞는 상황으로 구체적으로 (예: 데이트·연락·여행·돈 쓰는 법·일하는 방식 등). 두 사람의 이름을 넣어서.
- 위 판정을 근거로 들되, 사주 용어는 한 번씩 풀어서 설명. 겁주거나 단정하지 말고, 해결책을 함께.
- 반말 아닌 부드러운 존댓말(해요체). 각 본문은 2~4문장.

## 응답 형식 (반드시 JSON만)
\`\`\`json
{
  "goodPoints": [{"title": "짧은 제목", "body": "본문"}, {"title": "", "body": ""}, {"title": "", "body": ""}],
  "clashPoints": [{"title": "짧은 제목", "body": "본문 + 이렇게 해 보세요"}, {"title": "", "body": ""}],
  "yearFlow": "${year}년 두 사람 관계의 흐름 (3~5문장, 계절이나 시기별로)",
  "advice": ["둘을 위한 조언 1", "조언 2", "조언 3"]
}
\`\`\`

중요: JSON만 출력. goodPoints 정확히 3개, clashPoints 정확히 2개, advice 3개.`;
}


// ============================================================
// 프롬프트: 가족 케미 전체 리포트 (결제 뒤)
// 가족 점수·두 사람씩 점수는 앱의 규칙표가 이미 정했다 → AI는 뒤집지 않고 구체적으로 풀어 쓴다.
// ============================================================
export function buildFamilyReportPrompt(input: Record<string, any>): string {
  const people = input.people as any[];
  const r = input.rules as any;
  const person = (p: any) =>
    `- ${p.name} (${p.roleLabel}): ${p.birthInfo} / 사주 ${p.saju.yearPillar} ${p.saju.monthPillar} ${p.saju.dayPillar} ${p.saju.hourPillar}` +
    ` / 일간 ${p.saju.dayMaster} / 오행 목${p.saju.ohengBalance.목} 화${p.saju.ohengBalance.화} 토${p.saju.ohengBalance.토} 금${p.saju.ohengBalance.금} 수${p.saju.ohengBalance.수}`;
  const pairs = (r.pairs as any[]).map((x) => `- ${x.a} × ${x.b}: ${x.score}점, "${x.title}"`).join("\n");
  const o = r.oheng as Record<string, number>;
  const missing = (r.missing as string[]).length ? `없는 오행: ${(r.missing as string[]).join(", ")}` : "다섯 오행이 모두 있음";
  const year = new Date().getFullYear();
  const names = people.map((p) => `"${p.name}"`).join(", ");

  return `당신은 사주명리학 가족 궁합 전문가입니다. 이 가족(${people.length}명)의 가족 케미 전체 리포트를 써 주세요.

## 가족
${people.map(person).join("\n")}

## 이미 계산된 결과 (이 판정과 점수를 바꾸거나 반대로 말하지 마세요)
- 가족 케미 점수: ${r.score}점, "${r.title}"
- 가족 전체 오행: 목${o.목} 화${o.화} 토${o.토} 금${o.금} 수${o.수} (${missing})
## 두 사람씩 본 케미
${pairs}

## 쓰는 법
- 가족 일상 상황으로 구체적으로 (예: 식사 자리·명절·여행·집안일·용돈·연락). 이름을 넣어서.
- 위 판정을 근거로 들되, 사주 용어는 한 번씩 풀어서 설명. 겁주거나 단정하지 말고, 해결책을 함께.
- 반말 아닌 부드러운 존댓말(해요체). 각 본문은 2~4문장.

## 응답 형식 (반드시 JSON만)
\`\`\`json
{
  "strengths": [{"title": "짧은 제목", "body": "본문"}, {"title": "", "body": ""}, {"title": "", "body": ""}],
  "cautions": [{"title": "짧은 제목", "body": "본문 + 이렇게 해 보세요"}, {"title": "", "body": ""}],
  "members": [{"name": "가족 이름", "body": "이 사람이 가족 안에서 맡는 모습과, 가족에게 해 주면 좋은 것 (2~3문장)"}],
  "yearFlow": "${year}년 우리 가족의 흐름 (3~5문장, 계절이나 시기별로)"
}
\`\`\`

중요: JSON만 출력. strengths 정확히 3개, cautions 정확히 2개, members는 ${names} 순서대로 정확히 ${people.length}개.`;
}
