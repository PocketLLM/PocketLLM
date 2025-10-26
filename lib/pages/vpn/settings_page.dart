import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/vpn_connection_service.dart';

class VpnSettingsPage extends StatefulWidget {
  const VpnSettingsPage({super.key});

  @override
  State<VpnSettingsPage> createState() => _VpnSettingsPageState();
}

class _VpnSettingsPageState extends State<VpnSettingsPage> {
  bool _autoConnect = true;
  bool _killSwitch = true;
  bool _smartRouting = true;
  bool _speedAlerts = false;
  bool _dataUsageAlerts = true;
  bool _betaFeatures = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connection = context.watch<VpnConnectionService>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.12),
                  theme.colorScheme.secondary.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withOpacity(0.18),
                      ),
                      child: Icon(Icons.shield_rounded, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secure preferences',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Customize how PocketLLM protects your traffic.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _tag('Current location', connection.selectedLocation.city),
                    _tag('Status', connection.isConnected ? 'Connected' : 'Offline'),
                    _tag('Monthly usage', connection.formattedMonthlyUsage),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SettingsSection(
            title: 'Connection',
            description: 'Automations that keep you safe and connected.',
            children: [
              _SwitchTile(
                title: 'Auto-connect on startup',
                subtitle: 'Reconnect automatically when launching the app.',
                value: _autoConnect,
                onChanged: (value) => setState(() => _autoConnect = value),
              ),
              _SwitchTile(
                title: 'Network Kill Switch',
                subtitle: 'Block traffic if the VPN tunnel drops unexpectedly.',
                value: _killSwitch,
                onChanged: (value) => setState(() => _killSwitch = value),
              ),
              _SwitchTile(
                title: 'Smart routing',
                subtitle: 'Balance latency and privacy with multi-hop routes.',
                value: _smartRouting,
                onChanged: (value) => setState(() => _smartRouting = value),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Notifications',
            description: 'Stay informed about performance and security events.',
            children: [
              _SwitchTile(
                title: 'Speed alerts',
                subtitle: 'Notify me when download performance drops significantly.',
                value: _speedAlerts,
                onChanged: (value) => setState(() => _speedAlerts = value),
              ),
              _SwitchTile(
                title: 'Data usage alerts',
                subtitle: 'Warn me when I reach 90% of my monthly limit.',
                value: _dataUsageAlerts,
                onChanged: (value) => setState(() => _dataUsageAlerts = value),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Advanced',
            description: 'Protocols, diagnostics and preview features.',
            children: [
              _NavigationTile(
                icon: Icons.router_outlined,
                title: 'Connection protocol',
                subtitle: 'WireGuard® · Auto select',
                onTap: () {},
              ),
              _NavigationTile(
                icon: Icons.dns_outlined,
                title: 'Private DNS',
                subtitle: '1.1.1.1 · Managed by PocketLLM',
                onTap: () {},
              ),
              _SwitchTile(
                title: 'Enable beta features',
                subtitle: 'Get early access to experimental capabilities.',
                value: _betaFeatures,
                onChanged: (value) => setState(() => _betaFeatures = value),
              ),
              _NavigationTile(
                icon: Icons.description_outlined,
                title: 'Terms & Privacy',
                subtitle: 'Review the latest privacy guarantees.',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Support',
            description: 'Help center, diagnostics and account assistance.',
            children: const [
              _NavigationTile(
                icon: Icons.help_center_outlined,
                title: 'Help Center',
                subtitle: 'Guides, FAQs and troubleshooting',
              ),
              _NavigationTile(
                icon: Icons.chat_bubble_outline,
                title: 'Contact support',
                subtitle: 'Live chat available 24/7',
              ),
              _NavigationTile(
                icon: Icons.file_download_done,
                title: 'Export diagnostics',
                subtitle: 'Collect secure logs for support review',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, String value) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
