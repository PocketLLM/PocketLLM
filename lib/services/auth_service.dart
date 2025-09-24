import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

enum AuthStatus {
  unknown,
  unavailable,
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

class AuthResult {
  const AuthResult({
    required this.success,
    this.message,
    this.requiresEmailConfirmation = false,
    this.profile,
  });

  final bool success;
  final String? message;
  final bool requiresEmailConfirmation;
  final UserProfile? profile;
}

class UserProfile {
  const UserProfile({
    required this.id,
    this.email,
    this.fullName,
    this.username,
    this.bio,
    this.dateOfBirth,
    this.profession,
    this.avatarUrl,
    this.surveyCompleted = false,
    this.createdAt,
    this.updatedAt,
    this.deletionRequestedAt,
    this.deletionScheduledFor,
    this.deletionStatus,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value)?.toUtc();
      }
      return null;
    }

    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String?,
      fullName: map['full_name'] as String?,
      username: map['username'] as String?,
      bio: map['bio'] as String?,
      dateOfBirth: _parseDate(map['date_of_birth']),
      profession: map['profession'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      surveyCompleted: (map['survey_completed'] as bool?) ??
          (map['survey_completed'] is int
              ? (map['survey_completed'] as int) == 1
              : false),
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
      deletionRequestedAt: _parseDate(map['deletion_requested_at']),
      deletionScheduledFor: _parseDate(map['deletion_scheduled_for']),
      deletionStatus: map['deletion_status'] as String?,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'id': id,
      if (fullName != null) 'full_name': fullName,
      if (username != null) 'username': username,
      if (bio != null) 'bio': bio,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth!.toIso8601String(),
      if (profession != null) 'profession': profession,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'survey_completed': surveyCompleted,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (deletionRequestedAt != null)
        'deletion_requested_at': deletionRequestedAt!.toIso8601String(),
      if (deletionScheduledFor != null)
        'deletion_scheduled_for': deletionScheduledFor!.toIso8601String(),
      if (deletionStatus != null) 'deletion_status': deletionStatus,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? username,
    String? bio,
    DateTime? dateOfBirth,
    String? profession,
    String? avatarUrl,
    bool? surveyCompleted,
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
      avatarUrl: avatarUrl ?? this.avatarUrl,
      surveyCompleted: surveyCompleted ?? this.surveyCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletionRequestedAt: deletionRequestedAt ?? this.deletionRequestedAt,
      deletionScheduledFor: deletionScheduledFor ?? this.deletionScheduledFor,
      deletionStatus: deletionStatus ?? this.deletionStatus,
    );
  }

  bool get hasPendingDeletion {
    if (deletionStatus != 'pending') {
      return false;
    }
    final scheduled = deletionScheduledFor;
    if (scheduled == null) {
      return false;
    }
    return scheduled.isAfter(DateTime.now().toUtc());
  }

  Duration? get timeUntilDeletion {
    if (!hasPendingDeletion) {
      return null;
    }
    return deletionScheduledFor!.difference(DateTime.now().toUtc());
  }
}

class AuthService extends ChangeNotifier {
  AuthService._internal();

  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  static const _skipPreferenceKey = 'auth.skip_flow';

  final SupabaseService _supabaseService = SupabaseService();

  UserProfile? _currentProfile;
  AuthStatus _status = AuthStatus.unknown;
  String? _errorMessage;
  bool _hasSkippedAuth = false;
  StreamSubscription<AuthState>? _authSubscription;
  Completer<void>? _initializationCompleter;

  UserProfile? get currentProfile => _currentProfile;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get hasSkippedAuth => _hasSkippedAuth;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get canAttemptAuthentication => _supabaseService.isInitialized;

  Future<void> ready() async {
    if (_initializationCompleter != null) {
      await _initializationCompleter!.future;
    }
  }

  Future<void> initialize() async {
    if (_initializationCompleter != null) {
      return _initializationCompleter!.future;
    }

    _initializationCompleter = Completer<void>();

    final prefs = await SharedPreferences.getInstance();
    _hasSkippedAuth = prefs.getBool(_skipPreferenceKey) ?? false;

    if (!_supabaseService.isInitialized) {
      _status = AuthStatus.unavailable;
      _errorMessage = _supabaseService.initializationError ??
          'Authentication is not available. Configure Supabase credentials to enable sign in.';
      _initializationCompleter!.complete();
      notifyListeners();
      return;
    }

    try {
      _errorMessage = null;
      final session = _supabaseService.client.auth.currentSession;
      if (session != null) {
        await _handleSignedIn(session, notifyAfter: false);
      } else {
        _status = AuthStatus.unauthenticated;
      }

      _authSubscription =
          _supabaseService.client.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        final session = data.session;

        if (event == AuthChangeEvent.signedIn && session != null) {
          _handleSignedIn(session);
        } else if (event == AuthChangeEvent.signedOut) {
          _currentProfile = null;
          _status = AuthStatus.unauthenticated;
          notifyListeners();
        } else if (event == AuthChangeEvent.userUpdated && session != null) {
          _handleSignedIn(session, notifyAfter: true);
        }
      });

      _initializationCompleter!.complete();
      notifyListeners();
    } catch (error) {
      _status = AuthStatus.error;
      _errorMessage = error.toString();
      _initializationCompleter!.complete();
      notifyListeners();
    }
  }

  Future<void> _handleSignedIn(Session session, {bool notifyAfter = true}) async {
    _status = AuthStatus.authenticated;
    _errorMessage = null;

    try {
      final profile = await _ensureProfile(session.user);
      _currentProfile = profile;

      if (profile.hasPendingDeletion) {
        await cancelAccountDeletion();
      } else {
        notifyListeners();
      }
    } catch (error) {
      _status = AuthStatus.error;
      _errorMessage = error.toString();
      if (notifyAfter) {
        notifyListeners();
      }
    }
    if (notifyAfter) {
      notifyListeners();
    }
  }

  Future<UserProfile> _ensureProfile(User supabaseUser) async {
    final profileData = await _supabaseService.client
        .from('profiles')
        .select()
        .eq('id', supabaseUser.id)
        .maybeSingle();

    if (profileData != null) {
      return UserProfile.fromMap(profileData as Map<String, dynamic>);
    }

    final now = DateTime.now().toUtc();
    final profile = UserProfile(
      id: supabaseUser.id,
      email: supabaseUser.email,
      surveyCompleted: false,
      createdAt: now,
      updatedAt: now,
    );

    await _supabaseService.client.from('profiles').insert(profile.toInsertMap());
    return profile;
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    if (!_supabaseService.isInitialized) {
      return const AuthResult(
        success: false,
        message: 'Authentication is not available. Configure Supabase credentials to enable sign up.',
      );
    }

    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      final response = await _supabaseService.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      final session = response.session;

      if (user == null) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Unable to create the account. Please try again.';
        notifyListeners();
        return const AuthResult(
          success: false,
          message: 'Unable to create the account. Please try again.',
        );
      }

      if (session == null) {
        _status = AuthStatus.unauthenticated;
        _currentProfile = null;
        _errorMessage = null;
        notifyListeners();
        return AuthResult(
          success: true,
          requiresEmailConfirmation: true,
          message:
              'A confirmation link has been sent to $email. Please verify your email to continue.',
        );
      }

      final profile = await _ensureProfile(user);
      _currentProfile = profile;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return AuthResult(
        success: true,
        profile: profile,
      );
    } on AuthException catch (error) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = error.message;
      notifyListeners();
      return AuthResult(success: false, message: error.message);
    } catch (error) {
      _status = AuthStatus.error;
      _errorMessage = error.toString();
      notifyListeners();
      return AuthResult(success: false, message: error.toString());
    }
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    if (!_supabaseService.isInitialized) {
      return const AuthResult(
        success: false,
        message: 'Authentication is not available. Configure Supabase credentials to enable sign in.',
      );
    }

    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      final response = await _supabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final session = response.session;
      final user = response.user;
      if (session != null && user != null) {
        final profile = await _ensureProfile(user);
        _currentProfile = profile;
        _status = AuthStatus.authenticated;
        _errorMessage = null;
        notifyListeners();
        return AuthResult(success: true, profile: profile);
      }

      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return const AuthResult(
        success: false,
        message: 'Unable to sign in. Please try again.',
      );
    } on AuthException catch (error) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = error.message;
      notifyListeners();
      return AuthResult(success: false, message: error.message);
    } catch (error) {
      _status = AuthStatus.error;
      _errorMessage = error.toString();
      notifyListeners();
      return AuthResult(success: false, message: error.toString());
    }
  }

  Future<void> signOut() async {
    if (!_supabaseService.isInitialized) {
      return;
    }

    await _supabaseService.client.auth.signOut();
    _currentProfile = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (!_supabaseService.isInitialized || _currentProfile == null) {
      return;
    }

    try {
      final data = await _supabaseService.client
          .from('profiles')
          .select()
          .eq('id', _currentProfile!.id)
          .maybeSingle();

      if (data != null) {
        _currentProfile = UserProfile.fromMap(data as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to refresh profile: $error');
      }
    }
  }

  Future<AuthResult> resetPassword(String email) async {
    if (!_supabaseService.isInitialized) {
      return const AuthResult(
        success: false,
        message: 'Reset password is unavailable without Supabase configuration.',
      );
    }

    try {
      await _supabaseService.client.auth.resetPasswordForEmail(email);
      return const AuthResult(
        success: true,
        message: 'Password reset instructions have been sent to your email.',
      );
    } on AuthException catch (error) {
      return AuthResult(success: false, message: error.message);
    } catch (error) {
      return AuthResult(success: false, message: error.toString());
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? username,
    String? bio,
    DateTime? dateOfBirth,
    String? profession,
    String? avatarUrl,
    bool? surveyCompleted,
  }) async {
    if (!_supabaseService.isInitialized || _currentProfile == null) {
      return;
    }

    final Map<String, dynamic> updates = {
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (fullName != null) updates['full_name'] = fullName;
    if (username != null) updates['username'] = username;
    if (bio != null) updates['bio'] = bio;
    if (dateOfBirth != null) {
      updates['date_of_birth'] = dateOfBirth.toIso8601String();
    }
    if (profession != null) updates['profession'] = profession;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (surveyCompleted != null) updates['survey_completed'] = surveyCompleted;

    if (updates.length <= 1) {
      return;
    }

    await _supabaseService.client
        .from('profiles')
        .update(updates)
        .eq('id', _currentProfile!.id);

    _currentProfile = _currentProfile!.copyWith(
      fullName: fullName ?? _currentProfile!.fullName,
      username: username ?? _currentProfile!.username,
      bio: bio ?? _currentProfile!.bio,
      dateOfBirth: dateOfBirth ?? _currentProfile!.dateOfBirth,
      profession: profession ?? _currentProfile!.profession,
      avatarUrl: avatarUrl ?? _currentProfile!.avatarUrl,
      surveyCompleted: surveyCompleted ?? _currentProfile!.surveyCompleted,
      updatedAt: DateTime.now().toUtc(),
    );

    notifyListeners();
  }

  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!_supabaseService.isInitialized || _currentProfile == null) {
      return const AuthResult(
        success: false,
        message: 'Password change is unavailable. Please sign in first.',
      );
    }

    final email = _currentProfile!.email;
    if (email == null) {
      return const AuthResult(
        success: false,
        message: 'Unable to verify your email address. Please sign out and sign in again.',
      );
    }

    try {
      await _supabaseService.client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      await _supabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return const AuthResult(success: true, message: 'Password updated successfully.');
    } on AuthException catch (error) {
      return AuthResult(success: false, message: error.message);
    } catch (error) {
      return AuthResult(success: false, message: error.toString());
    }
  }

  Future<void> requestAccountDeletion() async {
    if (!_supabaseService.isInitialized || _currentProfile == null) {
      return;
    }

    final now = DateTime.now().toUtc();
    final scheduled = now.add(const Duration(days: 30));

    await _supabaseService.client.from('profiles').update({
      'deletion_requested_at': now.toIso8601String(),
      'deletion_scheduled_for': scheduled.toIso8601String(),
      'deletion_status': 'pending',
      'updated_at': now.toIso8601String(),
    }).eq('id', _currentProfile!.id);

    _currentProfile = _currentProfile!.copyWith(
      deletionRequestedAt: now,
      deletionScheduledFor: scheduled,
      deletionStatus: 'pending',
      updatedAt: now,
    );

    notifyListeners();
  }

  Future<void> cancelAccountDeletion() async {
    if (!_supabaseService.isInitialized || _currentProfile == null) {
      return;
    }

    await _supabaseService.client.from('profiles').update({
      'deletion_requested_at': null,
      'deletion_scheduled_for': null,
      'deletion_status': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', _currentProfile!.id);

    _currentProfile = _currentProfile!.copyWith(
      deletionRequestedAt: null,
      deletionScheduledFor: null,
      deletionStatus: null,
      updatedAt: DateTime.now().toUtc(),
    );

    notifyListeners();
  }

  Future<void> markAuthSkipped() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipPreferenceKey, true);
    _hasSkippedAuth = true;
    notifyListeners();
  }

  Future<void> clearAuthSkip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_skipPreferenceKey);
    _hasSkippedAuth = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
