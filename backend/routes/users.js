const router = require('express').Router();
const User = require('../models/User');
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

module.exports = router;
