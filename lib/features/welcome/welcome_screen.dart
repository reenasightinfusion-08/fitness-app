import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/welcome/widgets/welcome_hero.dart';

/// First screen after the splash: a full-width photo, the
/// pitch with a few highlights, and the two ways in pinned to the bottom —
/// "Get started" (sign up) and "I already have an account" (log in).
///
/// Responsive: adapts with a premium 2-column layout on tablet/desktop while
/// keeping the original mobile experience 100% intact on phones.
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
            // Tablet breakpoint: width >= 600
            if (constraints.maxWidth >= 600) {
              final isLandscape =
                  constraints.maxWidth >= constraints.maxHeight;
              if (isLandscape || constraints.maxWidth >= 840) {
                return _buildTabletLandscapeLayout(
                  context: context,
                  colors: colors,
                  flow: flow,
                  constraints: constraints,
                  bottomInset: bottomInset,
                );
              } else {
                return _buildTabletPortraitLayout(
                  context: context,
                  colors: colors,
                  flow: flow,
                  constraints: constraints,
                  bottomInset: bottomInset,
                );
              }
            }

            // Mobile layout: strictly unchanged
            return _buildMobileLayout(
              context: context,
              colors: colors,
              flow: flow,
              constraints: constraints,
              bottomInset: bottomInset,
            );
          },
        ),
      ),
    );
  }

  /// Original mobile layout preserved with zero visual or functional changes.
  Widget _buildMobileLayout({
    required BuildContext context,
    required AppColors colors,
    required AppFlowController flow,
    required BoxConstraints constraints,
    required double bottomInset,
  }) {
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
  }

  /// Tablet landscape split view: 2-column layout matching the tablet mockup.
  /// Scaled proportionally to the tablet height and width so text and elements
  /// are bold, legible, and perfectly proportioned on any tablet resolution.
  Widget _buildTabletLandscapeLayout({
    required BuildContext context,
    required AppColors colors,
    required AppFlowController flow,
    required BoxConstraints constraints,
    required double bottomInset,
  }) {
    final h = constraints.maxHeight;
    final w = constraints.maxWidth;

    final outerPadding = (h * 0.038).clamp(24.0, 56.0);
    final columnGap = (w * 0.035).clamp(28.0, 80.0);
    final imageCornerRadius = (h * 0.035).clamp(24.0, 48.0);

    // Right column available width
    final colW = (w - (outerPadding * 2) - columnGap) / 2;
    final contentMaxWidth = colW * 0.85;

    // Scale fonts and elements proportionally with screen height
    final headlineSize = (h * 0.058).clamp(38.0, 96.0);
    final bodySize = (h * 0.022).clamp(15.5, 36.0);
    final buttonHeight = (h * 0.070).clamp(52.0, 110.0);
    final buttonFontSize = (h * 0.023).clamp(16.5, 38.0);
    final buttonRadius = (h * 0.024).clamp(16.0, 36.0);
    final secondaryFontSize = (h * 0.021).clamp(15.0, 34.0);

    // Tag dimensions
    final tagFontSize = (h * 0.019).clamp(13.5, 30.0);
    final tagIconSize = (h * 0.021).clamp(15.0, 34.0);
    final tagPadH = (h * 0.021).clamp(14.0, 36.0);
    final tagPadV = (h * 0.012).clamp(8.0, 20.0);
    final tagSpacing = (h * 0.016).clamp(10.0, 24.0);
    final tagIconGap = (h * 0.009).clamp(6.0, 16.0);

    // Vertical spacing
    final gapHeadToBody = (h * 0.026).clamp(16.0, 44.0);
    final gapBodyToTags = (h * 0.034).clamp(20.0, 54.0);
    final gapTagsToBtn = (h * 0.048).clamp(28.0, 72.0);
    final gapBtnToSecondary = (h * 0.018).clamp(12.0, 32.0);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(outerPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Half: Hero photo card
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(imageCornerRadius),
                child: Image.asset(
                  'assets/images/welcome_hero.jpg',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.15),
                ),
              ),
            ),
            SizedBox(width: columnGap),
            // Right Half: Content
            Expanded(
              flex: 5,
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: headlineSize,
                                fontWeight: FontWeight.w800,
                                height: 1.12,
                                letterSpacing: -0.02 * headlineSize,
                                color: colors.ink,
                              ),
                              children: [
                                const TextSpan(text: 'Stretching that fits\n'),
                                TextSpan(
                                  text: 'your',
                                  style: TextStyle(color: colors.accent),
                                ),
                                const TextSpan(text: ' body.'),
                              ],
                            ),
                          ),
                          SizedBox(height: gapHeadToBody),
                          Text(
                            'Routines built around your tight spots, your '
                            'injuries and the equipment you actually have. A '
                            'voice talks you through every hold, so you never '
                            'need to look at your phone.',
                            style: GoogleFonts.figtree(
                              fontSize: bodySize,
                              fontWeight: FontWeight.w400,
                              height: 1.55,
                              color: colors.ink2,
                            ),
                          ),
                          SizedBox(height: gapBodyToTags),
                          Wrap(
                            spacing: tagSpacing,
                            runSpacing: tagSpacing * 0.85,
                            children: [
                              _TabletTag(
                                label: 'Voice-guided',
                                icon: Icons.record_voice_over_rounded,
                                colors: colors,
                                fontSize: tagFontSize,
                                iconSize: tagIconSize,
                                paddingHorizontal: tagPadH,
                                paddingVertical: tagPadV,
                                spacing: tagIconGap,
                              ),
                              _TabletTag(
                                label: 'Built for your body',
                                icon: Icons.favorite_border_rounded,
                                colors: colors,
                                fontSize: tagFontSize,
                                iconSize: tagIconSize,
                                paddingHorizontal: tagPadH,
                                paddingVertical: tagPadV,
                                spacing: tagIconGap,
                              ),
                              _TabletTag(
                                label: 'Any equipment',
                                icon: Icons.fitness_center_rounded,
                                colors: colors,
                                fontSize: tagFontSize,
                                iconSize: tagIconSize,
                                paddingHorizontal: tagPadH,
                                paddingVertical: tagPadV,
                                spacing: tagIconGap,
                              ),
                            ],
                          ),
                          SizedBox(height: gapTagsToBtn),
                          // Primary Get Started Button
                          Material(
                            color: colors.accent,
                            borderRadius: BorderRadius.circular(buttonRadius),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: flow.showSignup,
                              child: Container(
                                height: buttonHeight,
                                width: double.infinity,
                                alignment: Alignment.center,
                                child: Text(
                                  'Get started',
                                  style: GoogleFonts.figtree(
                                    fontSize: buttonFontSize,
                                    fontWeight: FontWeight.w700,
                                    color: colors.accentInk,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: gapBtnToSecondary),
                          // Secondary Text Button
                          Center(
                            child: InkWell(
                              onTap: flow.showLogin,
                              borderRadius:
                                  BorderRadius.circular(buttonRadius * 0.6),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: tagPadH,
                                  vertical: tagPadV * 0.8,
                                ),
                                child: Text(
                                  'I already have an account',
                                  style: GoogleFonts.figtree(
                                    fontSize: secondaryFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: colors.accent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tablet portrait layout: balanced card image & centered readable content.
  Widget _buildTabletPortraitLayout({
    required BuildContext context,
    required AppColors colors,
    required AppFlowController flow,
    required BoxConstraints constraints,
    required double bottomInset,
  }) {
    final h = constraints.maxHeight;
    final w = constraints.maxWidth;

    final heroHeight = (h * 0.42).clamp(320.0, 700.0);
    final contentMaxWidth = (w * 0.85).clamp(460.0, 800.0);

    final headlineSize = (w * 0.052).clamp(34.0, 64.0);
    final bodySize = (w * 0.022).clamp(15.5, 26.0);
    final buttonHeight = (h * 0.062).clamp(52.0, 84.0);
    final buttonFontSize = (w * 0.024).clamp(16.5, 28.0);
    final buttonRadius = (w * 0.024).clamp(16.0, 28.0);
    final secondaryFontSize = (w * 0.021).clamp(15.0, 26.0);

    final tagFontSize = (w * 0.020).clamp(13.5, 24.0);
    final tagIconSize = (w * 0.022).clamp(15.0, 26.0);
    final tagPadH = (w * 0.022).clamp(14.0, 28.0);
    final tagPadV = (w * 0.012).clamp(8.0, 16.0);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: (w * 0.03).clamp(16.0, 32.0),
                    vertical: (h * 0.02).clamp(16.0, 32.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: SizedBox(
                          height: heroHeight,
                          width: double.infinity,
                          child: Image.asset(
                            'assets/images/welcome_hero.jpg',
                            fit: BoxFit.cover,
                            alignment: const Alignment(0, -0.15),
                          ),
                        ),
                      ),
                      SizedBox(height: (h * 0.03).clamp(20.0, 40.0)),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: headlineSize,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                            letterSpacing: -0.02 * headlineSize,
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
                      SizedBox(height: (h * 0.016).clamp(12.0, 24.0)),
                      Text(
                        'Routines built around your tight spots, your '
                        'injuries and the equipment you actually have. A '
                        'voice talks you through every hold, so you never '
                        'need to look at your phone.',
                        style: GoogleFonts.figtree(
                          fontSize: bodySize,
                          fontWeight: FontWeight.w400,
                          height: 1.55,
                          color: colors.ink2,
                        ),
                      ),
                      SizedBox(height: (h * 0.024).clamp(18.0, 36.0)),
                      Wrap(
                        spacing: (w * 0.018).clamp(10.0, 20.0),
                        runSpacing: (w * 0.015).clamp(8.0, 16.0),
                        children: [
                          _TabletTag(
                            label: 'Voice-guided',
                            icon: Icons.record_voice_over_rounded,
                            colors: colors,
                            fontSize: tagFontSize,
                            iconSize: tagIconSize,
                            paddingHorizontal: tagPadH,
                            paddingVertical: tagPadV,
                            spacing: 8,
                          ),
                          _TabletTag(
                            label: 'Built for your body',
                            icon: Icons.favorite_border_rounded,
                            colors: colors,
                            fontSize: tagFontSize,
                            iconSize: tagIconSize,
                            paddingHorizontal: tagPadH,
                            paddingVertical: tagPadV,
                            spacing: 8,
                          ),
                          _TabletTag(
                            label: 'Any equipment',
                            icon: Icons.fitness_center_rounded,
                            colors: colors,
                            fontSize: tagFontSize,
                            iconSize: tagIconSize,
                            paddingHorizontal: tagPadH,
                            paddingVertical: tagPadV,
                            spacing: 8,
                          ),
                        ],
                      ),
                      const Spacer(),
                      SizedBox(height: (h * 0.025).clamp(20.0, 36.0)),
                      Material(
                        color: colors.accent,
                        borderRadius: BorderRadius.circular(buttonRadius),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: flow.showSignup,
                          child: Container(
                            height: buttonHeight,
                            width: double.infinity,
                            alignment: Alignment.center,
                            child: Text(
                              'Get started',
                              style: GoogleFonts.figtree(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w700,
                                color: colors.accentInk,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: (h * 0.014).clamp(10.0, 20.0)),
                      Center(
                        child: InkWell(
                          onTap: flow.showLogin,
                          borderRadius:
                              BorderRadius.circular(buttonRadius * 0.6),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: tagPadH,
                              vertical: tagPadV * 0.8,
                            ),
                            child: Text(
                              'I already have an account',
                              style: GoogleFonts.figtree(
                                fontSize: secondaryFontSize,
                                fontWeight: FontWeight.w600,
                                color: colors.accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: bottomInset + 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tablet feature tag designed to scale proportionally with tablet viewport,
/// featuring generous padding, crisp icon, and readable figtree typography.
class _TabletTag extends StatelessWidget {
  const _TabletTag({
    required this.label,
    required this.icon,
    required this.colors,
    required this.fontSize,
    required this.iconSize,
    required this.paddingHorizontal,
    required this.paddingVertical,
    required this.spacing,
  });

  final String label;
  final IconData icon;
  final AppColors colors;
  final double fontSize;
  final double iconSize;
  final double paddingHorizontal;
  final double paddingVertical;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: paddingHorizontal,
        vertical: paddingVertical,
      ),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: colors.accent),
          SizedBox(width: spacing),
          Text(
            label,
            style: GoogleFonts.figtree(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: colors.accent,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
