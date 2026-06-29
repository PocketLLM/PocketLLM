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
  final String status;
  final String rewardStatus;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  ReferralListItem({
    required this.referralId,
    required this.email,
    required this.status,
    required this.rewardStatus,
    required this.createdAt,
    this.acceptedAt,
  });

  factory ReferralListItem.fromJson(Map<String, dynamic> json) {
    return ReferralListItem(
      referralId: json['referral_id'],
      email: json['email'],
      status: json['status'],
      rewardStatus: json['reward_status'],
      createdAt: DateTime.parse(json['created_at']),
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'])
          : null,
    );
  }
}

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
