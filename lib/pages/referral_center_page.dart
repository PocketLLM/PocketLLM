import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/referral_models.dart';
import '../services/backend_api_service.dart';
import '../services/referral_service.dart';

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
      setState(() {
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referral Center'),
      ),
      body: _buildBody(overview),
    );
  }

  Widget _buildBody(ReferralOverview? overview) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 40),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOverview,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (overview == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.card_giftcard, color: Colors.purple[300], size: 48),
              const SizedBox(height: 16),
              const Text(
                'No referral data yet.\nSend your first invite!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showInviteSheet,
                icon: const Icon(Icons.send),
                label: const Text('Send invite'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOverview,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildInviteCard(overview),
          const SizedBox(height: 16),
          _buildStatsRow(overview),
          const SizedBox(height: 24),
          _buildReferralList(overview),
        ],
      ),
    );
  }

  Widget _buildInviteCard(ReferralOverview overview) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your invite code',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              overview.inviteCode,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _copyToClipboard(overview.inviteCode, 'Code copied'),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy code'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _copyToClipboard(overview.inviteLink, 'Invite link copied'),
                  icon: const Icon(Icons.link),
                  label: const Text('Copy link'),
                ),
                FilledButton.icon(
                  onPressed: _showInviteSheet,
                  icon: const Icon(Icons.send),
                  label: const Text('Send invite'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Uses ${overview.usesCount} of ${overview.maxUses} • ${overview.remainingUses ?? 'Unlimited'} remaining',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ReferralOverview overview) {
    final stats = overview.stats;
    return Row(
      children: [
        Expanded(child: _buildStatTile('Sent', stats.totalSent, Icons.mail_outline)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatTile('Joined', stats.totalJoined, Icons.verified)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatTile('Pending', stats.pending, Icons.hourglass_bottom)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatTile('Rewards', stats.rewardsIssued, Icons.emoji_events_outlined)),
      ],
    );
  }

  Widget _buildStatTile(String label, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.grey[100],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurple[300]),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(label, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildReferralList(ReferralOverview overview) {
    if (overview.referrals.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent invites',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.grey[100],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No invites sent yet',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Share your code to unlock early access rewards.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent invites',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...overview.referrals.map(_buildReferralTile),
      ],
    );
  }

  Widget _buildReferralTile(ReferralEntry entry) {
    final statusColor = _statusColor(entry.status);
    final rewardColor = _rewardColor(entry.rewardStatus);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        title: Text(entry.email, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              entry.createdAt.toLocal().toString(),
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            if (entry.acceptedAt != null)
              Text(
                'Joined ${entry.acceptedAt!.toLocal()}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Chip(
              label: Text(entry.status.toUpperCase()),
              backgroundColor: statusColor.withOpacity(0.12),
              labelStyle: TextStyle(color: statusColor),
            ),
            const SizedBox(height: 6),
            Text(
              entry.rewardStatus.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: rewardColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'joined':
        return Colors.green;
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.orange;
    }
  }

  Color _rewardColor(String status) {
    switch (status.toLowerCase()) {
      case 'issued':
      case 'fulfilled':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'revoked':
        return Colors.redAccent;
      default:
        return Colors.grey[600]!;
    }
  }

  Future<void> _showInviteSheet() async {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    final messageController = TextEditingController();
    final emailRegex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) {
        bool isSubmitting = false;
        String? errorText;

        Future<void> submit(StateSetter setModalState) async {
          final email = emailController.text.trim();
          if (!emailRegex.hasMatch(email)) {
            setModalState(() {
              errorText = 'Enter a valid email';
            });
            return;
          }
          setModalState(() {
            isSubmitting = true;
            errorText = null;
          });
          try {
            await _referralService.sendInvite(
              email: email,
              fullName: nameController.text.trim(),
              message: messageController.text.trim(),
            );
            if (!mounted) return;
            Navigator.of(modalContext).pop(true);
            _showSnackBar('Invite sent to $email', success: true);
            await _loadOverview();
          } on BackendApiException catch (error) {
            setModalState(() {
              isSubmitting = false;
              errorText = error.message;
            });
          } catch (error) {
            setModalState(() {
              isSubmitting = false;
              errorText = error.toString();
            });
          }
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(modalContext).viewInsets.bottom),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Send invite',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(modalContext).pop(false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name (optional)'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: messageController,
                        decoration: const InputDecoration(
                          labelText: 'Personal message',
                          hintText: 'Let your teammate know why they should join you.',
                        ),
                        maxLines: 3,
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(errorText!, style: const TextStyle(color: Colors.redAccent)),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : () => submit(setModalState),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Send invite'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _copyToClipboard(String value, String message) {
    Clipboard.setData(ClipboardData(text: value));
    _showSnackBar(message, success: true);
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
