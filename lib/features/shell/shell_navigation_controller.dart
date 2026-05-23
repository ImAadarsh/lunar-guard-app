import 'package:flutter/foundation.dart';

/// Switches bottom-nav tabs from quick actions on the home screen.
class ShellNavigationController extends ChangeNotifier {
  int selectedIndex = 0;

  void goToTab(int index) {
    if (index < 0 || index > 4) return;
    if (index == selectedIndex) return;
    selectedIndex = index;
    notifyListeners();
  }
}
