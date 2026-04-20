import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg          = Color(0xFF0C0C0C);
  static const surface     = Color(0xFF161616);
  static const glassBg     = Color(0x12FFFFFF);
  static const glassBorder = Color(0x1FFFFFFF);
  static const glassStroke = Color(0x33FFFFFF);
  static const textPrimary   = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9E9E9E);
  static const textTertiary  = Color(0xFF5E5E5E);
  static const star  = Color(0xFFFFC107);
  static const error = Color(0xFFFF5252);
  static const success = Color(0xFF4AC98A);
}

class AppTheme {
  static ThemeData get dark {
    final base = GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.textPrimary,
        onPrimary: AppColors.bg,
        secondary: AppColors.textSecondary,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      useMaterial3: true,
      textTheme: base,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        titleTextStyle: GoogleFonts.dmSans(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textPrimary,
          foregroundColor: AppColors.bg,
          disabledBackgroundColor: AppColors.textTertiary,
          disabledForegroundColor: AppColors.bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          elevation: 0,
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.glassBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassBg,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.glassStroke, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.glassBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.glassBorder,
        space: 1,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        subtitleTextStyle: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.textPrimary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.bg : AppColors.textSecondary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.textPrimary : AppColors.glassBorder),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: GoogleFonts.dmSans(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF141414),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF141414),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.dmSans(
            color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
        contentTextStyle: GoogleFonts.dmSans(
            color: AppColors.textSecondary, fontSize: 14),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.textPrimary,
      ),
    );
  }
}
