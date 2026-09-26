import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';

class WeekDayModel {
  const WeekDayModel({
    required this.label,
    required this.dayOfMonth,
    this.isDone = false,
    this.isToday = false,
  });

  final String label;
  final int dayOfMonth;
  final bool isDone;
  final bool isToday;
}

class AppWeekStrip extends StatelessWidget {
  const AppWeekStrip({super.key, required this.days});

  final List<WeekDayModel> days;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final day in days) Expanded(child: AppWeekDayCell(day: day)),
    ],
  );
}

class AppWeekDayCell extends StatelessWidget {
  const AppWeekDayCell({super.key, required this.day});

  final WeekDayModel day;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label:
          '${day.label} ${day.dayOfMonth}${day.isDone ? ', stretched' : ''}${day.isToday ? ', today' : ''}',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(
            day.label,
            style: AppTextStyle.eyebrow.copyWith(color: colors.ink3),
          ),
          6.verticalSpace,
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 32.r,
            height: 32.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: day.isDone ? colors.accent : colors.surface2,
              shape: BoxShape.circle,
              border: day.isToday
                  ? Border.all(color: colors.warm, width: 2)
                  : null,
            ),
            child: Text(
              '${day.dayOfMonth}',
              style: AppTextStyle.numeric.copyWith(
                color: day.isDone ? colors.accentInk : colors.ink3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
