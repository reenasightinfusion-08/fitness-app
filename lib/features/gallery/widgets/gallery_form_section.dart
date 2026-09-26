import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/utils/app_validators.dart';
import 'package:fitness_app/core/widgets/widgets.dart';

class GalleryFormSection extends StatefulWidget {
  const GalleryFormSection({super.key});

  @override
  State<GalleryFormSection> createState() => GalleryFormSectionState();
}

class GalleryFormSectionState extends State<GalleryFormSection> {
  final formKey = GlobalKey<FormState>();
  String? timeOfDay;

  static const List<AppDropDownItemModel<String>> timeOptions = [
    AppDropDownItemModel(value: 'morning', label: 'Morning'),
    AppDropDownItemModel(value: 'break', label: 'Work break'),
    AppDropDownItemModel(value: 'evening', label: 'Evening'),
    AppDropDownItemModel(value: 'bed', label: 'Before bed'),
  ];

  void submit() {
    if (formKey.currentState?.validate() ?? false) {
      AppSnackBar.showSuccess(context, 'Looks good.');
    }
  }

  @override
  Widget build(BuildContext context) => AppSectionWrapper(
    title: 'Form fields',
    child: Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppButton(
            label: 'Continue with Apple',
            variant: AppButtonVariant.secondary,
            onPressed: null,
          ),
          16.verticalSpace,
          const AppDividerText(text: 'or use email'),
          16.verticalSpace,
          const AppTextField(
            label: 'Email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            autofillHints: [AutofillHints.email],
            validator: AppValidators.email,
          ),
          16.verticalSpace,
          const AppTextField(
            label: 'Password',
            hint: 'At least 8 characters',
            variant: AppTextFieldVariant.password,
            autofillHints: [AutofillHints.newPassword],
            validator: AppValidators.password,
          ),
          16.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Height (cm)',
                  isOptional: true,
                  hint: '165',
                  keyboardType: TextInputType.number,
                  validator: AppValidators.optionalNumber(min: 100, max: 250),
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: AppTextField(
                  label: 'Weight (kg)',
                  isOptional: true,
                  hint: '62',
                  keyboardType: TextInputType.number,
                  validator: AppValidators.optionalNumber(min: 25, max: 300),
                ),
              ),
            ],
          ),
          16.verticalSpace,
          const AppTextField(
            label: '6-digit code',
            hint: '••••••',
            variant: AppTextFieldVariant.otp,
            validator: AppValidators.otp,
          ),
          16.verticalSpace,
          const AppTextField(
            hint: 'Search stretches or body areas',
            variant: AppTextFieldVariant.search,
            validator: AppValidators.none,
          ),
          16.verticalSpace,
          AppDropDown<String>(
            label: 'When do you usually have time?',
            hint: 'Pick one',
            items: timeOptions,
            value: timeOfDay,
            onChanged: (value) => setState(() => timeOfDay = value),
          ),
          20.verticalSpace,
          AppButton(label: 'Validate form', onPressed: submit),
        ],
      ),
    ),
  );
}
