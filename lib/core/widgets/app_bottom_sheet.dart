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
    final padding = EdgeInsets.fromLTRB(
      18.w,
      8.h,
      18.w,
      22.h + MediaQuery.viewInsetsOf(context).bottom,
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Center(
            child: Container(
              width: 42.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: context.colors.line,
                borderRadius: AppBorderRadius.pill,
              ),
            ),
          ),
        ),
        14.verticalSpace,
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
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(title, style: AppTextStyle.titleLarge),
      8.verticalSpace,
      Text(
        message,
        style: AppTextStyle.bodyMedium.copyWith(color: context.colors.ink2),
      ),
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
  );
}
