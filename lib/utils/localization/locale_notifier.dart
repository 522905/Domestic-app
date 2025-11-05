import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends ChangeNotifier {
  LocaleNotifier({SharedPreferences? preferences}) : _preferences = preferences;

  static const String _key = 'selected_locale';
  final SharedPreferences? _preferences;
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  Future<void> initialize() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_key);
    if (savedCode != null && savedCode.isNotEmpty) {
      _locale = Locale(savedCode);
    }
  }

  Future<void> updateLocale(Locale locale) async {
    if (locale == _locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }
}
