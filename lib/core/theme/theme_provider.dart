import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hive_service.dart';
import '../services/service_providers.dart';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final HiveService _hive;

  ThemeModeNotifier(this._hive) : super(ThemeMode.dark) {
    _loadTheme();
  }

  void _loadTheme() {
    final mode = _hive.getThemeMode();
    state = mode == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      _hive.saveThemeMode('light');
    } else {
      state = ThemeMode.dark;
      _hive.saveThemeMode('dark');
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final hive = ref.watch(hiveServiceProvider);
  return ThemeModeNotifier(hive);
});
