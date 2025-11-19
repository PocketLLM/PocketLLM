/// File Overview:
/// - Purpose: Centralized theme manager that persists color preferences and
///   exposes Material `ThemeData` configurations to the app.
/// - Backend Migration: Keep; consider allowing the backend to push branding
///   metadata instead of forcing local defaults.
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/appearance_preferences.dart';
import '../models/theme_types.dart';
import '../theme/app_colors.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _preferencesKey = 'appearance.preferences';
  static const String _legacyThemeModeKey = 'theme_mode';
  static const String _legacyColorSchemeTypeKey = 'color_scheme_type';
  static const String _legacySystemThemeKey = 'follow_system_theme';

  SharedPreferences? _prefs;
  AppearancePreferences _preferences = const AppearancePreferences();
  Brightness _systemBrightness = Brightness.light;

  AppearancePreferences get preferences => _preferences;
  AppThemeMode get themeMode => _preferences.themeMode;
  ColorSchemeType get colorSchemeType => _preferences.colorSchemeType;
  bool get followSystemTheme => _preferences.followSystemTheme;
  bool get isDarkMode => effectiveBrightness == Brightness.dark;
  Brightness get effectiveBrightness => _getEffectiveBrightness();
  AppColorScheme get colorScheme => _getCurrentColorScheme();
  double get messageCornerRadius => _preferences.messageRadius.toDouble();
  ThemeMode get materialThemeMode =>
      _preferences.followSystemTheme || _preferences.themeMode == AppThemeMode.system
          ? ThemeMode.system
          : (_preferences.themeMode == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPreferences();
    _systemBrightness = PlatformDispatcher.instance.platformBrightness;
    PlatformDispatcher.instance.onPlatformBrightnessChanged = () {
      updateSystemBrightness(PlatformDispatcher.instance.platformBrightness);
    };
    _updateSystemStatusBar();
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    final stored = _prefs?.getString(_preferencesKey);
    if (stored != null && stored.isNotEmpty) {
      try {
        final decoded = jsonDecode(stored);
        if (decoded is Map<String, dynamic>) {
          _preferences = AppearancePreferences.fromMap(decoded);
          return;
        }
      } catch (_) {
        // Fall through to legacy migration.
      }
    }
    _preferences = _loadLegacyPreferences(_prefs);
    await _persistPreferences();
  }

  AppearancePreferences _loadLegacyPreferences(SharedPreferences? prefs) {
    if (prefs == null) {
      return const AppearancePreferences();
    }
    final themeIndex = prefs.getInt(_legacyThemeModeKey);
    final schemeIndex = prefs.getInt(_legacyColorSchemeTypeKey);
    final followSystem = prefs.getBool(_legacySystemThemeKey) ?? true;
    final theme = (themeIndex != null && themeIndex >= 0 && themeIndex < AppThemeMode.values.length)
        ? AppThemeMode.values[themeIndex]
        : AppThemeMode.system;
    final scheme = (schemeIndex != null && schemeIndex >= 0 && schemeIndex < ColorSchemeType.values.length)
        ? ColorSchemeType.values[schemeIndex]
        : ColorSchemeType.standard;
    return AppearancePreferences(
      themeMode: followSystem ? AppThemeMode.system : theme,
      followSystemTheme: followSystem,
      colorSchemeType: scheme,
    );
  }

  Future<void> _persistPreferences() async {
    final store = _prefs ??= await SharedPreferences.getInstance();
    await store.setString(_preferencesKey, jsonEncode(_preferences.toMap()));
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    final updated = _preferences.copyWith(
      themeMode: mode,
      followSystemTheme: mode == AppThemeMode.system ? true : false,
    );
    await applyPreferences(updated);
  }

  Future<void> setColorSchemeType(ColorSchemeType type) async {
    if (_preferences.colorSchemeType == type) return;
    await applyPreferences(_preferences.copyWith(colorSchemeType: type));
  }

  Future<void> setFollowSystemTheme(bool follow) async {
    if (_preferences.followSystemTheme == follow) return;
    final updated = _preferences.copyWith(
      themeMode: follow ? AppThemeMode.system : _preferences.themeMode,
      followSystemTheme: follow,
    );
    await applyPreferences(updated);
  }

  Future<void> toggleDarkMode() async {
    final nextMode = isDarkMode ? AppThemeMode.light : AppThemeMode.dark;
    await setThemeMode(nextMode);
  }

  Future<void> applyPreferences(AppearancePreferences preferences) async {
    if (preferences == _preferences) return;
    _preferences = preferences;
    await _persistPreferences();
    _updateSystemStatusBar();
    notifyListeners();
  }

  Future<void> applyRemotePreferences(AppearancePreferences? preferences) async {
    if (preferences == null) return;
    await applyPreferences(preferences);
  }

  void updateSystemBrightness(Brightness brightness) {
    if (_systemBrightness == brightness) {
      return;
    }
    _systemBrightness = brightness;
    if (_preferences.followSystemTheme || _preferences.themeMode == AppThemeMode.system) {
      _updateSystemStatusBar();
      notifyListeners();
    }
  }

  Brightness _getEffectiveBrightness() {
    if (_preferences.followSystemTheme || _preferences.themeMode == AppThemeMode.system) {
      return _systemBrightness;
    }
    if (_preferences.themeMode == AppThemeMode.dark) {
      return Brightness.dark;
    }
    return Brightness.light;
  }

  void _updateSystemStatusBar() {
    final brightness = _getEffectiveBrightness();
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: colorScheme.surface,
      systemNavigationBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
    );
    SystemChrome.setSystemUIOverlayStyle(overlay);
  }

  AppColorScheme _resolveBaseColorScheme(Brightness brightness) {
    final activeScheme = _preferences.themeMode == AppThemeMode.highContrast
        ? ColorSchemeType.highContrast
        : _preferences.colorSchemeType;
    switch (activeScheme) {
      case ColorSchemeType.highContrast:
        return brightness == Brightness.dark ? AppThemeColors.darkHighContrast : AppThemeColors.lightHighContrast;
      case ColorSchemeType.custom:
      case ColorSchemeType.standard:
        return brightness == Brightness.dark ? AppThemeColors.dark : AppThemeColors.light;
    }
  }

  AppColorScheme _getColorSchemeForBrightness(Brightness brightness) {
    final base = _resolveBaseColorScheme(brightness);
    return base.copyWith(
      userMessageBackground: _preferences.primaryColor,
      assistantMessageBackground: _preferences.secondaryColor,
    );
  }

  AppColorScheme _getCurrentColorScheme() => _getColorSchemeForBrightness(_getEffectiveBrightness());

  ThemeData get currentTheme {
    final brightness = _getEffectiveBrightness();
    return _buildThemeData(brightness, _getColorSchemeForBrightness(brightness));
  }

  ThemeData get lightTheme => _buildThemeData(Brightness.light, _getColorSchemeForBrightness(Brightness.light));

  ThemeData get darkTheme => _buildThemeData(Brightness.dark, _getColorSchemeForBrightness(Brightness.dark));

  ThemeData _buildThemeData(Brightness brightness, AppColorScheme appColorScheme) {
    final isDark = brightness == Brightness.dark;
    
    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      
      // Color scheme
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: appColorScheme.primary,
        onPrimary: appColorScheme.onPrimary,
        secondary: appColorScheme.secondary,
        onSecondary: appColorScheme.onSecondary,
        error: appColorScheme.error,
        onError: appColorScheme.onError,
        surface: appColorScheme.surface,
        onSurface: appColorScheme.onSurface,
        background: appColorScheme.background,
        onBackground: appColorScheme.onBackground,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: appColorScheme.background,
      
      // App bar
      appBarTheme: AppBarTheme(
        backgroundColor: appColorScheme.surface,
        foregroundColor: appColorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: appColorScheme.shadow,
        surfaceTintColor: appColorScheme.primary,
        iconTheme: IconThemeData(color: appColorScheme.onSurface),
        titleTextStyle: TextStyle(
          color: appColorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Cards
      cardTheme: CardThemeData(
        color: appColorScheme.cardBackground,
        shadowColor: appColorScheme.shadow,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: appColorScheme.cardBorder, width: 0.5),
        ),
      ),
      
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: appColorScheme.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appColorScheme.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appColorScheme.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appColorScheme.error),
        ),
        hintStyle: TextStyle(color: appColorScheme.hint),
        labelStyle: TextStyle(color: appColorScheme.onSurface),
      ),
      
      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: appColorScheme.primary,
          foregroundColor: appColorScheme.onPrimary,
          elevation: 2,
          shadowColor: appColorScheme.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: appColorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: appColorScheme.primary,
          side: BorderSide(color: appColorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Divider
      dividerTheme: DividerThemeData(
        color: appColorScheme.divider,
        thickness: 0.5,
      ),
      
      // List tile
      listTileTheme: ListTileThemeData(
        tileColor: appColorScheme.surface,
        textColor: appColorScheme.onSurface,
        iconColor: appColorScheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: appColorScheme.surface,
        surfaceTintColor: appColorScheme.primary,
        elevation: 8,
        shadowColor: appColorScheme.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Bottom sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: appColorScheme.surface,
        surfaceTintColor: appColorScheme.primary,
        elevation: 8,
        shadowColor: appColorScheme.shadow,
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
