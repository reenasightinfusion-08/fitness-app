import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/profile/providers/premium_provider.dart';

class _FeatureRow {
  const _FeatureRow(this.label, this.inFree, this.inPremium);

  final String label;
  final bool inFree;
  final bool inPremium;
}

const List<_FeatureRow> _featureRows = [
  _FeatureRow('Daily plan made for your body', true, true),
  _FeatureRow('9 guided routines', true, true),
  _FeatureRow('Voice cues, beeps or silent', true, true),
  _FeatureRow('Custom routines and your own stretches', true, true),
  _FeatureRow('Streaks, history and body map', true, true),
  _FeatureRow('Posture reset, Splits prep, Deep full-body', false, true),
  _FeatureRow('Offline downloads of every routine', false, true),
];

/// Matches the prototype's `screens.premium`. With [isSoftPaywall], this
/// is the screen shown after finishing 3 sessions — no back button, and
/// a "Maybe later" exit back to the tabbed home instead of a pop.
class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key, this.isSoftPaywall = false});

  final bool isSoftPaywall;

  void _buy(BuildContext context, WidgetRef ref, String plan) {
    ref.read(premiumProvider.notifier).setPremium(true);
    AppSnackBar.showSuccess(
      context,
      'Prototype: no payment was taken. You have Premium.',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isPremium = ref.watch(premiumProvider);

    return Scaffold(
      backgroundColor: colors.ground,
      appBar: AppTopBar(
        title: 'Premium',
        onBack: isSoftPaywall ? null : () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppInsets.page,
                children: [
                  if (isSoftPaywall) ...[
                    AppNote(
                      message:
                          "You've finished 3 sessions. Nice work! Here's "
                          "what Premium adds. No pressure: everything "
                          "you've used so far stays free.",
                    ),
                    16.verticalSpace,
                  ],
                  Text('Go deeper, Pay once.', style: AppTextStyle.headline),
                  6.verticalSpace,
                  Text(
                    'No trial that quietly turns into a charge. No '
                    'countdowns.',
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: colors.ink2,
                    ),
                  ),
                  16.verticalSpace,
                  AppCard(
                    variant: AppCardVariant.list,
                    child: Column(
                      children: [
                        for (final row in _featureRows)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    row.label,
                                    style: AppTextStyle.bodyMedium,
                                  ),
                                ),
                                SizedBox(
                                  width: 60.w,
                                  child: row.inFree
                                      ? Center(
                                        child: const AppTag(
                                            label: 'Free',
                                            tone: AppTone.accent,
                                          ),
                                      )
                                      : const SizedBox.shrink(),
                                ),
                                SizedBox(
                                  width: 76.w,
                                  child: row.inPremium
                                      ? Center(
                                        child: const AppTag(
                                            label: 'Premium',
                                            tone: AppTone.accent,
                                          ),
                                      )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  20.verticalSpace,
                  if (isPremium)
                    const AppNote(
                      title: 'You have Premium.',
                      message: 'Thank you for supporting Loosen.',
                    )
                  else ...[
                    AppButton(
                      label: '₹999 once, yours forever',
                      onPressed: () => _buy(context, ref, 'life'),
                    ),
                    8.verticalSpace,
                    AppButton(
                      label: '₹149 / month · cancel anytime in the app',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => _buy(context, ref, 'month'),
                    ),
                    10.verticalSpace,
                    Text(
                      'Prototype: no payment is taken. Monthly plans get a '
                      'reminder 3 days before each renewal.',
                      textAlign: TextAlign.center,
                      style: AppTextStyle.meta.copyWith(color: colors.ink2),
                    ),
                    8.verticalSpace,
                    AppButton(
                      label: 'Restore purchase',
                      variant: AppButtonVariant.text,
                      onPressed: () => AppSnackBar.show(
                        context,
                        'No previous purchase found.',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSoftPaywall)
              AppBottomActionBar(
                children: [
                  AppButton(
                    label: 'Maybe later',
                    variant: AppButtonVariant.secondary,
                    onPressed: () =>
                        ref.read(appFlowProvider.notifier).enterApp(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
