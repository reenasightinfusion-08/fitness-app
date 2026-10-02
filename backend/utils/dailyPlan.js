// Picks today's routine for one user from their onboarding answers. Pure
// functions, no database access, so the rules are easy to read and test.

const LEVEL_RANK = { beginner: 1, intermediate: 2, advanced: 3 };

// The names the app's equipment chips map to in Stretch / Routine `equipment`.
const EQUIPMENT_NAME = {
  mat: 'mat',
  strap: 'strap',
  block: 'yoga block',
  roller: 'foam roller',
  chair: 'chair',
  wall: 'wall',
  band: 'resistance band',
};

// Short, friendly label for each goal id, used when writing the day's reason.
const GOAL_LABEL = {
  sleep: 'better sleep',
  recovery: 'recovery after training',
  flexibility: 'more flexibility',
  splits: 'splits training',
  posture: 'better posture',
  pain: 'easing pain',
};
const LIFESTYLE_LABEL = { desk: 'desk days', active: 'active days', athlete: 'training days' };
const TIME_OF_DAY_LABEL = { Morning: 'the morning', Evening: 'the evening', 'Before bed': 'before bed' };
const AREA_LABEL = {
  neck: 'neck', shoulders: 'shoulders', upperback: 'upper back', chest: 'chest',
  spine: 'spine', lowerback: 'lower back', hips: 'hips', glutes: 'glutes',
  hamstrings: 'hamstrings', quads: 'quads', calves: 'calves', wrists: 'wrists',
  knees: 'knees', back: 'back',
};

// Routine `tags` that serve each answer. A routine with a matching tag scores higher.
const GOAL_TAGS = {
  sleep: ['Before sleep'],
  recovery: ['After a workout'],
  flexibility: ['For flexibility', 'Full body'],
  splits: ['For flexibility'],
  posture: ['For your upper back', 'Fits your desk job'],
  pain: [],
};
const LIFESTYLE_TAGS = {
  desk: ['Fits your desk job'],
  active: ['Before you train', 'After a workout'],
  athlete: ['Before you train', 'After a workout'],
};
const TIME_OF_DAY_TAGS = {
  Morning: ['Start your day'],
  Evening: ['Before sleep'],
  'Before bed': ['Before sleep'],
};

// "Where does it hurt" answers that are not a stretch area name.
const PAIN_AREA_TARGETS = { knees: ['quads', 'hamstrings', 'calves'] };

// Body areas an injury rules out once it is moderate or serious (the app's
// InjurySeverity values). Mild injuries don't exclude anything.
const INJURY_AREAS = {
  back: ['lowerback'],
  neck: ['neck'],
  shoulder: ['shoulders'],
  wrist: ['wrists'],
  hip: ['hips'],
  knee: ['quads'],
};

// Pregnancy: nothing lying on the front, no deep twists.
const PREGNANCY_AVOID = ['cobra', 'supinetwist', 'seatedtwist', 'chairtwist', 'torsotwist', 'thread'];

// What a matching goal is worth in a routine's score.
const GOAL_WEIGHT = 2;

// A plan never runs longer than this many days, however many routines fit.
const MAX_DAYS = 30;

function rulesFor(user) {
  const injuries = user.injurySeverity || {};
  const hurt = (key) => injuries[key] === 'moderate' || injuries[key] === 'serious';
  const severe = Object.keys(injuries).filter(hurt);
  const onlyBeginner = !!user.hadRecentSurgery;
  const equipment = user.equipmentNone ? [] : user.equipment || [];

  return {
    noFloor: !!user.noFloor,
    noKneel: !!user.noKneel || hurt('knee'),
    avoidPoses: new Set(user.isPregnant ? PREGNANCY_AVOID : []),
    avoidAreas: new Set(severe.flatMap((key) => INJURY_AREAS[key] || [])),
    // Stretches the user marked as painful after a session.
    avoidStretchIds: new Set((user.hurtStretches || []).map((h) => String(h.stretch))),
    onlyBeginner,
    maxRank: onlyBeginner ? 1 : Math.min(3, Math.max(1, user.flexibilityLevel || 1)),
    // A wall and a chair are in every home, so they never count as equipment.
    equipment: new Set(['wall', 'chair', ...equipment.map((id) => EQUIPMENT_NAME[id]).filter(Boolean)]),
    maxSeconds: (user.minutesPerDay || 10) * 60 + 60,
  };
}

const stretchesOf = (routine) => routine.stretches.map((item) => item.stretch).filter(Boolean);

// Safety rules are never relaxed.
function isSafe(routine, rules) {
  const stretches = stretchesOf(routine);
  if (stretches.length !== routine.stretches.length) return false;
  if (rules.onlyBeginner && routine.level !== 'beginner') return false;
  if (routine.areas.some((area) => rules.avoidAreas.has(area))) return false;
  return stretches.every(
    (s) =>
      !(rules.noFloor && s.position === 'floor') &&
      !(rules.noKneel && s.isKneeling) &&
      !rules.avoidPoses.has(s.poseKey) &&
      !rules.avoidStretchIds.has(String(s._id)),
  );
}

const fitsEquipment = (routine, rules) => routine.equipment.every((item) => rules.equipment.has(item));
const fitsLevel = (routine, rules) => (LEVEL_RANK[routine.level] || 1) <= rules.maxRank;
const fitsTime = (routine, rules) => routine.totalSeconds <= rules.maxSeconds;

// Strictest first. The first tier that leaves at least one routine wins.
const TIERS = [
  (r, rules) => isSafe(r, rules) && fitsEquipment(r, rules) && fitsLevel(r, rules) && fitsTime(r, rules),
  (r, rules) => isSafe(r, rules) && fitsEquipment(r, rules),
  (r, rules) => isSafe(r, rules),
];

// How well a routine matches what the user asked for: their body areas and
// goals. 0 means it speaks to none of them.
function wanted(routine, user) {
  const tagHit = (tags = []) => tags.some((tag) => routine.tags.includes(tag));
  const targets = new Set((user.painAreas || []).flatMap((a) => PAIN_AREA_TARGETS[a] || [a]));
  const focus = routine.areas.length
    ? routine.areas.filter((a) => targets.has(a)).length / routine.areas.length
    : 0;
  return 3 * focus + (user.goals || []).reduce((sum, goal) => sum + (tagHit(GOAL_TAGS[goal]) ? GOAL_WEIGHT : 0), 0);
}

// Ranking: what they asked for first, then lifestyle, time of day and length.
function score(routine, user) {
  const tagHit = (tags = []) => tags.some((tag) => routine.tags.includes(tag));
  const minutes = routine.totalSeconds / 60;
  const target = user.minutesPerDay || 10;
  const closeness = 1 - Math.min(1, Math.abs(minutes - target) / target);

  return (
    wanted(routine, user) +
    (tagHit(LIFESTYLE_TAGS[user.lifestyle]) ? 1 : 0) +
    (tagHit(TIME_OF_DAY_TAGS[user.timeOfDay]) ? 1 : 0) +
    closeness
  );
}

// `routines` are active, with `stretches.stretch` populated. Returns the
// routines this user rotates through, best fit first, or an empty array when
// nothing is safe for them. This is the user's "plan": one routine per day,
// cycling through the list, so its length is however many routines fit their
// answers (up to MAX_DAYS): 2 for a narrow profile, more for a broad one.
//
// The strictest tier with any routine is used (safe, equipment, level, time;
// otherwise relax those but never safety). Within it, when the user named body
// areas or goals, only routines that speak to at least one of them stay.
function planPool(routines, user) {
  const rules = rulesFor(user);
  let candidates = [];
  for (const fits of TIERS) {
    candidates = routines.filter((r) => fits(r, rules));
    if (candidates.length) break;
  }
  if (!candidates.length) return [];

  const relevant = candidates.filter((r) => wanted(r, user) > 0);
  const chosen = relevant.length ? relevant : candidates;
  return chosen
    .map((routine) => ({ routine, score: score(routine, user) }))
    .sort((a, b) => b.score - a.score || a.routine.name.localeCompare(b.routine.name))
    .slice(0, MAX_DAYS)
    .map((entry) => entry.routine);
}

// `dayNumber` is the whole days since 1970-01-01 of the user's local date, so
// the pick changes at the user's midnight. Returns null when nothing is safe.
function pickRoutine(routines, user, dayNumber) {
  const pool = planPool(routines, user);
  return pool.length ? pool[dayNumber % pool.length] : null;
}

// The routines the AI may choose from: safe for the user, and (when any remain)
// matching their equipment and level too. The AI picks and orders them, but can
// never go outside this list, so safety stays a hard rule.
function candidatesFor(routines, user) {
  const rules = rulesFor(user);
  const safe = routines.filter((r) => isSafe(r, rules));
  const equipped = safe.filter((r) => fitsEquipment(r, rules));
  const pool = equipped.length ? equipped : safe;
  const levelled = pool.filter((r) => fitsLevel(r, rules));
  return levelled.length ? levelled : pool;
}

// Why this routine is on the user's plan, written from their own answers so a
// day's card can explain itself. Lists the body areas / goals it serves, falling
// back to lifestyle, time of day or length when the user chose nothing specific.
function reasonFor(routine, user) {
  const parts = [];
  const targetAreas = new Set((user.painAreas || []).flatMap((a) => PAIN_AREA_TARGETS[a] || [a]));
  const matchedAreas = routine.areas.filter((a) => targetAreas.has(a));
  if (matchedAreas.length) {
    const labels = [...new Set((user.painAreas || []).filter((a) => matchedAreas.some((m) => (PAIN_AREA_TARGETS[a] || [a]).includes(m))).map((a) => AREA_LABEL[a] || a))];
    parts.push(`For your ${labels.join(', ')}`);
  }
  const matchedGoals = (user.goals || []).filter((g) => (GOAL_TAGS[g] || []).some((t) => routine.tags.includes(t)));
  if (matchedGoals.length) parts.push(`Helps with ${matchedGoals.map((g) => GOAL_LABEL[g] || g).join(' and ')}`);

  if (!parts.length) {
    if ((LIFESTYLE_TAGS[user.lifestyle] || []).some((t) => routine.tags.includes(t))) parts.push(`Suits your ${LIFESTYLE_LABEL[user.lifestyle] || user.lifestyle}`);
    else if ((TIME_OF_DAY_TAGS[user.timeOfDay] || []).some((t) => routine.tags.includes(t))) parts.push(`Good for ${TIME_OF_DAY_LABEL[user.timeOfDay] || user.timeOfDay}`);
  }

  const minutes = Math.round(routine.totalSeconds / 60);
  const target = user.minutesPerDay || 10;
  if (minutes <= target) parts.push(`${minutes} min, fits your ${target}-min day`);
  else parts.push(`${minutes} min`);
  return parts.join(' · ');
}

// Builds the plan for the user from the routines that suit them: every routine
// that matches a chosen body area or goal becomes a day, ordered best match first.
// Nothing chosen = every safe, equipment-fitting routine. Capped at MAX_DAYS so
// the overview page stays readable.
function buildPlan(routines, user) {
  const candidates = candidatesFor(routines, user);
  if (!candidates.length) return { days: [] };

  const chose = (user.painAreas || []).length || (user.goals || []).length;
  const relevant = chose
    ? candidates.filter((r) => wanted(r, user) > 0)
    : candidates;
  const pool = relevant.length ? relevant : candidates;

  const ranked = pool
    .map((routine) => ({ routine, score: score(routine, user) }))
    .sort((a, b) => b.score - a.score || a.routine.name.localeCompare(b.routine.name));

  // Spread the days so neighbours don't repeat the same body area as their top
  // focus. Keeps order within the ranked list — just skips an area twice in a row.
  const picked = [];
  const remaining = ranked.slice();
  while (picked.length < MAX_DAYS && remaining.length) {
    const lastArea = picked.length ? picked[picked.length - 1].routine.areas[0] : null;
    const idx = remaining.findIndex((entry) => entry.routine.areas[0] !== lastArea);
    picked.push(remaining[idx >= 0 ? idx : 0]);
    remaining.splice(idx >= 0 ? idx : 0, 1);
  }

  const days = picked.map((entry) => ({ routine: entry.routine, reason: reasonFor(entry.routine, user) }));
  return { days };
}

module.exports = { pickRoutine, planPool, candidatesFor, rulesFor, buildPlan, reasonFor };
