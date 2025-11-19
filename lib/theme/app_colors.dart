/// File Overview:
/// - Purpose: Central palette definitions used to keep visual styling
///   consistent across PocketLLM themes.
/// - Backend Migration: Keep; colors remain frontend concerns although they
///   may later respond to backend-provided branding options.
import 'package:flutter/material.dart';

/// Foundational color tokens used across PocketLLM.
///
/// These values capture the product's brand, surfaces, feedback and
/// chat-specific styling so that components can reference a single source of
/// truth. Higher level theme configuration should compose these tokens instead
/// of hard coding color values.
class AppColorTokens {
  AppColorTokens._();

  // Brand colors (Lavender theme)
  static const Color brandPrimary = Color(0xFF7C70F2);  // Lavender primary
  static const Color brandPrimaryVariant = Color(0xFF4D43C6);  // Deep lavender
  static const Color brandSecondary = Color(0xFFB4A7FF);  // Lavender secondary
  static const Color brandSecondaryVariant = Color(0xFFE6E0FF);  // Tint lavender

  // Light surfaces
  static const Color surfaceLight = Color(0xFFF7F6FB);  // Surface light
  static const Color backgroundLight = Color(0xFFFFFFFF);  // Background light

  // Dark surfaces
  static const Color surfaceDark = Color(0xFF1B1726);  // Surface dark
  static const Color backgroundDark = Color(0xFF121017);  // Background dark

  // Error states
  static const Color errorLight = Color(0xFFE5484D);  // Error light
  static const Color errorDark = Color(0xFFFFB4AB);  // Error dark (keeping existing)

  // Foreground on light surfaces
  static const Color textOnLight = Color(0xFF111111);  // Text on light
  static const Color inverseTextOnLight = Color(0xFFFFFFFF);  // White text

  // Foreground on dark surfaces
  static const Color textOnDark = Color(0xFFF5F3FF);  // Text on dark
  static const Color inverseTextOnDark = Color(0xFF371E73);  // Inverse text on dark

  // High contrast palettes
  static const Color highContrastSurfaceLight = Color(0xFFFFFFFF);
  static const Color highContrastSurfaceDark = Color(0xFF000000);
  static const Color highContrastPrimaryLight = Color(0xFF000000);
  static const Color highContrastPrimaryDark = Color(0xFFFFFFFF);
  static const Color highContrastErrorLight = Color(0xFFD32F2F);
  static const Color highContrastErrorDark = Color(0xFFFF5252);

  // Chat specific tokens
  static const Color chatUserMessage = Color(0xFF6750A4);
  static const Color chatAssistantMessageLight = Color(0xFFF3F0FF);
  static const Color chatAssistantMessageDark = Color(0xFF2B2930);

  static const Color chatMessageBorderLight = Color(0xFFE7E0EC);
  static const Color chatMessageBorderDark = Color(0xFF49454F);

  static const Color inputBackgroundLight = Color(0xFFF7F2FA);
  static const Color inputBackgroundDark = Color(0xFF2B2930);
  static const Color inputBorderLight = Color(0xFFCAC4D0);
  static const Color inputBorderDark = Color(0xFF79747E);

  static const Color cardBorderLight = Color(0xFFE7E0EC);
  static const Color cardBorderDark = Color(0xFF49454F);

  static const Color overlay = Color(0x66000000);
  static const Color shadowLight = Color(0x1F000000);
  static const Color shadowDark = Color(0x3F000000);

  static const Color disabledOnLight = Color(0x61000000);
  static const Color disabledOnDark = Color(0x61FFFFFF);
  static const Color hintOnLight = Color(0x99000000);
  static const Color hintOnDark = Color(0x99FFFFFF);
}

/// Rich color definition for a particular application theme. Widgets can
/// reference these strongly typed fields to keep color usage expressive.
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

  AppColorScheme copyWith({
    Color? primary,
    Color? primaryVariant,
    Color? secondary,
    Color? secondaryVariant,
    Color? surface,
    Color? background,
    Color? error,
    Color? onPrimary,
    Color? onSecondary,
    Color? onSurface,
    Color? onBackground,
    Color? onError,
    Color? userMessageBackground,
    Color? assistantMessageBackground,
    Color? messageText,
    Color? messageBorder,
    Color? inputBackground,
    Color? inputBorder,
    Color? inputText,
    Color? cardBackground,
    Color? cardBorder,
    Color? divider,
    Color? shadow,
    Color? overlay,
    Color? disabled,
    Color? hint,
  }) {
    return AppColorScheme(
      primary: primary ?? this.primary,
      primaryVariant: primaryVariant ?? this.primaryVariant,
      secondary: secondary ?? this.secondary,
      secondaryVariant: secondaryVariant ?? this.secondaryVariant,
      surface: surface ?? this.surface,
      background: background ?? this.background,
      error: error ?? this.error,
      onPrimary: onPrimary ?? this.onPrimary,
      onSecondary: onSecondary ?? this.onSecondary,
      onSurface: onSurface ?? this.onSurface,
      onBackground: onBackground ?? this.onBackground,
      onError: onError ?? this.onError,
      userMessageBackground: userMessageBackground ?? this.userMessageBackground,
      assistantMessageBackground: assistantMessageBackground ?? this.assistantMessageBackground,
      messageText: messageText ?? this.messageText,
      messageBorder: messageBorder ?? this.messageBorder,
      inputBackground: inputBackground ?? this.inputBackground,
      inputBorder: inputBorder ?? this.inputBorder,
      inputText: inputText ?? this.inputText,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      divider: divider ?? this.divider,
      shadow: shadow ?? this.shadow,
      overlay: overlay ?? this.overlay,
      disabled: disabled ?? this.disabled,
      hint: hint ?? this.hint,
    );
  }
}

/// Canonical color schemes that can be consumed by the [ThemeService] or any
/// widget that needs direct access to the palette.
class AppThemeColors {
  AppThemeColors._();

  static const AppColorScheme light = AppColorScheme(
    primary: AppColorTokens.brandPrimary,
    primaryVariant: AppColorTokens.brandPrimaryVariant,
    secondary: AppColorTokens.brandSecondary,
    secondaryVariant: AppColorTokens.brandSecondaryVariant,
    surface: AppColorTokens.surfaceLight,
    background: AppColorTokens.backgroundLight,
    error: AppColorTokens.errorLight,
    onPrimary: AppColorTokens.inverseTextOnLight,
    onSecondary: AppColorTokens.inverseTextOnLight,
    onSurface: AppColorTokens.textOnLight,
    onBackground: AppColorTokens.textOnLight,
    onError: AppColorTokens.inverseTextOnLight,
    userMessageBackground: AppColorTokens.chatUserMessage,
    assistantMessageBackground: AppColorTokens.chatAssistantMessageLight,
    messageText: AppColorTokens.textOnLight,
    messageBorder: AppColorTokens.chatMessageBorderLight,
    inputBackground: AppColorTokens.inputBackgroundLight,
    inputBorder: AppColorTokens.inputBorderLight,
    inputText: AppColorTokens.textOnLight,
    cardBackground: AppColorTokens.surfaceLight,
    cardBorder: AppColorTokens.cardBorderLight,
    divider: AppColorTokens.cardBorderLight,
    shadow: AppColorTokens.shadowLight,
    overlay: AppColorTokens.overlay,
    disabled: AppColorTokens.disabledOnLight,
    hint: AppColorTokens.hintOnLight,
  );

  static const AppColorScheme dark = AppColorScheme(
    primary: AppColorTokens.brandPrimary,
    primaryVariant: AppColorTokens.brandPrimaryVariant,
    secondary: AppColorTokens.brandSecondary,
    secondaryVariant: AppColorTokens.brandSecondaryVariant,
    surface: AppColorTokens.surfaceDark,
    background: AppColorTokens.backgroundDark,
    error: AppColorTokens.errorDark,
    onPrimary: AppColorTokens.inverseTextOnDark,
    onSecondary: AppColorTokens.textOnDark,
    onSurface: AppColorTokens.textOnDark,
    onBackground: AppColorTokens.textOnDark,
    onError: AppColorTokens.textOnDark,
    userMessageBackground: AppColorTokens.chatUserMessage,
    assistantMessageBackground: AppColorTokens.chatAssistantMessageDark,
    messageText: AppColorTokens.textOnDark,
    messageBorder: AppColorTokens.chatMessageBorderDark,
    inputBackground: AppColorTokens.inputBackgroundDark,
    inputBorder: AppColorTokens.inputBorderDark,
    inputText: AppColorTokens.textOnDark,
    cardBackground: AppColorTokens.surfaceDark,
    cardBorder: AppColorTokens.cardBorderDark,
    divider: AppColorTokens.cardBorderDark,
    shadow: AppColorTokens.shadowDark,
    overlay: AppColorTokens.overlay,
    disabled: AppColorTokens.disabledOnDark,
    hint: AppColorTokens.hintOnDark,
  );

  static const AppColorScheme lightHighContrast = AppColorScheme(
    primary: AppColorTokens.highContrastPrimaryLight,
    primaryVariant: AppColorTokens.highContrastPrimaryLight,
    secondary: Color(0xFF2E2E2E),
    secondaryVariant: Color(0xFF1A1A1A),
    surface: AppColorTokens.highContrastSurfaceLight,
    background: AppColorTokens.highContrastSurfaceLight,
    error: AppColorTokens.highContrastErrorLight,
    onPrimary: AppColorTokens.inverseTextOnLight,
    onSecondary: AppColorTokens.inverseTextOnLight,
    onSurface: AppColorTokens.highContrastPrimaryLight,
    onBackground: AppColorTokens.highContrastPrimaryLight,
    onError: AppColorTokens.inverseTextOnLight,
    userMessageBackground: AppColorTokens.highContrastPrimaryLight,
    assistantMessageBackground: Color(0xFFF5F5F5),
    messageText: AppColorTokens.highContrastPrimaryLight,
    messageBorder: AppColorTokens.highContrastPrimaryLight,
    inputBackground: AppColorTokens.highContrastSurfaceLight,
    inputBorder: AppColorTokens.highContrastPrimaryLight,
    inputText: AppColorTokens.highContrastPrimaryLight,
    cardBackground: AppColorTokens.highContrastSurfaceLight,
    cardBorder: AppColorTokens.highContrastPrimaryLight,
    divider: AppColorTokens.highContrastPrimaryLight,
    shadow: AppColorTokens.shadowDark,
    overlay: const Color(0x80000000),
    disabled: const Color(0x80000000),
    hint: const Color(0x80000000),
  );

  static const AppColorScheme darkHighContrast = AppColorScheme(
    primary: AppColorTokens.highContrastPrimaryDark,
    primaryVariant: AppColorTokens.highContrastPrimaryDark,
    secondary: Color(0xFFE0E0E0),
    secondaryVariant: Color(0xFFCCCCCC),
    surface: AppColorTokens.highContrastSurfaceDark,
    background: AppColorTokens.highContrastSurfaceDark,
    error: AppColorTokens.highContrastErrorDark,
    onPrimary: AppColorTokens.highContrastSurfaceDark,
    onSecondary: AppColorTokens.highContrastSurfaceDark,
    onSurface: AppColorTokens.highContrastPrimaryDark,
    onBackground: AppColorTokens.highContrastPrimaryDark,
    onError: AppColorTokens.highContrastSurfaceDark,
    userMessageBackground: AppColorTokens.highContrastPrimaryDark,
    assistantMessageBackground: const Color(0xFF1A1A1A),
    messageText: AppColorTokens.highContrastPrimaryDark,
    messageBorder: AppColorTokens.highContrastPrimaryDark,
    inputBackground: AppColorTokens.highContrastSurfaceDark,
    inputBorder: AppColorTokens.highContrastPrimaryDark,
    inputText: AppColorTokens.highContrastPrimaryDark,
    cardBackground: AppColorTokens.highContrastSurfaceDark,
    cardBorder: AppColorTokens.highContrastPrimaryDark,
    divider: AppColorTokens.highContrastPrimaryDark,
    shadow: AppColorTokens.shadowDark,
    overlay: const Color(0x80FFFFFF),
    disabled: const Color(0x80FFFFFF),
    hint: const Color(0x80FFFFFF),
  );
}
