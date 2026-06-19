import 'package:flutter/material.dart';
import 'custom_theme_model.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryDark = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF4F46E5);
  
  static const Color secondaryDark = Color(0xFF14B8A6); // Teal
  static const Color secondaryLight = Color(0xFF0D9488);

  static const Color bgDark = Color(0xFF0E131F); // Dark slate
  static const Color bgLight = Color(0xFFF8FAFC); // Very light slate

  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color surfaceLight = Color(0xFFFFFFFF);

  static const Color accentColor = Color(0xFFF43F5E); // Rose (calls/delete)

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: secondaryDark,
        surface: surfaceDark,
        error: accentColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFE2E8F0),
      ),
      scaffoldBackgroundColor: bgDark,
      cardTheme: const CardThemeData(
        color: surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFFF1F5F9)),
        titleTextStyle: TextStyle(
          color: Color(0xFFF1F5F9),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentColor, width: 1.5),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFF1F5F9)),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF1F5F9)),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFF1F5F9)),
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFFE2E8F0)),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        secondary: secondaryLight,
        surface: surfaceLight,
        error: accentColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF334155),
      ),
      scaffoldBackgroundColor: bgLight,
      cardTheme: const CardThemeData(
        color: surfaceLight,
        elevation: 1,
        shadowColor: Color(0x0F000000),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgLight,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentColor, width: 1.5),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
        bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF334155)),
        bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
      ),
    );
  }

  static ThemeData get terminalTheme {
    const Color bg = Colors.black;
    const Color fg = Colors.white;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: fg,
        secondary: fg,
        surface: bg,
        error: fg,
        onPrimary: bg,
        onSecondary: bg,
        onSurface: fg,
      ),
      scaffoldBackgroundColor: bg,
      cardTheme: const CardThemeData(
        color: bg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: fg, width: 1),
          borderRadius: BorderRadius.zero,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: fg),
        titleTextStyle: TextStyle(
          color: fg,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: fg, width: 1),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: bg,
        hintStyle: TextStyle(color: Colors.white54, fontFamily: 'monospace'),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: fg, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: fg, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: fg, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: fg, width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: fg, fontFamily: 'monospace'),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: fg, fontFamily: 'monospace'),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: fg, fontFamily: 'monospace'),
        bodyLarge: TextStyle(fontSize: 16, color: fg, fontFamily: 'monospace'),
        bodyMedium: TextStyle(fontSize: 14, color: fg, fontFamily: 'monospace'),
        labelLarge: TextStyle(fontFamily: 'monospace', color: fg),
        labelMedium: TextStyle(fontFamily: 'monospace', color: fg),
        labelSmall: TextStyle(fontFamily: 'monospace', color: fg),
      ),
    );
  }

  static ThemeData get oldPhoneTheme {
    const Color bg = Color(0xFF869D8A); // Classic greenish-grey Nokia screen
    const Color fg = Color(0xFF1E2124); // Dark pixels
    const Color surface = Color(0xFF7D9381); // Slightly darker green-grey for surface
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: fg,
        secondary: fg,
        surface: surface,
        error: fg,
        onPrimary: bg,
        onSecondary: bg,
        onSurface: fg,
      ),
      scaffoldBackgroundColor: bg,
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: fg, width: 2),
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: fg),
        titleTextStyle: TextStyle(
          color: fg,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          letterSpacing: 2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: surface,
          foregroundColor: fg,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: fg, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            letterSpacing: 1,
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: Color(0x991E2124), fontFamily: 'monospace'),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: fg, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: fg, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: fg, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: fg, width: 2),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: fg, fontFamily: 'monospace'),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: fg, fontFamily: 'monospace'),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: fg, fontFamily: 'monospace'),
        bodyLarge: TextStyle(fontSize: 16, color: fg, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
        bodyMedium: TextStyle(fontSize: 14, color: fg, fontWeight: FontWeight.w700, fontFamily: 'monospace'),
        labelLarge: TextStyle(fontFamily: 'monospace', color: fg, fontWeight: FontWeight.w700),
        labelMedium: TextStyle(fontFamily: 'monospace', color: fg, fontWeight: FontWeight.w700),
        labelSmall: TextStyle(fontFamily: 'monospace', color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }

  static ThemeData buildCustomTheme(CustomThemeModel model) {
    return ThemeData(
      useMaterial3: true,
      brightness: ThemeData.estimateBrightnessForColor(model.backgroundColor),
      colorScheme: ColorScheme(
        brightness: ThemeData.estimateBrightnessForColor(model.backgroundColor),
        primary: model.primaryColor,
        onPrimary: ThemeData.estimateBrightnessForColor(model.primaryColor) == Brightness.dark ? Colors.white : Colors.black87,
        secondary: model.secondaryColor,
        onSecondary: Colors.white,
        surface: model.surfaceColor,
        onSurface: ThemeData.estimateBrightnessForColor(model.surfaceColor) == Brightness.dark ? Colors.white : Colors.black87,
        error: accentColor,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: model.backgroundColor,
      cardTheme: CardThemeData(
        color: model.surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(model.bubbleRadius)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: model.backgroundColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: ThemeData.estimateBrightnessForColor(model.backgroundColor) == Brightness.dark ? Colors.white : Colors.black87),
        titleTextStyle: TextStyle(
          color: ThemeData.estimateBrightnessForColor(model.backgroundColor) == Brightness.dark ? Colors.white : Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: model.fontFamily,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: model.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(model.bubbleRadius),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: model.fontFamily,
          ),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: model.fontFamily),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: model.fontFamily),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, fontFamily: model.fontFamily),
        bodyLarge: TextStyle(fontSize: 16, fontFamily: model.fontFamily),
        bodyMedium: TextStyle(fontSize: 14, fontFamily: model.fontFamily),
      ).apply(
        bodyColor: ThemeData.estimateBrightnessForColor(model.surfaceColor) == Brightness.dark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
        displayColor: ThemeData.estimateBrightnessForColor(model.surfaceColor) == Brightness.dark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
      ),
    );
  }

  static ThemeData get cyberpunkTheme {
    return buildCustomTheme(const CustomThemeModel(
      primaryColor: Color(0xFFFCE205),
      secondaryColor: Color(0xFFFF003C),
      backgroundColor: Color(0xFF0D0D0D),
      surfaceColor: Color(0xFF1A1A1A),
      fontFamily: 'monospace',
      bubbleRadius: 0.0,
    ));
  }
}
