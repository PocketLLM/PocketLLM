import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketllm/services/theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('ThemeService', () {
    late ThemeService themeService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      themeService = ThemeService();
    });

    group('Initialization', () {
      test('should have default values before initialization', () {
        expect(themeService.themeMode, AppThemeMode.system);
        expect(themeService.colorSchemeType, ColorSchemeType.standard);
        expect(themeService.followSystemTheme, true);
      });

      test('should load saved preferences on initialization', () async {
        SharedPreferences.setMockInitialValues({
          'theme_mode': AppThemeMode.dark.index,
          'color_scheme_type': ColorSchemeType.highContrast.index,
          'follow_system_theme': false,
        });

        await themeService.init();

        expect(themeService.themeMode, AppThemeMode.dark);
        expect(themeService.colorSchemeType, ColorSchemeType.highContrast);
        expect(themeService.followSystemTheme, false);
      });
    });

    group('Theme Mode Management', () {
      test('should set theme mode and persist to preferences', () async {
        await themeService.init();
        
        await themeService.setThemeMode(AppThemeMode.dark);
        
        expect(themeService.themeMode, AppThemeMode.dark);
        
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('theme_mode'), AppThemeMode.dark.index);
      });

      test('should toggle between light and dark modes', () async {
        await themeService.init();
        await themeService.setThemeMode(AppThemeMode.light);
        
        await themeService.toggleDarkMode();
        expect(themeService.themeMode, AppThemeMode.dark);
        
        await themeService.toggleDarkMode();
        expect(themeService.themeMode, AppThemeMode.light);
      });
    });

    group('Color Scheme Management', () {
      test('should set color scheme type and persist to preferences', () async {
        await themeService.init();
        
        await themeService.setColorSchemeType(ColorSchemeType.highContrast);
        
        expect(themeService.colorSchemeType, ColorSchemeType.highContrast);
        
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('color_scheme_type'), ColorSchemeType.highContrast.index);
      });
    });

    group('Effective Brightness', () {
      test('should return light brightness for light theme mode', () async {
        await themeService.init();
        await themeService.setThemeMode(AppThemeMode.light);
        
        expect(themeService.effectiveBrightness, Brightness.light);
        expect(themeService.isDarkMode, false);
      });

      test('should return dark brightness for dark theme mode', () async {
        await themeService.init();
        await themeService.setThemeMode(AppThemeMode.dark);
        
        expect(themeService.effectiveBrightness, Brightness.dark);
        expect(themeService.isDarkMode, true);
      });
    });

    group('Theme Data Generation', () {
      test('should generate valid theme data', () async {
        await themeService.init();
        
        final themeData = themeService.currentTheme;
        
        expect(themeData, isA<ThemeData>());
        expect(themeData.useMaterial3, true);
        expect(themeData.colorScheme, isNotNull);
        expect(themeData.appBarTheme, isNotNull);
        expect(themeData.cardTheme, isNotNull);
        expect(themeData.inputDecorationTheme, isNotNull);
      });
    });
  });
}