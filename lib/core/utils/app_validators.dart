typedef AppValidator = String? Function(String? value);

class AppValidators {
  const AppValidators._();

  static final RegExp emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? none(String? value) => null;

  static String? required(String? value) =>
      (value == null || value.trim().isEmpty) ? 'This field is required' : null;

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your email';
    return emailPattern.hasMatch(value.trim())
        ? null
        : 'That email doesn’t look right';
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Enter a password';
    return value.length < 8 ? 'Use at least 8 characters' : null;
  }

  static String? otp(String? value) => RegExp(r'^\d{6}$').hasMatch(value ?? '')
      ? null
      : 'Enter the 6-digit code';

  /// Empty is allowed; if filled it must be a whole number within [min]..[max].
  static AppValidator optionalNumber({required int min, required int max}) =>
      (value) {
        if (value == null || value.trim().isEmpty) return null;
        final parsed = int.tryParse(value.trim());
        if (parsed == null) return 'Numbers only';
        if (parsed < min || parsed > max) {
          return 'Enter a value between $min and $max';
        }
        return null;
      };
}
