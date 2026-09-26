import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/welcome/widgets/welcome_hero.dart';
import 'package:fitness_app/features/welcome/widgets/welcome_pricing_card.dart';

/// Matches the prototype's `screens.welcome` view. "Get started", "I
/// already have an account" and "Explore with a sample account" all route
/// into the app for now, since sign-up and login screens aren't built yet.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final flow = ref.read(appFlowProvider.notifier);

    return Scaffold(
      backgroundColor: colors.ground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppInsets.page,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppBrandLogo(),
              20.verticalSpace,
              const WelcomeHero(),
              20.verticalSpace,
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
              8.verticalSpace,
              Text(
                'Routines built around your tight spots, your injuries and '
                'the equipment you actually have. A voice talks you '
                "through every hold, so you never need to look at your "
                'phone.',
                style: AppTextStyle.bodyMedium.copyWith(color: colors.ink2),
              ),
              20.verticalSpace,
              const WelcomePricingCard(),
              20.verticalSpace,
              AppButton(label: 'Get started', onPressed: flow.showSignup),
              10.verticalSpace,
              AppButton(
                label: 'I already have an account',
                variant: AppButtonVariant.secondary,
                onPressed: flow.showLogin,
              ),
              10.verticalSpace,
              AppButton(
                label: 'Explore with a sample account',
                variant: AppButtonVariant.text,
                onPressed: flow.enterApp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
