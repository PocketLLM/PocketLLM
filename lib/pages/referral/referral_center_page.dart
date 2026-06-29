import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pocketllm/models/referral_models.dart';
import 'package:pocketllm/services/backend_api_service.dart';
import 'package:pocketllm/services/referral_service.dart';

class ReferralCenterPage extends StatefulWidget {
  const ReferralCenterPage({super.key});

  @override
  State<ReferralCenterPage> createState() => _ReferralCenterPageState();
}

class _ReferralCenterPageState extends State<ReferralCenterPage> {
  final ReferralService _referralService = ReferralService();
  ReferralOverview? _overview;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _referralService.fetchOverview();
      if (!mounted) return;
      setState(() {
        _overview = result;
      });
    } on BackendApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Referral Center'),
        centerTitle: true,
        elevation: 0,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _ErrorState(
        message: _error!,
        onRetry: _loadOverview,
      );
    }

    final overview = _overview;
    if (overview == null) {
      return _EmptyState(onInvite: _loadOverview);
    }

    return RefreshIndicator(
      onRefresh: _loadOverview,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _InviteCodeCard(
            overview: overview,
            onCopy: () => _copyToClipboard(
              overview.inviteCode,
              'Invite code copied',
            ),
          ),
          const SizedBox(height: 20),
          _ReferralStatsRow(stats: overview.stats),
          const SizedBox(height: 24),
          _ShareSection(
            shareMessage: overview.buildShareMessage(),
            inviteLink: overview.inviteLink,
            onShareChannel: _shareToChannel,
            onCopyLink: overview.inviteLink == null
                ? null
                : () => _copyToClipboard(
                      overview.inviteLink!,
                      'Referral link copied',
                    ),
          ),
          const SizedBox(height: 24),
          _ReferralListSection(referrals: overview.referrals),
        ],
      ),
    );
  }

  Future<void> _shareToChannel(_ShareChannel channel) async {
    final overview = _overview;
    if (overview == null) return;
    final message = overview.buildShareMessage();

    try {
      switch (channel) {
        case _ShareChannel.whatsapp:
          final encoded = Uri.encodeComponent(message);
          final uri = Uri.parse('https://wa.me/?text=$encoded');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          break;
        case _ShareChannel.x:
          final encoded = Uri.encodeComponent(message);
          final uri = Uri.parse('https://twitter.com/intent/tweet?text=$encoded');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          break;
        case _ShareChannel.generic:
          await Share.share(message);
          break;
      }
    } catch (error) {
      _showSnackBar('Unable to share link: $error');
    }
  }

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    _showSnackBar(label, success: true);
  }

  void _showSnackBar(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : null,
      ),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({
    required this.overview,
    required this.onCopy,
  });

  final ReferralOverview overview;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSlots = overview.totalSlots;
    final usesCount = overview.usesCount;
    final progressLabel = totalSlots > 0 ? '$usesCount of $totalSlots invites used' : '$usesCount invites sent';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Invite Code',
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  overview.inviteCode,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              IconButton(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
                color: theme.colorScheme.onPrimaryContainer,
                tooltip: 'Copy code',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            totalSlots > 0 ? 'You have ${overview.availableSlots} invites left' : 'Unlimited invites enabled',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: totalSlots > 0 ? overview.usageProgress : 0,
              backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progressLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralStatsRow extends StatelessWidget {
  const _ReferralStatsRow({required this.stats});

  final ReferralStats stats;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _StatTileData(
        label: 'Total Invites',
        value: stats.totalSent,
        icon: Icons.people_outline,
        color: Colors.indigo,
      ),
      _StatTileData(
        label: 'Successful',
        value: stats.totalJoined,
        icon: Icons.verified_outlined,
        color: Colors.green,
      ),
      _StatTileData(
        label: 'Rewards Earned',
        value: stats.rewardsIssued,
        icon: Icons.emoji_events_outlined,
        color: Colors.orange,
      ),
    ];

    return Row(
      children: tiles
          .map(
            (tile) => Expanded(
              child: _StatTile(data: tile),
            ),
          )
          .toList(),
    );
  }
}

class _StatTileData {
  const _StatTileData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.data});

  final _StatTileData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: data.color.withOpacity(0.15),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(height: 12),
          Text(
            data.value.toString(),
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareSection extends StatelessWidget {
  const _ShareSection({
    required this.shareMessage,
    required this.inviteLink,
    required this.onShareChannel,
    this.onCopyLink,
  });

  final String shareMessage;
  final String? inviteLink;
  final Future<void> Function(_ShareChannel) onShareChannel;
  final VoidCallback? onCopyLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share your link',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Row(
          children: _ShareTarget.values
              .map(
                (target) => Expanded(
                  child: _SharePill(
                    label: target.label,
                    icon: target.icon,
                    background: target.color.withOpacity(0.1),
                    iconColor: target.color,
                    onTap: () => onShareChannel(target.channel),
                  ),
                ),
              )
              .toList(),
        ),
        if (inviteLink != null && inviteLink!.isNotEmpty) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onCopyLink,
            icon: const Icon(Icons.link),
            label: const Text('Copy share link'),
          ),
        ],
      ],
    );
  }
}

class _SharePill extends StatelessWidget {
  const _SharePill({
    required this.label,
    required this.icon,
    required this.background,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: background,
          foregroundColor: iconColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Column(
          children: [
            Icon(icon),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

enum _ShareChannel { whatsapp, x, generic }

class _ShareTarget {
  const _ShareTarget(this.channel, this.label, this.icon, this.color);

  final _ShareChannel channel;
  final String label;
  final IconData icon;
  final Color color;

  static const values = [
    _ShareTarget(_ShareChannel.whatsapp, 'WhatsApp', Icons.chat_bubble_outline, Color(0xFF25D366)),
    _ShareTarget(_ShareChannel.x, 'X', Icons.alternate_email_outlined, Color(0xFF0F1419)),
    _ShareTarget(_ShareChannel.generic, 'Share', Icons.ios_share, Color(0xFF6C63FF)),
  ];
}

class _ReferralListSection extends StatelessWidget {
  const _ReferralListSection({required this.referrals});

  final List<ReferralEntry> referrals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (referrals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
        ),
        child: Column(
          children: [
            Icon(Icons.group_add_outlined, color: theme.colorScheme.primary, size: 40),
            const SizedBox(height: 12),
            Text(
              'No referrals yet',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your invite link to start earning rewards.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Referrals',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: theme.cardColor,
          ),
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: referrals.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor.withOpacity(0.3)),
            itemBuilder: (context, index) {
              final referral = referrals[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    _initials(referral),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  referral.fullName?.isNotEmpty == true ? referral.fullName! : referral.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Text(
                  _subtitle(referral),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                trailing: _StatusChip(status: referral.status),
              );
            },
          ),
        ),
      ],
    );
  }

  String _initials(ReferralEntry referral) {
    if (referral.fullName != null && referral.fullName!.trim().isNotEmpty) {
      final parts = referral.fullName!.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        return (parts.first.isNotEmpty && parts.last.isNotEmpty)
            ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
            : _fallbackInitials(parts.join());
      }
      return _fallbackInitials(parts.first);
    }
    final emailPrefix = referral.email.split('@').first;
    if (emailPrefix.isEmpty) return '??';
    return _fallbackInitials(emailPrefix);
  }

  String _fallbackInitials(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final source = sanitized.isNotEmpty ? sanitized : value;
    final length = min(2, source.length);
    return source.substring(0, length).toUpperCase();
  }

  String _subtitle(ReferralEntry referral) {
    final formatter = DateFormat('MMM d, yyyy');
    final date = referral.acceptedAt ?? referral.createdAt;
    final label = referral.acceptedAt != null ? 'Joined' : 'Invited';
    return '$label ${formatter.format(date)}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    late Color color;
    late Color textColor;
    late String label;

    switch (normalized) {
      case 'joined':
        color = Colors.green.withOpacity(0.15);
        textColor = Colors.green.shade700;
        label = 'Complete';
        break;
      case 'pending':
        color = Colors.orange.withOpacity(0.15);
        textColor = Colors.orange.shade700;
        label = 'Pending';
        break;
      case 'rejected':
      case 'expired':
        color = Colors.red.withOpacity(0.15);
        textColor = Colors.red.shade700;
        label = 'Declined';
        break;
      default:
        color = Colors.blueGrey.withOpacity(0.15);
        textColor = Colors.blueGrey;
        label = normalized.isEmpty ? 'Pending' : normalized[0].toUpperCase() + normalized.substring(1);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onInvite});

  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.card_giftcard, color: theme.colorScheme.primary, size: 48),
            const SizedBox(height: 16),
            Text(
              'Send your first invite',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Share your invite code to start tracking successful referrals.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onInvite,
              icon: const Icon(Icons.send),
              label: const Text('Refresh data'),
            ),
          ],
        ),
      ),
    );
  }
}
