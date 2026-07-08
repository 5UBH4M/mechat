import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hive_service.dart';
import '../services/service_providers.dart';
import 'custom_theme_model.dart';

enum AppThemeType { light, dark, terminal, oldPhone, cyberpunk, custom }

class ThemeModeNotifier extends StateNotifier<AppThemeType> {
  final HiveService _hive;

  ThemeModeNotifier(this._hive) : super(AppThemeType.dark) {
    _loadTheme();
  }

  void _loadTheme() {
    final mode = _hive.getThemeMode();
    state = AppThemeType.values.firstWhere(
      (e) => e.name == mode,
      orElse: () => AppThemeType.dark,
    );
  }

  void setTheme(AppThemeType themeType) {
    state = themeType;
    _hive.saveThemeMode(themeType.name);
  }
}

class CustomThemeNotifier extends StateNotifier<CustomThemeModel> {
  final HiveService _hive;

  CustomThemeNotifier(this._hive) : super(CustomThemeModel.defaultTheme()) {
    _loadCustomTheme();
  }

  void _loadCustomTheme() {
    final raw = _hive.getCustomTheme();
    if (raw != null) {
      state = CustomThemeModel.fromJson(raw);
    }
  }

  void updateTheme(CustomThemeModel model) {
    state = model;
    _hive.saveCustomTheme(model.toJson());
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeType>((ref) {
      final hive = ref.watch(hiveServiceProvider);
      return ThemeModeNotifier(hive);
    });

final customThemeProvider =
    StateNotifierProvider<CustomThemeNotifier, CustomThemeModel>((ref) {
      final hive = ref.watch(hiveServiceProvider);
      return CustomThemeNotifier(hive);
    });
