import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFF9B8FF5);
  static const Color primaryDark = Color(0xFF4A3CB5);

  // Secondary
  static const Color secondary = Color(0xFF00CEC9);
  static const Color secondaryLight = Color(0xFF55EFC4);

  // Accent
  static const Color accent = Color(0xFFFF7675);
  static const Color accentOrange = Color(0xFFFD9644);
  static const Color accentYellow = Color(0xFFFECA57);
  static const Color accentGreen = Color(0xFF26DE81);

  // Neutrals
  static const Color background = Color(0xFF0F0E1A);
  static const Color surface = Color(0xFF1A1931);
  static const Color surfaceCard = Color(0xFF22203C);
  static const Color surfaceElevated = Color(0xFF2C2A4A);

  static const Color textPrimary = Color(0xFFF8F7FF);
  static const Color textSecondary = Color(0xFFB0AECB);
  static const Color textHint = Color(0xFF6B6990);

  static const Color divider = Color(0xFF2D2B4E);
  static const Color border = Color(0xFF3D3B6E);

  // Status colors
  static const Color success = Color(0xFF26DE81);
  static const Color warning = Color(0xFFFECA57);
  static const Color error = Color(0xFFFF7675);
  static const Color info = Color(0xFF45AAF2);

  // Light mode
  static const Color lightBackground = Color(0xFFF5F5FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceCard = Color(0xFFF0EEFF);
  static const Color lightTextPrimary = Color(0xFF1A1931);
  static const Color lightTextSecondary = Color(0xFF6B6990);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF9B8FF5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [background, Color(0xFF12102A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [surfaceCard, surfaceElevated],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Poppins',
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.surfaceCard,
      dividerColor: AppColors.divider,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            );
          }
          return const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: AppColors.textHint,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return const IconThemeData(color: AppColors.textHint, size: 24);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontFamily: 'Poppins',
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceCard,
        selectedColor: AppColors.primary.withOpacity(0.3),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: AppColors.surfaceCard,
        textColor: AppColors.textPrimary,
        iconColor: AppColors.textSecondary,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        displayMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        displaySmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        headlineLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontFamily: 'Poppins', color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary),
        bodySmall: TextStyle(fontFamily: 'Poppins', color: AppColors.textHint, fontSize: 12),
        labelLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        labelMedium: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary),
        labelSmall: TextStyle(fontFamily: 'Poppins', color: AppColors.textHint, fontSize: 10),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Poppins',
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
    );
  }
}
