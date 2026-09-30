const router = require('express').Router();
const Routine = require('../models/Routine');
const { resolvePoseKeys, toResponse } = require('../utils/routineItems');
const { ok, fail, asyncHandler } = require('../utils/response');

// GET /api/routines  (inactive routines are hidden, not deleted)
router.get('/', asyncHandler(async (_req, res) => {
  const routines = await Routine.find({ isActive: true })
    .sort({ name: 1 })
    .populate('stretches.stretch');
  ok(res, routines.map(toResponse), 'Routines fetched');
}));

// GET /api/routines/:id
router.get('/:id', asyncHandler(async (req, res) => {
  const routine = await Routine.findById(req.params.id).populate('stretches.stretch');
  if (!routine) return fail(res, 404, 'Routine not found');
  ok(res, toResponse(routine), 'Routine fetched');
}));

// POST /api/routines  { name, description, level, tags, transitionSeconds,
//   stretches: [{ stretch | poseKey, holdSeconds, repCount }] }
// No auth on this one yet — it's content data for seeding the library,
// not user data. Lock this down (e.g. an admin check) before shipping.
router.post('/', async (req, res) => {
  try {
    await Routine.create({
      ...req.body,
      stretches: await resolvePoseKeys(req.body.stretches),
    });
    ok(res, null, 'Routine created', 201);
  } catch (err) {
    if (err.code === 11000) return fail(res, 409, 'A routine with this name already exists');
    fail(res, 400, err.message);
  }
});

// DELETE /api/routines/:id  (permanent — no auth yet, lock down before use)
router.delete('/:id', asyncHandler(async (req, res) => {
  const routine = await Routine.findByIdAndDelete(req.params.id);
  if (!routine) return fail(res, 404, 'Routine not found');
  ok(res, null, 'Routine deleted');
}));

module.exports = router;
