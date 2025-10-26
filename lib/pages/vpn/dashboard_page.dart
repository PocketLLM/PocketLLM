import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/vpn_models.dart';
import '../../services/vpn_connection_service.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VpnConnectionService>(
      builder: (context, connection, _) {
        return RefreshIndicator(
          onRefresh: () async {
            if (connection.isConnected) {
              await connection.toggleConnection();
              await Future<void>.delayed(const Duration(milliseconds: 350));
              await connection.toggleConnection();
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ConnectionOverview(connection: connection),
                const SizedBox(height: 24),
                _ConnectButton(connection: connection),
                const SizedBox(height: 28),
                _LocationCarousel(connection: connection),
                const SizedBox(height: 28),
                _InsightsRow(connection: connection),
                const SizedBox(height: 28),
                _AlertSection(connection: connection),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ConnectionOverview extends StatelessWidget {
  const _ConnectionOverview({required this.connection});

  final VpnConnectionService connection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = connection.status;
    final quality = connection.connectionQuality;
    final colorScheme = theme.colorScheme;

    Color qualityColor;
    switch (quality) {
      case ConnectionQuality.excellent:
        qualityColor = Colors.blueAccent;
        break;
      case ConnectionQuality.good:
        qualityColor = Colors.teal;
        break;
      case ConnectionQuality.fair:
        qualityColor = Colors.amber;
        break;
      case ConnectionQuality.poor:
        qualityColor = Colors.redAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.12),
            colorScheme.secondary.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status == ConnectionStatus.connected
                ? 'Secure connection active'
                : status == ConnectionStatus.connecting
                    ? 'Establishing secure tunnel'
                    : 'You are disconnected',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _pill(context,
                  icon: Icons.shield_moon,
                  label: status == ConnectionStatus.connected
                      ? 'Protected'
                      : status == ConnectionStatus.connecting
                          ? 'Connecting'
                          : 'Offline',
                  color: status == ConnectionStatus.connected
                      ? Colors.green
                      : status == ConnectionStatus.connecting
                          ? Colors.amber
                          : Colors.grey),
              const SizedBox(width: 12),
              _pill(
                context,
                icon: Icons.waves,
                label: quality.label,
                color: qualityColor,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current location', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Text(
                      connection.selectedLocation.city,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 20, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          connection.formattedSessionDuration,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Session usage', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Text(
                    connection.formattedSessionUsage,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Monthly ${connection.formattedMonthlyUsage} · Limit ${connection.formattedMonthlyLimit}',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context,
      {required IconData icon, required String label, required Color color}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  const _ConnectButton({required this.connection});

  final VpnConnectionService connection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = connection.status;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.08),
                  theme.colorScheme.primary.withOpacity(0.01),
                ],
              ),
            ),
          ),
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: status == ConnectionStatus.connected
                    ? [
                        const Color(0xFF5AD7FE),
                        const Color(0xFF6F6BFE),
                      ]
                    : [
                        const Color(0xFF7F8CFF),
                        const Color(0xFF9F6BFE),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: connection.isBusy
                  ? null
                  : () {
                      connection.toggleConnection();
                    },
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                      child: Icon(
                        status == ConnectionStatus.connected
                            ? Icons.power_settings_new
                            : status == ConnectionStatus.connecting
                                ? Icons.hourglass_top
                                : Icons.play_circle_fill,
                        key: ValueKey(status),
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      status == ConnectionStatus.connected
                          ? 'Disconnect'
                          : status == ConnectionStatus.connecting
                              ? 'Connecting…'
                              : 'Connect',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCarousel extends StatelessWidget {
  const _LocationCarousel({required this.connection});

  final VpnConnectionService connection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recommended locations',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final location = connection.locations[index];
              final isSelected = identical(location, connection.selectedLocation);
              return _LocationCard(
                location: location,
                isSelected: isSelected,
                onTap: () => connection.selectLocation(location),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemCount: connection.locations.length,
          ),
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.isSelected,
    required this.onTap,
  });

  final VpnLocation location;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 200,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.2),
                  colorScheme.secondary.withOpacity(0.12),
                ],
              )
            : null,
        border: Border.all(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.5)
              : colorScheme.outline.withOpacity(0.2),
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  location.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    location.city,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.network_ping, size: 18, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  location.formattedLatency,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: location.isPremium
                    ? const Color(0xFF7F56D9).withOpacity(0.12)
                    : colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                location.isPremium ? 'Premium route' : location.quality.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: location.isPremium
                      ? const Color(0xFF7F56D9)
                      : colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightsRow extends StatelessWidget {
  const _InsightsRow({required this.connection});

  final VpnConnectionService connection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: _InsightCard(
            title: 'Data usage',
            primaryValue: connection.formattedMonthlyUsage,
            secondaryValue: 'of ${connection.formattedMonthlyLimit}',
            progress: connection.monthlyUsagePercent,
            gradient: [
              const Color(0xFF7B61FF).withOpacity(0.9),
              const Color(0xFFA352FF).withOpacity(0.8),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: _InsightCard(
            title: 'Session uptime',
            primaryValue: connection.formattedSessionDuration,
            secondaryValue: connection.connectionQuality.description,
            progress: connection.connectionQuality == ConnectionQuality.excellent
                ? 1
                : connection.connectionQuality == ConnectionQuality.good
                    ? 0.8
                    : connection.connectionQuality == ConnectionQuality.fair
                        ? 0.5
                        : 0.2,
            gradient: [
              colorScheme.primary.withOpacity(0.9),
              const Color(0xFF4C9AFF).withOpacity(0.8),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.primaryValue,
    required this.secondaryValue,
    required this.progress,
    required this.gradient,
  });

  final String title;
  final String primaryValue;
  final String secondaryValue;
  final double progress;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withOpacity(0.2),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            primaryValue,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            secondaryValue,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              color: Colors.white,
              backgroundColor: Colors.white24,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertSection extends StatelessWidget {
  const _AlertSection({required this.connection});

  final VpnConnectionService connection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alerts = connection.alerts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart recommendations',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...alerts.map(
          (alert) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withOpacity(0.12),
                    ),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      alert,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
