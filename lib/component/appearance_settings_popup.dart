import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/appearance_preferences.dart';
import '../models/theme_types.dart';
import '../services/auth_state.dart';
import '../services/theme_service.dart';
import '../theme/app_colors.dart';

class AppearanceSettingsPopup extends StatefulWidget {
  final ThemeService themeService;

  const AppearanceSettingsPopup({
    Key? key,
    required this.themeService,
  }) : super(key: key);

  @override
  _AppearanceSettingsPopupState createState() => _AppearanceSettingsPopupState();
}

class _AppearanceSettingsPopupState extends State<AppearanceSettingsPopup> {
  static const int _minRadius = 4;
  static const int _maxRadius = 40;

  late AppThemeMode _selectedThemeMode;
  late int _selectedRadius;
  late Color _selectedPrimaryColor;
  late Color _selectedSecondaryColor;
  bool _isSaving = false;

  final List<Color> _primaryColors = const [
    Color(0xFF4D43C6),
    Color(0xFF6B62E8),
    Color(0xFF7C70F2),
    Color(0xFFA89BFF),
    Color(0xFFD8D3FF),
    Color(0xFFF5F3FF),
    Color(0xFF6750A4),
    Color(0xFF9A82DB),
    Color(0xFFB69DF8),
    Color(0xFF00BFA6),
    Color(0xFF00A2FF),
    Color(0xFFFFC94A),
  ];

  final List<Color> _secondaryColors = const [
    Color(0xFF4D43C6),
    Color(0xFF6B62E8),
    Color(0xFF7C70F2),
    Color(0xFFA89BFF),
    Color(0xFFD8D3FF),
    Color(0xFFF5F3FF),
    Color(0xFF6750A4),
    Color(0xFF9A82DB),
    Color(0xFFB69DF8),
    Color(0xFF00BFA6),
    Color(0xFF00A2FF),
    Color(0xFFFFC94A),
  ];

  @override
  void initState() {
    super.initState();
    final prefs = widget.themeService.preferences;
    _selectedThemeMode = prefs.followSystemTheme ? AppThemeMode.system : prefs.themeMode;
    _selectedRadius = prefs.messageRadius.clamp(_minRadius, _maxRadius);
    _selectedPrimaryColor = prefs.primaryColor;
    _selectedSecondaryColor = prefs.secondaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.themeService.colorScheme;

    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(color: colorScheme.cardBorder.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.25),
            offset: const Offset(0, 12),
            blurRadius: 24,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lavender accents with synced preferences.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                _buildThemeSegmentedControl(colorScheme),
                const SizedBox(height: 20),
                _buildRadiusSlider(colorScheme),
                const SizedBox(height: 20),
                _buildColorSwatchSection(
                  title: 'Primary (outgoing) color',
                  colors: _primaryColors,
                  selectedColor: _selectedPrimaryColor,
                  onColorSelected: (color) => setState(() => _selectedPrimaryColor = color),
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),
                _buildColorSwatchSection(
                  title: 'Secondary (incoming) color',
                  colors: _secondaryColors,
                  selectedColor: _selectedSecondaryColor,
                  onColorSelected: (color) => setState(() => _selectedSecondaryColor = color),
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 20),
                _buildLivePreviewCard(colorScheme),
                const SizedBox(height: 24),
                _buildActionsRow(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSegmentedControl(AppColorScheme colorScheme) {
    final options = [
      {'label': 'System', 'mode': AppThemeMode.system, 'icon': Icons.brightness_auto},
      {'label': 'Light', 'mode': AppThemeMode.light, 'icon': Icons.light_mode},
      {'label': 'Dark', 'mode': AppThemeMode.dark, 'icon': Icons.dark_mode},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.cardBorder.withOpacity(0.8)),
      ),
      child: Row(
        children: options.map((option) {
          final mode = option['mode'] as AppThemeMode;
          final isSelected = _selectedThemeMode == mode;
          final label = option['label'] as String;
          final icon = option['icon'] as IconData;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedThemeMode = mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRadiusSlider(AppColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chat bubble corners',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.cardBorder.withOpacity(0.4),
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withOpacity(0.15),
          ),
          child: Slider(
            value: _selectedRadius.toDouble(),
            min: _minRadius.toDouble(),
            max: _maxRadius.toDouble(),
            divisions: _maxRadius - _minRadius,
            label: '$_selectedRadius px',
            onChanged: (value) => setState(() => _selectedRadius = value.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Rounded', style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.7))),
            Text('Pill', style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.7))),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSwatchSection({
    required String title,
    required List<Color> colors,
    required Color selectedColor,
    required ValueChanged<Color> onColorSelected,
    required AppColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors.map((color) {
            final isSelected = color.value == selectedColor.value;
            return GestureDetector(
              onTap: () => onColorSelected(color),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : colorScheme.cardBorder.withOpacity(0.6),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: color,
                  child: isSelected
                      ? Icon(Icons.check, color: _getTextColor(color), size: 16)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLivePreviewCard(AppColorScheme colorScheme) {
    final borderRadiusValue = _selectedRadius.toDouble();
    final incomingRadius = BorderRadius.only(
      topLeft: Radius.circular(borderRadiusValue),
      topRight: Radius.circular(borderRadiusValue),
      bottomLeft: Radius.circular(borderRadiusValue),
      bottomRight: const Radius.circular(6),
    );
    final outgoingRadius = BorderRadius.only(
      topLeft: Radius.circular(borderRadiusValue),
      topRight: Radius.circular(borderRadiusValue),
      bottomLeft: const Radius.circular(6),
      bottomRight: Radius.circular(borderRadiusValue),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.cardBorder.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _selectedSecondaryColor,
              borderRadius: incomingRadius,
            ),
            child: Text(
              'Incoming messages follow this palette.',
              style: TextStyle(
                color: _getTextColor(_selectedSecondaryColor),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selectedPrimaryColor,
                borderRadius: outgoingRadius,
              ),
              child: Text(
                'Outgoing replies keep lavender energy.',
                style: TextStyle(
                  color: _getTextColor(_selectedPrimaryColor),
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTextColor(Color backgroundColor) {
    final yiq = (backgroundColor.red * 299 + backgroundColor.green * 587 + backgroundColor.blue * 114) / 1000;
    return yiq >= 160 ? Colors.black : Colors.white;
  }

  Widget _buildActionsRow(AppColorScheme colorScheme) {
    return Row(
      children: [
        TextButton(
          onPressed: _isSaving ? null : _resetToDefaults,
          child: const Text('Reset'),
        ),
        const Spacer(),
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveAppearanceSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSaving
              ? SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  void _resetToDefaults() {
    const defaults = AppearancePreferences();
    setState(() {
      _selectedThemeMode = defaults.themeMode;
      _selectedRadius = defaults.messageRadius;
      _selectedPrimaryColor = defaults.primaryColor;
      _selectedSecondaryColor = defaults.secondaryColor;
    });
  }

  AppearancePreferences _buildSelectedPreferences() {
    return widget.themeService.preferences.copyWith(
      themeMode: _selectedThemeMode,
      followSystemTheme: _selectedThemeMode == AppThemeMode.system,
      messageRadius: _selectedRadius,
      primaryColor: _selectedPrimaryColor,
      secondaryColor: _selectedSecondaryColor,
    );
  }

  Future<void> _saveAppearanceSettings() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final authState = context.read<AuthState>();
    final newPreferences = _buildSelectedPreferences();

    try {
      if (authState.isAuthenticated) {
        await authState.saveAppearancePreferences(newPreferences);
      } else {
        await widget.themeService.applyPreferences(newPreferences);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save appearance: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
