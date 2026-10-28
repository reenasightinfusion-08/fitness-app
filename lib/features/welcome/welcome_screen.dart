import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fitness_app/core/providers/providers.dart';
import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/widgets.dart';

/// Elevated Welcome screen: striking hero imagery, clear brand identity,
/// tactile benefit highlights, and effortless entry into the app.
///
/// Responsive: adapts dynamically for both phones (fluid single-column)
/// and tablets (rich editorial split or framed layout).
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final flow = ref.read(appFlowProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            isDark ? Brightness.dark : Brightness.light,
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

            // Mobile layout
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

  // ===========================================================================
  // MOBILE LAYOUT
  // ===========================================================================
  Widget _buildMobileLayout({
    required BuildContext context,
    required AppColors colors,
    required AppFlowController flow,
    required BoxConstraints constraints,
    required double bottomInset,
  }) {
    final isShort = constraints.maxHeight < 700;
    final heroHeight = (constraints.maxHeight * (isShort ? 0.30 : 0.36))
        .clamp(180.0, 310.0);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12.0),
                  // Clean Brand Header
                  const AppBrandLogo(isLarge: false),
                  const SizedBox(height: 14.0),

                  // Hero Visual Card
                  Container(
                    height: heroHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.0),
                      boxShadow: [
                        BoxShadow(
                          color: colors.shadow.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24.0),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/welcome_hero.jpg',
                            fit: BoxFit.cover,
                            alignment: const Alignment(0, -0.2),
                          ),
                          // Subtle gradient for depth
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.1),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.45),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                          // Floating frosted micro-badge on image
                          Positioned(
                            left: 14.0,
                            bottom: 14.0,
                            child: _FrostedBadge(
                              icon: Icons.headphones_rounded,
                              label: 'Voice-guided holds',
                              colors: colors,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: isShort ? 14.0 : 20.0),

                  // Headline
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: isShort ? 26.0 : 31.0,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.6,
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

                  const SizedBox(height: 8.0),

                  // Subtitle
                  Text(
                    'Routines built around your tight spots, your injuries and the equipment you actually have. A voice talks you through every hold, so you never need to look at your phone.',
                    style: GoogleFonts.figtree(
                      fontSize: isShort ? 13.5 : 14.5,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: colors.ink2,
                    ),
                  ),

                  if (!isShort) ...[
                    const SizedBox(height: 14.0),
                    // Feature highlights
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        _FeaturePill(
                          label: 'Voice-guided',
                          icon: Icons.record_voice_over_rounded,
                          colors: colors,
                        ),
                        _FeaturePill(
                          label: 'Built for your body',
                          icon: Icons.favorite_border_rounded,
                          colors: colors,
                        ),
                        _FeaturePill(
                          label: 'Any equipment',
                          icon: Icons.fitness_center_rounded,
                          colors: colors,
                        ),
                      ],
                    ),
                  ],

                  const Spacer(),
                  SizedBox(height: isShort ? 10.0 : 16.0),

                  // Action Buttons
                  AppButton(
                    label: 'Get started',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: flow.showSignup,
                  ),
                  const SizedBox(height: 6.0),
                  AppButton(
                    label: 'I already have an account',
                    variant: AppButtonVariant.text,
                    onPressed: flow.showLogin,
                  ),

                  // Trust reassurance
                  const SizedBox(height: 6.0),
                  Center(
                    child: Text(
                      'Free daily plan · No credit card required',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.figtree(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w500,
                        color: colors.ink3,
                      ),
                    ),
                  ),

                  SizedBox(height: bottomInset + 12.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TABLET LANDSCAPE LAYOUT (2-COLUMN EDITORIAL)
  // ===========================================================================
  Widget _buildTabletLandscapeLayout({
    required BuildContext context,
    required AppColors colors,
    required AppFlowController flow,
    required BoxConstraints constraints,
    required double bottomInset,
  }) {
    final h = constraints.maxHeight;
    final w = constraints.maxWidth;

    final outerPad = (h * 0.04).clamp(24.0, 48.0);
    final colGap = (w * 0.04).clamp(32.0, 64.0);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(outerPad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Column: Framed Hero Card with Overlays
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32.0),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.12),
                      blurRadius: 36,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32.0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/welcome_hero.jpg',
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.2),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.25),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.55),
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Top pill badge
                      Positioned(
                        top: 24.0,
                        left: 24.0,
                        child: _FrostedBadge(
                          icon: Icons.auto_awesome_rounded,
                          label: 'StretchMind Mobility & Recovery',
                          colors: colors,
                        ),
                      ),
                      // Bottom card with social proof
                      Positioned(
                        left: 24.0,
                        right: 24.0,
                        bottom: 24.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.0),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18.0,
                                vertical: 14.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.38),
                                borderRadius: BorderRadius.circular(20.0),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7.0),
                                    decoration: BoxDecoration(
                                      color: colors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.star_rounded,
                                      size: 16.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '4.9 Rating · Loved by 50,000+ movers',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.figtree(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2.0),
                                        Text(
                                          'Personalized stretching for tight joints & muscles',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.figtree(
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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

            SizedBox(width: colGap),

            // Right Column: Editorial Typography & Actions
            Expanded(
              flex: 5,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480.0),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppBrandLogo(isLarge: false),
                          const SizedBox(height: 18.0),

                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 34.0,
                                fontWeight: FontWeight.w800,
                                height: 1.12,
                                letterSpacing: -0.8,
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
                          const SizedBox(height: 12.0),

                          Text(
                            'Routines built around your tight spots, your injuries and the equipment you actually have. A voice talks you through every hold, so you never need to look at your phone.',
                            style: GoogleFonts.figtree(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w400,
                              height: 1.55,
                              color: colors.ink2,
                            ),
                          ),

                          const SizedBox(height: 20.0),

                          // 3 Benefit Rows
                          _TabletBenefitRow(
                            icon: Icons.record_voice_over_rounded,
                            title: 'Voice-guided',
                            subtitle:
                                'Clear audio cues talk you through holds eyes-free',
                            colors: colors,
                          ),
                          const SizedBox(height: 10.0),
                          _TabletBenefitRow(
                            icon: Icons.favorite_border_rounded,
                            title: 'Built for your body',
                            subtitle:
                                'Adapts to your stiffness, injuries & pain spots',
                            colors: colors,
                          ),
                          const SizedBox(height: 10.0),
                          _TabletBenefitRow(
                            icon: Icons.fitness_center_rounded,
                            title: 'Any equipment',
                            subtitle:
                                'Strap, foam roller, or zero gear needed',
                            colors: colors,
                          ),

                          const SizedBox(height: 26.0),

                          // Primary Action
                          AppButton(
                            label: 'Get started',
                            icon: Icons.arrow_forward_rounded,
                            minHeight: 52.0,
                            onPressed: flow.showSignup,
                          ),
                          const SizedBox(height: 8.0),

                          // Secondary Action
                          AppButton(
                            label: 'I already have an account',
                            variant: AppButtonVariant.text,
                            onPressed: flow.showLogin,
                          ),

                          const SizedBox(height: 6.0),
                          Center(
                            child: Text(
                              'Free daily plan included · No credit card required',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.figtree(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w500,
                                color: colors.ink3,
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

  // ===========================================================================
  // TABLET PORTRAIT LAYOUT
  // ===========================================================================
  Widget _buildTabletPortraitLayout({
    required BuildContext context,
    required AppColors colors,
    required AppFlowController flow,
    required BoxConstraints constraints,
    required double bottomInset,
  }) {
    final h = constraints.maxHeight;
    final heroHeight = (h * 0.33).clamp(230.0, 350.0);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16.0),
                // Header
                const AppBrandLogo(isLarge: false),
                const SizedBox(height: 16.0),

                // Framed Hero Card
                Container(
                  height: heroHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28.0),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: 0.1),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28.0),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/welcome_hero.jpg',
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, -0.2),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.45),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 18.0,
                          bottom: 18.0,
                          child: _FrostedBadge(
                            icon: Icons.headphones_rounded,
                            label: 'Voice-guided holds',
                            colors: colors,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22.0),

                // Headline
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 32.0,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -0.7,
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
                const SizedBox(height: 10.0),

                // Subtitle
                Text(
                  'Routines built around your tight spots, your injuries and the equipment you actually have. A voice talks you through every hold, so you never need to look at your phone.',
                  style: GoogleFonts.figtree(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: colors.ink2,
                  ),
                ),

                const SizedBox(height: 16.0),

                // Feature Highlights Wrap
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: [
                    _FeaturePill(
                      label: 'Voice-guided',
                      icon: Icons.record_voice_over_rounded,
                      colors: colors,
                    ),
                    _FeaturePill(
                      label: 'Built for your body',
                      icon: Icons.favorite_border_rounded,
                      colors: colors,
                    ),
                    _FeaturePill(
                      label: 'Any equipment',
                      icon: Icons.fitness_center_rounded,
                      colors: colors,
                    ),
                  ],
                ),

                const Spacer(),

                // Buttons
                AppButton(
                  label: 'Get started',
                  icon: Icons.arrow_forward_rounded,
                  minHeight: 52.0,
                  onPressed: flow.showSignup,
                ),
                const SizedBox(height: 8.0),
                AppButton(
                  label: 'I already have an account',
                  variant: AppButtonVariant.text,
                  onPressed: flow.showLogin,
                ),

                const SizedBox(height: 6.0),
                Center(
                  child: Text(
                    'Free daily plan included · No credit card required',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.figtree(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w500,
                      color: colors.ink3,
                    ),
                  ),
                ),

                SizedBox(height: bottomInset + 16.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// REUSABLE MICRO-COMPONENTS FOR WELCOME SCREEN
// =============================================================================

class _FrostedBadge extends StatelessWidget {
  const _FrostedBadge({
    required this.label,
    required this.icon,
    required this.colors,
  });

  final String label;
  final IconData icon;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14.0, color: Colors.white),
              const SizedBox(width: 6.0),
              Text(
                label,
                style: GoogleFonts.figtree(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.label,
    required this.icon,
    required this.colors,
  });

  final String label;
  final IconData icon;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: colors.line.withValues(alpha: 0.85),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: colors.accentSoft.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12.0, color: colors.accent),
          ),
          const SizedBox(width: 8.0),
          Text(
            label,
            style: GoogleFonts.figtree(
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
              color: colors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabletBenefitRow extends StatelessWidget {
  const _TabletBenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: colors.line.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38.0,
            height: 38.0,
            decoration: BoxDecoration(
              color: colors.accentSoft.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(10.0),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18.0, color: colors.accent),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.figtree(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  subtitle,
                  style: GoogleFonts.figtree(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: colors.ink2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
