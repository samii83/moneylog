import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _darkStyle = 'Black';

  ThemeMode get themeMode => _themeMode;
  String get darkStyle => _darkStyle;

  AppThemeProvider() {
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('theme_mode') ?? 'system';
    final style = prefs.getString('dark_style') ?? 'Black';
    _themeMode = _themeModeFromString(mode);
    _darkStyle = style;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', _themeModeToString(mode));
    notifyListeners();
  }

  Future<void> setDarkStyle(String style) async {
    _darkStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dark_style', style);
    notifyListeners();
  }

  static ThemeMode _themeModeFromString(String s) {
    switch (s) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      default:
        return 'system';
    }
  }
}
