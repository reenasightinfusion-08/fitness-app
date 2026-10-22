import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/app_button.dart';

class AppBottomSheet {
  const AppBottomSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    bool isScrollable = false,
  }) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    // Mobile: Preserve 100% of the exact existing bottom sheet behavior.
    if (!isTablet) {
      final colors = context.colors;
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: isScrollable,
        enableDrag: true,
        isDismissible: true,
        useSafeArea: true,
        backgroundColor: colors.surface,
        barrierColor: colors.scrim,
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.sheet),
        builder: (context) {
          if (isScrollable) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.0,
              maxChildSize: 0.95,
              expand: false,
              snap: true,
              shouldCloseOnMinExtent: true,
              builder: (context, scrollController) => AppSheetBody(
                scrollController: scrollController,
                isScrollable: true,
                child: child,
              ),
            );
          }
          return AppSheetBody(
            isScrollable: false,
            child: child,
          );
        },
      );
    }

    // Tablet: Elegant centered floating modal card with smooth cubic fade & scale.
    final colors = context.colors;
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: colors.scrim,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, animation, secondaryAnimation) =>
          AppTabletSheetContainer(
            isScrollable: isScrollable,
            child: child,
          ),
      transitionBuilder: (dialogContext, animation, secondaryAnimation, dialogChild) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: dialogChild,
          ),
        );
      },
    );
  }

  /// Returns true when the user confirms.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async =>
      await show<bool>(
        context,
        child: AppConfirmSheet(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          isDestructive: isDestructive,
        ),
      ) ??
      false;
}

/// Floating circular close button for tablet modal presentations.
class AppSheetCloseButton extends StatelessWidget {
  const AppSheetCloseButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: 'Close',
        child: InkWell(
          onTap: onPressed ?? () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.surface2.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.line.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.close_rounded,
              size: 20,
              color: colors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered floating modal container on tablets.
class AppTabletSheetContainer extends StatelessWidget {
  const AppTabletSheetContainer({
    super.key,
    required this.child,
    this.isScrollable = false,
  });

  final Widget child;
  final bool isScrollable;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final size = MediaQuery.sizeOf(context);

    // Responsive maxWidth: scrollable sheets (e.g. stretch detail, picker)
    // get a comfortable reading/viewing width, while confirm dialogs remain compact.
    final maxWidth = isScrollable
        ? (size.width * 0.72).clamp(520.0, 620.0)
        : (size.width * 0.52).clamp(380.0, 460.0);

    // Max height leaves generous breathing room above and below the card.
    final maxHeight = (size.height * 0.88).clamp(340.0, 840.0);

    return SafeArea(
      child: AnimatedPadding(
        padding: MediaQuery.viewInsetsOf(context),
        duration: const Duration(milliseconds: 100),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: maxWidth,
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: colors.line.withValues(alpha: 0.55),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 36,
                    spreadRadius: -4,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  if (isScrollable)
                    Scrollbar(
                      thumbVisibility: false,
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: child,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: child,
                    ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: const AppSheetCloseButton(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppSheetBody extends StatelessWidget {
  const AppSheetBody({
    super.key,
    required this.child,
    this.scrollController,
    this.isScrollable = false,
  });

  final Widget child;
  final ScrollController? scrollController;
  final bool isScrollable;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    final padding = EdgeInsets.fromLTRB(
      isTablet ? 24.0 : 18.w,
      isTablet ? 12.0 : 8.h,
      isTablet ? 24.0 : 18.w,
      (isTablet ? 24.0 : 22.h) + MediaQuery.viewInsetsOf(context).bottom,
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: isTablet ? 6.0 : 4.h),
          child: Center(
            child: Container(
              width: isTablet ? 44.0 : 42.w,
              height: isTablet ? 5.0 : 5.h,
              decoration: BoxDecoration(
                color: context.colors.line,
                borderRadius: AppBorderRadius.pill,
              ),
            ),
          ),
        ),
        (isTablet ? 16.0 : 14.h).verticalSpace,
        child,
      ],
    );

    if (isScrollable) {
      return SingleChildScrollView(
        controller: scrollController,
        physics: const ClampingScrollPhysics(),
        padding: padding,
        child: content,
      );
    }

    return Padding(
      padding: padding,
      child: content,
    );
  }
}

class AppConfirmSheet extends StatelessWidget {
  const AppConfirmSheet({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDestructive,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(right: isTablet ? 36.0 : 0.0),
          child: Text(title, style: AppTextStyle.titleLarge),
        ),
        8.verticalSpace,
        Text(
          message,
          style: AppTextStyle.bodyMedium.copyWith(color: context.colors.ink2),
        ),
        if (isTablet) ...[
          22.verticalSpace,
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: cancelLabel,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: AppButton(
                  label: confirmLabel,
                  variant: isDestructive
                      ? AppButtonVariant.danger
                      : AppButtonVariant.primary,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ] else ...[
          20.verticalSpace,
          AppButton(
            label: confirmLabel,
            variant: isDestructive
                ? AppButtonVariant.danger
                : AppButtonVariant.primary,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          4.verticalSpace,
          AppButton(
            label: cancelLabel,
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ],
    );
  }
}
