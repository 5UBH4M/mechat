import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hive_service.dart';
import '../services/service_providers.dart';

enum AppThemeType {
  light,
  dark,
  terminal,
  oldPhone,
}

class ThemeModeNotifier extends StateNotifier<AppThemeType> {
  final HiveService _hive;

  ThemeModeNotifier(this._hive) : super(AppThemeType.dark) {
    _loadTheme();
  }

  void _loadTheme() {
    final mode = _hive.getThemeMode();
    state = AppThemeType.values.firstWhere(
      (e) => e.name == mode, 
      orElse: () => AppThemeType.dark
    );
  }

  void setTheme(AppThemeType themeType) {
    state = themeType;
    _hive.saveThemeMode(themeType.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AppThemeType>((ref) {
  final hive = ref.watch(hiveServiceProvider);
  return ThemeModeNotifier(hive);
});
