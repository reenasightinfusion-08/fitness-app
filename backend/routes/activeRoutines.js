const router = require('express').Router();
const ActiveRoutine = require('../models/ActiveRoutine');
const Routine = require('../models/Routine');
const CustomRoutine = require('../models/CustomRoutine');
const requireAuth = require('../middleware/auth');
const { ok, fail, asyncHandler } = require('../utils/response');

router.use(requireAuth);

// POST /api/active-routines  { routineId, routineType: 'system' | 'custom' }
// Begins a routine (fetch it with GET /current). Several routines can be in progress
// at once; beginning one that is already in progress changes nothing.
router.post('/', asyncHandler(async (req, res) => {
  const { routineId, routineType } = req.body;
  if (!routineId) return fail(res, 400, 'routineId is required');
  if (routineType !== 'system' && routineType !== 'custom') {
    return fail(res, 400, "routineType must be 'system' or 'custom'");
  }

  const source = routineType === 'system'
    ? await Routine.findOne({ _id: routineId, isActive: true })
    : await CustomRoutine.findOne({ _id: routineId, user: req.userId });
  if (!source) return fail(res, 404, 'Routine not found');

  const inProgress = { user: req.userId, routineType, routineId: source._id, status: 'inProgress' };
  if (await ActiveRoutine.exists(inProgress)) return ok(res, null, 'Routine already in progress');

  try {
    await ActiveRoutine.create({
      user: req.userId,
      routineType,
      routineId: source._id,
      routineName: source.name,
      stretches: source.stretches.map(({ stretch, poseKey, holdSeconds, repCount }) => ({
        stretch, poseKey, holdSeconds, repCount,
      })),
      totalStretch: source.stretchCount,
    });
    ok(res, null, 'Routine started', 201);
  } catch (err) {
    // A parallel Begin won the race; its record is already saved.
    if (err.code !== 11000 || !(await ActiveRoutine.exists(inProgress))) throw err;
    ok(res, null, 'Routine already in progress');
  }
}));

// GET /api/active-routines/current  (resume check: every routine in progress, latest activity first;
// an empty array when there are none. Match a tapped routine by routineType + routineId.)
router.get('/current', asyncHandler(async (req, res) => {
  const current = await ActiveRoutine.find({ user: req.userId, status: 'inProgress' })
    .sort({ updatedAt: -1 })
    .populate('stretches.stretch');
  ok(res, current, 'Current routines fetched');
}));

// GET /api/active-routines/history  (completed routines, newest first)
router.get('/history', asyncHandler(async (req, res) => {
  const history = await ActiveRoutine.find({ user: req.userId, status: 'completed' })
    .select('-stretches')
    .sort({ completedAt: -1 });
  ok(res, history, 'History fetched');
}));

// PATCH /api/active-routines/:id/progress  { completedStretch }
// Sets the position (0..totalStretch), so a retry can't double count. The total
// completes the routine; 0 starts it over and restarts its clock.
router.patch('/:id/progress', asyncHandler(async (req, res) => {
  const { completedStretch } = req.body;
  const active = await ActiveRoutine.findOne({ _id: req.params.id, user: req.userId });
  if (!active) return fail(res, 404, 'Active routine not found');
  if (active.status !== 'inProgress') return fail(res, 409, `Routine is already ${active.status}`);
  if (!Number.isInteger(completedStretch) || completedStretch < 0 || completedStretch > active.totalStretch) {
    return fail(res, 400, `completedStretch must be a whole number from 0 to ${active.totalStretch}`);
  }

  active.completedStretch = completedStretch;
  if (completedStretch === 0) active.startedAt = new Date();
  const finished = completedStretch === active.totalStretch;
  if (finished) {
    active.status = 'completed';
    active.completedAt = new Date();
  }
  await active.save();
  ok(res, null, finished ? 'Routine completed' : 'Progress saved');
}));

module.exports = router;
