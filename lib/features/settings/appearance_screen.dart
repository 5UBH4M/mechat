import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/theme_controller.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildThemeTile(
            context,
            ref,
            title: 'Light Theme',
            icon: Icons.light_mode_rounded,
            themeType: AppThemeType.light,
            currentTheme: themeMode,
          ),
          _buildThemeTile(
            context,
            ref,
            title: 'Dark Theme',
            icon: Icons.dark_mode_rounded,
            themeType: AppThemeType.dark,
            currentTheme: themeMode,
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Divider(thickness: 0.5),
          ),
          ListTile(
            leading: Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
            title: const Text('Advanced Customization', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Terminal, Cyberpunk, Old Phone & custom themes'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () {
              context.push('/custom-theme');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required IconData icon,
    required AppThemeType themeType,
    required AppThemeType currentTheme,
  }) {
    final theme = Theme.of(context);
    final isSelected = currentTheme == themeType;

    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6)),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
          : null,
      onTap: () {
        if (themeType == AppThemeType.light || themeType == AppThemeType.dark) {
          // Just change the brightness mode, keep the advanced theme
          ref.read(themeModeProvider.notifier).setTheme(themeType);
        } else {
          // Standard full themes (Terminal, Cyberpunk, Old Phone)
          // Set the old theme mode
          ref.read(themeModeProvider.notifier).setTheme(themeType);
          
          // Also try to find a matching advanced theme to keep things perfectly synced
          if (themeType == AppThemeType.terminal) {
            ref.read(themeControllerProvider.notifier).setGlobalTheme('terminal');
          } else if (themeType == AppThemeType.cyberpunk) {
            ref.read(themeControllerProvider.notifier).setGlobalTheme('cyberpunk');
          } else if (themeType == AppThemeType.oldPhone) {
            ref.read(themeControllerProvider.notifier).setGlobalTheme('oldphone');
          } else {
            ref.read(themeControllerProvider.notifier).setGlobalTheme('material3');
          }
        }
      },
    );
  }
}
