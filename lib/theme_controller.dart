import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static final ThemeController I = ThemeController._internal();
  ThemeController._internal();

  static const _key = 'isDarkTheme';
  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeMode get currentMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDark);
  }
}
