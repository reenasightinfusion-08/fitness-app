import 'package:flutter/painting.dart';

class OnboardingPageModel {
  const OnboardingPageModel({
    required this.step,
    required this.titleLead,
    required this.titleAccent,
    required this.body,
    required this.imagePath,
    required this.imageLabel,
    this.imageAlignment = Alignment.bottomCenter,
    this.isImageFirst = false,
    this.note,
  });

  final int step;
  final String titleLead;
  final String titleAccent;
  final String body;
  final String imagePath;
  final String imageLabel;
  final Alignment imageAlignment;

  /// Image above the copy (step 1) instead of below it.
  final bool isImageFirst;

  /// Optional hand-written line drawn over the image.
  final String? note;

  String get stepLabel => 'STEP ${step.toString().padLeft(2, '0')}';

  static const List<OnboardingPageModel> pages = [
    OnboardingPageModel(
      step: 1,
      titleLead: 'Stretching that',
      titleAccent: 'fits your body',
      body:
          'Routines built around your tight spots, your injuries and the gear you have at home.',
      imagePath: 'assets/images/onboarding/onboarding_1.webp',
      imageLabel: 'Woman stretching her neck, eyes closed and smiling',
      imageAlignment: Alignment.center,
      isImageFirst: true,
      note: 'Feel\nlighter',
    ),
    OnboardingPageModel(
      step: 2,
      titleLead: 'Small steps,',
      titleAccent: 'real change',
      body:
          'Log every session and watch your flexibility grow, week after week.',
      imagePath: 'assets/images/onboarding/onboarding_2.webp',
      imageLabel:
          'Progress checklist on a phone beside a yoga mat and water bottle',
    ),
    OnboardingPageModel(
      step: 3,
      titleLead: 'Just breathe.',
      titleAccent: 'We’ll keep time.',
      body:
          'A calm voice cues every hold and side switch, so you never need to look at your phone.',
      imagePath: 'assets/images/onboarding/onboarding_3.webp',
      imageLabel: 'Man breathing deeply with his eyes closed',
    ),
  ];
}
