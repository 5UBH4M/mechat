import 'package:flutter/material.dart';
import '../../../core/theme/advanced_theme_model.dart';

class ChatInputBar extends StatefulWidget {
  final ThemeData theme;
  final AdvancedThemeModel advTheme;
  final bool useAdvancedThemeData;
  final TextEditingController messageController;
  final FocusNode messageFocusNode;
  final bool isRecording;
  final DateTime? recordingStartTime;
  final VoidCallback onSend;
  final VoidCallback onStartRecording;
  final Function(bool shouldSend) onStopRecording;
  final VoidCallback onShowMediaOptions;
  final Function(String text) onTextChanged;
  final bool hasText;

  const ChatInputBar({
    super.key,
    required this.theme,
    required this.advTheme,
    required this.useAdvancedThemeData,
    required this.messageController,
    required this.messageFocusNode,
    required this.isRecording,
    required this.recordingStartTime,
    required this.onSend,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onShowMediaOptions,
    required this.onTextChanged,
    required this.hasText,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final advTheme = widget.advTheme;
    final useAdvancedThemeData = widget.useAdvancedThemeData;

    final defaultIconColor = useAdvancedThemeData
        ? Color(advTheme.appAppearance.iconColor)
        : theme.colorScheme.primary;
    final defaultInputBg = useAdvancedThemeData
        ? Color(advTheme.appAppearance.inputBackgroundColor)
        : theme.colorScheme.surface;
    final defaultInputText = useAdvancedThemeData
        ? Color(advTheme.appAppearance.inputTextColor)
        : theme.colorScheme.onSurface;

    return Container(
      key: const ValueKey('input_bar'),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Media attachments button
          IconButton(
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: defaultIconColor,
            ),
            onPressed: widget.onShowMediaOptions,
          ),

          // Main text entry field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: defaultInputBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: widget.isRecording
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.mic,
                            color: theme.colorScheme.error,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Recording audio...',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: defaultInputText,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => widget.onStopRecording(false), // Cancel
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    )
                  : TextField(
                      controller: widget.messageController,
                      focusNode: widget.messageFocusNode,
                      onChanged: widget.onTextChanged,
                      onTapOutside: (event) {
                        // Prevent keyboard from closing automatically when tapping outside (e.g. starting a swipe).
                        // It will close on drag due to ListView's keyboardDismissBehavior.
                      },
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      style: TextStyle(color: defaultInputText),
                      cursorColor: defaultIconColor,
                      decoration: InputDecoration(
                        hintText: 'Message',
                        hintStyle: TextStyle(
                          color: defaultInputText.withValues(alpha: 0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 8),

          // Send / Voice Record Button
          Builder(builder: (context) {
            final sendButtonBgColor = useAdvancedThemeData
                ? Color(advTheme.appAppearance.sendButtonColor)
                : theme.colorScheme.secondary;
            final sendIconColor = sendButtonBgColor.computeLuminance() > 0.5
                ? Colors.black
                : Colors.white;
            return GestureDetector(
              onLongPress: widget.isRecording ? null : widget.onStartRecording,
              onLongPressUp: widget.isRecording ? () => widget.onStopRecording(true) : null,
              child: IconButton.filled(
                onPressed: widget.isRecording ? null : widget.onSend,
                style: IconButton.styleFrom(
                  backgroundColor: sendButtonBgColor,
                  shape: const CircleBorder(),
                  minimumSize: const Size(48, 48),
                ),
                icon: widget.isRecording
                    ? Icon(Icons.stop, color: sendIconColor)
                    : (widget.hasText
                        ? Icon(Icons.send, color: sendIconColor)
                        : Icon(Icons.mic, color: sendIconColor)),
              ),
            );
          }),
        ],
      ),
    );
  }
}
