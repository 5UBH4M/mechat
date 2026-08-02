import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mechat/core/theme/advanced_theme_model.dart';
import 'package:mechat/core/theme/theme_controller.dart';
import 'package:mechat/core/theme/theme_provider.dart';

const List<String> _fontOptions = [
  'Roboto',
  'Inter',
  'Open Sans',
  'Lato',
  'Poppins',
  'Montserrat',
  'Oswald',
  'Raleway',
  'Ubuntu',
  'Nunito',
  'Playfair Display',
  'Source Code Pro',
  'Fira Code',
  'JetBrains Mono',
  'Courier Prime',
];

const List<Color> _presetColors = [
  Colors.transparent,
  Colors.white,
  Colors.black,
  Color(0xFF9E9E9E),
  Color(0xFFF44336),
  Color(0xFFE91E63),
  Color(0xFF9C27B0),
  Color(0xFF673AB7),
  Color(0xFF3F51B5),
  Color(0xFF2196F3),
  Color(0xFF03A9F4),
  Color(0xFF00BCD4),
  Color(0xFF009688),
  Color(0xFF4CAF50),
  Color(0xFF8BC34A),
  Color(0xFFCDDC39),
  Color(0xFFFFEB3B),
  Color(0xFFFFC107),
  Color(0xFFFF9800),
  Color(0xFFFF5722),
  Color(0xFF795548),
  Color(0xFF075E54),
  Color(0xFF128C7E),
  Color(0xFF25D366),
  Color(0xFFE7FFDB),
  Color(0xFF0088CC),
  Color(0xFF517DA2),
  Color(0xFFEEFFDE),
  Color(0xFF007AFF),
  Color(0xFFE5E5EA),
  Color(0xFF5865F2),
  Color(0xFF36393F),
  Color(0xFF40444B),
  Color(0xFF1A1A1A),
  Color(0xFF333333),
  Color(0xFF0D0D0D),
  Color(0xFF00FFFF),
  Color(0xFFFF00FF),
  Color(0xFF39FF14),
  Color(0xFFFFB3BA),
  Color(0xFFBAE1FF),
  Color(0xFFBFFFBA),
];

class AdvancedAppearanceScreen extends ConsumerStatefulWidget {
  final String? chatId;

  const AdvancedAppearanceScreen({super.key, this.chatId});

  @override
  ConsumerState<AdvancedAppearanceScreen> createState() =>
      _AdvancedAppearanceScreenState();
}

class _AdvancedAppearanceScreenState
    extends ConsumerState<AdvancedAppearanceScreen> {
  late AdvancedThemeModel _theme;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final controller = ref.read(themeControllerProvider.notifier);
    _theme = controller.getEffectiveTheme(widget.chatId);


    final allThemes = _getAllThemes();
    final idx = allThemes.indexWhere((t) => t.id == _theme.id);
    if (idx >= 0) _selectedIndex = idx;
  }

  List<AdvancedThemeModel> _getAllThemes() {
    final themeState = ref.read(themeControllerProvider);
    return [...AdvancedThemeModel.presets, ...themeState.customThemes];
  }

  void _selectTheme(int index) {
    final themes = _getAllThemes();
    setState(() {
      _selectedIndex = index;
      _theme = themes[index];
    });
  }

  void _applyTheme() {
    final controller = ref.read(themeControllerProvider.notifier);

    final originalPreset = AdvancedThemeModel.presets
        .where((p) => p.id == _theme.id)
        .firstOrNull;
    final isModifiedPreset = originalPreset != null && _theme != originalPreset;
    final isUnmodifiedPreset = originalPreset != null && !isModifiedPreset;

    if (isModifiedPreset || !isUnmodifiedPreset) {
      final themeState = ref.read(themeControllerProvider);
      final existsAsCustom = themeState.customThemes.any(
        (t) => t.id == _theme.id,
      );

      if (isModifiedPreset || !existsAsCustom) {
        final customTheme = _theme.copyWith(
          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
          name: isModifiedPreset ? '${_theme.name} (Custom)' : _theme.name,
        );
        controller.saveCustomTheme(customTheme);
        _theme = customTheme;
      } else {
        controller.saveCustomTheme(_theme);
      }
    }

    if (widget.chatId != null) {
      controller.setPerChatTheme(widget.chatId!, _theme.id);
    } else {
      controller.setGlobalTheme(_theme.id);

      final themeId = _theme.id.toLowerCase();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (themeId == 'terminal') {
          ref.read(themeModeProvider.notifier).setTheme(AppThemeType.terminal);
        } else if (themeId == 'cyberpunk') {
          ref.read(themeModeProvider.notifier).setTheme(AppThemeType.cyberpunk);
        } else if (themeId == 'oldphone') {
          ref.read(themeModeProvider.notifier).setTheme(AppThemeType.oldPhone);
        }
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Theme "${_theme.name}" applied!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.of(context).pop();
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  void _showColorPicker(
    Color initialColor,
    ValueChanged<Color> onColorChanged,
  ) {
    final hexController = TextEditingController(
      text:
          '#${initialColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Color'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: initialColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: _presetColors.length,
                  itemBuilder: (context, index) {
                    final c = _presetColors[index];
                    final isSelected = c.toARGB32() == initialColor.toARGB32();
                    return GestureDetector(
                      onTap: () {
                        onColorChanged(c);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                        child: c == Colors.transparent
                            ? Icon(
                                Icons.block,
                                size: 16,
                                color: Colors.grey.shade400,
                              )
                            : (isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hexController,
                decoration: InputDecoration(
                  labelText: 'Hex Color',
                  hintText: '#RRGGBB',
                  prefixIcon: const Icon(Icons.color_lens_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (value) {
                  final hex = value.replaceAll('#', '').trim();
                  if (hex.length == 6) {
                    final parsed = int.tryParse('FF$hex', radix: 16);
                    if (parsed != null) {
                      onColorChanged(Color(parsed));
                      Navigator.pop(ctx);
                    }
                  } else if (hex.length == 8) {
                    final parsed = int.tryParse(hex, radix: 16);
                    if (parsed != null) {
                      onColorChanged(Color(parsed));
                      Navigator.pop(ctx);
                    }
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final hex = hexController.text.replaceAll('#', '').trim();
              if (hex.length == 6) {
                final parsed = int.tryParse('FF$hex', radix: 16);
                if (parsed != null) onColorChanged(Color(parsed));
              } else if (hex.length == 8) {
                final parsed = int.tryParse(hex, radix: 16);
                if (parsed != null) onColorChanged(Color(parsed));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Apply Hex'),
          ),
        ],
      ),
    );
  }

  void _updateTheme(AdvancedThemeModel newTheme) {
    setState(() {
      _theme = newTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeControllerProvider);
    final allThemes = _getAllThemes();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Customizer'),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _cancel,
            child: Text('Cancel', style: TextStyle(color: colorScheme.error)),
          ),
          FilledButton(
            onPressed: _applyTheme,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text('Apply'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [

          _buildLivePreview(),

          const SizedBox(height: 8),


          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: const [
                      Tab(text: 'Themes'),
                      Tab(text: 'Customize'),
                    ],
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurface.withValues(
                      alpha: 0.5,
                    ),
                    indicatorColor: colorScheme.primary,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [

                        ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: allThemes.length,
                          itemBuilder: (context, index) {
                            final theme = allThemes[index];
                            final isSelected = index == _selectedIndex;
                            return ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Color(
                                    theme.senderBubble.backgroundColor,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 18,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Color(
                                        theme.receiverBubble.backgroundColor,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                theme.name,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : null,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle_rounded,
                                      color: colorScheme.primary,
                                    )
                                  : null,
                              onTap: () => _selectTheme(index),
                            );
                          },
                        ),


                        ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildSenderBubblePanel(),
                            const SizedBox(height: 8),
                            _buildReceiverBubblePanel(),
                            const SizedBox(height: 8),
                            _buildTypographyPanel(),
                            const SizedBox(height: 8),
                            _buildBackgroundPanel(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLivePreview() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 240,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [

          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: Color(_theme.appAppearance.appBarColor),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(
                    Icons.arrow_back,
                    color: Color(_theme.appAppearance.appBarIconColor),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chat Preview',
                      style: AdvancedThemeModel.safeGetFont(
                        _theme.textTheme.fontFamily,
                        color: Color(_theme.appAppearance.appBarTitleColor),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.more_vert,
                    color: Color(_theme.appAppearance.appBarIconColor),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),


          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: Color(_theme.backgroundTheme.solidColor),
              child: Stack(
                children: [
                  if (_theme.backgroundTheme.blur > 0)
                    Positioned.fill(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: _theme.backgroundTheme.blur,
                          sigmaY: _theme.backgroundTheme.blur,
                        ),
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Column(
                      children: [
                        _buildPreviewBubble(
                          isSender: false,
                          text: "Hey! How's the new theme?",
                          time: '10:28 AM',
                        ),
                        const SizedBox(height: 4),
                        _buildPreviewBubble(
                          isSender: true,
                          text: 'It looks incredible! 🚀',
                          time: '10:29 AM',
                        ),
                        const SizedBox(height: 4),
                        _buildPreviewBubble(
                          isSender: false,
                          text: 'Try dark mode too 😎',
                          time: '10:30 AM',
                        ),
                      ],
                    ),
                  ),


                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: Color(
                        _theme.appAppearance.appBarColor,
                      ).withValues(alpha: 0.95),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add,
                            color: Color(_theme.appAppearance.iconColor),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Color(
                                  _theme.appAppearance.inputBackgroundColor,
                                ),
                                borderRadius: BorderRadius.circular(
                                  _theme.appAppearance.inputBorderRadius,
                                ),
                                border:
                                    _theme.appAppearance.inputBorderColor != 0
                                    ? Border.all(
                                        color: Color(
                                          _theme.appAppearance.inputBorderColor,
                                        ),
                                      )
                                    : null,
                              ),
                              child: Text(
                                'Message',
                                style: TextStyle(
                                  color: Color(
                                    _theme.appAppearance.inputHintColor,
                                  ),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(
                                _theme.appAppearance.sendButtonColor,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBubble({
    required bool isSender,
    required String text,
    required String time,
    bool isEmoji = false,
  }) {
    final bubble = isSender ? _theme.senderBubble : _theme.receiverBubble;
    final textColor = isSender
        ? _theme.textTheme.senderMessageColor
        : _theme.textTheme.receiverMessageColor;

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        constraints: const BoxConstraints(maxWidth: 220),
        padding: EdgeInsets.symmetric(
          horizontal: bubble.paddingHorizontal,
          vertical: bubble.paddingVertical,
        ),
        decoration: BoxDecoration(
          color: Color(bubble.backgroundColor).withValues(alpha: bubble.opacity),
          border: bubble.borderWidth > 0
              ? Border.all(
                  color: Color(bubble.borderColor),
                  width: bubble.borderWidth,
                )
              : null,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(bubble.radiusTopLeft),
            topRight: Radius.circular(bubble.radiusTopRight),
            bottomLeft: Radius.circular(bubble.radiusBottomLeft),
            bottomRight: Radius.circular(bubble.radiusBottomRight),
          ),
        ),
        child: Column(
          crossAxisAlignment: isSender
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: AdvancedThemeModel.safeGetFont(
                _theme.textTheme.fontFamily,
                color: Color(textColor),
                fontSize: isEmoji
                    ? _theme.textTheme.emojiSize
                    : _theme.textTheme.fontSize - 1,
                fontWeight: FontWeight
                    .values[(_theme.textTheme.fontWeight ~/ 100).clamp(0, 8)],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: AdvancedThemeModel.safeGetFont(
                _theme.textTheme.fontFamily,
                color: Color(_theme.textTheme.timestampColor),
                fontSize: _theme.textTheme.timestampSize - 1,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCustomizationCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(icon, size: 20),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildColorRow(
    String label,
    int colorValue,
    ValueChanged<int> onChanged,
  ) {
    return InkWell(
      onTap: () => _showColorPicker(Color(colorValue), (c) {
        onChanged(c.toARGB32());
      }),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Color(colorValue),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    int? divisions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }


  Widget _buildSenderBubblePanel() {
    return _buildCustomizationCard(
      title: 'Sender Bubble',
      icon: Icons.chat_bubble,
      children: [
        _buildColorRow(
          'Background Color',
          _theme.senderBubble.backgroundColor,
          (c) {
            _updateTheme(
              _theme.copyWith(
                senderBubble: _theme.senderBubble.copyWith(backgroundColor: c),
              ),
            );
          },
        ),
        _buildColorRow('Border Color', _theme.senderBubble.borderColor, (c) {
          _updateTheme(
            _theme.copyWith(
              senderBubble: _theme.senderBubble.copyWith(borderColor: c),
            ),
          );
        }),
        _buildSlider('Border Width', _theme.senderBubble.borderWidth, 0, 5, (
          v,
        ) {
          _updateTheme(
            _theme.copyWith(
              senderBubble: _theme.senderBubble.copyWith(borderWidth: v),
            ),
          );
        }),
        _buildSlider(
          'Bubble Radius',
          _theme.senderBubble.radiusTopLeft,
          0,
          32,
          (v) {
            _updateTheme(
              _theme.copyWith(
                senderBubble: _theme.senderBubble.copyWith(
                  radiusTopLeft: v,
                  radiusTopRight: v,
                  radiusBottomLeft: v,
                  radiusBottomRight: v,
                ),
              ),
            );
          },
        ),
      ],
    );
  }


  Widget _buildReceiverBubblePanel() {
    return _buildCustomizationCard(
      title: 'Receiver Bubble',
      icon: Icons.chat_bubble_outline,
      children: [
        _buildColorRow(
          'Background Color',
          _theme.receiverBubble.backgroundColor,
          (c) {
            _updateTheme(
              _theme.copyWith(
                receiverBubble: _theme.receiverBubble.copyWith(
                  backgroundColor: c,
                ),
              ),
            );
          },
        ),
        _buildColorRow('Border Color', _theme.receiverBubble.borderColor, (c) {
          _updateTheme(
            _theme.copyWith(
              receiverBubble: _theme.receiverBubble.copyWith(borderColor: c),
            ),
          );
        }),
        _buildSlider('Border Width', _theme.receiverBubble.borderWidth, 0, 5, (
          v,
        ) {
          _updateTheme(
            _theme.copyWith(
              receiverBubble: _theme.receiverBubble.copyWith(borderWidth: v),
            ),
          );
        }),
        _buildSlider(
          'Bubble Radius',
          _theme.receiverBubble.radiusTopLeft,
          0,
          32,
          (v) {
            _updateTheme(
              _theme.copyWith(
                receiverBubble: _theme.receiverBubble.copyWith(
                  radiusTopLeft: v,
                  radiusTopRight: v,
                  radiusBottomLeft: v,
                  radiusBottomRight: v,
                ),
              ),
            );
          },
        ),
      ],
    );
  }


  Widget _buildTypographyPanel() {
    return _buildCustomizationCard(
      title: 'Typography',
      icon: Icons.text_fields,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _fontOptions.contains(_theme.textTheme.fontFamily)
              ? _theme.textTheme.fontFamily
              : 'Roboto',
          decoration: InputDecoration(
            labelText: 'Font Family',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: _fontOptions.map((f) {
            TextStyle style;
            try {
              style = GoogleFonts.getFont(f, fontSize: 14);
            } catch (_) {
              style = TextStyle(fontFamily: f, fontSize: 14);
            }
            return DropdownMenuItem(
              value: f,
              child: Text(f, style: style),
            );
          }).toList(),
          onChanged: (f) {
            if (f != null) {
              _updateTheme(
                _theme.copyWith(
                  textTheme: _theme.textTheme.copyWith(fontFamily: f),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 8),
        _buildColorRow(
          'Sender Text Color',
          _theme.textTheme.senderMessageColor,
          (c) {
            _updateTheme(
              _theme.copyWith(
                textTheme: _theme.textTheme.copyWith(senderMessageColor: c),
              ),
            );
          },
        ),
        _buildColorRow(
          'Receiver Text Color',
          _theme.textTheme.receiverMessageColor,
          (c) {
            _updateTheme(
              _theme.copyWith(
                textTheme: _theme.textTheme.copyWith(receiverMessageColor: c),
              ),
            );
          },
        ),
        _buildColorRow('Timestamp Color', _theme.textTheme.timestampColor, (c) {
          _updateTheme(
            _theme.copyWith(
              textTheme: _theme.textTheme.copyWith(timestampColor: c),
            ),
          );
        }),
      ],
    );
  }


  Widget _buildBackgroundPanel() {
    return _buildCustomizationCard(
      title: 'Chat Background',
      icon: Icons.wallpaper,
      children: [
        _buildColorRow('Background Color', _theme.backgroundTheme.solidColor, (
          c,
        ) {
          _updateTheme(
            _theme.copyWith(
              backgroundTheme: _theme.backgroundTheme.copyWith(solidColor: c),
            ),
          );
        }),
      ],
    );
  }
}
