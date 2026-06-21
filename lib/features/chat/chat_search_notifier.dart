import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:mechat/domain/entities/message_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatSearchState {
  final bool isSearching;
  final String query;
  final List<int> matchIndices;
  final int currentMatchIndex;
  final List<String> recentSearches;
  final bool isFuzzy;

  const ChatSearchState({
    this.isSearching = false,
    this.query = '',
    this.matchIndices = const [],
    this.currentMatchIndex = -1,
    this.recentSearches = const [],
    this.isFuzzy = false,
  });

  ChatSearchState copyWith({
    bool? isSearching,
    String? query,
    List<int>? matchIndices,
    int? currentMatchIndex,
    List<String>? recentSearches,
    bool? isFuzzy,
  }) {
    return ChatSearchState(
      isSearching: isSearching ?? this.isSearching,
      query: query ?? this.query,
      matchIndices: matchIndices ?? this.matchIndices,
      currentMatchIndex: currentMatchIndex ?? this.currentMatchIndex,
      recentSearches: recentSearches ?? this.recentSearches,
      isFuzzy: isFuzzy ?? this.isFuzzy,
    );
  }
}

class ChatSearchNotifier extends StateNotifier<ChatSearchState> {
  ChatSearchNotifier() : super(const ChatSearchState()) {
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList('recent_searches') ?? [];
    state = state.copyWith(recentSearches: recent);
  }

  Future<void> _saveRecentSearches(List<String> recent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', recent);
  }

  void startSearch() {
    state = state.copyWith(isSearching: true, query: '', matchIndices: [], currentMatchIndex: -1);
  }

  void stopSearch() {
    state = state.copyWith(isSearching: false, query: '', matchIndices: [], currentMatchIndex: -1);
  }

  void addRecentSearch(String query) {
    if (query.trim().isEmpty) return;
    final recent = List<String>.from(state.recentSearches);
    recent.remove(query);
    recent.insert(0, query);
    if (recent.length > 10) {
      recent.removeLast();
    }
    state = state.copyWith(recentSearches: recent);
    _saveRecentSearches(recent);
  }

  void removeRecentSearch(String query) {
    final recent = List<String>.from(state.recentSearches);
    recent.remove(query);
    state = state.copyWith(recentSearches: recent);
    _saveRecentSearches(recent);
  }

  void clearRecentSearches() {
    state = state.copyWith(recentSearches: []);
    _saveRecentSearches([]);
  }

  void updateQuery(String query, List<MessageEntity> messages) {
    if (query.isEmpty) {
      state = state.copyWith(query: query, matchIndices: [], currentMatchIndex: -1, isFuzzy: false);
      return;
    }

    // Exact search first (case-insensitive)
    final exactMatches = <int>[];
    final lowerQuery = query.toLowerCase();
    
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].content.toLowerCase().contains(lowerQuery)) {
        exactMatches.add(i);
      }
    }

    if (exactMatches.isNotEmpty) {
      state = state.copyWith(
        query: query,
        matchIndices: exactMatches,
        currentMatchIndex: exactMatches.length - 1, // Start at bottom-most match (since messages are usually reversed or ordered, let's say index 0 is latest. Wait, indices depend on the provided list)
        isFuzzy: false,
      );
      return;
    }

    // If no exact matches, try fuzzy
    // We only fuzzy search if query is at least 4 chars long
    if (query.length < 4) {
      state = state.copyWith(query: query, matchIndices: [], currentMatchIndex: -1, isFuzzy: false);
      return;
    }

    final fuse = Fuzzy<MessageEntity>(
      messages,
      options: FuzzyOptions(
        keys: [WeightedKey(name: 'content', getter: (i) => i.content, weight: 1)],
        threshold: 0.3, // 0 is perfect, 1 is anything. 0.3 allows minor spelling mistakes
        minMatchCharLength: 3,
      ),
    );

    final results = fuse.search(query);
    final fuzzyIndices = <int>[];
    
    for (var result in results) {
      if (result.score < 0.4) { // Only good matches
        // Find the index in original list
        final idx = messages.indexOf(result.item);
        if (idx != -1) {
          fuzzyIndices.add(idx);
        }
      }
    }

    // Sort to keep order consistent with the list
    fuzzyIndices.sort();

    if (fuzzyIndices.isNotEmpty) {
      state = state.copyWith(
        query: query,
        matchIndices: fuzzyIndices,
        currentMatchIndex: fuzzyIndices.length - 1,
        isFuzzy: true,
      );
    } else {
      state = state.copyWith(query: query, matchIndices: [], currentMatchIndex: -1, isFuzzy: false);
    }
  }

  void nextMatch() {
    if (state.matchIndices.isEmpty) return;
    int next = state.currentMatchIndex - 1;
    if (next < 0) next = state.matchIndices.length - 1;
    state = state.copyWith(currentMatchIndex: next);
  }

  void previousMatch() {
    if (state.matchIndices.isEmpty) return;
    int prev = state.currentMatchIndex + 1;
    if (prev >= state.matchIndices.length) prev = 0;
    state = state.copyWith(currentMatchIndex: prev);
  }
}

final chatSearchProvider = StateNotifierProvider<ChatSearchNotifier, ChatSearchState>((ref) {
  return ChatSearchNotifier();
});
