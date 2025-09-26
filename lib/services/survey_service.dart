/// File Overview:
/// - Purpose: Thin wrapper around `AuthState` used by the onboarding survey to
///   populate a user profile.
/// - Backend Migration: Keep as coordinator but ensure it calls real backend
///   survey/profile endpoints instead of local state once available.
import 'package:meta/meta.dart';

import 'auth_state.dart';

@immutable
class SurveyPayload {
  final String fullName;
  final String username;
  final String? bio;
  final String? profession;
  final String? heardFrom;
  final Map<String, dynamic>? onboarding;

  const SurveyPayload({
    required this.fullName,
    required this.username,
    this.bio,
    this.profession,
    this.heardFrom,
    this.onboarding,
  });
}

class SurveyService {
  final AuthState _authState;

  SurveyService(this._authState);

  Future<void> submitSurvey(SurveyPayload payload) async {
    await _authState.completeProfile(
      fullName: payload.fullName,
      username: payload.username,
      bio: payload.bio,
      dateOfBirth: null,
      profession: payload.profession,
      heardFrom: payload.heardFrom,
      avatarUrl: null,
      onboarding: payload.onboarding,
    );
    await _authState.refreshProfile();
  }
}
