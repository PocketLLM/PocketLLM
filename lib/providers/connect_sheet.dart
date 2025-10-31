import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../motion/tokens.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';

class ProviderConnectSheet extends StatefulWidget {
  const ProviderConnectSheet({
    super.key,
    required this.provider,
    required this.initialValue,
  });

  final String provider;
  final String initialValue;

  @override
  State<ProviderConnectSheet> createState() => _ProviderConnectSheetState();
}

class _ProviderConnectSheetState extends State<ProviderConnectSheet>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add ${widget.provider} key',
                style: AppTypography.textTheme.headlineMedium,
              ).animate().fadeIn(duration: MotionDurations.medium),
              const SizedBox(height: 12),
              Text(
                'Keys are stored securely on this device. You can edit them anytime in Settings.',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'API key',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Cancel',
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Save',
                      onPressed: _saving ? null : _save,
                      loading: _saving,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().slide(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
          duration: MotionDurations.medium,
          curve: MotionCurves.easeOutCubic,
        );
  }
}

Future<String?> showProviderConnectSheet({
  required BuildContext context,
  required String provider,
  required String initialValue,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ProviderConnectSheet(
          provider: provider,
          initialValue: initialValue,
        ),
      );
    },
  );
}
