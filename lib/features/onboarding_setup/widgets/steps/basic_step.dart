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
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20.r,
            color: colors.ink3,
          ),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 460;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AppTextField(
                      label: 'First name',
                      hint: 'What should we call you?',
                      initialValue: profile.name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: AppValidators.required,
                      onChanged: controller.setName,
                    ),
                  ),
                  14.horizontalSpace,
                  Expanded(
                    flex: 2,
                    child: AppTextField(
                      label: 'Age',
                      hint: 'Years',
                      isOptional: true,
                      initialValue: profile.age,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: AppValidators.optionalNumber(
                        min: 10,
                        max: 100,
                      ),
                      onChanged: controller.setAge,
                    ),
                  ),
                ],
              )
            else ...[
              AppTextField(
                label: 'First name',
                hint: 'What should we call you?',
                initialValue: profile.name,
                textCapitalization: TextCapitalization.words,
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
            ],
            (isWide ? 24.0 : 14.0).verticalSpace,
            AppFieldLabel(text: 'Country', isOptional: true),
            (isWide ? 10.0 : 6.0).verticalSpace,
            InkWell(
              onTap: () => _showAppCountryPicker(context, ref),
              borderRadius: isWide
                  ? BorderRadius.circular(16.0)
                  : AppBorderRadius.lg,
              child: Container(
                padding: isWide
                    ? EdgeInsets.symmetric(
                        horizontal: (MediaQuery.sizeOf(context).height * 0.026)
                            .clamp(20.0, 32.0),
                        vertical: (MediaQuery.sizeOf(context).height * 0.024)
                            .clamp(18.0, 28.0),
                      )
                    : EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: isWide
                      ? BorderRadius.circular(16.0)
                      : AppBorderRadius.lg,
                  border: Border.all(
                    color: colors.line,
                    width: isWide ? 1.2 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    if (selectedCountry != null) ...[
                      Text(
                        selectedCountry.flagEmoji,
                        style: TextStyle(
                          fontSize: isWide
                              ? (MediaQuery.sizeOf(context).height * 0.038)
                                    .clamp(30.0, 44.0)
                              : 20.r,
                        ),
                      ),
                      (isWide ? 16.0 : 10.0).horizontalSpace,
                    ],
                    Expanded(
                      child: Text(
                        profile.country.isEmpty
                            ? 'Select your country'
                            : profile.country,
                        style: AppTextStyle.bodyLarge.copyWith(
                          color: profile.country.isEmpty
                              ? colors.ink3
                              : colors.ink,
                          fontSize: isWide
                              ? (MediaQuery.sizeOf(context).height * 0.028)
                                    .clamp(20.0, 30.0)
                              : null,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colors.ink2,
                      size: isWide
                          ? (MediaQuery.sizeOf(context).height * 0.032).clamp(
                              28.0,
                              40.0,
                            )
                          : 22.r,
                    ),
                  ],
                ),
              ),
            ),
            (isWide ? 28.0 : 18.0).verticalSpace,
            AppFieldLabel(text: 'Gender', isOptional: true),
            (isWide ? 14.0 : 8.0).verticalSpace,
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
      },
    );
  }
}
