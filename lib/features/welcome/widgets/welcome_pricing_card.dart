import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';

/// Mirrors the prototype's `.pricing` card on the welcome screen: a free
/// tier row and a premium row, each led by an [AppTag].
class WelcomePricingCard extends StatelessWidget {
  const WelcomePricingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PricingRow(
            tag: AppTag(label: 'Free forever', tone: AppTone.accent),
            description:
                '9 routines, a daily plan made for you, voice cues and '
                'your own routine builder. No daily limits.',
          ),
          12.verticalSpace,
          const _PricingRow(
            tag: AppTag(label: 'Premium'),
            description:
                "₹999 once or ₹149/month for 3 advanced programs. We'll "
                "only mention it after you've tried the app.",
          ),
        ],
      ),
    );
  }
}

class _PricingRow extends StatelessWidget {
  const _PricingRow({required this.tag, required this.description});

  final Widget tag;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tag,
        10.horizontalSpace,
        Expanded(
          child: Text(
            description,
            style: AppTextStyle.bodySmall.copyWith(color: colors.ink),
          ),
        ),
      ],
    );
  }
}
