import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class AppColorScheme {
  final Color primary;
  final Color primaryVariant;
  final Color secondary;
  final Color secondaryVariant;
  final Color surface;
  final Color background;
  final Color error;
  final Color onPrimary;
  final Color onSecondary;
  final Color onSurface;
  final Color onBackground;
  final Color onError;
  
  // Chat-specific colors
  final Color userMessageBackground;
  final Color assistantMessageBackground;
  final Color messageText;
  final Color messageBorder;
  final Color inputBackground;
  final Color inputBorder;
  final Color inputText;
  
  // UI-specific colors
  final Color cardBackground;
  final Color cardBorder;
  final Color divider;
  final Color shadow;
  final Color overlay;
  final Color disabled;
  final Color hint;
  
  const AppColorScheme({
    required this.primary,
    required this.primaryVariant,
    required this.secondary,
    required this.secondaryVariant,
    required this.surface,
    required this.background,
    required this.error,
    required this.onPrimary,
    required this.onSecondary,
    required this.onSurface,
    required this.onBackground,
    required this.onError,
    required this.userMessageBackground,
    required this.assistantMessageBackground,
    required this.messageText,
    required this.messageBorder,
    required this.inputBackground,
    required this.inputBorder,
    required this.inputText,
    required this.cardBackground,
    required this.cardBorder,
    required this.divider,
    required this.shadow,
    required this.overlay,
    required this.disabled,
    required this.hint,
  });
}

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _themeModeKey = 'theme_mode';
  static const String _colorSchemeTypeKey = 'color_scheme_type';
  static const String _systemThemeKey = 'follow_system_theme';
  
  AppThemeMode _themeMode = AppThemeMode.system;
  ColorSchemeType _colorSchemeType = ColorSchemeType.standard;
  bool _followSystemTheme = true;
  Brightness _systemBrightness = Brightness.light;
  
  AppThemeMode get themeMode => _themeMode;
  ColorSchemeType get colorSchemeType => _colorSchemeType;
  bool get followSystemTheme => _followSystemTheme;
  bool get isDarkMode => _getEffectiveBrightness() == Brightness.dark;
  Brightness get effectiveBrightness => _getEffectiveBrightness();
  AppColorScheme get colorScheme => _getCurrentColorScheme();

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load theme preferences
    final themeModeIndex = prefs.getInt(_themeModeKey) ?? AppThemeMode.system.index;
    _themeMode = AppThemeMode.values[themeModeIndex];
    
    final colorSchemeIndex = prefs.getInt(_colorSchemeTypeKey) ?? ColorSchemeType.standard.index;
    _colorSchemeType = ColorSchemeType.values[colorSchemeIndex];
    
    _followSystemTheme = prefs.getBool(_systemThemeKey) ?? true;
    
    // Get system brightness
    _updateSystemBrightness();
    _updateSystemStatusBar();

    notifyListeners();
  }
  
  void _updateSystemBrightness() {
    try {
      final window = WidgetsBinding.instance.platformDispatcher;
      _systemBrightness = window.platformBrightness;
    } catch (e) {
      // Fallback to light mode if binding is not initialized (e.g., in tests)
      _systemBrightness = Brightness.light;
    }
  }
  
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);

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
    if (_followSystemTheme == follow) return;

    _followSystemTheme = follow;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_systemThemeKey, follow);

    _updateSystemStatusBar();
    notifyListeners();
  }
  
  Future<void> toggleDarkMode() async {
    final newMode = isDarkMode ? AppThemeMode.light : AppThemeMode.dark;
    await setThemeMode(newMode);
  }
  
  void updateSystemBrightness(Brightness brightness) {
    if (_systemBrightness == brightness) return;
    
    _systemBrightness = brightness;
    if (_followSystemTheme && _themeMode == AppThemeMode.system) {
      _updateSystemStatusBar();
      notifyListeners();
    }
  }
  
  Brightness _getEffectiveBrightness() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return Brightness.light;
      case AppThemeMode.dark:
      case AppThemeMode.highContrast:
        return Brightness.dark;
      case AppThemeMode.system:
        if (_followSystemTheme) {
          return _systemBrightness;
        }
        return Brightness.light;
    }
  }
  
  void _updateSystemStatusBar() {
    final brightness = _getEffectiveBrightness();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness == Brightness.dark 
            ? Brightness.light 
            : Brightness.dark,
        systemNavigationBarColor: brightness == Brightness.dark
            ? const Color(0xFF121212)
            : Colors.white,
        systemNavigationBarIconBrightness: brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }

  AppColorScheme _getColorSchemeForBrightness(Brightness brightness) {
    switch (_colorSchemeType) {
      case ColorSchemeType.standard:
        return brightness == Brightness.dark ? _darkColorScheme : _lightColorScheme;
      case ColorSchemeType.highContrast:
        return brightness == Brightness.dark ? _darkHighContrastColorScheme : _lightHighContrastColorScheme;
      case ColorSchemeType.custom:
        // TODO: Implement custom color schemes
        return brightness == Brightness.dark ? _darkColorScheme : _lightColorScheme;
    }
  }

  AppColorScheme _getCurrentColorScheme() {
    final brightness = _getEffectiveBrightness();
    return _getColorSchemeForBrightness(brightness);
  }

  ThemeData get currentTheme {
    final brightness = _getEffectiveBrightness();
    final colorScheme = _getCurrentColorScheme();

    return _buildThemeData(brightness, colorScheme);
  }

  ThemeData get lightTheme =>
      _buildThemeData(Brightness.light, _getColorSchemeForBrightness(Brightness.light));

  ThemeData get darkTheme =>
      _buildThemeData(Brightness.dark, _getColorSchemeForBrightness(Brightness.dark));
  
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
        contentTextStyle: TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // Light color scheme
  static const AppColorScheme _lightColorScheme = AppColorScheme(
    primary: Color(0xFF6750A4),
    primaryVariant: Color(0xFF4F378B),
    secondary: Color(0xFF625B71),
    secondaryVariant: Color(0xFF4A4458),
    surface: Color(0xFFFFFBFE),
    background: Color(0xFFFFFBFE),
    error: Color(0xFFBA1A1A),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1C1B1F),
    onBackground: Color(0xFF1C1B1F),
    onError: Color(0xFFFFFFFF),
    userMessageBackground: Color(0xFF6750A4),
    assistantMessageBackground: Color(0xFFF3F0FF),
    messageText: Color(0xFF1C1B1F),
    messageBorder: Color(0xFFE7E0EC),
    inputBackground: Color(0xFFF7F2FA),
    inputBorder: Color(0xFFCAC4D0),
    inputText: Color(0xFF1C1B1F),
    cardBackground: Color(0xFFFFFBFE),
    cardBorder: Color(0xFFE7E0EC),
    divider: Color(0xFFE7E0EC),
    shadow: Color(0x1F000000),
    overlay: Color(0x66000000),
    disabled: Color(0x61000000),
    hint: Color(0x99000000),
  );
  
  // Dark color scheme
  static const AppColorScheme _darkColorScheme = AppColorScheme(
    primary: Color(0xFFD0BCFF),
    primaryVariant: Color(0xFF6750A4),
    secondary: Color(0xFFCCC2DC),
    secondaryVariant: Color(0xFF625B71),
    surface: Color(0xFF1C1B1F),
    background: Color(0xFF141218),
    error: Color(0xFFFFB4AB),
    onPrimary: Color(0xFF371E73),
    onSecondary: Color(0xFF332D41),
    onSurface: Color(0xFFE6E1E5),
    onBackground: Color(0xFFE6E1E5),
    onError: Color(0xFF690005),
    userMessageBackground: Color(0xFF6750A4),
    assistantMessageBackground: Color(0xFF2B2930),
    messageText: Color(0xFFE6E1E5),
    messageBorder: Color(0xFF49454F),
    inputBackground: Color(0xFF2B2930),
    inputBorder: Color(0xFF79747E),
    inputText: Color(0xFFE6E1E5),
    cardBackground: Color(0xFF1C1B1F),
    cardBorder: Color(0xFF49454F),
    divider: Color(0xFF49454F),
    shadow: Color(0x3F000000),
    overlay: Color(0x66000000),
    disabled: Color(0x61FFFFFF),
    hint: Color(0x99FFFFFF),
  );
  
  // Light high contrast color scheme
  static const AppColorScheme _lightHighContrastColorScheme = AppColorScheme(
    primary: Color(0xFF000000),
    primaryVariant: Color(0xFF000000),
    secondary: Color(0xFF2E2E2E),
    secondaryVariant: Color(0xFF1A1A1A),
    surface: Color(0xFFFFFFFF),
    background: Color(0xFFFFFFFF),
    error: Color(0xFFD32F2F),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onSurface: Color(0xFF000000),
    onBackground: Color(0xFF000000),
    onError: Color(0xFFFFFFFF),
    userMessageBackground: Color(0xFF000000),
    assistantMessageBackground: Color(0xFFF5F5F5),
    messageText: Color(0xFF000000),
    messageBorder: Color(0xFF000000),
    inputBackground: Color(0xFFFFFFFF),
    inputBorder: Color(0xFF000000),
    inputText: Color(0xFF000000),
    cardBackground: Color(0xFFFFFFFF),
    cardBorder: Color(0xFF000000),
    divider: Color(0xFF000000),
    shadow: Color(0x3F000000),
    overlay: Color(0x80000000),
    disabled: Color(0x80000000),
    hint: Color(0x80000000),
  );
  
  // Dark high contrast color scheme
  static const AppColorScheme _darkHighContrastColorScheme = AppColorScheme(
    primary: Color(0xFFFFFFFF),
    primaryVariant: Color(0xFFFFFFFF),
    secondary: Color(0xFFE0E0E0),
    secondaryVariant: Color(0xFFCCCCCC),
    surface: Color(0xFF000000),
    background: Color(0xFF000000),
    error: Color(0xFFFF5252),
    onPrimary: Color(0xFF000000),
    onSecondary: Color(0xFF000000),
    onSurface: Color(0xFFFFFFFF),
    onBackground: Color(0xFFFFFFFF),
    onError: Color(0xFF000000),
    userMessageBackground: Color(0xFFFFFFFF),
    assistantMessageBackground: Color(0xFF1A1A1A),
    messageText: Color(0xFFFFFFFF),
    messageBorder: Color(0xFFFFFFFF),
    inputBackground: Color(0xFF000000),
    inputBorder: Color(0xFFFFFFFF),
    inputText: Color(0xFFFFFFFF),
    cardBackground: Color(0xFF000000),
    cardBorder: Color(0xFFFFFFFF),
    divider: Color(0xFFFFFFFF),
    shadow: Color(0x3FFFFFFF),
    overlay: Color(0x80FFFFFF),
    disabled: Color(0x80FFFFFF),
    hint: Color(0x80FFFFFF),
  );
}