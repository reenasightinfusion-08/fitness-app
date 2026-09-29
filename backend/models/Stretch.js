const mongoose = require('mongoose');

const stretchSchema = new mongoose.Schema(
  {
    poseKey: { type: String, required: true, unique: true, trim: true },
    name: { type: String, required: true, trim: true },
    position: { type: String, enum: ['standing', 'seated', 'floor'], required: true },
    isEachSide: { type: Boolean, default: false },
    isDynamic: { type: Boolean, default: false },
    isKneeling: { type: Boolean, default: false },
    level: { type: String, enum: ['beginner', 'intermediate', 'advanced'], default: 'beginner' },
    equipment: { type: [String], default: [] },
    defaultHoldSeconds: { type: Number, default: 30 },
    defaultRepCount: { type: Number, default: 1 },
    setupCue: { type: String, default: '' },
    feelCue: { type: String, default: null },
    feel: { type: String, required: true },
    steps: { type: [String], default: [] },
    commonMistake: { type: String, default: '' },
    easier: { type: String, default: '' },
    harder: { type: String, default: '' },
    cautions: { type: String, default: '' },
  },
  { timestamps: true },
);

module.exports = mongoose.model('Stretch', stretchSchema);
