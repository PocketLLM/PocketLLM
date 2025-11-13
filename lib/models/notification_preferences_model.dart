class NotificationPreferences {
  final bool notifyJobStatus;
  final bool notifyAccountAlerts;
  final bool notifyReferralRewards;
  final bool notifyProductUpdates;

  NotificationPreferences({
    required this.notifyJobStatus,
    required this.notifyAccountAlerts,
    required this.notifyReferralRewards,
    required this.notifyProductUpdates,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      notifyJobStatus: json['notify_job_status'],
      notifyAccountAlerts: json['notify_account_alerts'],
      notifyReferralRewards: json['notify_referral_rewards'],
      notifyProductUpdates: json['notify_product_updates'],
    );
  }
}

class NotificationPreferencesUpdate {
  final bool? notifyJobStatus;
  final bool? notifyAccountAlerts;
  final bool? notifyReferralRewards;
  final bool? notifyProductUpdates;

  NotificationPreferencesUpdate({
    this.notifyJobStatus,
    this.notifyAccountAlerts,
    this.notifyReferralRewards,
    this.notifyProductUpdates,
  });

  Map<String, dynamic> toJson() {
    return {
      'notify_job_status': notifyJobStatus,
      'notify_account_alerts': notifyAccountAlerts,
      'notify_referral_rewards': notifyReferralRewards,
      'notify_product_updates': notifyProductUpdates,
    }..removeWhere((key, value) => value == null);
  }
}
