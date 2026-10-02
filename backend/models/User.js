const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    // --- auth ---
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    // Null for accounts created through Google sign-in until a password is set.
    passwordHash: { type: String, default: null },
    googleId: { type: String, unique: true, sparse: true },
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

    // --- reminders ---
    // The daily stretch reminders the phone schedules as local notifications. Absent until
    // the user first saves them; GET /api/users/me/reminders then falls back to the
    // onboarding answer (reminderOn / reminderTime). `days` are 1 (Mon) to 7 (Sun).
    reminders: {
      type: [
        new mongoose.Schema(
          {
            time: {
              hour: { type: Number, min: 0, max: 23, required: true },
              minute: { type: Number, min: 0, max: 59, required: true },
            },
            isOn: { type: Boolean, default: true },
            days: { type: [Number], default: [1, 2, 3, 4, 5, 6, 7] },
          },
          { _id: false },
        ),
      ],
      default: undefined,
    },

    // --- stretches that hurt ---
    // Stretches the user marked as painful after a session. The plan builder leaves any
    // routine containing one out. Changed through PUT/DELETE /api/users/me/hurt-stretches/:stretchId.
    hurtStretches: {
      type: [
        new mongoose.Schema(
          {
            stretch: { type: mongoose.Schema.Types.ObjectId, ref: 'Stretch', required: true },
            name: { type: String, required: true },
          },
          { _id: false },
        ),
      ],
      default: [],
    },

    // --- favourites ---
    // The routines (library or custom) the user hearted, oldest first. `routineId` is the
    // routine's own _id; `routineType` says which collection it is in, as on ActiveRoutine.
    // Session screen preferences, changed through PATCH /api/users/me.
    sessionSettings: {
      guidance: { type: String, enum: ['voice', 'beeps', 'silent'], default: 'voice' },
      voiceRate: { type: Number, min: 0.7, max: 1.3, default: 1 },
      musicOn: { type: Boolean, default: true },
      showCalories: { type: Boolean, default: false },
      dayStartHour: { type: Number, min: 0, max: 6, default: 0 },
    },

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
