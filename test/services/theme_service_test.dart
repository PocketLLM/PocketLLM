import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketllm/models/theme_types.dart';
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
        final storedPrefs = jsonEncode({
          'themeMode': 'dark',
          'followSystemTheme': false,
          'colorSchemeType': 'highContrast',
          'messageRadius': 20,
          'primaryColor': const Color(0xFF7C70F2).value,
          'secondaryColor': const Color(0xFFB4A7FF).value,
        });
        SharedPreferences.setMockInitialValues({'appearance.preferences': storedPrefs});

        await themeService.init();

        expect(themeService.themeMode, AppThemeMode.dark);
        expect(themeService.colorSchemeType, ColorSchemeType.highContrast);
        expect(themeService.followSystemTheme, false);
        expect(themeService.messageCornerRadius, 20);
      });
    });

    group('Theme Mode Management', () {
      test('should set theme mode and persist to preferences', () async {
        await themeService.init();

        await themeService.setThemeMode(AppThemeMode.dark);

        expect(themeService.themeMode, AppThemeMode.dark);

        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getString('appearance.preferences');
        expect(stored, isNotNull);
        final decoded = jsonDecode(stored!) as Map<String, dynamic>;
        expect(decoded['themeMode'], 'dark');
        expect(decoded['followSystemTheme'], false);
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
        final stored = prefs.getString('appearance.preferences');
        final decoded = jsonDecode(stored!) as Map<String, dynamic>;
        expect(decoded['colorSchemeType'], 'highContrast');
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
