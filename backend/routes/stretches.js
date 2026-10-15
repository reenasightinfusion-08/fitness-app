const router = require('express').Router();
const Stretch = require('../models/Stretch');
const requireAdminKey = require('../middleware/adminKey');
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
// Admin only: send the ADMIN_API_KEY secret in an `x-admin-key` header.
router.post('/', requireAdminKey, async (req, res) => {
  try {
    await Stretch.create(req.body);
    ok(res, null, 'Stretch created', 201);
  } catch (err) {
    if (err.code === 11000) return fail(res, 409, 'A stretch with this poseKey already exists');
    fail(res, 400, err.message);
  }
});

// DELETE /api/stretches/:id  (permanent — admin only, `x-admin-key` header)
router.delete('/:id', requireAdminKey, asyncHandler(async (req, res) => {
  const stretch = await Stretch.findByIdAndDelete(req.params.id);
  if (!stretch) return fail(res, 404, 'Stretch not found');
  ok(res, null, 'Stretch deleted');
}));

module.exports = router;
