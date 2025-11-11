import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/theme_service.dart';

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
  // Theme mode options
  late AppThemeMode _selectedThemeMode;
  
  // Radius options
  static const int smallRadius = 6;
  static const int mediumRadius = 16;
  static const int largeRadius = 28;
  int _selectedRadius = mediumRadius;
  
  // Color options - first two rows are lavender family
  final List<Color> _primaryColors = [
    const Color(0xFF4D43C6), // Deep lavender
    const Color(0xFF6B62E8), // Lavender
    const Color(0xFF7C70F2), // Primary lavender
    const Color(0xFFA89BFF), // Light lavender
    const Color(0xFFD8D3FF), // Very light lavender
    const Color(0xFFF5F3FF), // Almost white
    const Color(0xFF6750A4), // Purple
    const Color(0xFF9A82DB), // Light purple
    const Color(0xFFB69DF8), // Very light purple
    const Color(0xFF00BFA6), // Teal
    const Color(0xFF00A2FF), // Blue
    const Color(0xFFFFC94A), // Yellow
  ];
  
  final List<Color> _secondaryColors = [
    const Color(0xFF4D43C6), // Deep lavender
    const Color(0xFF6B62E8), // Lavender
    const Color(0xFF7C70F2), // Primary lavender
    const Color(0xFFA89BFF), // Light lavender
    const Color(0xFFD8D3FF), // Very light lavender
    const Color(0xFFF5F3FF), // Almost white
    const Color(0xFF6750A4), // Purple
    const Color(0xFF9A82DB), // Light purple
    const Color(0xFFB69DF8), // Very light purple
    const Color(0xFF00BFA6), // Teal
    const Color(0xFF00A2FF), // Blue
    const Color(0xFFFFC94A), // Yellow
  ];
  
  Color _selectedPrimaryColor = const Color(0xFF7C70F2);
  Color _selectedSecondaryColor = const Color(0xFFB4A7FF);
  
  @override
  void initState() {
    super.initState();
    // Initialize with the current theme mode
    _selectedThemeMode = widget.themeService.themeMode;
    _selectedRadius = mediumRadius;
  }

  @override
  Widget build(BuildContext context) {
    _selectedThemeMode = widget.themeService.themeMode;
    
    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: widget.themeService.isDarkMode ? const Color(0xFF1B1726) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF111015).withOpacity(0.18),
            offset: const Offset(0, 12),
            blurRadius: 24,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Appearance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lavender accent. Live preview below.',
                style: TextStyle(
                  fontSize: 12,
                  color: (widget.themeService.isDarkMode ? Colors.white : Colors.black).withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              
              // Theme Segmented Control
              _buildThemeSegmentedControl(widget.themeService.isDarkMode),
              const SizedBox(height: 12),
              
              // Radius Slider
              _buildRadiusSlider(),
              const SizedBox(height: 12),
              
              // Primary Color Swatches
              _buildColorSwatchSection(
                title: 'Primary (outgoing) color',
                colors: _primaryColors,
                selectedColor: _selectedPrimaryColor,
                onColorSelected: (color) => setState(() => _selectedPrimaryColor = color),
                isDarkMode: widget.themeService.isDarkMode,
              ),
              const SizedBox(height: 12),
              
              // Secondary Color Swatches
              _buildColorSwatchSection(
                title: 'Secondary (incoming) color',
                colors: _secondaryColors,
                selectedColor: _selectedSecondaryColor,
                onColorSelected: (color) => setState(() => _selectedSecondaryColor = color),
                isDarkMode: widget.themeService.isDarkMode,
              ),
              const SizedBox(height: 12),
              
              // Live Preview Card
              _buildLivePreviewCard(widget.themeService.isDarkMode),
              const SizedBox(height: 12),
              
              // Actions Row
              _buildActionsRow(widget.themeService),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSegmentedControl(bool isDarkMode) {
    final options = ['System', 'Light', 'Dark'];
    final selectedIndex = _getThemeModeIndex(_selectedThemeMode);
    
    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE6E0FF),
        ),
      ),
      child: Row(
        children: List.generate(options.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedThemeMode = _getThemeModeFromIndex(index)),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE6E0FF) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected 
                    ? Border.all(color: const Color(0xFFB9A7FF)) 
                    : Border.all(color: Colors.transparent),
                ),
                child: Center(
                  child: Text(
                    options[index],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected 
                        ? const Color(0xFF4D43C6) 
                        : (isDarkMode ? const Color(0xFFF5F3FF) : const Color(0xFF111111)),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  int _getThemeModeIndex(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 0;
      case AppThemeMode.light:
        return 1;
      case AppThemeMode.dark:
      case AppThemeMode.highContrast:
        return 2;
    }
  }

  AppThemeMode _getThemeModeFromIndex(int index) {
    switch (index) {
      case 0:
        return AppThemeMode.system;
      case 1:
        return AppThemeMode.light;
      case 2:
        return AppThemeMode.dark;
      default:
        return AppThemeMode.light;
    }
  }

  Widget _buildRadiusSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chat bubble corners',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF7C70F2),
            inactiveTrackColor: const Color(0xFFE6E0FF),
            thumbColor: const Color(0xFF7C70F2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
            tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 2.0),
            activeTickMarkColor: const Color(0xFF7C70F2),
            inactiveTickMarkColor: const Color(0xFFE6E0FF),
          ),
          child: Slider(
            value: _selectedRadius.toDouble(),
            min: 0,
            max: 28,
            divisions: 28,
            label: '$_selectedRadius px',
            onChanged: (value) => setState(() => _selectedRadius = value.toInt()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('0 px'),
            Text('16 px'),
            Text('28 px'),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSwatchSection({
    required String title,
    required List<Color> colors,
    required Color selectedColor,
    required Function(Color) onColorSelected,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: colors.length,
            itemBuilder: (context, index) {
              final color = colors[index];
              final isSelected = color == selectedColor;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => onColorSelected(color),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: isDarkMode ? Colors.white : Colors.black,
                              width: 2,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLivePreviewCard(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF111015) : const Color(0xFFF7F6FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE6E0FF).withOpacity(isDarkMode ? 0.2 : 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Incoming message (left-aligned)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _selectedSecondaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_selectedRadius.toDouble()),
                topRight: Radius.circular(_selectedRadius.toDouble()),
                bottomLeft: Radius.circular(_selectedRadius.toDouble()),
                bottomRight: const Radius.circular(4),
              ),
            ),
            child: Text(
              'This is an incoming message.',
              style: TextStyle(
                color: _getTextColor(_selectedSecondaryColor),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Outgoing message (right-aligned)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _selectedPrimaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(_selectedRadius.toDouble()),
                  topRight: Radius.circular(_selectedRadius.toDouble()),
                  bottomLeft: const Radius.circular(4),
                  bottomRight: Radius.circular(_selectedRadius.toDouble()),
                ),
              ),
              child: Text(
                'This is your reply. Lavender stays tasteful.',
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
    // Calculate YIQ value to determine if text should be black or white
    final yiq = (backgroundColor.red * 299 + 
                 backgroundColor.green * 587 + 
                 backgroundColor.blue * 114) / 1000;
    return yiq >= 160 ? Colors.black : Colors.white;
  }

  Widget _buildActionsRow(ThemeService themeService) {
    return Row(
      children: [
        TextButton(
          onPressed: () {
            // Reset to defaults
            setState(() {
              _selectedThemeMode = AppThemeMode.light;
              _selectedRadius = mediumRadius;
              _selectedPrimaryColor = const Color(0xFF7C70F2);
              _selectedSecondaryColor = const Color(0xFFB4A7FF);
            });
          },
          child: const Text('Reset'),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () async {
            // Apply changes
            await themeService.setThemeMode(_selectedThemeMode);
            if (!mounted) return;
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C70F2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}