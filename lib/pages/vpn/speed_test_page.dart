import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/speed_test_controller.dart';
import '../../services/vpn_connection_service.dart';

class SpeedTestPage extends StatelessWidget {
  const SpeedTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SpeedTestController, VpnConnectionService>(
      builder: (context, controller, connection, _) {
        final status = controller.status;
        final result = controller.result;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          child: Column(
            children: [
              _SpeedGauge(controller: controller, locationName: connection.selectedLocation.city),
              const SizedBox(height: 28),
              if (status == SpeedTestStatus.error && controller.errorMessage != null)
                _ErrorBanner(message: controller.errorMessage!),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'Download',
                      value: result?.formattedDownload ?? '-- Mbps',
                      icon: Icons.arrow_downward_rounded,
                      color: const Color(0xFF6F6BFE),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MetricCard(
                      title: 'Upload',
                      value: result?.formattedUpload ?? '-- Mbps',
                      icon: Icons.arrow_upward_rounded,
                      color: const Color(0xFF55D7FF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'Ping',
                      value: result?.formattedPing ?? '-- ms',
                      icon: Icons.timelapse,
                      color: const Color(0xFF8BC34A),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MetricCard(
                      title: 'Jitter',
                      value: result?.formattedJitter ?? '-- ms',
                      icon: Icons.graphic_eq,
                      color: const Color(0xFFFFB74D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _MetricCard(
                title: 'Secure IP',
                value: result?.ipAddress ?? 'Awaiting test',
                icon: Icons.language_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: controller.isRunning
                      ? null
                      : () {
                          controller.start();
                        },
                  icon: Icon(
                    status == SpeedTestStatus.completed ? Icons.restart_alt : Icons.speed,
                  ),
                  label: Text(
                    status == SpeedTestStatus.completed
                        ? 'Run Again'
                        : status == SpeedTestStatus.running
                            ? 'Testing…'
                            : 'Start Test',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SpeedGauge extends StatelessWidget {
  const _SpeedGauge({
    required this.controller,
    required this.locationName,
  });

  final SpeedTestController controller;
  final String locationName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = controller.status;
    final progress = controller.progress;
    final result = controller.result;

    final displayValue = status == SpeedTestStatus.completed
        ? result!.downloadMbps
        : status == SpeedTestStatus.running
            ? (progress * 120).clamp(0, 120)
            : 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFFEDF3FF), Color(0xFFE2F4FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status == SpeedTestStatus.completed
                ? 'Speed Test · Normal'
                : status == SpeedTestStatus.running
                    ? 'Measuring performance…'
                    : 'Tap start to measure',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: status == SpeedTestStatus.completed
                        ? 1
                        : status == SpeedTestStatus.running
                            ? progress.clamp(0.0, 1.0)
                            : 0,
                    strokeWidth: 14,
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6F6BFE), Color(0xFF55D7FF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${displayValue.toStringAsFixed(0)}',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 48,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mbps',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                locationName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (status == SpeedTestStatus.running) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ],
          if (status == SpeedTestStatus.completed && result != null) ...[
            const SizedBox(height: 16),
            Text(
              'Last run: ${result.timestamp.hour.toString().padLeft(2, '0')}:${result.timestamp.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.red.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
