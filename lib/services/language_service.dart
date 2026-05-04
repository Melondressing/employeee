import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { ko, en }

extension AppLanguageText on AppLanguage {
  String text(String ko, String en) => this == AppLanguage.ko ? ko : en;

  String get shortLabel => this == AppLanguage.ko ? 'KO' : 'EN';

  Locale get locale {
    switch (this) {
      case AppLanguage.ko:
        return const Locale('ko', 'KR');
      case AppLanguage.en:
        return const Locale('en', 'GB');
    }
  }
}

final appLanguageProvider =
    StateNotifierProvider<AppLanguageNotifier, AppLanguage>((ref) {
  return AppLanguageNotifier()..load();
});

class AppLanguageNotifier extends StateNotifier<AppLanguage> {
  AppLanguageNotifier() : super(AppLanguage.ko);

  static const _languageKey = 'app_language';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_languageKey);
    state = raw == AppLanguage.en.name ? AppLanguage.en : AppLanguage.ko;
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.name);
  }

  Future<void> toggle() async {
    await setLanguage(
      state == AppLanguage.ko ? AppLanguage.en : AppLanguage.ko,
    );
  }
}

String weekdayLabel(
  DateTime date,
  AppLanguage language, {
  bool short = true,
}) {
  final index = (date.weekday - 1) % 7;
  const koShort = ['월', '화', '수', '목', '금', '토', '일'];
  const koLong = ['월요일', '화요일', '수요일', '목요일', '금요일', '토요일', '일요일'];
  const enShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const enLong = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  if (language == AppLanguage.ko) {
    return short ? koShort[index] : koLong[index];
  }
  return short ? enShort[index] : enLong[index];
}
