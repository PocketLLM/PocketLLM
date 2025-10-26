import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/vpn_models.dart';
import '../../services/vpn_connection_service.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnConnectionService>(
      builder: (context, connection, _) {
        final history = connection.history;
        if (history.isEmpty) {
          return _EmptyHistory(onGetStarted: connection.toggleConnection);
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          itemCount: history.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final entry = history[index];
            return _HistoryTile(entry: entry);
          },
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSpeedTest = entry.type == HistoryEntryType.speedTest;
    final icon = isSpeedTest ? Icons.speed_outlined : Icons.lock_outline;
    final color = isSpeedTest ? const Color(0xFF6F6BFE) : const Color(0xFF55D7FF);
    final dateFormatter = DateFormat('MMM d · HH:mm');
    final timestamp = dateFormatter.format(entry.timestamp);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.16),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSpeedTest
                          ? 'Speed test · ${entry.location.city}'
                          : '${entry.status == ConnectionStatus.connected ? 'Connected to' : 'Disconnected from'} ${entry.location.city}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timestamp,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  entry.location.quality.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (isSpeedTest)
            _SpeedResultDetails(result: entry.speedTestResult!)
          else
            _ConnectionDetails(entry: entry),
        ],
      ),
    );
  }
}

class _ConnectionDetails extends StatelessWidget {
  const _ConnectionDetails({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _DetailChip(
          icon: Icons.timer_outlined,
          label: 'Duration',
          value: entry.formattedDuration,
        ),
        const SizedBox(width: 12),
        _DetailChip(
          icon: Icons.data_usage,
          label: 'Data',
          value: entry.formattedDataUsage,
        ),
        const SizedBox(width: 12),
        _DetailChip(
          icon: Icons.shield,
          label: entry.status == ConnectionStatus.connected ? 'Active' : 'Closed',
          value: entry.status == ConnectionStatus.connected ? 'Secure' : 'Ended',
        ),
      ],
    );
  }
}

class _SpeedResultDetails extends StatelessWidget {
  const _SpeedResultDetails({required this.result});

  final SpeedTestResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _DetailChip(
          icon: Icons.arrow_downward_rounded,
          label: 'Download',
          value: result.formattedDownload,
        ),
        _DetailChip(
          icon: Icons.arrow_upward_rounded,
          label: 'Upload',
          value: result.formattedUpload,
        ),
        _DetailChip(
          icon: Icons.network_ping,
          label: 'Ping',
          value: result.formattedPing,
        ),
        _DetailChip(
          icon: Icons.graphic_eq,
          label: 'Jitter',
          value: result.formattedJitter,
        ),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.primary.withOpacity(0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onGetStarted});

  final Future<void> Function() onGetStarted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history_toggle_off, color: theme.colorScheme.primary, size: 64),
            ),
            const SizedBox(height: 24),
            Text(
              'No activity yet',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'Connect to a location or run a speed test to see your sessions listed here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onGetStarted,
              child: const Text('Get started'),
            ),
          ],
        ),
      ),
    );
  }
}
