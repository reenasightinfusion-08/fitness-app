import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/welcome/widgets/welcome_hero.dart';

/// First screen after the splash: a full-width photo, the
/// pitch with a few highlights, and the two ways in pinned to the bottom —
/// "Get started" (sign up) and "I already have an account" (log in).
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final flow = ref.read(appFlowProvider.notifier);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: colors.ground,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isShort = constraints.maxHeight < 700;
            return CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WelcomeHero(
                        height:
                            (constraints.maxHeight * (isShort ? 0.38 : 0.44))
                                .clamp(200.0, 420.0),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(22.w, 36.h, 22.w, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: AppTextStyle.headlineLarge.copyWith(
                                  color: colors.ink,
                                ),
                                children: [
                                  const TextSpan(text: 'Stretching that fits '),
                                  TextSpan(
                                    text: 'your',
                                    style: TextStyle(color: colors.accent),
                                  ),
                                  const TextSpan(text: ' body.'),
                                ],
                              ),
                            ),
                            10.verticalSpace,
                            Text(
                              'Routines built around your tight spots, your '
                              'injuries and the equipment you actually have. A '
                              'voice talks you through every hold, so you never '
                              'need to look at your phone.',
                              style: AppTextStyle.bodyMedium.copyWith(
                                color: colors.ink2,
                              ),
                            ),
                            if (!isShort) ...[
                              16.verticalSpace,
                              const Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  AppTag(
                                    label: 'Voice-guided',
                                    tone: AppTone.accent,
                                    icon: Icons.record_voice_over_rounded,
                                  ),
                                  AppTag(
                                    label: 'Built for your body',
                                    tone: AppTone.accent,
                                    icon: Icons.favorite_border_rounded,
                                  ),
                                  AppTag(
                                    label: 'Any equipment',
                                    tone: AppTone.accent,
                                    icon: Icons.fitness_center_rounded,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          22.w,
                          24.h,
                          22.w,
                          bottomInset + 16.h,
                        ),
                        child: Column(
                          children: [
                            AppButton(
                              label: 'Get started',
                              onPressed: flow.showSignup,
                            ),
                            6.verticalSpace,
                            AppButton(
                              label: 'I already have an account',
                              variant: AppButtonVariant.text,
                              onPressed: flow.showLogin,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
