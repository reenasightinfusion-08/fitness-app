import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/utils/legal_links.dart';

/// "By creating an account you agree to our" over "Terms of Use and Privacy
/// Policy." — two fixed lines, so a link never wraps on its own.
class AuthLegalNotice extends StatefulWidget {
  const AuthLegalNotice({super.key});

  @override
  State<AuthLegalNotice> createState() => _AuthLegalNoticeState();
}

class _AuthLegalNoticeState extends State<AuthLegalNotice> {
  late final TapGestureRecognizer _terms = TapGestureRecognizer()
    ..onTap = () => LegalLinks.open(context, LegalLinks.terms);
  late final TapGestureRecognizer _privacy = TapGestureRecognizer()
    ..onTap = () => LegalLinks.open(context, LegalLinks.privacy);

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = AppTextStyle.body(12).copyWith(color: colors.ink3, height: 1.5);
    final link = base.copyWith(
      color: colors.ink,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: colors.ink3,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'By creating an account, you agree to our\n'),
          TextSpan(text: 'Terms of Use', style: link, recognizer: _terms),
          const TextSpan(text: ' and '),
          TextSpan(text: 'Privacy Policy', style: link, recognizer: _privacy),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
