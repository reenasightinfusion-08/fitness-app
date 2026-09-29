import 'package:flutter/material.dart';

import 'package:country_picker/country_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/utils/app_validators.dart';
import 'package:fitness_app/core/widgets/widgets.dart';
import 'package:fitness_app/features/onboarding_setup/models/onboarding_options.dart';
import 'package:fitness_app/features/onboarding_setup/providers/onboarding_profile_provider.dart';

/// Step 0 — first name (required), country (optional), age (optional), gender (optional chips).
class BasicStep extends ConsumerWidget {
  const BasicStep({super.key});

  void _showAppCountryPicker(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      showDragHandle: false,
      onSelect: (Country country) {
        ref.read(onboardingProfileProvider.notifier).setCountry(country.name);
      },
      countryListTheme: CountryListThemeData(
        backgroundColor: colors.surface,
        textStyle: AppTextStyle.bodyLarge.copyWith(color: colors.ink),
        searchTextStyle: AppTextStyle.bodyLarge.copyWith(color: colors.ink),
        bottomSheetHeight: 520.h,
        borderRadius: AppBorderRadius.sheet,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        inputDecoration: AppInputDecoration.build(
          colors,
          hint: 'Search country...',
          prefixIcon: Icon(Icons.search_rounded, size: 20.r, color: colors.ink3),
        ),
        flagSize: 24.r,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final profile = ref.watch(onboardingProfileProvider);
    final controller = ref.read(onboardingProfileProvider.notifier);

    final selectedCountry = profile.country.isEmpty
        ? null
        : CountryService().findByName(profile.country);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'First name',
          hint: 'What should we call you?',
          initialValue: profile.name,
          textInputAction: TextInputAction.next,
          validator: AppValidators.required,
          onChanged: controller.setName,
        ),
        14.verticalSpace,
        AppTextField(
          label: 'Age',
          hint: 'Years',
          isOptional: true,
          initialValue: profile.age,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          validator: AppValidators.optionalNumber(min: 10, max: 100),
          onChanged: controller.setAge,
        ),
        14.verticalSpace,
        AppFieldLabel(text: 'Country', isOptional: true),
        6.verticalSpace,
        InkWell(
          onTap: () => _showAppCountryPicker(context, ref),
          borderRadius: AppBorderRadius.lg,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppBorderRadius.lg,
              border: Border.all(color: colors.line),
            ),
            child: Row(
              children: [
                if (selectedCountry != null) ...[
                  Text(
                    selectedCountry.flagEmoji,
                    style: TextStyle(fontSize: 20.r),
                  ),
                  10.horizontalSpace,
                ],
                Expanded(
                  child: Text(
                    profile.country.isEmpty
                        ? 'Select your country'
                        : profile.country,
                    style: AppTextStyle.bodyLarge.copyWith(
                      color: profile.country.isEmpty ? colors.ink3 : colors.ink,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colors.ink2,
                  size: 22.r,
                ),
              ],
            ),
          ),
        ),
        18.verticalSpace,
        AppFieldLabel(text: 'Gender', isOptional: true),
        8.verticalSpace,
        AppChipGroup(
          children: [
            for (final option in genderOptions)
              AppChip(
                label: option,
                isSelected: profile.gender == option,
                onTap: () => controller.setGender(option),
              ),
          ],
        ),
      ],
    );
  }
}
