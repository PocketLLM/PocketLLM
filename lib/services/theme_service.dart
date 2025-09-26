/// File Overview:
/// - Purpose: Centralized theme manager that persists color preferences and
///   exposes Material `ThemeData` configurations to the app.
/// - Backend Migration: Keep; consider allowing the backend to push branding
///   metadata instead of forcing local defaults.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';

enum AppThemeMode {
  light,
  dark,
  system,
  highContrast,
}

enum ColorSchemeType {
  standard,
  highContrast,
  custom,
}

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _themeModeKey = 'theme_mode';
  static const String _colorSchemeTypeKey = 'color_scheme_type';
  static const String _systemThemeKey = 'follow_system_theme';

  AppThemeMode _themeMode = AppThemeMode.light;
  ColorSchemeType _colorSchemeType = ColorSchemeType.standard;
  bool _followSystemTheme = false;
  Brightness _systemBrightness = Brightness.light;
  
  AppThemeMode get themeMode => _themeMode;
  ColorSchemeType get colorSchemeType => _colorSchemeType;
  bool get followSystemTheme => _followSystemTheme;
  bool get isDarkMode => _getEffectiveBrightness() == Brightness.dark;
  Brightness get effectiveBrightness => _getEffectiveBrightness();
  AppColorScheme get colorScheme => _getCurrentColorScheme();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Always start in light mode while dark mode is not implemented.
    _themeMode = AppThemeMode.light;
    _colorSchemeType = ColorSchemeType.standard;
    _followSystemTheme = false;
    _systemBrightness = Brightness.light;

    await prefs.setInt(_themeModeKey, AppThemeMode.light.index);
    await prefs.setInt(_colorSchemeTypeKey, ColorSchemeType.standard.index);
    await prefs.setBool(_systemThemeKey, false);

    _updateSystemStatusBar();

    notifyListeners();
  }

  void _updateSystemBrightness() {
    _systemBrightness = Brightness.light;
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    // Persist the request but keep the app in light mode until dark mode is supported.
    _themeMode = AppThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, AppThemeMode.light.index);

    _updateSystemStatusBar();
    notifyListeners();
  }
  
  Future<void> setColorSchemeType(ColorSchemeType type) async {
    if (_colorSchemeType == type) return;

    _colorSchemeType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorSchemeTypeKey, type.index);

    notifyListeners();
  }

  Future<void> setFollowSystemTheme(bool follow) async {
    if (_followSystemTheme == false) return;

    _followSystemTheme = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_systemThemeKey, false);

    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    await setThemeMode(AppThemeMode.light);
  }

  void updateSystemBrightness(Brightness brightness) {
    if (_systemBrightness == Brightness.light) return;

    _systemBrightness = Brightness.light;
  }

  Brightness _getEffectiveBrightness() => Brightness.light;

  void _updateSystemStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  AppColorScheme _getColorSchemeForBrightness(Brightness brightness) {
    switch (_colorSchemeType) {
      case ColorSchemeType.highContrast:
        return brightness == Brightness.dark
            ? AppThemeColors.darkHighContrast
            : AppThemeColors.lightHighContrast;
      case ColorSchemeType.custom:
      case ColorSchemeType.standard:
        return brightness == Brightness.dark
            ? AppThemeColors.dark
            : AppThemeColors.light;
    }
  }

  AppColorScheme _getCurrentColorScheme() =>
      _getColorSchemeForBrightness(_getEffectiveBrightness());

  ThemeData get currentTheme {
    final brightness = _getEffectiveBrightness();
    return _buildThemeData(brightness, _getColorSchemeForBrightness(brightness));
  }

  ThemeData get lightTheme =>
      _buildThemeData(Brightness.light, AppThemeColors.light);

  ThemeData get darkTheme =>
      _buildThemeData(Brightness.dark, AppThemeColors.dark);
  
  ThemeData _buildThemeData(Brightness brightness, AppColorScheme colorScheme) {
    final isDark = brightness == Brightness.dark;
    
    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      
      // Color scheme
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colorScheme.primary,
        onPrimary: colorScheme.onPrimary,
        secondary: colorScheme.secondary,
        onSecondary: colorScheme.onSecondary,
        error: colorScheme.error,
        onError: colorScheme.onError,
        surface: colorScheme.surface,
        onSurface: colorScheme.onSurface,
        background: colorScheme.background,
        onBackground: colorScheme.onBackground,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: colorScheme.background,
      
      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: colorScheme.shadow,
        surfaceTintColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Cards
      cardTheme: CardTheme(
        color: colorScheme.cardBackground,
        shadowColor: colorScheme.shadow,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.cardBorder, width: 0.5),
        ),
      ),
      
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        hintStyle: TextStyle(color: colorScheme.hint),
        labelStyle: TextStyle(color: colorScheme.onSurface),
      ),
      
      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 2,
          shadowColor: colorScheme.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: colorScheme.divider,
        thickness: 0.5,
      ),
      
      // List tile
      listTileTheme: ListTileThemeData(
        tileColor: colorScheme.surface,
        textColor: colorScheme.onSurface,
        iconColor: colorScheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      // Dialog
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.primary,
        elevation: 8,
        shadowColor: colorScheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.primary,
        elevation: 8,
        shadowColor: colorScheme.shadow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      
      // Snack bar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[900],
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
