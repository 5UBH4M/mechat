import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mechat/domain/entities/message_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMediaState {
  final List<MessageEntity> mediaMessages; // images, videos
  final List<MessageEntity> documentMessages;
  final List<MessageEntity> voiceMessages;
  final List<MessageEntity> links;
  final List<MessageEntity> bookmarkedMessages;
  final Set<String> bookmarkedIds;

  const ChatMediaState({
    this.mediaMessages = const [],
    this.documentMessages = const [],
    this.voiceMessages = const [],
    this.links = const [],
    this.bookmarkedMessages = const [],
    this.bookmarkedIds = const {},
  });

  ChatMediaState copyWith({
    List<MessageEntity>? mediaMessages,
    List<MessageEntity>? documentMessages,
    List<MessageEntity>? voiceMessages,
    List<MessageEntity>? links,
    List<MessageEntity>? bookmarkedMessages,
    Set<String>? bookmarkedIds,
  }) {
    return ChatMediaState(
      mediaMessages: mediaMessages ?? this.mediaMessages,
      documentMessages: documentMessages ?? this.documentMessages,
      voiceMessages: voiceMessages ?? this.voiceMessages,
      links: links ?? this.links,
      bookmarkedMessages: bookmarkedMessages ?? this.bookmarkedMessages,
      bookmarkedIds: bookmarkedIds ?? this.bookmarkedIds,
    );
  }
}

class ChatMediaNotifier extends StateNotifier<ChatMediaState> {
  final String chatId;
  
  ChatMediaNotifier(this.chatId) : super(const ChatMediaState()) {
    _loadBookmarks();
  }

  static final RegExp _urlRegExp = RegExp(
    r'(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9]+\.[^\s]{2,}|www\.[a-zA-Z0-9]+\.[^\s]{2,})',
    caseSensitive: false,
  );

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('bookmarks_$chatId') ?? [];
    state = state.copyWith(bookmarkedIds: ids.toSet());
  }

  Future<void> _saveBookmarks(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('bookmarks_$chatId', ids.toList());
  }

  void processMessages(List<MessageEntity> messages) {
    final media = <MessageEntity>[];
    final docs = <MessageEntity>[];
    final voice = <MessageEntity>[];
    final links = <MessageEntity>[];
    final bookmarks = <MessageEntity>[];

    for (final m in messages) {
      if (m.type == 'image' || m.type == 'video') {
        media.add(m);
      } else if (m.type == 'document') {
        docs.add(m);
      } else if (m.type == 'audio') {
        voice.add(m);
      }

      if (m.type == 'text' && _urlRegExp.hasMatch(m.content)) {
        links.add(m);
      }

      if (state.bookmarkedIds.contains(m.id)) {
        bookmarks.add(m);
      }
    }

    state = state.copyWith(
      mediaMessages: media,
      documentMessages: docs,
      voiceMessages: voice,
      links: links,
      bookmarkedMessages: bookmarks,
    );
  }

  void toggleBookmark(MessageEntity message) {
    final ids = Set<String>.from(state.bookmarkedIds);
    final isBookmarked = ids.contains(message.id);
    
    if (isBookmarked) {
      ids.remove(message.id);
    } else {
      ids.add(message.id);
    }
    
    state = state.copyWith(bookmarkedIds: ids);
    _saveBookmarks(ids);
    
    // We don't re-process everything, just add/remove from current list for efficiency
    final bookmarks = List<MessageEntity>.from(state.bookmarkedMessages);
    if (isBookmarked) {
      bookmarks.removeWhere((m) => m.id == message.id);
    } else {
      bookmarks.add(message);
      bookmarks.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
    }
    state = state.copyWith(bookmarkedMessages: bookmarks);
  }

  bool isBookmarked(String messageId) {
    return state.bookmarkedIds.contains(messageId);
  }
}

final chatMediaProvider = StateNotifierProvider.family<ChatMediaNotifier, ChatMediaState, String>((ref, chatId) {
  return ChatMediaNotifier(chatId);
});
