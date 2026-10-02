import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The bottom tabs of the home shell, in order.
enum HomeTab { today, explore, mine, progress, profile }

/// Which tab the home shell shows. Set it before returning to Home to land
/// on a specific tab, e.g. Mine after saving a routine.
class HomeTabController extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.today;

  void show(HomeTab tab) => state = tab;
}

final homeTabProvider = NotifierProvider<HomeTabController, HomeTab>(
  HomeTabController.new,
);
