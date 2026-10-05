import 'package:flutter/material.dart';

/// Colours from the website. Brand tokens and hex literals come from `src/index.css` and the JSX.
/// Tailwind palette colours use tailwindcss 4.3.3's OKLCH values converted to sRGB hex,
/// so they match what the website renders (v4 greys and reds differ from v3).
abstract final class AppColors {
  // Brand tokens (index.css @theme)
  static const sand = Color(0xFFF9FAFC);
  static const forest = Color(0xFF07571C);
  static const terracotta = Color(0xFFE07A5F);
  static const charcoal = Color(0xFF3D4035);
  static const earth = Color(0xFFE5E7EB);

  // Hex literals used in the website's components
  static const gold = Color(0xFFF0C169);
  static const bannerGreen = Color(0xFF0F5A27);
  static const lime = Color(0xFFA3D977);
  static const authButton = Color(0xFF324329);
  static const authButtonPressed = Color(0xFF1A2315);
  static const darkText = Color(0xFF1D2B15);
  static const chartTerracotta = Color(0xFFC05A3B);
  static const healthGood = Color(0xFF22C55E);
  static const healthAverage = Color(0xFFEAB308);
  static const healthPoor = Color(0xFFEF4444);
  static const seedOrange = Color(0xFFF97316);
  static const avatar = Color(0xFF2D5A27);

  // Tailwind v4 palette (as rendered by the website)
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DC);
  static const gray400 = Color(0xFF99A1AF);
  static const gray500 = Color(0xFF6A7282);
  static const gray600 = Color(0xFF4A5565);
  static const gray700 = Color(0xFF364153);
  static const gray800 = Color(0xFF1E2939);
  static const gray900 = Color(0xFF101828);
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCAD5E2);
  static const slate400 = Color(0xFF90A1B9);
  static const slate500 = Color(0xFF62748E);
  static const slate600 = Color(0xFF45556C);
  static const slate700 = Color(0xFF314158);
  static const slate800 = Color(0xFF1D293D);
  static const slate900 = Color(0xFF0F172B);
  static const red50 = Color(0xFFFEF2F2);
  static const red100 = Color(0xFFFFE2E2);
  static const red500 = Color(0xFFFB2C36);
  static const red600 = Color(0xFFE7000B);
  static const red700 = Color(0xFFC10007);
  static const red800 = Color(0xFF9F0712);
  static const green50 = Color(0xFFF0FDF4);
  static const green100 = Color(0xFFDCFCE7);
  static const green200 = Color(0xFFB9F8CF);
  static const green500 = Color(0xFF00C950);
  static const emerald100 = Color(0xFFD0FAE5);
  static const emerald200 = Color(0xFFA4F4CF);
  static const amber50 = Color(0xFFFFFBEB);
  static const amber100 = Color(0xFFFEF3C6);
  static const amber200 = Color(0xFFFEE685);
  static const amber500 = Color(0xFFFE9A00);
  static const amber600 = Color(0xFFE17100);
  static const amber700 = Color(0xFFBB4D00);
  static const sky50 = Color(0xFFF0F9FF);
  static const sky500 = Color(0xFF00A6F4);
  static const blue50 = Color(0xFFEFF6FF);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue500 = Color(0xFF2B7FFF);
  static const blue600 = Color(0xFF155DFC);
  static const blue700 = Color(0xFF1447E6);
  static const rose200 = Color(0xFFFFCCD3);
  static const rose500 = Color(0xFFFF2056);
  static const rose700 = Color(0xFFC70036);
  static const teal50 = Color(0xFFF0FDFA);
  static const teal500 = Color(0xFF00BBA7);
  static const teal600 = Color(0xFF009689);
  static const orange400 = Color(0xFFFF8904);
  static const orange500 = Color(0xFFFF6900);
  static const yellow400 = Color(0xFFFDC700);
  static const yellow500 = Color(0xFFF0B100);
  static const purple50 = Color(0xFFFAF5FF);
  static const purple100 = Color(0xFFF3E8FF);
  static const purple400 = Color(0xFFC27AFF);
  static const purple500 = Color(0xFFAD46FF);
  static const purple600 = Color(0xFF9810FA);
  static const purple700 = Color(0xFF8200DB);
  static const purple800 = Color(0xFF6E11B0);
  static const purple900 = Color(0xFF59168B);

  // Semantic aliases
  static const muted = gray500;
  static const danger = red500;
}

/// Fonts are bundled (assets/fonts): Inter for text, Plus Jakarta Sans for headings,
/// Noto Nastaliq Urdu in Urdu. Each falls back to the other script's font.
ThemeData buildAppTheme(String languageCode) {
  // Seeded, then flattened: the website has no Material tonal tints, only white surfaces.
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.forest,
    primary: AppColors.forest,
    onPrimary: Colors.white,
    secondary: AppColors.terracotta,
    surface: Colors.white,
    onSurface: AppColors.charcoal,
    error: AppColors.red500,
  ).copyWith(
    surfaceTint: Colors.transparent,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Colors.white,
    surfaceContainer: Colors.white,
    surfaceContainerHigh: Colors.white,
    surfaceContainerHighest: Colors.white,
    onSurfaceVariant: AppColors.gray500,
    outline: AppColors.earth,
    outlineVariant: AppColors.gray100,
  );
  final pressed = AppColors.forest.withValues(alpha: 0.1); // hover:bg-forest/10
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: languageCode == 'ur' ? 'NotoNastaliqUrdu' : 'Inter',
    fontFamilyFallback: languageCode == 'ur' ? const ['Inter'] : const ['NotoNastaliqUrdu'],
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.sand,
    canvasColor: Colors.white,
    splashColor: pressed,
    highlightColor: pressed,
    hoverColor: pressed,
    dividerColor: AppColors.earth,
  );
  final textTheme = _textTheme(
    base.textTheme.apply(bodyColor: AppColors.charcoal, displayColor: AppColors.charcoal),
    languageCode,
  );
  final radius12 = BorderRadius.circular(12);
  // index.css forces a forest border on every input; focus adds ring-1, so 2px total.
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: radius12,
        borderSide: BorderSide(color: color, width: width),
      );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.charcoal,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.earth),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: radius12,
        side: const BorderSide(color: AppColors.gray100),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.forest,
      selectionColor: AppColors.forest.withValues(alpha: 0.2),
      selectionHandleColor: AppColors.forest,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.forest),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      // Tailwind v4 placeholders are the text colour at 50%.
      hintStyle: TextStyle(color: AppColors.charcoal.withValues(alpha: 0.5), fontSize: 14),
      errorStyle: const TextStyle(color: AppColors.red500, fontWeight: FontWeight.w700, fontSize: 14),
      prefixIconColor: AppColors.gray400,
      suffixIconColor: AppColors.gray400,
      border: border(AppColors.forest),
      enabledBorder: border(AppColors.forest),
      focusedBorder: border(AppColors.forest, 2),
      errorBorder: border(AppColors.red500),
      focusedErrorBorder: border(AppColors.red500, 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: radius12),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.forest,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Line height for Urdu (Nastaliq) text.
const double urduLineHeight = 1.9;

TextTheme _textTheme(TextTheme base, String languageCode) {
  if (languageCode == 'ur') {
    final ur = base.apply(fontFamily: 'NotoNastaliqUrdu', fontFamilyFallback: const ['Inter']);
    // Material's line heights (about 1.4x, and MaterialApp merges them back in for any style
    // that leaves height unset) are made for Latin text. Nastaliq is much taller, so two lines
    // that close overlap. 1.9x keeps stacked Urdu lines apart.
    TextStyle? tall(TextStyle? style) => style?.copyWith(height: urduLineHeight);
    return TextTheme(
      displayLarge: tall(ur.displayLarge),
      displayMedium: tall(ur.displayMedium),
      displaySmall: tall(ur.displaySmall),
      headlineLarge: tall(ur.headlineLarge),
      headlineMedium: tall(ur.headlineMedium),
      headlineSmall: tall(ur.headlineSmall),
      titleLarge: tall(ur.titleLarge),
      titleMedium: tall(ur.titleMedium),
      titleSmall: tall(ur.titleSmall),
      bodyLarge: tall(ur.bodyLarge),
      bodyMedium: tall(ur.bodyMedium),
      bodySmall: tall(ur.bodySmall),
      labelLarge: tall(ur.labelLarge),
      labelMedium: tall(ur.labelMedium),
      labelSmall: tall(ur.labelSmall),
    );
  }
  final body = base.apply(fontFamily: 'Inter', fontFamilyFallback: const ['NotoNastaliqUrdu']);
  final heading = base.apply(fontFamily: 'PlusJakartaSans', fontFamilyFallback: const ['Inter', 'NotoNastaliqUrdu']);
  return body.copyWith(
    displayLarge: heading.displayLarge,
    displayMedium: heading.displayMedium,
    displaySmall: heading.displaySmall,
    headlineLarge: heading.headlineLarge,
    headlineMedium: heading.headlineMedium,
    headlineSmall: heading.headlineSmall,
    titleLarge: heading.titleLarge,
  );
}
