import 'package:equatable/equatable.dart';

class ReferralStats extends Equatable {
  final int totalSent;
  final int totalJoined;
  final int pending;
  final int rewardsIssued;

  const ReferralStats({
    required this.totalSent,
    required this.totalJoined,
    required this.pending,
    required this.rewardsIssued,
  });

  factory ReferralStats.fromMap(Map<String, dynamic> map) {
    return ReferralStats(
      totalSent: (map['total_sent'] as num?)?.toInt() ?? 0,
      totalJoined: (map['total_joined'] as num?)?.toInt() ?? 0,
      pending: (map['pending'] as num?)?.toInt() ?? 0,
      rewardsIssued: (map['rewards_issued'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [totalSent, totalJoined, pending, rewardsIssued];
}

class ReferralEntry extends Equatable {
  final String id;
  final String email;
  final String status;
  final String rewardStatus;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  const ReferralEntry({
    required this.id,
    required this.email,
    required this.status,
    required this.rewardStatus,
    required this.createdAt,
    this.acceptedAt,
  });

  factory ReferralEntry.fromMap(Map<String, dynamic> map) {
    return ReferralEntry(
      id: map['referral_id']?.toString() ?? map['id'].toString(),
      email: map['email'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      rewardStatus: map['reward_status'] as String? ?? 'none',
      createdAt: _parseDate(map['created_at']) ?? DateTime.now(),
      acceptedAt: _parseDate(map['accepted_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  @override
  List<Object?> get props => [id, email, status, rewardStatus, createdAt, acceptedAt];
}

class ReferralOverview extends Equatable {
  final String inviteCode;
  final int maxUses;
  final int usesCount;
  final int? remainingUses;
  final ReferralStats stats;
  final List<ReferralEntry> referrals;

  const ReferralOverview({
    required this.inviteCode,
    required this.maxUses,
    required this.usesCount,
    required this.remainingUses,
    required this.stats,
    required this.referrals,
  });

  factory ReferralOverview.fromMap(Map<String, dynamic> map) {
    final referralItems = (map['referrals'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ReferralEntry.fromMap)
        .toList();
    return ReferralOverview(
      inviteCode: map['invite_code'] as String? ?? '',
      maxUses: (map['max_uses'] as num?)?.toInt() ?? 0,
      usesCount: (map['uses_count'] as num?)?.toInt() ?? 0,
      remainingUses: (map['remaining_uses'] as num?)?.toInt(),
      stats: ReferralStats.fromMap((map['stats'] as Map<String, dynamic>?) ?? <String, dynamic>{}),
      referrals: referralItems,
    );
  }

  @override
  List<Object?> get props => [inviteCode, maxUses, usesCount, remainingUses, stats, referrals];

  String get inviteLink => 'https://pocketllm.ai/invite?code=$inviteCode';
}
