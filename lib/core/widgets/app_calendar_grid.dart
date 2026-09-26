import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

/// Month heatmap of completed sessions. Monday-first.
class AppCalendarGrid extends StatelessWidget {
  const AppCalendarGrid({
    super.key,
    required this.leadingBlankDays,
    required this.dayCount,
    required this.completedDays,
    this.today,
  });

  /// Empty cells before day 1 (0 when the month starts on Monday).
  final int leadingBlankDays;
  final int dayCount;
  final Set<int> completedDays;

  /// Day-of-month for today, or null when showing another month.
  final int? today;

  static const List<String> weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GridView.count(
      crossAxisCount: 7,
      mainAxisSpacing: 5.r,
      crossAxisSpacing: 5.r,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final label in weekdayLabels)
          Center(
            child: Text(
              label,
              style: AppTextStyle.tab.copyWith(color: colors.ink3),
            ),
          ),
        for (var i = 0; i < leadingBlankDays; i++) const SizedBox.shrink(),
        for (var day = 1; day <= dayCount; day++)
          AppCalendarDayCell(
            day: day,
            isDone: completedDays.contains(day),
            isToday: day == today,
            isFuture: today != null && day > today!,
          ),
      ],
    );
  }
}

class AppCalendarDayCell extends StatelessWidget {
  const AppCalendarDayCell({
    super.key,
    required this.day,
    required this.isDone,
    required this.isToday,
    required this.isFuture,
  });

  final int day;
  final bool isDone;
  final bool isToday;
  final bool isFuture;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Opacity(
      opacity: isFuture ? 0.35 : 1,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDone ? colors.accent : colors.surface2,
          borderRadius: AppBorderRadius.sm,
          border: isToday ? Border.all(color: colors.warm, width: 2) : null,
        ),
        child: Text(
          '$day',
          style: AppTextStyle.caption.copyWith(
            color: isDone ? colors.accentInk : colors.ink3,
            fontWeight: FontWeight.w600,
            fontFeatures: AppTextStyle.tabular,
          ),
        ),
      ),
    );
  }
}
