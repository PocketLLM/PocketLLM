import 'package:flutter/foundation.dart';

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

AppThemeMode appThemeModeFromName(String? value, {AppThemeMode fallback = AppThemeMode.system}) {
  if (value == null || value.isEmpty) {
    return fallback;
  }
  return AppThemeMode.values.firstWhere(
    (mode) => describeEnum(mode).toLowerCase() == value.toLowerCase(),
    orElse: () => fallback,
  );
}

ColorSchemeType colorSchemeTypeFromName(String? value, {ColorSchemeType fallback = ColorSchemeType.standard}) {
  if (value == null || value.isEmpty) {
    return fallback;
  }
  return ColorSchemeType.values.firstWhere(
    (mode) => describeEnum(mode).toLowerCase() == value.toLowerCase(),
    orElse: () => fallback,
  );
}
