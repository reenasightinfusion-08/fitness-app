const mongoose = require('mongoose');

// A user's plan: the routines they cycle through, one per day, in order. Built
// once from their onboarding answers (by the AI, or by the rules in
// utils/dailyPlan.js when the AI isn't available) and kept, so the plan doesn't
// change under them from one visit to the next.
const userPlanSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },

    // Fingerprints used to tell when the plan is out of date: the answers it was
    // built from, and the routines it could choose from.
    profileHash: { type: String, required: true },
    catalogHash: { type: String, required: true },

    // Day 1. Kept when only the routine library changes, reset when the answers do.
    startedAt: { type: Date, required: true },

    source: { type: String, enum: ['rules', 'ai'], required: true },
    summary: { type: String, default: '' },
    generatedAt: { type: Date, default: Date.now },

    days: {
      type: [
        {
          _id: false,
          routine: { type: mongoose.Schema.Types.ObjectId, ref: 'Routine', required: true },
          // Why this routine is on the plan, in terms of the user's answers.
          reason: { type: String, default: '' },
        },
      ],
      default: [],
    },
  },
  { timestamps: false },
);

module.exports = mongoose.model('UserPlan', userPlanSchema);
