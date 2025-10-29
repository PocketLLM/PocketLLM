import 'package:flutter/material.dart';

/// Metadata describing a provider that can be configured during onboarding.
class ProviderOption {
  const ProviderOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
}

/// Grid of provider cards used in step two of the onboarding flow.
class ProviderSelection extends StatelessWidget {
  const ProviderSelection({
    required this.options,
    required this.connectedProviders,
    required this.apiKeys,
    required this.onRequestApiKey,
    required this.onRemoveProvider,
    Key? key,
  }) : super(key: key);

  final List<ProviderOption> options;
  final Set<String> connectedProviders;
  final Map<String, String> apiKeys;
  final ValueChanged<ProviderOption> onRequestApiKey;
  final ValueChanged<ProviderOption> onRemoveProvider;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 520
            ? 3
            : constraints.maxWidth > 360
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: options.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final option = options[index];
            final isConnected = connectedProviders.contains(option.id);
            final hasKey = apiKeys.containsKey(option.id);

            return _ProviderCard(
              option: option,
              isConnected: isConnected,
              hasKey: hasKey,
              onTap: () {
                if (isConnected) {
                  onRemoveProvider(option);
                } else {
                  onRequestApiKey(option);
                }
              },
              onConfigure: () => onRequestApiKey(option),
            );
          },
        );
      },
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.option,
    required this.isConnected,
    required this.hasKey,
    required this.onTap,
    required this.onConfigure,
  });

  final ProviderOption option;
  final bool isConnected;
  final bool hasKey;
  final VoidCallback onTap;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isConnected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isConnected
                    ? colorScheme.primary.withOpacity(0.15)
                    : colorScheme.onSurface.withOpacity(0.08),
                child: Icon(
                  option.icon,
                  color: isConnected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                option.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                option.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.68),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    avatar: Icon(
                      hasKey ? Icons.lock : Icons.lock_open,
                      size: 16,
                    ),
                    label: Text(hasKey ? 'Secured' : 'Needs key'),
                  ),
                  IconButton(
                    tooltip: 'Configure API key',
                    onPressed: onConfigure,
                    icon: const Icon(Icons.vpn_key),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
