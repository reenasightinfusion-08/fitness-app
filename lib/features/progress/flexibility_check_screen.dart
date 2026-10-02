import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_profile.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';
import 'package:fitness_app/features/onboarding_setup/widgets/steps/flexibility_step.dart';
import 'package:fitness_app/services/auth_service.dart';

/// Screen allowing the user to re-assess their flexibility level from Progress screen.
class FlexibilityCheckScreen extends ConsumerStatefulWidget {
  const FlexibilityCheckScreen({super.key});

  @override
  ConsumerState<FlexibilityCheckScreen> createState() =>
      FlexibilityCheckScreenState();
}

class FlexibilityCheckScreenState
    extends ConsumerState<FlexibilityCheckScreen> {
  late final List<int?> previousAnswers = ref
      .read(onboardingProfileProvider)
      .flexAnswers;
  bool isSaving = false;
  bool isSaved = false;

  /// Answers edit the shared profile live, so leaving without saving
  /// puts the earlier ones back and Progress keeps showing the old level.
  void _leave() {
    if (!isSaved) {
      final controller = ref.read(onboardingProfileProvider.notifier);
      for (var i = 0; i < previousAnswers.length; i++) {
        final score = previousAnswers[i];
        if (score != null) controller.setFlexAnswer(i, score);
      }
    }
    Navigator.of(context).pop();
  }

  Future<void> _save() async {
    if (isSaving) return;
    setState(() => isSaving = true);
    final update = ref.read(onboardingProfileProvider).toUserUpdate();
    try {
      await ref.read(authServiceProvider).updateMe({
        'flexAnswers': update['flexAnswers'],
        'flexibilityLevel': update['flexibilityLevel'],
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => isSaving = false);
      AppSnackBar.showError(context, "Couldn't save: ${e.message}");
      return;
    }
    isSaved = true;
    if (!mounted) return;
    Navigator.of(context).pop();
    AppSnackBar.showSuccess(context, 'Flexibility level updated.');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final profile = ref.watch(onboardingProfileProvider);
    final allAnswered = profile.flexAnswers.every((answer) => answer != null);
    final level = calcFlexibilityLevel(profile.flexAnswers);

    return Scaffold(
      backgroundColor: colors.ground,
      appBar: AppTopBar(
        title: 'Flexibility level',
        onBack: _leave,
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave();
        },
        child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppInsets.page,
                children: [
                  Text(
                    'Retake flexibility check',
                    style: AppTextStyle.headline,
                  ),
                  6.verticalSpace,
                  Text(
                    'Re-evaluate your range of motion as you loosen up.',
                    style: AppTextStyle.meta.copyWith(color: colors.ink2),
                  ),
                  20.verticalSpace,
                  const FlexibilityStep(),
                ],
              ),
            ),
            if (allAnswered)
              Padding(
                padding: AppInsets.page,
                child: AppButton(
                  label: 'Done · Save level (${flexibilityLevelLabels[level]})',
                  isLoading: isSaving,
                  onPressed: _save,
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }
}
