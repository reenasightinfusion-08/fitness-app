const mongoose = require('mongoose');

// Must match the StretchPoses constant names in lib/core/widgets/stretch_figure.dart —
// the app draws the figure from this key, so a typo would render nothing.
const POSE_KEYS = [
  'reach', 'sidebend', 'necktilt', 'cross', 'wallchest', 'fold', 'quad', 'calf', 'wrist',
  'chairtwist', 'chairfig4', 'seatedfold', 'butterfly', 'seatedtwist', 'strap', 'kneehug',
  'fig4', 'supinetwist', 'child', 'catcow', 'lunge', 'cobra', 'downdog', 'pigeon', 'thread',
  'roller', 'bandpull', 'bridge', 'halfsplit', 'torsotwist',
  'overheadtriceps', 'chestclasp', 'neckforward', 'chintuck', 'standhamstring', 'soleus',
  'standfig4', 'walllat', 'highlunge', 'pyramid', 'legswing', 'hugstretch', 'wristext',
  'squat', 'seatedsingle', 'chairfold', 'chaircatcow', 'sphinx', 'happybaby', 'puppy',
  'pronequad', 'camel', 'rockback', 'supinereach', 'tabletop',
];

// Must match ExploreDemoData.areas in lib/features/explore/models/explore_data.dart.
const AREAS = [
  'neck', 'shoulders', 'chest', 'upperback', 'lowerback', 'spine',
  'hips', 'glutes', 'hamstrings', 'quads', 'calves', 'wrists',
];

const isWholeNumber = { validator: Number.isInteger, message: '{PATH} must be a whole number' };

const stretchSchema = new mongoose.Schema(
  {
    poseKey: { type: String, required: true, unique: true, trim: true, enum: POSE_KEYS },
    name: { type: String, required: true, trim: true },
    position: { type: String, enum: ['standing', 'seated', 'floor'], required: true },
    areas: {
      type: [{ type: String, enum: AREAS }],
      validate: { validator: (v) => v.length > 0, message: 'At least one area is required' },
    },
    level: { type: String, enum: ['beginner', 'intermediate', 'advanced'], default: 'beginner' },
    equipment: { type: [String], default: [] },
    isEachSide: { type: Boolean, default: false },
    isDynamic: { type: Boolean, default: false },
    isKneeling: { type: Boolean, default: false },

    // Per side. Limits mirror the routine builder's stepper (10-90s, 1-5 reps).
    defaultHoldSeconds: { type: Number, default: 30, min: 10, max: 90, validate: isWholeNumber },
    defaultRepCount: { type: Number, default: 1, min: 1, max: 5, validate: isWholeNumber },
    // Derived, never trusted from the client — see the pre('validate') hook below.
    totalHoldSeconds: { type: Number, default: 30 },

    setupCue: { type: String, default: '' },
    feelCue: { type: String, default: null },
    feel: { type: String, required: true },
    steps: { type: [String], default: [] },
    commonMistake: { type: String, default: '' },
    easier: { type: String, default: '' },
    harder: { type: String, default: '' },
    cautions: { type: String, default: '' },
    thumbnailUrl: { type: String, default: '' },
    videoUrl: { type: String, default: '' },

    isActive: { type: Boolean, default: true },
  },
  { timestamps: true },
);

stretchSchema.index({ areas: 1 });

// Keeps the stored total in step with hold/reps/sides so lists can show the
// right time without recomputing it in every client.
stretchSchema.pre('validate', function () {
  this.totalHoldSeconds =
    this.defaultHoldSeconds * this.defaultRepCount * (this.isEachSide ? 2 : 1);
});

module.exports = mongoose.model('Stretch', stretchSchema);
module.exports.POSE_KEYS = POSE_KEYS;
module.exports.AREAS = AREAS;
