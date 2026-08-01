import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { bengali, english }

class AppLanguageController extends ValueNotifier<AppLanguage> {
  AppLanguageController._() : super(AppLanguage.bengali);

  static final AppLanguageController instance = AppLanguageController._();
  static const _key = 'app_language_v1';

  AppLanguage get current => value;
  bool get isBengali => value == AppLanguage.bengali;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    value = prefs.getString(_key) == 'en'
        ? AppLanguage.english
        : AppLanguage.bengali;
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (value == language) return;
    value = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, language == AppLanguage.english ? 'en' : 'bn');
  }

  String text(String bn, String en) => isBengali ? bn : en;
}

class L10n {
  static AppLanguageController get _c => AppLanguageController.instance;
  static String t(String bn, String en) => _c.text(bn, en);
}
