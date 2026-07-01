class ReferralOverview {
  final String inviteCode;
  final int maxUses;
  final int usesCount;
  final int remainingUses;
  final String? inviteLink;
  final String? shareMessage;
  final List<ReferralListItem> referrals;
  final ReferralStats stats;

  ReferralOverview({
    required this.inviteCode,
    required this.maxUses,
    required this.usesCount,
    required this.remainingUses,
    this.inviteLink,
    this.shareMessage,
    required this.referrals,
    required this.stats,
  });

  /// Alias for [maxUses] — used by the referral center UI.
  int get totalSlots => maxUses;

  /// Number of invite slots still available.
  int get availableSlots => remainingUses;

  /// Progress fraction (0.0 – 1.0) of invite usage.
  /// Returns 0 when there is no slot cap.
  double get usageProgress =>
      totalSlots > 0 ? (usesCount / totalSlots).clamp(0.0, 1.0) : 0.0;

  /// Build a share message from backend-provided fields, with a fallback.
  String buildShareMessage() {
    if (shareMessage != null && shareMessage!.isNotEmpty) {
      return shareMessage!;
    }
    final link = inviteLink ?? '';
    return 'Join me on PocketLLM! Use my invite code: $inviteCode $link'.trim();
  }

  factory ReferralOverview.fromJson(Map<String, dynamic> json) {
    return ReferralOverview(
      inviteCode: json['invite_code'],
      maxUses: json['max_uses'],
      usesCount: json['uses_count'],
      remainingUses: json['remaining_uses'],
      inviteLink: json['invite_link'],
      shareMessage: json['share_message'],
      referrals: (json['referrals'] as List)
          .map((item) => ReferralListItem.fromJson(item))
          .toList(),
      stats: ReferralStats.fromJson(json['stats']),
    );
  }
}

class ReferralListItem {
  final String referralId;
  final String email;
  final String? fullName;
  final String status;
  final String rewardStatus;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  ReferralListItem({
    required this.referralId,
    required this.email,
    this.fullName,
    required this.status,
    required this.rewardStatus,
    required this.createdAt,
    this.acceptedAt,
  });

  factory ReferralListItem.fromJson(Map<String, dynamic> json) {
    return ReferralListItem(
      referralId: json['referral_id'],
      email: json['email'],
      fullName: json['full_name'],
      status: json['status'],
      rewardStatus: json['reward_status'],
      createdAt: DateTime.parse(json['created_at']),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
    );
  }
}

/// Backwards-compatible alias used by referral_center_page.dart.
typedef ReferralEntry = ReferralListItem;

class ReferralStats {
  final int totalSent;
  final int totalJoined;
  final int pending;
  final int rewardsIssued;

  ReferralStats({
    required this.totalSent,
    required this.totalJoined,
    required this.pending,
    required this.rewardsIssued,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      totalSent: json['total_sent'],
      totalJoined: json['total_joined'],
      pending: json['pending'],
      rewardsIssued: json['rewards_issued'],
    );
  }
}
