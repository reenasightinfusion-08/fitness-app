const router = require('express').Router();
const mongoose = require('mongoose');
const User = require('../models/User');
const Routine = require('../models/Routine');
const CustomRoutine = require('../models/CustomRoutine');
const ActiveRoutine = require('../models/ActiveRoutine');
const Stretch = require('../models/Stretch');
const UserPlan = require('../models/UserPlan');
const requireAuth = require('../middleware/auth');
const { ok, fail, asyncHandler } = require('../utils/response');

const PROFILE_FIELDS = [
  'name', 'age', 'gender', 'country', 'heightCm', 'weightKg', 'lifestyle',
  'sports', 'goals', 'painAreas',
  'noKneel', 'noFloor', 'hadRecentSurgery', 'isPregnant', 'injurySeverity',
  'equipment', 'equipmentNone',
  'flexAnswers', 'flexibilityLevel',
  'minutesPerDay', 'timeOfDay', 'reminderOn', 'reminderTime',
  'safetyAcknowledged', 'onboardingComplete',
];

const HIDDEN_FIELDS = '-passwordHash -verifyCode -resetCode -resetCodeExpires -lastCodeSentAt -__v';

// GET /api/users/me
router.get('/me', requireAuth, asyncHandler(async (req, res) => {
  const user = await User.findById(req.userId).select(HIDDEN_FIELDS);
  if (!user) return fail(res, 404, 'User not found');
  ok(res, user, 'Profile fetched');
}));

// PATCH /api/users/me  { ...any subset of PROFILE_FIELDS }
router.patch('/me', requireAuth, asyncHandler(async (req, res) => {
  const updates = {};
  for (const key of PROFILE_FIELDS) {
    if (key in req.body) updates[key] = req.body[key];
  }
  const user = await User.findByIdAndUpdate(req.userId, updates, {
    new: true,
    runValidators: true,
  }).select(HIDDEN_FIELDS);
  if (!user) return fail(res, 404, 'User not found');
  ok(res, user, 'Profile updated');
}));

// DELETE /api/users/me
// Permanently deletes the account and everything stored for it: the saved plan,
// routine progress and history, and the user's own routines (favorites and
// reminders live on the user document). The user is removed last, so a failure
// part-way leaves the account in place and the request can simply be retried.
router.delete('/me', requireAuth, asyncHandler(async (req, res) => {
  if (!(await User.exists({ _id: req.userId }))) return fail(res, 404, 'User not found');

  await Promise.all([
    UserPlan.deleteMany({ user: req.userId }),
    ActiveRoutine.deleteMany({ user: req.userId }),
    CustomRoutine.deleteMany({ user: req.userId }),
  ]);
  await User.deleteOne({ _id: req.userId });
  ok(res, null, 'Account deleted');
}));

// PUT /api/users/me/hurt-stretches/:stretchId
// Marks a stretch as one that hurt (marking it twice changes nothing). Routines that
// contain it are left out of the user's plan from now on.
router.put('/me/hurt-stretches/:stretchId', requireAuth, asyncHandler(async (req, res) => {
  const { stretchId } = req.params;
  if (!mongoose.isValidObjectId(stretchId)) return fail(res, 400, 'Invalid stretch id');
  const stretch = await Stretch.findById(stretchId).select('name').lean();
  if (!stretch) return fail(res, 404, 'Stretch not found');

  await User.updateOne(
    { _id: req.userId, 'hurtStretches.stretch': { $ne: stretchId } },
    { $push: { hurtStretches: { stretch: stretchId, name: stretch.name } } },
  );
  ok(res, null, 'Marked as hurt');
}));

// DELETE /api/users/me/hurt-stretches/:stretchId
// Undoes it; removing one that isn't marked changes nothing.
router.delete('/me/hurt-stretches/:stretchId', requireAuth, asyncHandler(async (req, res) => {
  const { stretchId } = req.params;
  if (!mongoose.isValidObjectId(stretchId)) return fail(res, 400, 'Invalid stretch id');

  await User.updateOne({ _id: req.userId }, { $pull: { hurtStretches: { stretch: stretchId } } });
  ok(res, null, 'Removed from hurt stretches');
}));

const MAX_REMINDERS = 10;
const ALL_DAYS = [1, 2, 3, 4, 5, 6, 7];

// The user's reminders as the app reads them. Before the first save this is the
// reminder chosen during onboarding.
function remindersOf(user) {
  if (user.reminders) {
    return user.reminders.map((r) => ({ time: { hour: r.time.hour, minute: r.time.minute }, isOn: r.isOn, days: r.days }));
  }
  const time = user.reminderTime || {};
  return [{ time: { hour: time.hour ?? 8, minute: time.minute ?? 0 }, isOn: user.reminderOn !== false, days: ALL_DAYS }];
}

// Returns { reminders } cleaned up, or { error } with the 400 message.
function parseReminders(body) {
  const list = body && body.reminders;
  if (!Array.isArray(list) || list.length > MAX_REMINDERS) {
    return { error: `reminders must be an array of at most ${MAX_REMINDERS}` };
  }
  const reminders = [];
  for (const item of list) {
    const hour = item && item.time && item.time.hour;
    const minute = item && item.time && item.time.minute;
    if (!Number.isInteger(hour) || hour < 0 || hour > 23 || !Number.isInteger(minute) || minute < 0 || minute > 59) {
      return { error: 'Each reminder needs time.hour (0-23) and time.minute (0-59)' };
    }
    if (typeof item.isOn !== 'boolean') return { error: 'Each reminder needs isOn as true or false' };
    if (!Array.isArray(item.days) || !item.days.every((d) => Number.isInteger(d) && d >= 1 && d <= 7)) {
      return { error: 'Each reminder needs days as numbers from 1 (Monday) to 7 (Sunday)' };
    }
    reminders.push({ time: { hour, minute }, isOn: item.isOn, days: [...new Set(item.days)].sort() });
  }
  return { reminders };
}

// GET /api/users/me/reminders
router.get('/me/reminders', requireAuth, asyncHandler(async (req, res) => {
  const user = await User.findById(req.userId).select('reminders reminderOn reminderTime').lean();
  if (!user) return fail(res, 404, 'User not found');
  ok(res, { reminders: remindersOf(user) }, 'Reminders fetched');
}));

// PUT /api/users/me/reminders  { reminders: [{ time: { hour, minute }, isOn, days }] }
// Replaces the whole list.
router.put('/me/reminders', requireAuth, asyncHandler(async (req, res) => {
  const parsed = parseReminders(req.body);
  if (parsed.error) return fail(res, 400, parsed.error);
  const user = await User.findByIdAndUpdate(req.userId, { reminders: parsed.reminders }, { new: true })
    .select('reminders reminderOn reminderTime').lean();
  if (!user) return fail(res, 404, 'User not found');
  ok(res, { reminders: remindersOf(user) }, 'Reminders saved');
}));

// Which collection a favouritable routine is in — any active library routine
// ('system') or one of the user's own custom routines ('custom') — or null.
async function favouriteType(userId, routineId) {
  if (await Routine.exists({ _id: routineId, isActive: true })) return 'system';
  if (await CustomRoutine.exists({ _id: routineId, user: userId })) return 'custom';
  return null;
}

// PUT /api/users/me/favorites/:routineId
// Adds the routine to the user's favorites (adding it twice changes nothing).
router.put('/me/favorites/:routineId', requireAuth, asyncHandler(async (req, res) => {
  const { routineId } = req.params;
  if (!mongoose.isValidObjectId(routineId)) return fail(res, 400, 'Invalid routine id');
  const routineType = await favouriteType(req.userId, routineId);
  if (!routineType) return fail(res, 404, 'Routine not found');

  // Only pushed when this routine isn't already in the list.
  await User.updateOne(
    { _id: req.userId, 'favorites.routineId': { $ne: routineId } },
    { $push: { favorites: { routineId, routineType } } },
  );
  ok(res, null, 'Added to favorites');
}));

// DELETE /api/users/me/favorites/:routineId
// Removes it; removing one that isn't there changes nothing.
router.delete('/me/favorites/:routineId', requireAuth, asyncHandler(async (req, res) => {
  const { routineId } = req.params;
  if (!mongoose.isValidObjectId(routineId)) return fail(res, 400, 'Invalid routine id');

  await User.updateOne({ _id: req.userId }, { $pull: { favorites: { routineId } } });
  ok(res, null, 'Removed from favorites');
}));

module.exports = router;
