import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'theme_types.dart';

class AppearancePreferences {
  static const int _minRadius = 4;
  static const int _maxRadius = 40;

  final AppThemeMode themeMode;
  final bool followSystemTheme;
  final ColorSchemeType colorSchemeType;
  final int messageRadius;
  final Color primaryColor;
  final Color secondaryColor;

  const AppearancePreferences({
    this.themeMode = AppThemeMode.system,
    this.followSystemTheme = true,
    this.colorSchemeType = ColorSchemeType.standard,
    this.messageRadius = 16,
    this.primaryColor = AppColorTokens.chatUserMessage,
    this.secondaryColor = AppColorTokens.chatAssistantMessageLight,
  });

  AppearancePreferences copyWith({
    AppThemeMode? themeMode,
    bool? followSystemTheme,
    ColorSchemeType? colorSchemeType,
    int? messageRadius,
    Color? primaryColor,
    Color? secondaryColor,
  }) {
    final resolvedFollow = followSystemTheme ?? this.followSystemTheme;
    final resolvedMode = resolvedFollow ? AppThemeMode.system : (themeMode ?? this.themeMode);
    final clampedRadius = _clampRadius(messageRadius ?? this.messageRadius);
    return AppearancePreferences(
      themeMode: resolvedMode,
      followSystemTheme: resolvedFollow,
      colorSchemeType: colorSchemeType ?? this.colorSchemeType,
      messageRadius: clampedRadius,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode.name,
      'followSystemTheme': followSystemTheme,
      'colorSchemeType': colorSchemeType.name,
      'messageRadius': messageRadius,
      'primaryColor': primaryColor.value,
      'secondaryColor': secondaryColor.value,
    };
  }

  factory AppearancePreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return const AppearancePreferences();
    }
    final followSystem = map['followSystemTheme'] as bool? ?? false;
    final parsedTheme = appThemeModeFromName(
      map['themeMode'] as String?,
      fallback: AppThemeMode.light,
    );
    final resolvedRadius = _clampRadius(_parseInt(map['messageRadius']) ?? 16);
    return AppearancePreferences(
      themeMode: followSystem ? AppThemeMode.system : parsedTheme,
      followSystemTheme: followSystem,
      colorSchemeType: colorSchemeTypeFromName(map['colorSchemeType'] as String?),
      messageRadius: resolvedRadius,
      primaryColor: _colorFromValue(map['primaryColor'], AppColorTokens.chatUserMessage),
      secondaryColor: _colorFromValue(map['secondaryColor'], AppColorTokens.chatAssistantMessageLight),
    );
  }

  static int _clampRadius(int value) => value.clamp(_minRadius, _maxRadius);

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed;
    }
    return null;
  }

  static Color _colorFromValue(dynamic value, Color fallback) {
    if (value is int) {
      return Color(value);
    }
    if (value is String && value.isNotEmpty) {
      final normalized = value.startsWith('0x') ? value : '0xFF${value.replaceAll('#', '')}';
      final parsed = int.tryParse(normalized);
      if (parsed != null) {
        return Color(parsed);
      }
    }
    return fallback;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppearancePreferences &&
        other.themeMode == themeMode &&
        other.followSystemTheme == followSystemTheme &&
        other.colorSchemeType == colorSchemeType &&
        other.messageRadius == messageRadius &&
        other.primaryColor.value == primaryColor.value &&
        other.secondaryColor.value == secondaryColor.value;
  }

  @override
  int get hashCode => Object.hash(
        themeMode,
        followSystemTheme,
        colorSchemeType,
        messageRadius,
        primaryColor.value,
        secondaryColor.value,
      );
}
