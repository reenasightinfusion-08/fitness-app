const router = require('express').Router();
const CustomRoutine = require('../models/CustomRoutine');
const User = require('../models/User');
const requireAuth = require('../middleware/auth');
const { resolvePoseKeys, toResponse } = require('../utils/routineItems');
const { ok, fail, asyncHandler } = require('../utils/response');

const INPUT_FIELDS = ['name', 'description', 'level', 'tags', 'transitionSeconds', 'stretches'];

router.use(requireAuth);

// POST /api/custom-routines  { name, description, level, tags, transitionSeconds,
//   stretches: [{ stretch | poseKey, holdSeconds, repCount }] }
// The owner always comes from the token; derived fields are computed by the model.
router.post('/', async (req, res) => {
  try {
    const input = {};
    for (const key of INPUT_FIELDS) {
      if (key in req.body) input[key] = req.body[key];
    }
    await CustomRoutine.create({
      ...input,
      stretches: await resolvePoseKeys(input.stretches),
      user: req.userId,
    });
    ok(res, null, 'Custom routine created', 201);
  } catch (err) {
    if (err.code === 11000) return fail(res, 409, 'You already have a routine with this name');
    fail(res, 400, err.message);
  }
});

// GET /api/custom-routines  (only the signed-in user's routines, newest first)
router.get('/', asyncHandler(async (req, res) => {
  const routines = await CustomRoutine.find({ user: req.userId })
    .sort({ createdAt: -1 })
    .populate('stretches.stretch');
  ok(res, routines.map(toResponse), 'Custom routines fetched');
}));

// GET /api/custom-routines/:id
router.get('/:id', asyncHandler(async (req, res) => {
  const routine = await CustomRoutine.findOne({ _id: req.params.id, user: req.userId })
    .populate('stretches.stretch');
  if (!routine) return fail(res, 404, 'Custom routine not found');
  ok(res, toResponse(routine), 'Custom routine fetched');
}));

// DELETE /api/custom-routines/:id  (permanent)
router.delete('/:id', asyncHandler(async (req, res) => {
  const routine = await CustomRoutine.findOneAndDelete({ _id: req.params.id, user: req.userId });
  if (!routine) return fail(res, 404, 'Custom routine not found');
  await User.updateOne({ _id: req.userId }, { $pull: { favorites: { routineId: routine._id } } });
  ok(res, null, 'Custom routine deleted');
}));

module.exports = router;
