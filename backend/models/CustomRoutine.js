const mongoose = require('mongoose');
const routineItemSchema = require('./routineItem');
const { deriveRoutineFields } = require('../utils/routineItems');

// A routine built by one user in the routine builder. Common routines shown
// to everyone live in the Routine collection.
const customRoutineSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    name: { type: String, required: true, trim: true },
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
  },
  { timestamps: true },
);

// A name only has to be unique within one user's routines.
customRoutineSchema.index({ user: 1, name: 1 }, { unique: true });

customRoutineSchema.pre('validate', function () {
  return deriveRoutineFields(this);
});

module.exports = mongoose.model('CustomRoutine', customRoutineSchema);
