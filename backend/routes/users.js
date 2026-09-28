const router = require('express').Router();
const User = require('../models/User');
const requireAuth = require('../middleware/auth');

const PROFILE_FIELDS = [
  'name', 'age', 'gender', 'heightCm', 'weightKg', 'lifestyle',
  'sports', 'goals', 'painAreas',
  'noKneel', 'noFloor', 'hadRecentSurgery', 'isPregnant', 'injurySeverity',
  'equipment', 'equipmentNone',
  'flexAnswers', 'flexibilityLevel',
  'minutesPerDay', 'timeOfDay', 'reminderOn', 'reminderTime',
  'safetyAcknowledged', 'onboardingComplete',
];

const HIDDEN_FIELDS = '-passwordHash -verifyCode -resetCode -resetCodeExpires -lastCodeSentAt -__v';

// GET /api/users/me
router.get('/me', requireAuth, async (req, res) => {
  const user = await User.findById(req.userId).select(HIDDEN_FIELDS);
  if (!user) return res.status(404).json({ error: 'User not found' });
  res.json(user);
});

// PATCH /api/users/me  { ...any subset of PROFILE_FIELDS }
router.patch('/me', requireAuth, async (req, res) => {
  const updates = {};
  for (const key of PROFILE_FIELDS) {
    if (key in req.body) updates[key] = req.body[key];
  }
  const user = await User.findByIdAndUpdate(req.userId, updates, {
    new: true,
    runValidators: true,
  }).select(HIDDEN_FIELDS);
  if (!user) return res.status(404).json({ error: 'User not found' });
  res.json(user);
});

module.exports = router;
