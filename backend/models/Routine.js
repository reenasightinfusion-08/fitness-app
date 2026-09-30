const mongoose = require('mongoose');
const Stretch = require('./Stretch');
const routineItemSchema = require('./routineItem');

const POSITION_LABEL = { standing: 'Standing', seated: 'Seated', floor: 'Floor' };

// Common routines shown to every user. Routines built by a user live in a
// separate collection.
const routineSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, unique: true, trim: true },
    description: { type: String, default: '' },
    level: { type: String, enum: ['beginner', 'intermediate', 'advanced'], default: 'beginner' },
    tags: { type: [String], default: [] },
    // null = "Auto" (more time when moving from standing to the floor).
    transitionSeconds: { type: Number, default: null, min: 0 },

    // Order is play order.
    stretches: {
      type: [routineItemSchema],
      validate: { validator: (v) => v.length > 0, message: 'At least one stretch is required' },
    },

    // Derived from the stretches, never trusted from the client — see the pre('validate') hook.
    areas: { type: [String], default: [] },
    equipment: { type: [String], default: [] },
    stretchCount: { type: Number, default: 0 },
    totalSeconds: { type: Number, default: 0 },
    sequence: { type: String, default: '' },

    isActive: { type: Boolean, default: true },
  },
  {
    timestamps: true,
    id: false,
    toJSON: { virtuals: true },
  },
);

routineSchema.virtual('minutes').get(function () {
  return Math.max(1, Math.round(this.totalSeconds / 60));
});

routineSchema.pre('validate', async function () {
  const ids = this.stretches.map((item) => item.stretch).filter(Boolean);
  const found = await Stretch.find({ _id: { $in: ids } });
  const byId = new Map(found.map((s) => [String(s._id), s]));

  let totalSeconds = 0;
  const areas = new Set();
  const equipment = new Set();
  const positions = [];

  for (const item of this.stretches) {
    const stretch = byId.get(String(item.stretch));
    if (!stretch) throw new Error(`Stretch not found: ${item.stretch}`);

    totalSeconds += item.holdSeconds * item.repCount * (stretch.isEachSide ? 2 : 1);
    stretch.areas.forEach((a) => areas.add(a));
    stretch.equipment.forEach((e) => equipment.add(e));
    if (positions[positions.length - 1] !== stretch.position) positions.push(stretch.position);
  }

  this.areas = [...areas];
  this.equipment = [...equipment];
  this.stretchCount = this.stretches.length;
  this.totalSeconds = totalSeconds;
  this.sequence = positions.map((p) => POSITION_LABEL[p]).join(' → ');
});

module.exports = mongoose.model('Routine', routineSchema);
