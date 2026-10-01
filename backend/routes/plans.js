const router = require('express').Router();
const Routine = require('../models/Routine');
const User = require('../models/User');
const ActiveRoutine = require('../models/ActiveRoutine');
const requireAuth = require('../middleware/auth');
const crypto = require('crypto');
const UserPlan = require('../models/UserPlan');
const { buildPlan } = require('../utils/dailyPlan');
const { toResponse } = require('../utils/routineItems');
const { ok, fail, asyncHandler } = require('../utils/response');

const DAY_MS = 24 * 60 * 60 * 1000;

router.use(requireAuth);

// Reads `date` / `tzOffset` from the query. Returns { tzOffset, dayStart } or
// { error } with the 400 message.
function readDay(query) {
  const tzOffset = query.tzOffset === undefined ? 0 : Number(query.tzOffset);
  if (!Number.isInteger(tzOffset) || Math.abs(tzOffset) > 840) {
    return { error: 'tzOffset must be whole minutes from UTC, e.g. 330' };
  }
  const date = query.date ?? new Date(Date.now() + tzOffset * 60000).toISOString().slice(0, 10);
  const parts = /^(\d{4})-(\d{2})-(\d{2})$/.exec(date);
  const dayStart = parts && Date.UTC(+parts[1], +parts[2] - 1, +parts[3]);
  if (!parts || new Date(dayStart).toISOString().slice(0, 10) !== date) {
    return { error: 'date must be a real date as YYYY-MM-DD' };
  }
  return { tzOffset, dayStart };
}

const hash = (value) => crypto.createHash('sha1').update(JSON.stringify(value)).digest('hex');
const RETRY_AI_AFTER_MS = 10 * 60 * 1000;

// Everything in the user's answers that can change which routines suit them.
const profileOf = (user) => ({
  painAreas: user.painAreas, goals: user.goals, lifestyle: user.lifestyle, timeOfDay: user.timeOfDay,
  minutesPerDay: user.minutesPerDay, equipment: user.equipment, equipmentNone: user.equipmentNone,
  noKneel: user.noKneel, noFloor: user.noFloor, injurySeverity: user.injurySeverity,
  isPregnant: user.isPregnant, hadRecentSurgery: user.hadRecentSurgery, flexibilityLevel: user.flexibilityLevel,
});

// The user's saved plan, built the first time and rebuilt when their answers or
// the routines in the library change. Returns null when nothing is safe for them.
async function ensurePlan(user, routines) {
  const built = buildPlan(routines, user);
  if (!built.days.length) return null;

  const profileHash = hash(profileOf(user));
  const catalogHash = hash(routines.map((r) => String(r._id)).sort());
  const saved = await UserPlan.findOne({ user: user._id });
  const current = saved && saved.profileHash === profileHash && saved.catalogHash === catalogHash;
  if (current) return saved;

  return UserPlan.findOneAndUpdate(
    { user: user._id },
    {
      user: user._id,
      profileHash,
      catalogHash,
      startedAt: saved && saved.profileHash === profileHash ? saved.startedAt : new Date(),
      source: 'rules',
      summary: '',
      generatedAt: new Date(),
      days: built.days.map((d) => ({ routine: d.routine._id, reason: d.reason })),
    },
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );
}

// The user's plan and which day of it today is.
async function loadPlan(req, res) {
  const day = readDay(req.query);
  if (day.error) return void fail(res, 400, day.error);

  const user = await User.findById(req.userId).lean();
  if (!user) return void fail(res, 404, 'User not found');

  const routines = await Routine.find({ isActive: true }).populate('stretches.stretch');
  const plan = await ensurePlan(user, routines);
  if (!plan || !plan.days.length) return void fail(res, 404, 'No routine fits your profile yet');

  const byId = new Map(routines.map((r) => [String(r._id), r]));
  const days = plan.days.map((d, i) => ({ day: i + 1, routine: byId.get(String(d.routine)), reason: d.reason }));
  // Day 1 is the day the plan started (in the user's time zone).
  const startDay = Math.floor((plan.startedAt.getTime() + day.tzOffset * 60000) / DAY_MS);
  const daysIn = Math.max(0, Math.floor(day.dayStart / DAY_MS) - startDay);
  return { ...day, days, summary: plan.summary, source: plan.source, todayIndex: daysIn % days.length };
}

// GET /api/plans/today?date=YYYY-MM-DD&tzOffset=330
// Today's routine from the user's plan. `date` is the user's local date and
// `tzOffset` their offset from UTC in minutes (IST = 330), so "today" and "done
// today" follow their clock; both are optional (tzOffset defaults to 0, date to
// today at that offset). `completedToday` is true once a routine started from
// the plan (source 'plan') was finished today.
router.get('/today', asyncHandler(async (req, res) => {
  const plan = await loadPlan(req, res);
  if (!plan) return;

  const from = new Date(plan.dayStart - plan.tzOffset * 60000);
  const completedToday = await ActiveRoutine.exists({
    user: req.userId,
    source: 'plan',
    status: 'completed',
    completedAt: { $gte: from, $lt: new Date(from.getTime() + DAY_MS) },
  });
  const today = plan.days[plan.todayIndex];
  ok(res, {
    ...toResponse(today.routine),
    reason: today.reason,
    planDays: plan.days.length,
    todayDay: today.day,
    completedToday: !!completedToday,
  }, "Today's plan fetched");
}));

// GET /api/plans/overview?date=YYYY-MM-DD&tzOffset=330
// The whole plan: `planDays` routines, one per day, repeating in order, each with
// the reason it is there. Shown once after onboarding so the user sees what they got.
router.get('/overview', asyncHandler(async (req, res) => {
  const plan = await loadPlan(req, res);
  if (!plan) return;

  ok(res, {
    planDays: plan.days.length,
    todayDay: plan.todayIndex + 1,
    summary: plan.summary,
    source: plan.source,
    days: plan.days.map((d, i) => ({ day: d.day, isToday: i === plan.todayIndex, reason: d.reason, routine: toResponse(d.routine) })),
  }, 'Plan overview fetched');
}));

module.exports = router;
