import 'package:flutter/foundation.dart';

/// A single row of the profile menu — "Edit profile", "Reminders", etc.
@immutable
class ProfileMenuItem {
  const ProfileMenuItem({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

/// Demo content for the Profile screen — there's no backend yet, so this
/// stands in for what a real account service would return.
class ProfileDemoData {
  const ProfileDemoData._();

  static const name = 'Anand Patel';
  static const email = 'anand@example.com';
  static const isPremium = false;

  static const menu = [
    ProfileMenuItem(
      title: 'Edit profile',
      subtitle: 'Body, injuries, equipment, goals, time',
    ),
    ProfileMenuItem(
      title: 'Session settings',
      subtitle: 'Voice, music, hold and transition times, streak day',
    ),
    ProfileMenuItem(title: 'Reminders', subtitle: '8:00 am, 9:00 pm'),
    ProfileMenuItem(
      title: 'Account & security',
      subtitle: 'Password, sign-in, delete account',
    ),
    ProfileMenuItem(title: 'Premium', subtitle: '₹999 once, or ₹149/month'),
  ];
}
