import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppColors {
  static const paper = Color(0xFFF4EFE6);
  static const card = Color(0xFFFFFBF6);
  static const line = Color(0xFFE3D6C4);
  static const ink = Color(0xFF1E1A16);
  static const inkSoft = Color(0xFF6B6158);
  static const cinnabar = Color(0xFF8E2F2A);
  static const bronze = Color(0xFF8A6A3B);
  static const moss = Color(0xFF2F5D45);
}

abstract final class AppTheme {
  static const overlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.card,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.cinnabar,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.cinnabar,
      onPrimary: Colors.white,
      secondary: AppColors.bronze,
      onSecondary: Colors.white,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paper,
      splashColor: AppColors.cinnabar.withValues(alpha: 0.08),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: overlay,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        height: 68,
        elevation: 0,
        indicatorColor: AppColors.cinnabar.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.cinnabar : AppColors.inkSoft,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.cinnabar : AppColors.inkSoft,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.cinnabar,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.cinnabar),
      ),
      inputDecorationTheme: const InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: TextStyle(color: AppColors.inkSoft),
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppColors.cinnabar, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.cinnabar,
        disabledColor: AppColors.paper,
        side: const BorderSide(color: AppColors.line),
        labelStyle: const TextStyle(color: AppColors.ink),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: AppColors.card),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        dragHandleColor: AppColors.line,
      ),
      dividerColor: AppColors.line,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.cinnabar;
            }
            return AppColors.card;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return AppColors.ink;
          }),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.line)),
        ),
      ),
    );
  }
}
