const { candidatesFor } = require('./dailyPlan');

const MAX_DAYS = 30;
const MODEL = process.env.ANTHROPIC_MODEL || 'claude-haiku-4-5-20251001';

const SYSTEM = `You are a stretching coach building a personal multi-day plan for one user of a stretching app.
You are given the user's onboarding answers and a catalog of routines. Build the plan only from the catalog.

Rules:
- Use only routineId values from the catalog, each at most once.
- Decide how many days the plan has (1 to ${MAX_DAYS}) from the user's needs: a narrow need (one body area, one goal) gets a short plan; several areas and goals get a longer one. Include every routine that really serves what the user asked for, and leave out those that do not.
- Order the days so neighbouring days work different areas and the effort builds up gently; put the best overall fit on day 1.
- Prefer routines close to the user's minutesPerDay, matching their timeOfDay and lifestyle when it helps.
- A wall and a chair are always available to the user.
- For each day give a short reason (max 20 words) that names the user's own answers (body areas, goals, lifestyle) it serves.
- Also give a summary of the plan (max 35 words) addressed to the user as "you".

Reply with JSON only, no prose, in exactly this shape:
{"summary": string, "days": [{"routineId": string, "reason": string}]}`;

function describeUser(user) {
  return {
    bodyAreas: user.painAreas || [],
    goals: user.goals || [],
    lifestyle: user.lifestyle || null,
    timeOfDay: user.timeOfDay || null,
    minutesPerDay: user.minutesPerDay || 10,
    flexibilityLevel: `${user.flexibilityLevel || 1} (1 beginner, 2 intermediate, 3 advanced)`,
    equipment: user.equipmentNone ? [] : user.equipment || [],
    noFloorWork: !!user.noFloor,
    noKneeling: !!user.noKneel,
    pregnant: !!user.isPregnant,
    recentSurgery: !!user.hadRecentSurgery,
    injuries: user.injurySeverity ? Object.fromEntries(user.injurySeverity instanceof Map ? user.injurySeverity : Object.entries(user.injurySeverity)) : {},
  };
}

function describeRoutine(routine) {
  return {
    routineId: String(routine._id),
    name: routine.name,
    about: routine.description || '',
    minutes: Math.max(1, Math.round(routine.totalSeconds / 60)),
    level: routine.level,
    equipment: routine.equipment,
    bodyAreas: routine.areas,
    tags: routine.tags,
  };
}

function parseJson(text) {
  const start = text.indexOf('{');
  const end = text.lastIndexOf('}');
  if (start < 0 || end <= start) throw new Error('AI reply had no JSON');
  return JSON.parse(text.slice(start, end + 1));
}

// Asks the AI to build the plan. Returns { days: [{ routine, reason }], summary }
// using only routines the user may safely do, or throws when the AI is
// unavailable or its answer can't be used (the caller then falls back to rules).
async function generateAiPlan(routines, user) {
  const key = process.env.ANTHROPIC_API_KEY;
  if (!key) throw new Error('ANTHROPIC_API_KEY is not set');

  const candidates = candidatesFor(routines, user);
  if (!candidates.length) return { days: [], summary: '' };
  const byId = new Map(candidates.map((r) => [String(r._id), r]));

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: { 'x-api-key': key, 'anthropic-version': '2023-06-01', 'content-type': 'application/json' },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: 4000,
      system: SYSTEM,
      messages: [
        {
          role: 'user',
          content: JSON.stringify({ user: describeUser(user), catalog: candidates.map(describeRoutine) }),
        },
      ],
    }),
    signal: AbortSignal.timeout(45000),
  });
  if (!response.ok) throw new Error(`AI request failed: HTTP ${response.status}`);

  const body = await response.json();
  const reply = parseJson((body.content || []).map((part) => part.text || '').join(''));

  const seen = new Set();
  const days = [];
  for (const item of Array.isArray(reply.days) ? reply.days : []) {
    const routine = byId.get(String(item && item.routineId));
    if (!routine || seen.has(String(routine._id))) continue;
    seen.add(String(routine._id));
    days.push({ routine, reason: String((item && item.reason) || '').trim().slice(0, 240) });
    if (days.length === MAX_DAYS) break;
  }
  if (!days.length) throw new Error('AI plan had no usable routines');
  return { days, summary: String(reply.summary || '').trim().slice(0, 300) };
}

module.exports = { generateAiPlan };
