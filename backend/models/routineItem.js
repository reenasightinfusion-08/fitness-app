const mongoose = require('mongoose');

const isWholeNumber = { validator: Number.isInteger, message: '{PATH} must be a whole number' };

// One stretch inside a routine. Shared by Routine and (later) UserRoutine.
// Limits mirror the routine builder's stepper (10-90s, 1-5 reps).
const routineItemSchema = new mongoose.Schema(
  {
    stretch: { type: mongoose.Schema.Types.ObjectId, ref: 'Stretch', required: true },
    // Copied from the stretch on save (and checked against it if the client sends one).
    poseKey: { type: String },
    holdSeconds: { type: Number, default: 30, min: 10, max: 90, validate: isWholeNumber },
    repCount: { type: Number, default: 1, min: 1, max: 5, validate: isWholeNumber },
  },
  { _id: false },
);

module.exports = routineItemSchema;
