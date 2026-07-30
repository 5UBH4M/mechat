import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/custom_theme_model.dart';

class CustomThemeScreen extends ConsumerStatefulWidget {
  const CustomThemeScreen({super.key});

  @override
  ConsumerState<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends ConsumerState<CustomThemeScreen> {
  late CustomThemeModel _tempTheme;

  final List<Color> _availableColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    const Color(0xFF0E131F),
    const Color(0xFFF8FAFC),
    const Color(0xFF1E293B),
    Colors.white,
    Colors.black,
  ];

  final List<String> _availableFonts = [
    'Roboto',
    'monospace',
    'serif',
    'sans-serif',
    'sans-serif-condensed',
    'sans-serif-medium',
    'sans-serif-light',
    'cursive',
  ];

  @override
  void initState() {
    super.initState();
    _tempTheme = ref.read(customThemeProvider);
  }

  void _saveTheme() {
    ref.read(customThemeProvider.notifier).updateTheme(_tempTheme);
    ref.read(themeModeProvider.notifier).setTheme(AppThemeType.custom);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Theme Builder'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveTheme),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThemePreview(),
            const SizedBox(height: 24),
            _buildSectionHeader('Sender Bubble Color'),
            _buildColorPicker(
              selectedColor: _tempTheme.primaryColor,
              onColorSelected: (c) => setState(
                () => _tempTheme = _tempTheme.copyWith(primaryColor: c),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Sender Text Color'),
            _buildColorPicker(
              selectedColor: _tempTheme.senderTextColor,
              onColorSelected: (c) => setState(
                () => _tempTheme = _tempTheme.copyWith(senderTextColor: c),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Accent Color (Switches & Highlights)'),
            _buildColorPicker(
              selectedColor: _tempTheme.secondaryColor,
              onColorSelected: (c) => setState(
                () => _tempTheme = _tempTheme.copyWith(secondaryColor: c),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('App Background Color'),
            _buildColorPicker(
              selectedColor: _tempTheme.backgroundColor,
              onColorSelected: (c) => setState(
                () => _tempTheme = _tempTheme.copyWith(backgroundColor: c),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Receiver Bubble Color'),
            _buildColorPicker(
              selectedColor: _tempTheme.receiverBubbleColor,
              onColorSelected: (c) => setState(
                () => _tempTheme = _tempTheme.copyWith(receiverBubbleColor: c),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('Receiver Text Color'),
            _buildColorPicker(
              selectedColor: _tempTheme.receiverTextColor,
              onColorSelected: (c) => setState(
                () => _tempTheme = _tempTheme.copyWith(receiverTextColor: c),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader('App Font / Text Style'),
            Wrap(
              spacing: 8,
              children: _availableFonts.map((f) {
                return ChoiceChip(
                  label: Text(f, style: TextStyle(fontFamily: f)),
                  selected: _tempTheme.fontFamily == f,
                  onSelected: (selected) {
                    if (selected) {
                      setState(
                        () => _tempTheme = _tempTheme.copyWith(fontFamily: f),
                      );
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(
              'Chat Bubble Radius (${_tempTheme.bubbleRadius.toInt()})',
            ),
            Slider(
              value: _tempTheme.bubbleRadius,
              min: 0,
              max: 32,
              divisions: 32,
              label: _tempTheme.bubbleRadius.toInt().toString(),
              onChanged: (val) {
                setState(
                  () => _tempTheme = _tempTheme.copyWith(bubbleRadius: val),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildThemePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _tempTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Live Preview',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _tempTheme.backgroundColor.computeLuminance() > 0.5
                  ? Colors.black
                  : Colors.white,
              fontFamily: _tempTheme.fontFamily,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _tempTheme.receiverBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_tempTheme.bubbleRadius),
                  topRight: Radius.circular(_tempTheme.bubbleRadius),
                  bottomRight: Radius.circular(_tempTheme.bubbleRadius),
                ),
              ),
              child: Text(
                'Hi! Check out this new theme!',
                style: TextStyle(
                  color: _tempTheme.receiverTextColor,
                  fontFamily: _tempTheme.fontFamily,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _tempTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_tempTheme.bubbleRadius),
                  topRight: Radius.circular(_tempTheme.bubbleRadius),
                  bottomLeft: Radius.circular(_tempTheme.bubbleRadius),
                ),
              ),
              child: Text(
                'Wow, it looks fully customizable!',
                style: TextStyle(
                  color: _tempTheme.senderTextColor,
                  fontFamily: _tempTheme.fontFamily,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker({
    required Color selectedColor,
    required Function(Color) onColorSelected,
  }) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _availableColors.length,
        itemBuilder: (context, index) {
          final c = _availableColors[index];
          final isSelected = c.toARGB32() == selectedColor.toARGB32();
          return GestureDetector(
            onTap: () => onColorSelected(c),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : Colors.grey.withValues(alpha: 0.5),
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: c.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color:
                          ThemeData.estimateBrightnessForColor(c) ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
