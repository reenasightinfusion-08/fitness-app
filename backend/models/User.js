const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    // --- auth ---
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    passwordHash: { type: String, required: true },
    isVerified: { type: Boolean, default: false },
    verifyCode: { type: String, default: null },
    resetCode: { type: String, default: null },
    resetCodeExpires: { type: Date, default: null },
    lastCodeSentAt: { type: Date, default: null },

    // --- profile (flat, mirrors OnboardingProfile) ---
    name: { type: String, default: '' },
    age: { type: Number, default: null },
    gender: { type: String, default: null },
    country: { type: String, default: null, trim: true },
    heightCm: { type: Number, default: null },
    weightKg: { type: Number, default: null },
    lifestyle: { type: String, default: null },
    sports: { type: [String], default: [] },
    goals: { type: [String], default: [] },
    painAreas: { type: [String], default: [] },

    noKneel: { type: Boolean, default: false },
    noFloor: { type: Boolean, default: false },
    hadRecentSurgery: { type: Boolean, default: false },
    isPregnant: { type: Boolean, default: false },
    injurySeverity: { type: Map, of: String, default: {} },

    equipment: { type: [String], default: [] },
    equipmentNone: { type: Boolean, default: false },

    flexAnswers: {
      type: [
        {
          question: { type: String, required: true },
          answer: { type: String, required: true },
          score: { type: Number, required: true },
        },
      ],
      default: [],
    },
    flexibilityLevel: { type: Number, default: 1 },

    minutesPerDay: { type: Number, default: 10 },
    timeOfDay: { type: String, default: null },
    reminderOn: { type: Boolean, default: true },
    reminderTime: {
      hour: { type: Number, default: 8 },
      minute: { type: Number, default: 0 },
    },
    safetyAcknowledged: { type: Boolean, default: false },

    onboardingComplete: { type: Boolean, default: false },

    // --- favourites ---
    // The routines (library or custom) the user hearted, oldest first. `routineId` is the
    // routine's own _id; `routineType` says which collection it is in, as on ActiveRoutine.
    // Changed only through PUT/DELETE /api/users/me/favorites/:routineId.
    favorites: {
      type: [
        new mongoose.Schema(
          {
            routineId: { type: mongoose.Schema.Types.ObjectId, required: true },
            routineType: { type: String, enum: ['system', 'custom'], required: true },
          },
          { _id: false },
        ),
      ],
      default: [],
    },
  },
  { timestamps: true },
);

module.exports = mongoose.model('User', userSchema);
