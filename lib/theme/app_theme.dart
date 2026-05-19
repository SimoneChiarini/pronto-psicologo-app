import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Backgrounds ──────────────────────────────────────────────
  static const bg              = Color(0xFFFFFFFF);  // content area
  static const surface         = Color(0xFFFAFAFA);  // topbar, subtle surfaces
  static const bgPanel         = Color(0xFFF7F7F7);  // sub-nav, panels
  static const bgInverse       = Color(0xFF0A0A0A);  // rail, primary buttons
  static const bgInverseHover  = Color(0xFF232323);  // active rail item

  // ── Borders ──────────────────────────────────────────────────
  static const glassBorder   = Color(0xFFE5E5E5);   // main borders (compat alias)
  static const borderSubtle  = Color(0xFFECECEC);   // subtle dividers
  static const borderFaint   = Color(0xFFF2F2F2);   // table row borders
  static const glassStroke   = Color(0xFFD4D4D4);   // input focus / stronger border

  // ── Text ─────────────────────────────────────────────────────
  static const textPrimary     = Color(0xFF111111);  // main text
  static const textStrong      = Color(0xFF0A0A0A);  // headings, key numbers
  static const textSecondary   = Color(0xFF666666);  // secondary / muted
  static const textTertiary    = Color(0xFF888888);  // faint / labels
  static const textInverse     = Color(0xFFFFFFFF);  // text on dark bg
  static const textPlaceholder = Color(0xFF999999);  // placeholder

  // ── Legacy aliases (old names → new values, keeps existing code working) ──
  static const glassBg = bgPanel;     // #F7F7F7
  static const primary = bgInverse;   // #0A0A0A  (black as the single accent)

  // ── Functional feedback colors (kept for forms/snackbars) ────
  static const star    = Color(0xFFFFC107);
  static const error   = Color(0xFFFF5252);
  static const success = Color(0xFF4AC98A);
}

class AppTheme {
  static TextTheme _base() => GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textStrong,
  );

  static ThemeData get dark {
    final base = _base();

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.bgInverse,
        onPrimary: AppColors.textInverse,
        secondary: AppColors.textSecondary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      useMaterial3: true,
      textTheme: base,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textStrong,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.01,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.bgInverse,
          foregroundColor: AppColors.textInverse,
          disabledBackgroundColor: const Color(0xFFD4D4D4),
          disabledForegroundColor: AppColors.textPlaceholder,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.glassStroke),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        hintStyle: const TextStyle(color: AppColors.textPlaceholder, fontSize: 12),
        prefixIconColor: AppColors.textTertiary,
        suffixIconColor: AppColors.textTertiary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.textPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.glassBorder,
        space: 1,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textTertiary, size: 16),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textTertiary,
        textColor: AppColors.textPrimary,
        subtitleTextStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
        tileColor: Colors.transparent,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.textStrong,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.bgInverse,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.textInverse : AppColors.textTertiary),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.bgInverse : AppColors.borderSubtle),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.bgInverse,
        contentTextStyle: GoogleFonts.inter(color: AppColors.textInverse, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        titleTextStyle: GoogleFonts.inter(
            color: AppColors.textStrong, fontSize: 15, fontWeight: FontWeight.w600),
        contentTextStyle: GoogleFonts.inter(
            color: AppColors.textSecondary, fontSize: 13),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.bgInverse,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bg,
        selectedColor: AppColors.bgInverse,
        disabledColor: AppColors.surface,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textPrimary),
        secondaryLabelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textInverse),
        side: const BorderSide(color: AppColors.glassBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        checkmarkColor: AppColors.textInverse,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.bg),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          elevation: WidgetStateProperty.all(0),
          side: WidgetStateProperty.all(const BorderSide(color: AppColors.glassBorder)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ),
    );
  }
}

// ─── Categorie specializzazioni ────────────────────────────────────────────────

class SpecCategory {
  final String label;
  final IconData icon;
  final Map<String, String> specs;
  const SpecCategory({required this.label, required this.icon, required this.specs});
}

const kSpecCategories = <SpecCategory>[
  SpecCategory(
    label: 'Emozioni e benessere',
    icon: Icons.mood_rounded,
    specs: {
      'specAnsia': 'Ansia',
      'specUmore': 'Umore / depressione',
      'specStress': 'Stress / lavoro',
    },
  ),
  SpecCategory(
    label: 'Relazioni',
    icon: Icons.favorite_border_rounded,
    specs: {
      'specCoppia': 'Coppia',
      'specRelazioni': 'Relazioni',
      'specSessualita': 'Sessualità',
    },
  ),
  SpecCategory(
    label: 'Famiglia',
    icon: Icons.family_restroom_rounded,
    specs: {
      'specGenitorialita': 'Genitorialità',
      'specInfanzia': 'Infanzia / adolescenza',
    },
  ),
  SpecCategory(
    label: 'Identità e crescita',
    icon: Icons.self_improvement_rounded,
    specs: {
      'specAutostima': 'Autostima',
      'specTrauma': 'Trauma',
      'specLutto': 'Lutto',
    },
  ),
  SpecCategory(
    label: 'Difficoltà specifiche',
    icon: Icons.medical_services_outlined,
    specs: {
      'specDisturbiAlimentari': 'Disturbi alimentari',
      'specDipendenze': 'Dipendenze',
      'specNeurodivergenze': 'Neurodivergenze',
    },
  ),
];
