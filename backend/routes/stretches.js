const router = require('express').Router();
const Stretch = require('../models/Stretch');
const { ok, fail, asyncHandler } = require('../utils/response');

// GET /api/stretches  (inactive stretches are hidden, not deleted)
router.get('/', asyncHandler(async (_req, res) => {
  const stretches = await Stretch.find({ isActive: true }).sort({ name: 1 });
  ok(res, stretches, 'Stretches fetched');
}));

// GET /api/stretches/:id
router.get('/:id', asyncHandler(async (req, res) => {
  const stretch = await Stretch.findById(req.params.id);
  if (!stretch) return fail(res, 404, 'Stretch not found');
  ok(res, stretch, 'Stretch fetched');
}));

// POST /api/stretches  { poseKey, name, position, feel, ... }
// No auth on this one yet — it's content data for seeding the library,
// not user data. Lock this down (e.g. an admin check) before shipping.
router.post('/', async (req, res) => {
  try {
    const stretch = await Stretch.create(req.body);
    ok(res, stretch, 'Stretch created', 201);
  } catch (err) {
    if (err.code === 11000) return fail(res, 409, 'A stretch with this poseKey already exists');
    fail(res, 400, err.message);
  }
});

module.exports = router;
