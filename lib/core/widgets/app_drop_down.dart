import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/app_field_label.dart';
import 'package:fitness_app/core/widgets/app_input_decoration.dart';

class AppDropDownItemModel<T> {
  const AppDropDownItemModel({required this.value, required this.label});

  final T value;
  final String label;
}

class AppDropDown<T> extends StatelessWidget {
  const AppDropDown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.validator,
  });

  final List<AppDropDownItemModel<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[AppFieldLabel(text: label!), 6.verticalSpace],
        DropdownButtonFormField<T>(
          initialValue: value,
          onChanged: onChanged,
          validator: validator,
          isExpanded: true,
          borderRadius: AppBorderRadius.lg,
          dropdownColor: colors.surface,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: colors.ink2,
            size: 22.r,
          ),
          style: AppTextStyle.bodyLarge.copyWith(color: colors.ink),
          decoration: AppInputDecoration.build(colors, hint: hint),
          items: [
            for (final item in items)
              DropdownMenuItem(value: item.value, child: Text(item.label)),
          ],
        ),
      ],
    );
  }
}
