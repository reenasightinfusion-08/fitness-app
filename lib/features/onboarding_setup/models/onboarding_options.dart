import 'package:flutter/foundation.dart';

import 'package:fitness_app/core/widgets/widgets.dart';

/// "Woman" / "Man" / "Non-binary" / "Prefer not to say" — step 0.
const List<String> genderOptions = [
  'Woman',
  'Man',
  'Non-binary',
  'Prefer not to say',
];

@immutable
class LifestyleOption {
  const LifestyleOption(this.id, this.label, this.subtitle);

  final String id;
  final String label;
  final String subtitle;
}

/// Step 2's single-select list.
const List<LifestyleOption> lifestyleOptions = [
  LifestyleOption('desk', 'Mostly sitting', 'Desk job, long commutes'),
  LifestyleOption(
    'feet',
    'On my feet a lot',
    'Shop floor, teaching, caregiving',
  ),
  LifestyleOption('active', 'Active', 'I work out a few times a week'),
  LifestyleOption('athlete', 'Training for a sport', 'Regular hard sessions'),
];

/// Step 2's optional sports chips.
const List<String> sportsOptions = [
  'Running',
  'Gym',
  'Cycling',
  'Cricket',
  'Football',
  'Yoga',
  'Swimming',
  'Badminton',
];

@immutable
class GoalOption {
  const GoalOption(this.id, this.label);

  final String id;
  final String label;
}

/// Step 3's multi-select list, capped at two picks.
const List<GoalOption> goalOptions = [
  GoalOption('flexibility', 'Get more flexible'),
  GoalOption('pain', 'Ease pain or stiffness'),
  GoalOption('posture', 'Better posture'),
  GoalOption('recovery', 'Recover after workouts'),
  GoalOption('sleep', 'Sleep better'),
  GoalOption('splits', 'Work toward the splits'),
];
const int maxGoalPicks = 2;

/// Step 4's body-area chips, in the prototype's `PAIN_AREAS` order.
const Map<String, String> painAreaLabels = {
  'neck': 'Neck',
  'shoulders': 'Shoulders',
  'chest': 'Chest',
  'upperback': 'Upper back',
  'lowerback': 'Lower back',
  'hips': 'Hips',
  'glutes': 'Glutes',
  'hamstrings': 'Hamstrings',
  'quads': 'Quads',
  'knees': 'Knees',
  'calves': 'Calves',
  'wrists': 'Wrists',
};

@immutable
class InjuryToggle {
  const InjuryToggle(this.id, this.label);

  final String id;
  final String label;
}

/// Step 5's yes/no rows.
const List<InjuryToggle> injuryToggles = [
  InjuryToggle('noKneel', "I can't kneel comfortably"),
  InjuryToggle('noFloor', 'Getting down to the floor is hard'),
  InjuryToggle('surgery', 'I had surgery in the last 6 months'),
  InjuryToggle('pregnant', "I'm pregnant"),
];

/// Step 5's per-injury severity chips.
const Map<String, String> injuryAreaLabels = {
  'knee': 'Knee',
  'back': 'Lower back',
  'neck': 'Neck',
  'shoulder': 'Shoulder',
  'wrist': 'Wrist',
  'hip': 'Hip',
};

/// Step 6's equipment chips.
const Map<String, String> equipmentLabels = {
  'mat': 'Mat',
  'strap': 'Strap or towel',
  'block': 'Yoga block',
  'roller': 'Foam roller',
  'chair': 'Chair',
  'wall': 'Wall',
  'band': 'Resistance band',
};

@immutable
class FlexOption {
  const FlexOption(this.label, this.score);

  final String label;
  final int score;
}

@immutable
class FlexibilityQuestion {
  const FlexibilityQuestion(this.question, this.pose, this.options);

  final String question;
  final StretchPose pose;
  final List<FlexOption> options;
}

/// Step 7's three questions, ported from the prototype's `OBFLEX`.
const List<FlexibilityQuestion> flexibilityQuestions = [
  FlexibilityQuestion(
    'Stand with straight knees and fold forward. Where do your hands reach?',
    StretchPoses.fold,
    [
      FlexOption('Palms flat on the floor', 2),
      FlexOption('Fingertips to toes or shins', 1),
      FlexOption('Knees or higher', 0),
    ],
  ),
  FlexibilityQuestion(
    'Sitting cross-legged on the floor for a minute feels…',
    StretchPoses.butterfly,
    [
      FlexOption('Easy', 2),
      FlexOption('Okay, a bit tight', 1),
      FlexOption("Uncomfortable, or I can't", 0),
    ],
  ),
  FlexibilityQuestion(
    'Reach one hand over your shoulder and the other up your back. '
    'Your fingers…',
    StretchPoses.reach,
    [
      FlexOption('Touch or overlap', 2),
      FlexOption("Get within a hand's width", 1),
      FlexOption('Stay far apart', 0),
    ],
  ),
];

/// Step 8's "when do you usually have time?" chips.
const List<String> timeOfDayOptions = [
  'Morning',
  'Work break',
  'Evening',
  'Before bed',
];

/// Step 8's minutes-per-day segments.
const List<int> minutesPerDayOptions = [5, 10, 15, 20];
