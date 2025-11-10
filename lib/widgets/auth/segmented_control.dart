import 'package:flutter/material.dart';

/// Segmented control component based on the Figma design
class SegmentedControl extends StatefulWidget {
  final List<String> options;
  final int selectedIndex;
  final void Function(int) onSelectionChanged;

  const SegmentedControl({
    Key? key,
    required this.options,
    required this.selectedIndex,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  State<SegmentedControl> createState() => _SegmentedControlState();
}

class _SegmentedControlState extends State<SegmentedControl> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      height: 40,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(widget.options.length, (index) {
          final isSelected = index == widget.selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => widget.onSelectionChanged(index),
              child: Container(
                margin: index == 0
                    ? const EdgeInsets.only(left: 2)
                    : index == widget.options.length - 1
                        ? const EdgeInsets.only(right: 2)
                        : null,
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    widget.options[index],
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: isSelected ? colors.onPrimary : colors.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
}