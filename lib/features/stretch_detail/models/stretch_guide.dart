import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/home/models/today_plan.dart';

/// Everything the prototype's stretch-info sheet (`stretchSheet()`) shows
/// beyond what [StretchPreview]/[ExploreStretch] already carry: how it
/// should feel, the steps to get into it, a common mistake, easier/harder
/// variations and when to be careful. Ported 1:1 from the prototype's
/// `STRETCHES` table.
class StretchGuide {
  const StretchGuide({
    required this.position,
    this.isEachSide = false,
    this.isDynamic = false,
    this.isKneeling = false,
    this.level = RoutineLevel.beginner,
    this.equipment = const [],
    required this.feel,
    required this.steps,
    required this.commonMistake,
    required this.easier,
    required this.harder,
    required this.cautions,
  });

  final StretchPosition position;
  final bool isEachSide;
  final bool isDynamic;
  final bool isKneeling;
  final RoutineLevel level;
  final List<String> equipment;

  /// Where the hold should be felt, e.g. "Along your sides, from hips to
  /// fingertips."
  final String feel;
  final List<String> steps;
  final String commonMistake;
  final String easier;
  final String harder;

  /// When to skip or modify the stretch, e.g. "Recent shoulder injury:
  /// keep arms below shoulder height."
  final String cautions;
}

/// Looks a [StretchGuide] up by [StretchPose] identity. Every stretch in
/// the app — today's plan, a routine's stretch list, the explore library —
/// references one of the canonical [StretchPoses] constants, so this never
/// needs a separate id or name key.
class StretchLibrary {
  const StretchLibrary._();

  static StretchGuide? guideFor(StretchPose pose) => _guides[pose];

  static final Map<StretchPose, StretchGuide> _guides = {
    StretchPoses.reach: const StretchGuide(
      position: StretchPosition.standing,
      feel: 'Along your sides, from hips to fingertips.',
      steps: [
        'Stand tall, feet hip-width apart.',
        'Interlace your fingers and press your palms up to the ceiling.',
        'Lengthen through your sides and breathe slowly.',
      ],
      commonMistake: 'Arching the lower back. Keep your ribs gently tucked.',
      easier: 'Reach one arm at a time.',
      harder: 'Rise onto your toes as you reach.',
      cautions: 'Recent shoulder injury: keep arms below shoulder height.',
    ),
    StretchPoses.sidebend: const StretchGuide(
      position: StretchPosition.standing,
      isEachSide: true,
      feel: 'Down the side of your waist and ribs.',
      steps: [
        'Stand tall and raise one arm overhead.',
        'Lean gently to the opposite side, hips square.',
        'Breathe into the stretched side.',
      ],
      commonMistake: 'Leaning forward or twisting instead of bending sideways.',
      easier: 'Keep the raised hand on your head.',
      harder: 'Hold a strap between both hands overhead.',
      cautions: 'Sharp back pain: make the bend smaller.',
    ),
    StretchPoses.necktilt: const StretchGuide(
      position: StretchPosition.standing,
      isEachSide: true,
      feel: 'Side of the neck, toward the top of the shoulder.',
      steps: [
        'Stand or sit tall with shoulders relaxed.',
        'Tilt your ear toward your shoulder.',
        'Rest the same-side hand lightly on your head. No pulling.',
      ],
      commonMistake: 'Lifting the opposite shoulder, or pulling hard with the hand.',
      easier: 'Skip the hand and just tilt.',
      harder: 'Reach the opposite hand toward the floor.',
      cautions: 'Numbness or tingling in the arm: stop.',
    ),
    StretchPoses.cross: const StretchGuide(
      position: StretchPosition.standing,
      isEachSide: true,
      feel: 'Back of the shoulder.',
      steps: [
        'Bring one arm straight across your chest.',
        'Hook the other forearm just above the elbow.',
        'Draw the arm closer and keep the shoulder down.',
      ],
      commonMistake: 'Pressing on the elbow joint itself.',
      easier: 'Bend the stretching arm.',
      harder: 'Gently turn your head away from the arm.',
      cautions: 'Shoulder impingement: stay below the pinch.',
    ),
    StretchPoses.wallchest: const StretchGuide(
      position: StretchPosition.standing,
      isEachSide: true,
      equipment: ['Wall'],
      feel: 'Across the front of the chest and shoulder.',
      steps: [
        'Stand side-on to a wall.',
        'Place your palm on the wall at shoulder height, arm straight.',
        'Slowly turn your chest away from the wall.',
      ],
      commonMistake: 'Placing the hand too high, which pinches the shoulder.',
      easier: 'Bend the elbow to 90°.',
      harder: 'Slide the hand slightly higher.',
      cautions: 'History of dislocation: keep the hand low.',
    ),
    StretchPoses.fold: const StretchGuide(
      position: StretchPosition.standing,
      feel: 'Backs of your legs and lower back.',
      steps: [
        'Stand with feet hip-width apart, knees soft.',
        'Hinge at the hips and let your upper body hang.',
        'Let your head and arms be heavy.',
      ],
      commonMistake: 'Locking the knees and bouncing.',
      easier: 'Rest your hands on a chair or your thighs.',
      harder: 'Straighten your legs and hold opposite elbows.',
      cautions: 'Dizziness or high blood pressure: roll up slowly.',
    ),
    StretchPoses.quad: const StretchGuide(
      position: StretchPosition.standing,
      isEachSide: true,
      feel: 'Front of the thigh.',
      steps: [
        'Hold a wall or chair for balance.',
        'Bend one knee and hold the ankle behind you.',
        'Keep the knees together and tuck your tailbone.',
      ],
      commonMistake: 'Letting the knee drift out, or arching the back.',
      easier: 'Loop a strap or towel around the foot.',
      harder: 'Press the foot back into your hand.',
      cautions: 'Knee pain: use a strap and keep the bend partial.',
    ),
    StretchPoses.calf: const StretchGuide(
      position: StretchPosition.standing,
      isEachSide: true,
      equipment: ['Wall'],
      feel: 'Back of the lower leg.',
      steps: [
        'Place both hands on a wall.',
        'Step one foot back, heel down.',
        'Bend the front knee and lean in.',
      ],
      commonMistake: 'Letting the back heel lift.',
      easier: 'Shorten your stance.',
      harder: 'Bend the back knee slightly for the deeper calf.',
      cautions: 'Achilles injury: go gently.',
    ),
    StretchPoses.wrist: const StretchGuide(
      position: StretchPosition.standing,
      isEachSide: true,
      feel: 'Inside of the forearm.',
      steps: [
        'Extend one arm forward, palm up.',
        'With the other hand, draw the fingers gently down.',
        'Keep the elbow straight but not locked.',
      ],
      commonMistake: 'Yanking the fingers back.',
      easier: 'Bend the elbow slightly.',
      harder: 'Turn the palm to face forward.',
      cautions: 'Carpal tunnel: stop if tingling increases.',
    ),
    StretchPoses.chairtwist: const StretchGuide(
      position: StretchPosition.seated,
      isEachSide: true,
      equipment: ['Chair'],
      feel: 'Along the spine and the side of the ribs.',
      steps: [
        'Sit tall near the front of a chair.',
        'Turn your chest to one side and hold the backrest.',
        'Grow taller on each inhale, twist a little on each exhale.',
      ],
      commonMistake: 'Twisting from the neck only.',
      easier: 'Keep both hands on your thighs.',
      harder: 'Place the opposite elbow outside your knee.',
      cautions: 'Disc problems: keep the twist small.',
    ),
    StretchPoses.chairfig4: const StretchGuide(
      position: StretchPosition.seated,
      isEachSide: true,
      equipment: ['Chair'],
      feel: 'Outer hip and buttock.',
      steps: [
        'Sit tall and cross one ankle over the opposite knee.',
        'Keep the raised foot flexed.',
        'Hinge forward from the hips with a long back.',
      ],
      commonMistake: 'Rounding the back to go deeper.',
      easier: 'Rest the ankle on your shin instead.',
      harder: 'Press the raised knee gently down.',
      cautions: 'Knee pain: move the ankle lower on the leg.',
    ),
    StretchPoses.seatedfold: const StretchGuide(
      position: StretchPosition.seated,
      level: RoutineLevel.intermediate,
      feel: 'Backs of the legs.',
      steps: [
        'Sit with legs straight out in front.',
        'Hinge forward from the hips, reaching toward your feet.',
        'Keep the chest open rather than rounding down.',
      ],
      commonMistake: 'Collapsing the chest toward the knees.',
      easier: 'Bend your knees or sit on a folded towel.',
      harder: 'Loop a strap around your feet and walk your hands down.',
      cautions: 'Sciatica: bend the knees.',
    ),
    StretchPoses.butterfly: const StretchGuide(
      position: StretchPosition.seated,
      feel: 'Inner thighs and groin.',
      steps: [
        'Sit with the soles of your feet together.',
        'Let your knees fall out to the sides.',
        'Sit tall and hold your ankles.',
      ],
      commonMistake: 'Pushing the knees down with your hands.',
      easier: 'Move your feet further away from you.',
      harder: 'Hinge forward with a long spine.',
      cautions: 'Groin strain: keep your feet far away.',
    ),
    StretchPoses.seatedtwist: const StretchGuide(
      position: StretchPosition.seated,
      isEachSide: true,
      feel: 'Along the spine and outer hip.',
      steps: [
        'Sit cross-legged or with legs out.',
        'Place one hand behind you and the other on the opposite knee.',
        'Lengthen, then turn gently.',
      ],
      commonMistake: 'Leaning back onto the rear hand.',
      easier: 'Sit on a cushion.',
      harder: 'Cross one foot over the straight leg.',
      cautions: 'Pregnancy: twist away from the belly, gently.',
    ),
    StretchPoses.strap: const StretchGuide(
      position: StretchPosition.floor,
      isEachSide: true,
      equipment: ['Strap or towel'],
      feel: 'Back of the raised leg.',
      steps: [
        'Lie on your back and loop a strap around one foot.',
        'Raise the leg, keeping the other leg long.',
        'Hold the strap with both hands, shoulders relaxed.',
      ],
      commonMistake: 'Lifting the hips off the floor.',
      easier: 'Bend the lower knee, foot flat.',
      harder: 'Straighten the raised leg fully.',
      cautions: 'Later pregnancy: do it seated instead.',
    ),
    StretchPoses.kneehug: const StretchGuide(
      position: StretchPosition.floor,
      isEachSide: true,
      feel: 'Lower back and buttock.',
      steps: [
        'Lie on your back.',
        'Draw one knee toward your chest with both hands.',
        'Keep the other leg long or bent.',
      ],
      commonMistake: 'Lifting the head off the floor.',
      easier: 'Hold behind the thigh instead of the shin.',
      harder: 'Hug both knees at once.',
      cautions: 'Knee pain: hold behind the thigh.',
    ),
    StretchPoses.fig4: const StretchGuide(
      position: StretchPosition.floor,
      isEachSide: true,
      feel: 'Outer hip.',
      steps: [
        'Lie on your back, knees bent.',
        'Cross one ankle over the opposite knee.',
        'Draw the lower leg toward you.',
      ],
      commonMistake: 'Letting the head and shoulders lift.',
      easier: 'Keep the lower foot on the floor.',
      harder: 'Pull the lower thigh closer.',
      cautions: 'Hip replacement: check with your surgeon first.',
    ),
    StretchPoses.supinetwist: const StretchGuide(
      position: StretchPosition.floor,
      isEachSide: true,
      feel: 'Lower back and across the chest.',
      steps: [
        'Lie on your back and hug one knee in.',
        'Let it fall across your body.',
        'Open the arms wide and look the other way if comfortable.',
      ],
      commonMistake: 'Forcing the knee down to the floor.',
      easier: 'Put a cushion under the knee.',
      harder: 'Straighten the top leg.',
      cautions: 'Disc problems: keep the range small.',
    ),
    StretchPoses.child: const StretchGuide(
      position: StretchPosition.floor,
      isKneeling: true,
      feel: 'Lower back, hips and shoulders.',
      steps: [
        'Kneel and sit back toward your heels.',
        'Walk your hands forward and rest your forehead down.',
        'Breathe into your back.',
      ],
      commonMistake: 'Forcing the hips down to the heels.',
      easier: 'Place a cushion between calves and thighs.',
      harder: 'Walk the hands to one side for a side stretch.',
      cautions: 'Knee problems: try knee-to-chest instead.',
    ),
    StretchPoses.catcow: const StretchGuide(
      position: StretchPosition.floor,
      isKneeling: true,
      isDynamic: true,
      feel: 'Movement through the whole spine.',
      steps: [
        'Come to hands and knees.',
        'Inhale: drop the belly, lift the chest and gaze.',
        'Exhale: round the back, tuck chin and tailbone. Keep flowing.',
      ],
      commonMistake: 'Moving only from the neck.',
      easier: 'Do it seated on a chair.',
      harder: 'Slow each phase to a 5-count.',
      cautions: 'Wrist pain: rest on your fists or forearms.',
    ),
    StretchPoses.lunge: const StretchGuide(
      position: StretchPosition.floor,
      isEachSide: true,
      isKneeling: true,
      level: RoutineLevel.intermediate,
      feel: 'Front of the back hip.',
      steps: [
        'Kneel and step one foot forward.',
        'Shift your hips forward until you feel the front of the back hip.',
        'Lift the chest; arms up if comfortable.',
      ],
      commonMistake: 'Front knee drifting past the toes.',
      easier: 'Keep your hands on the front thigh.',
      harder: 'Reach back and hold the back foot.',
      cautions: 'Kneeling pain: pad the knee with a folded mat.',
    ),
    StretchPoses.cobra: const StretchGuide(
      position: StretchPosition.floor,
      level: RoutineLevel.intermediate,
      feel: 'Front of the body and along the lower back.',
      steps: [
        'Lie on your front, hands under your shoulders.',
        'Press gently to lift the chest.',
        'Keep elbows bent and shoulders away from your ears.',
      ],
      commonMistake: 'Pushing too high and pinching the lower back.',
      easier: 'Stay on your forearms (sphinx).',
      harder: 'Straighten the arms a little more.',
      cautions: 'Back pain when bending backward: skip this one.',
    ),
    StretchPoses.downdog: const StretchGuide(
      position: StretchPosition.floor,
      level: RoutineLevel.intermediate,
      feel: 'Backs of the legs and the shoulders.',
      steps: [
        'From hands and knees, lift your hips up and back.',
        'Press the floor away and lengthen your spine.',
        'Pedal the heels toward the floor.',
      ],
      commonMistake: 'Rounding the back to get the heels down.',
      easier: 'Keep the knees generously bent.',
      harder: 'Lift one leg at a time.',
      cautions: 'High blood pressure: keep it short.',
    ),
    StretchPoses.pigeon: const StretchGuide(
      position: StretchPosition.floor,
      isEachSide: true,
      level: RoutineLevel.advanced,
      feel: 'Deep in the outer hip of the front leg.',
      steps: [
        'From hands and knees, bring one knee forward behind the wrist.',
        'Slide the other leg straight back.',
        'Square the hips and lower down if comfortable.',
      ],
      commonMistake: 'Collapsing onto one hip.',
      easier: 'Place a cushion under the front hip.',
      harder: 'Fold forward onto your forearms.',
      cautions: 'Knee pain: use lying figure-4 instead.',
    ),
    StretchPoses.thread: const StretchGuide(
      position: StretchPosition.floor,
      isEachSide: true,
      isKneeling: true,
      feel: 'Between the shoulder blades.',
      steps: [
        'Start on hands and knees.',
        'Slide one arm under your body, palm up.',
        'Rest your shoulder and temple down.',
      ],
      commonMistake: 'Letting the hips shift sideways.',
      easier: 'Go only partway down.',
      harder: 'Reach the top arm overhead.',
      cautions: 'Neck discomfort: rest your head on a cushion.',
    ),
    StretchPoses.roller: const StretchGuide(
      position: StretchPosition.floor,
      equipment: ['Foam roller'],
      feel: 'Across the chest and upper back.',
      steps: [
        'Lie back with the roller under your upper back, across the spine.',
        'Support your head with your hands, or open your arms overhead.',
        'Breathe and let the upper back soften.',
      ],
      commonMistake: 'Arching the lower back.',
      easier: 'Keep your hands behind your head.',
      harder: 'Reach your arms overhead to the floor.',
      cautions: 'Osteoporosis: skip this one.',
    ),
    StretchPoses.bandpull: const StretchGuide(
      position: StretchPosition.standing,
      equipment: ['Resistance band'],
      isDynamic: true,
      feel: 'Front of the shoulders and chest.',
      steps: [
        'Hold a band in front of you, hands wide.',
        'Open your arms out to the sides, squeezing the shoulder blades.',
        'Return slowly and repeat.',
      ],
      commonMistake: 'Shrugging the shoulders up.',
      easier: 'Use a lighter band or a wider grip.',
      harder: 'Pause 3 seconds at full opening.',
      cautions: 'Shoulder pain: keep arms below shoulder height.',
    ),
    StretchPoses.bridge: const StretchGuide(
      position: StretchPosition.floor,
      equipment: ['Yoga block'],
      feel: 'Front of the hips.',
      steps: [
        'Lie on your back, knees bent, feet flat.',
        'Lift your hips and slide a block under your sacrum.',
        'Rest your weight on the block and relax.',
      ],
      commonMistake: 'Placing the block under the lower back instead of the sacrum.',
      easier: 'Use the block on its lowest side.',
      harder: 'Straighten one leg along the floor.',
      cautions: 'Neck issues: keep your head still.',
    ),
    StretchPoses.halfsplit: const StretchGuide(
      position: StretchPosition.floor,
      isEachSide: true,
      isKneeling: true,
      level: RoutineLevel.advanced,
      feel: 'Back of the straight front leg.',
      steps: [
        'From a low lunge, shift your hips back over the back knee.',
        'Straighten the front leg, toes up.',
        'Hinge forward with a long spine.',
      ],
      commonMistake: 'Rounding the back to reach the toes.',
      easier: 'Use blocks under your hands.',
      harder: 'Fold your chest toward your thigh.',
      cautions: 'Hamstring strain: stay upright.',
    ),
    StretchPoses.torsotwist: const StretchGuide(
      position: StretchPosition.standing,
      isDynamic: true,
      feel: 'Warmth through the middle and upper back.',
      steps: [
        'Stand with feet wider than hips, knees soft.',
        'Let your arms swing loosely as you turn side to side.',
        'Let the heels pivot naturally.',
      ],
      commonMistake: 'Swinging too fast.',
      easier: 'Keep the movement small.',
      harder: 'Reach your arms longer as you turn.',
      cautions: 'Balance issues: stand near a wall.',
    ),
  };
}
