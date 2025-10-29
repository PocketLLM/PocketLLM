import 'package:flutter/material.dart';

enum LayoutDensity { compact, comfortable }

typedef LayoutCallback = void Function(LayoutDensity density);

typedef ThemeModeCallback = void Function(ThemeMode mode);

typedef AccentCallback = void Function(Color color);

class ThemeCustomization extends StatelessWidget {
  const ThemeCustomization({
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.accentColor,
    required this.onAccentChanged,
    required this.layoutDensity,
    required this.onLayoutChanged,
    Key? key,
  }) : super(key: key);

  final ThemeMode themeMode;
  final ThemeModeCallback onThemeModeChanged;
  final Color accentColor;
  final AccentCallback onAccentChanged;
  final LayoutDensity layoutDensity;
  final LayoutCallback onLayoutChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentChoices = <Color>[
      theme.colorScheme.primary,
      const Color(0xFF6750A4),
      const Color(0xFF006E5C),
      const Color(0xFFB3261E),
      const Color(0xFF005AC2),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme mode',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.auto_awesome)),
            ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
          ],
          selected: {themeMode},
          onSelectionChanged: (value) => onThemeModeChanged(value.first),
        ),
        const SizedBox(height: 24),
        Text(
          'Accent color',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: accentChoices
              .map(
                (color) => GestureDetector(
                  onTap: () => onAccentChanged(color),
                  child: _AccentSwatch(
                    color: color,
                    isActive: color.value == accentColor.value,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'Chat layout',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: LayoutDensity.values
              .map(
                (density) => ChoiceChip(
                  label: Text(
                    density == LayoutDensity.compact ? 'Compact bubbles' : 'Comfortable spacing',
                  ),
                  selected: layoutDensity == density,
                  onSelected: (_) => onLayoutChanged(density),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.color,
    required this.isActive,
  });

  final Color color;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? Colors.white
              : Colors.black.withOpacity(0.1),
          width: 3,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: isActive
          ? const Icon(Icons.check, color: Colors.white)
          : const SizedBox.shrink(),
    );
  }
}
