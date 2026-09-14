import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode get themeMode => ThemeMode.light;
  bool get isDarkMode => false;

  ThemeProvider();

  Future<void> setThemeMode(ThemeMode mode) async {
    // Pure light mode enforced
    notifyListeners();
  }

  void toggleTheme() {
    // Pure light mode enforced
    notifyListeners();
  }
}
