import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/utils/app_validators.dart';
import 'package:fitness_app/core/widgets/app_field_label.dart';
import 'package:fitness_app/core/widgets/app_input_decoration.dart';

enum AppTextFieldVariant { normal, password, search, otp }

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.validator,
    this.controller,
    this.label,
    this.isOptional = false,
    this.hint,
    this.variant = AppTextFieldVariant.normal,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.autovalidateMode = AutovalidateMode.disabled,
  });

  final AppValidator validator;
  final TextEditingController? controller;
  final String? label;
  final bool isOptional;
  final String? hint;
  final AppTextFieldVariant variant;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final int? maxLength;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Defaults to [AutovalidateMode.disabled] so an error doesn't flash up
  /// before the user has ever tried to submit. Pass
  /// [AutovalidateMode.onUserInteraction] once the surrounding form has
  /// had a failed submit attempt, so fixes are then validated live.
  final AutovalidateMode autovalidateMode;

  @override
  State<AppTextField> createState() => AppTextFieldState();
}

class AppTextFieldState extends State<AppTextField> {
  bool isObscured = true;

  bool get isPassword => widget.variant == AppTextFieldVariant.password;
  bool get isOtp => widget.variant == AppTextFieldVariant.otp;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          AppFieldLabel(text: widget.label!, isOptional: widget.isOptional),
          6.verticalSpace,
        ],
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,
          obscureText: isPassword && isObscured,
          keyboardType: isOtp ? TextInputType.number : widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          autofillHints: isOtp
              ? const [AutofillHints.oneTimeCode]
              : widget.autofillHints,
          inputFormatters: isOtp
              ? [FilteringTextInputFormatter.digitsOnly]
              : widget.inputFormatters,
          maxLines: isPassword ? 1 : widget.maxLines,
          maxLength: isOtp ? 6 : widget.maxLength,
          textAlign: isOtp ? TextAlign.center : TextAlign.start,
          style: (isOtp ? AppTextStyle.otp : AppTextStyle.bodyLarge).copyWith(
            color: colors.ink,
          ),
          cursorColor: colors.accent,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          decoration: AppInputDecoration.build(
            colors,
            hint: widget.hint,
            prefixIcon: widget.variant == AppTextFieldVariant.search
                ? Icon(Icons.search_rounded, size: 22.r)
                : null,
            suffixIcon: isPassword
                ? IconButton(
                    tooltip: isObscured ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => isObscured = !isObscured),
                    icon: Icon(
                      isObscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20.r,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
