import 'package:flutter/material.dart';
import 'package:any_link_preview/any_link_preview.dart';
import '../../../../domain/entities/message_entity.dart';
import '../../chat_search_notifier.dart';

class TextBubble extends StatelessWidget {
  final MessageEntity msg;
  final bool isMatch;
  final bool isCurrentMatch;
  final ChatSearchState searchState;
  final Color textColor;
  final ThemeData theme;
  final bool isMe;

  const TextBubble({
    super.key,
    required this.msg,
    required this.isMatch,
    required this.isCurrentMatch,
    required this.searchState,
    required this.textColor,
    required this.theme,
    required this.isMe,
  });

  bool _containsLink(String text) {
    return RegExp(r'(https?:\/\/[^\s]+)').hasMatch(text);
  }

  String _extractLink(String text) {
    final match = RegExp(r'(https?:\/\/[^\s]+)').firstMatch(text);
    final raw = match?.group(0) ?? '';
    if (raw.isEmpty) return '';
    final uri = Uri.tryParse(raw);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return '';
    }
    return raw;
  }

  Widget _buildHighlightedText(
    String text,
    String query,
    bool isCurrentMatch,
    Color textColor,
  ) {
    if (query.isEmpty) {
      return Text(text, style: TextStyle(color: textColor, fontSize: 15));
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    final List<TextSpan> spans = [];
    int start = 0;

    while (true) {
      final int index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(
          TextSpan(
            text: text.substring(start),
            style: TextStyle(color: textColor, fontSize: 15),
          ),
        );
        break;
      }

      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: TextStyle(color: textColor, fontSize: 15),
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            color: Colors.black,
            backgroundColor: isCurrentMatch ? Colors.deepOrange : Colors.yellow,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + query.length;
    }

    return RichText(text: TextSpan(children: spans));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMatch &&
            !searchState.isFuzzy &&
            searchState.query.isNotEmpty)
          _buildHighlightedText(
            msg.content,
            searchState.query,
            isCurrentMatch,
            textColor,
          )
        else
          Text(
            msg.content,
            style: TextStyle(color: textColor, fontSize: 15),
          ),
        if (msg.type == 'text' && _containsLink(msg.content)) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.6,
            child: AnyLinkPreview(
              link: _extractLink(msg.content),
              displayDirection: UIDirection.uiDirectionHorizontal,
              backgroundColor: isMe
                  ? Colors.white12
                  : theme.colorScheme.surfaceContainerHighest,
              bodyStyle: TextStyle(
                color: textColor,
                fontSize: 12,
              ),
              titleStyle: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              errorWidget: const SizedBox.shrink(),
            ),
          ),
        ],
      ],
    );
  }
}
