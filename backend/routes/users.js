const router = require('express').Router();
const mongoose = require('mongoose');
const User = require('../models/User');
const Routine = require('../models/Routine');
const CustomRoutine = require('../models/CustomRoutine');
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
