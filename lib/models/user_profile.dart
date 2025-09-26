/// File Overview:
/// - Purpose: Immutable representation of a user profile synchronized with the
///   backend.
/// - Backend Migration: Keep but confirm fields align with backend DTOs to
///   prevent divergence.
import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final String? username;
  final String? bio;
  final DateTime? dateOfBirth;
  final String? profession;
  final String? heardFrom;
  final String? avatarUrl;
  final bool surveyCompleted;
  final int? age;
  final Map<String, dynamic>? onboarding;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletionRequestedAt;
  final DateTime? deletionScheduledFor;
  final String? deletionStatus;

  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.username,
    this.bio,
    this.dateOfBirth,
    this.profession,
    this.heardFrom,
    this.avatarUrl,
    this.surveyCompleted = false,
    this.age,
    this.onboarding,
    this.createdAt,
    this.updatedAt,
    this.deletionRequestedAt,
    this.deletionScheduledFor,
    this.deletionStatus,
  });

  bool get hasPendingDeletion {
    if (deletionStatus != 'pending' || deletionScheduledFor == null) {
      return false;
    }
    return deletionScheduledFor!.isAfter(DateTime.now());
  }

  Duration? get timeUntilDeletion {
    if (!hasPendingDeletion) {
      return null;
    }
    return deletionScheduledFor!.difference(DateTime.now());
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? username,
    String? bio,
    DateTime? dateOfBirth,
    String? profession,
    String? heardFrom,
    String? avatarUrl,
    bool? surveyCompleted,
    int? age,
    Map<String, dynamic>? onboarding,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletionRequestedAt,
    DateTime? deletionScheduledFor,
    String? deletionStatus,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profession: profession ?? this.profession,
      heardFrom: heardFrom ?? this.heardFrom,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      surveyCompleted: surveyCompleted ?? this.surveyCompleted,
      age: age ?? this.age,
      onboarding: onboarding ?? this.onboarding,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletionRequestedAt: deletionRequestedAt ?? this.deletionRequestedAt,
      deletionScheduledFor: deletionScheduledFor ?? this.deletionScheduledFor,
      deletionStatus: deletionStatus ?? this.deletionStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'username': username,
      'bio': bio,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'profession': profession,
      'heard_from': heardFrom,
      'avatar_url': avatarUrl,
      'survey_completed': surveyCompleted,
      'age': age,
      'onboarding': onboarding,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deletion_requested_at': deletionRequestedAt?.toIso8601String(),
      'deletion_scheduled_for': deletionScheduledFor?.toIso8601String(),
      'deletion_status': deletionStatus,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String,
      fullName: map['full_name'] as String?,
      username: map['username'] as String?,
      bio: map['bio'] as String?,
      dateOfBirth: parseDate(map['date_of_birth']),
      profession: map['profession'] as String?,
      heardFrom: map['heard_from'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      surveyCompleted: _parseBool(map['survey_completed']),
      age: _parseInt(map['age']),
      onboarding: _parseOnboarding(map['onboarding']),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
      deletionRequestedAt: parseDate(map['deletion_requested_at']),
      deletionScheduledFor: parseDate(map['deletion_scheduled_for']),
      deletionStatus: map['deletion_status'] as String?,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String && value.isNotEmpty) {
      final parsed = int.tryParse(value);
      return parsed;
    }
    return null;
  }

  static Map<String, dynamic>? _parseOnboarding(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        username,
        bio,
        dateOfBirth,
        profession,
        heardFrom,
        avatarUrl,
        surveyCompleted,
        age,
        onboarding,
        createdAt,
        updatedAt,
        deletionRequestedAt,
        deletionScheduledFor,
        deletionStatus,
      ];
}
