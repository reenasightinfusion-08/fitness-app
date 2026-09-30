const mongoose = require('mongoose');
const routineItemSchema = require('./routineItem');

// One attempt at a routine by one user. A user can have several routines in
// progress at once, each keeping its own position. Finished attempts stay in
// this collection with status 'completed' — progress history is just a query.
const activeRoutineSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },

    // 'system' = Routine collection, 'custom' = CustomRoutine collection.
    routineType: { type: String, enum: ['system', 'custom'], required: true },
    routineId: { type: mongoose.Schema.Types.ObjectId, required: true },

    // Copied when the routine begins, so editing or deleting the source
    // routine can't break an attempt that is already in progress.
    routineName: { type: String, required: true },
    stretches: { type: [routineItemSchema], required: true },

    totalStretch: { type: Number, required: true, min: 1 },
    // Resume position: 2 means the next stretch is the third one.
    completedStretch: { type: Number, default: 0, min: 0 },

    status: { type: String, enum: ['inProgress', 'completed'], default: 'inProgress' },
    startedAt: { type: Date, default: Date.now },
    completedAt: { type: Date, default: null },
  },
  { timestamps: { createdAt: false, updatedAt: true } },
);

// A routine can be in progress only once per user; this also stops a double-tapped Begin.
activeRoutineSchema.index(
  { user: 1, routineType: 1, routineId: 1 },
  { unique: true, partialFilterExpression: { status: 'inProgress' } },
);

// Serves the history list and the resume check.
activeRoutineSchema.index({ user: 1, status: 1, completedAt: -1 });

module.exports = mongoose.model('ActiveRoutine', activeRoutineSchema);
