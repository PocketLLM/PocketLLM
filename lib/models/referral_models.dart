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
  final String? fullName;
  final String? message;

  const ReferralEntry({
    required this.id,
    required this.email,
    required this.status,
    required this.rewardStatus,
    required this.createdAt,
    this.acceptedAt,
    this.fullName,
    this.message,
  });

  factory ReferralEntry.fromMap(Map<String, dynamic> map) {
    return ReferralEntry(
      id: map['referral_id']?.toString() ?? map['id'].toString(),
      email: map['email'] as String? ?? '',
      status: (map['status'] as String?)?.toLowerCase() ?? 'pending',
      rewardStatus: (map['reward_status'] as String?)?.toLowerCase() ?? 'pending',
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString()).toLocal() 
          : DateTime.now(),
      acceptedAt: map['accepted_at'] != null 
          ? DateTime.parse(map['accepted_at'].toString()).toLocal() 
          : null,
      fullName: map['full_name'] as String?,
      message: map['message'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        status,
        rewardStatus,
        createdAt,
        acceptedAt,
        fullName,
        message,
      ];
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
    this.remainingUses,
    required this.stats,
    required this.referrals,
  });

  factory ReferralOverview.fromMap(Map<String, dynamic> map) {
    return ReferralOverview(
      inviteCode: map['invite_code'] as String? ?? '',
      maxUses: (map['max_uses'] as num?)?.toInt() ?? 0,
      usesCount: (map['uses_count'] as num?)?.toInt() ?? 0,
      remainingUses: (map['remaining_uses'] as num?)?.toInt(),
      stats: map['stats'] != null
          ? ReferralStats.fromMap(Map<String, dynamic>.from(map['stats']))
          : ReferralStats(
              totalSent: 0,
              totalJoined: 0,
              pending: 0,
              rewardsIssued: 0,
            ),
      referrals: map['referrals'] != null
          ? (map['referrals'] as List<dynamic>)
              .map((e) => ReferralEntry.fromMap(
                  Map<String, dynamic>.from(e as Map)))
              .toList()
          : <ReferralEntry>[],
    );
  }

  @override
  List<Object?> get props => [inviteCode, maxUses, usesCount, remainingUses, stats, referrals];

  String get inviteLink => 'https://pocketllm.ai/invite?code=$inviteCode';
}
