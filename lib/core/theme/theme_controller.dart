import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:mechat/core/theme/advanced_theme_model.dart';

class ThemeState {
  final List<AdvancedThemeModel> customThemes;
  final String globalThemeId;
  final Map<String, String> perChatThemes;
  final Set<String> favoriteThemeIds;
  final List<String> recentThemeIds;

  ThemeState({
    required this.customThemes,
    required this.globalThemeId,
    required this.perChatThemes,
    required this.favoriteThemeIds,
    required this.recentThemeIds,
  });

  ThemeState copyWith({
    List<AdvancedThemeModel>? customThemes,
    String? globalThemeId,
    Map<String, String>? perChatThemes,
    Set<String>? favoriteThemeIds,
    List<String>? recentThemeIds,
  }) {
    return ThemeState(
      customThemes: customThemes ?? this.customThemes,
      globalThemeId: globalThemeId ?? this.globalThemeId,
      perChatThemes: perChatThemes ?? this.perChatThemes,
      favoriteThemeIds: favoriteThemeIds ?? this.favoriteThemeIds,
      recentThemeIds: recentThemeIds ?? this.recentThemeIds,
    );
  }
}

class ThemeController extends Notifier<ThemeState> {
  static const boxName = 'advanced_theme_box';
  late Box _box;

  @override
  ThemeState build() {
    _box = Hive.box(boxName);
    return _loadState();
  }

  ThemeState _loadState() {
    final customThemesJson = _box.get('custom_themes');
    List<AdvancedThemeModel> themes = [];
    if (customThemesJson != null) {
      final List decoded = jsonDecode(customThemesJson);
      themes = decoded.map((e) => AdvancedThemeModel.fromJson(e)).toList();
    }

    final globalId = _box.get('global_theme_id', defaultValue: 'material3');

    final Map<dynamic, dynamic>? perChatJson = _box.get('per_chat_themes');
    Map<String, String> perChat = {};
    if (perChatJson != null) {
      perChatJson.forEach((k, v) => perChat[k.toString()] = v.toString());
    }

    // Load favorites
    final List<dynamic>? favJson = _box.get('favorite_theme_ids');
    Set<String> favorites = {};
    if (favJson != null) {
      favorites = favJson.map((e) => e.toString()).toSet();
    }

    // Load recents
    final List<dynamic>? recentJson = _box.get('recent_theme_ids');
    List<String> recents = [];
    if (recentJson != null) {
      recents = recentJson.map((e) => e.toString()).toList();
    }

    return ThemeState(
      customThemes: themes,
      globalThemeId: globalId,
      perChatThemes: perChat,
      favoriteThemeIds: favorites,
      recentThemeIds: recents,
    );
  }

  void _saveState() {
    _box.put(
      'custom_themes',
      jsonEncode(state.customThemes.map((e) => e.toJson()).toList()),
    );
    _box.put('global_theme_id', state.globalThemeId);
    _box.put('per_chat_themes', state.perChatThemes);
    _box.put('favorite_theme_ids', state.favoriteThemeIds.toList());
    _box.put('recent_theme_ids', state.recentThemeIds);
  }

  // Find theme by ID (checks presets then custom)
  AdvancedThemeModel getTheme(String id) {
    return AdvancedThemeModel.presets.firstWhere(
      (t) => t.id == id,
      orElse: () => state.customThemes.firstWhere(
        (t) => t.id == id,
        orElse: () => AdvancedThemeModel.presetMaterial3(),
      ),
    );
  }

  // Get effective theme for a chat
  AdvancedThemeModel getEffectiveTheme(String? chatId) {
    if (chatId != null && state.perChatThemes.containsKey(chatId)) {
      return getTheme(state.perChatThemes[chatId]!);
    }
    return getTheme(state.globalThemeId);
  }

  void setGlobalTheme(String id) {
    state = state.copyWith(globalThemeId: id);
    addToRecent(id);
    _saveState();
  }

  void setPerChatTheme(String chatId, String themeId) {
    final newMap = Map<String, String>.from(state.perChatThemes);
    newMap[chatId] = themeId;
    state = state.copyWith(perChatThemes: newMap);
    addToRecent(themeId);
    _saveState();
  }

  void clearPerChatTheme(String chatId) {
    final newMap = Map<String, String>.from(state.perChatThemes);
    newMap.remove(chatId);
    state = state.copyWith(perChatThemes: newMap);
    _saveState();
  }

  void saveCustomTheme(AdvancedThemeModel theme) {
    final newThemes = List<AdvancedThemeModel>.from(state.customThemes);
    final idx = newThemes.indexWhere((t) => t.id == theme.id);
    if (idx >= 0) {
      newThemes[idx] = theme;
    } else {
      newThemes.add(theme);
    }
    state = state.copyWith(customThemes: newThemes);
    _saveState();
  }

  void deleteCustomTheme(String id) {
    final newThemes = List<AdvancedThemeModel>.from(state.customThemes);
    newThemes.removeWhere((t) => t.id == id);

    // If it was global, fallback to material3
    String globalId = state.globalThemeId;
    if (globalId == id) {
      globalId = 'material3';
    }

    // Remove from perChat
    final newMap = Map<String, String>.from(state.perChatThemes);
    newMap.removeWhere((k, v) => v == id);

    // Remove from favorites
    final newFavorites = Set<String>.from(state.favoriteThemeIds);
    newFavorites.remove(id);

    // Remove from recents
    final newRecents = List<String>.from(state.recentThemeIds);
    newRecents.remove(id);

    state = state.copyWith(
      customThemes: newThemes,
      globalThemeId: globalId,
      perChatThemes: newMap,
      favoriteThemeIds: newFavorites,
      recentThemeIds: newRecents,
    );
    _saveState();
  }

  // Toggle a theme as favorite
  void toggleFavorite(String themeId) {
    final newFavorites = Set<String>.from(state.favoriteThemeIds);
    if (newFavorites.contains(themeId)) {
      newFavorites.remove(themeId);
    } else {
      newFavorites.add(themeId);
    }
    state = state.copyWith(favoriteThemeIds: newFavorites);
    _saveState();
  }

  // Check if a theme is favorited
  bool isFavorite(String themeId) {
    return state.favoriteThemeIds.contains(themeId);
  }

  // Add theme to recent list (max 10, most recent first)
  void addToRecent(String themeId) {
    final newRecents = List<String>.from(state.recentThemeIds);
    newRecents.remove(themeId); // Remove if already exists
    newRecents.insert(0, themeId); // Add to front
    if (newRecents.length > 10) {
      newRecents.removeRange(10, newRecents.length);
    }
    state = state.copyWith(recentThemeIds: newRecents);
    // _saveState is typically called by the caller (setGlobalTheme, setPerChatTheme)
    // but we also save here for direct calls
    _saveState();
  }
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeState>(
  ThemeController.new,
);

final advancedThemeProvider = Provider.family<AdvancedThemeModel, String?>((
  ref,
  chatId,
) {
  // Watch the state to ensure UI rebuilds when theme changes
  ref.watch(themeControllerProvider);
  return ref.read(themeControllerProvider.notifier).getEffectiveTheme(chatId);
});
