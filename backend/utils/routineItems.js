const Stretch = require('../models/Stretch');

const POSITION_LABEL = { standing: 'Standing', seated: 'Seated', floor: 'Floor' };

// An item may send `stretch` (id), `poseKey`, or both. With only a poseKey the
// id is looked up here; with both, deriveRoutineFields checks they match.
async function resolvePoseKeys(items) {
  if (!Array.isArray(items)) return items;
  const keys = items.filter((i) => i && i.poseKey && !i.stretch).map((i) => i.poseKey);
  const found = await Stretch.find({ poseKey: { $in: keys } }).select('_id poseKey');
  const idByKey = new Map(found.map((s) => [s.poseKey, s._id]));

  return items.map((item) => {
    if (!item.poseKey || item.stretch) return item;
    if (!idByKey.has(item.poseKey)) throw new Error(`Unknown poseKey: ${item.poseKey}`);
    return { ...item, stretch: idByKey.get(item.poseKey) };
  });
}

// Fills areas, equipment, stretchCount, totalSeconds and sequence from
// `routine.stretches`. Shared by Routine and CustomRoutine so both compute
// them the same way; the client never supplies these.
async function deriveRoutineFields(routine) {
  const ids = routine.stretches.map((item) => item.stretch).filter(Boolean);
  const found = await Stretch.find({ _id: { $in: ids } });
  const byId = new Map(found.map((s) => [String(s._id), s]));

  let totalSeconds = 0;
  const areas = new Set();
  const equipment = new Set();
  const positions = [];

  for (const item of routine.stretches) {
    const stretch = byId.get(String(item.stretch));
    if (!stretch) throw new Error(`Stretch not found: ${item.stretch}`);
    if (item.poseKey && item.poseKey !== stretch.poseKey) {
      throw new Error(`poseKey ${item.poseKey} does not match stretch ${item.stretch} (${stretch.poseKey})`);
    }
    item.poseKey = stretch.poseKey;

    totalSeconds += item.holdSeconds * item.repCount * (stretch.isEachSide ? 2 : 1);
    stretch.areas.forEach((a) => areas.add(a));
    stretch.equipment.forEach((e) => equipment.add(e));
    if (positions[positions.length - 1] !== stretch.position) positions.push(stretch.position);
  }

  routine.areas = [...areas];
  routine.equipment = [...equipment];
  routine.stretchCount = routine.stretches.length;
  routine.totalSeconds = totalSeconds;
  routine.sequence = positions.map((p) => POSITION_LABEL[p]).join(' → ');
}

// The API shape of a routine: the stored fields plus `minutes`. Items return
// the full stretch (which carries its own poseKey), so the item's stored
// poseKey is left out.
function toResponse(routine) {
  const json = routine.toJSON();
  json.stretches = json.stretches.map(({ stretch, holdSeconds, repCount }) => ({
    stretch,
    holdSeconds,
    repCount,
  }));
  json.minutes = Math.max(1, Math.round(json.totalSeconds / 60));
  return json;
}

module.exports = { resolvePoseKeys, deriveRoutineFields, toResponse };
