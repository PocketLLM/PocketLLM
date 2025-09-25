import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_profile.dart';
import 'backend_api_service.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;

  const AuthException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class SignInResult {
  final bool canceledDeletion;
  const SignInResult({this.canceledDeletion = false});
}

class SignUpResult {
  final String? userId;
  final bool emailConfirmationRequired;
  final String? message;

  const SignUpResult({
    required this.userId,
    this.emailConfirmationRequired = false,
    this.message,
  });
}

class DeletionSchedule {
  final DateTime requestedAt;
  final DateTime scheduledFor;

  const DeletionSchedule({
    required this.requestedAt,
    required this.scheduledFor,
  });

  bool get isExpired => DateTime.now().toUtc().isAfter(scheduledFor);

  Map<String, dynamic> toJson() => {
        'requestedAt': requestedAt.toIso8601String(),
        'scheduledFor': scheduledFor.toIso8601String(),
      };

  factory DeletionSchedule.fromJson(Map<String, dynamic> json) {
    return DeletionSchedule(
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      scheduledFor: DateTime.parse(json['scheduledFor'] as String),
    );
  }
}

class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    _initialize();
  }

  static const String _accessTokenKey = 'auth.accessToken';
  static const String _refreshTokenKey = 'auth.refreshToken';
  static const String _tokenExpiryKey = 'auth.accessTokenExpiry';
  static const String _userIdKey = 'auth.userId';
  static const String _userEmailKey = 'auth.userEmail';
  static const String _deletionInfoPrefix = 'auth.deletionInfo.';

  static const Set<String> _allowedProfileFields = {
    'full_name',
    'username',
    'bio',
    'date_of_birth',
    'profession',
    'avatar_url',
    'survey_completed',
    'heard_from',
  };

  final FlutterSecureStorage _secureStorage;
  final BackendApiService _backendApi = BackendApiService();
  final Completer<void> _readyCompleter = Completer<void>();

  static const Duration _deletionGracePeriod = Duration(days: 30);

  String? _accessToken;
  String? _refreshToken;
  DateTime? _accessTokenExpiresAt;
  String? _userId;
  String? _userEmail;
  UserProfile? _profile;
  bool _serviceAvailable = true;
  bool _isPerformingRequest = false;
  DeletionSchedule? _deletionSchedule;

  Future<void> get ready => _readyCompleter.future;

  UserProfile? get profile => _profile;
  bool get isAuthenticated => _accessToken != null;
  bool get isServiceAvailable => _serviceAvailable;
  bool get isPerformingRequest => _isPerformingRequest;
  String? get currentUserEmail => _userEmail ?? _profile?.email;
  DeletionSchedule? get deletionSchedule => _deletionSchedule;

  Future<void> _initialize() async {
    try {
      _serviceAvailable = BackendApiService.baseUrls.isNotEmpty;
      if (!_serviceAvailable) {
        return;
      }

      _accessToken = await _secureStorage.read(key: _accessTokenKey);
      _refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      final expiryIso = await _secureStorage.read(key: _tokenExpiryKey);
      if (expiryIso != null) {
        _accessTokenExpiresAt = DateTime.tryParse(expiryIso);
      }
      _userId = await _secureStorage.read(key: _userIdKey);
      _userEmail = await _secureStorage.read(key: _userEmailKey);

      if (_accessToken != null && _userId != null) {
        if (_accessTokenExpiresAt != null && _accessTokenExpiresAt!.isBefore(DateTime.now().toUtc())) {
          await _clearSession();
        } else {
          await _loadDeletionSchedule();
          await _fetchProfile();
          await _handlePendingDeletionOnLogin();
        }
      }
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        await _clearSession();
      }
    } on SocketException {
      _serviceAvailable = false;
    } catch (error, stackTrace) {
      debugPrint('Auth initialization failed: $error');
      debugPrint(stackTrace.toString());
    } finally {
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
      notifyListeners();
    }
  }

  Future<SignUpResult> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    SignUpResult? result;
    await _runWithLoading(() async {
      try {
        debugPrint('Attempting to sign up user: $email');
        final response = await _post(
          '/auth/signup',
          body: {
            'email': email,
            'password': password,
          },
        );
        debugPrint('Signup response: $response');

        final data = _extractData(response);
        debugPrint('Extracted data: $data');
        final user = data['user'] as Map<String, dynamic>?;
        final session = data['session'] as Map<String, dynamic>?;
        final message = data['message'] as String?;

        if (session != null && user != null) {
          final accessToken = session['access_token'] as String?;
          if (accessToken == null || accessToken.isEmpty) {
            throw const AuthException('Authentication token missing from response.');
          }

          final refreshToken = session['refresh_token'] as String?;
          final expiresIn = session['expires_in'] as int?;
          final userId = user['id'] as String?;
          final userEmail = user['email'] as String? ?? email;

          await _saveSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresIn: expiresIn,
            userId: userId,
            email: userEmail,
          );

          await _loadDeletionSchedule();
          await _fetchProfile();
        }

        result = SignUpResult(
          userId: user?['id'] as String?,
          emailConfirmationRequired: session == null,
          message: message,
        );
      } catch (e) {
        debugPrint('Sign up error: $e');
        rethrow;
      }
    });

    return result ?? const SignUpResult(userId: null);
  }

  Future<SignInResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    SignInResult result = const SignInResult();
    await _runWithLoading(() async {
      result = await _authenticate(email: email, password: password);
    });
    return result;
  }

  Future<void> signOut() async {
    await _clearSession();
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (!isAuthenticated) return;
    await _fetchProfile();
    notifyListeners();
  }

  Future<void> completeProfile({
    required String fullName,
    required String username,
    String? bio,
    DateTime? dateOfBirth,
    String? profession,
    String? heardFrom,
    String? avatarUrl,
  }) async {
    _ensureAuthenticated();
    final update = {
      'full_name': fullName,
      'username': username,
      'bio': bio,
      'date_of_birth': _formatDate(dateOfBirth),
      'profession': profession,
      'heard_from': heardFrom,
      'avatar_url': avatarUrl,
      'survey_completed': true,
    }..removeWhere((key, value) => value == null || (value is String && value.isEmpty));

    await _updateProfile(update);
    notifyListeners();
  }

  Future<void> updateProfileFields(Map<String, dynamic> fields) async {
    _ensureAuthenticated();
    if (fields.isEmpty) return;

    final sanitized = Map<String, dynamic>.from(fields);
    if (sanitized.containsKey('date_of_birth')) {
      sanitized['date_of_birth'] = _formatDate(sanitized['date_of_birth']);
    }

    sanitized.removeWhere((key, value) => value == null || (value is String && value.isEmpty));

    if (sanitized.isEmpty) return;

    await _updateProfile(sanitized);
    notifyListeners();
  }

  Future<void> updatePassword(String newPassword) async {
    throw const AuthException('Password updates are not supported yet.');
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    throw const AuthException('Profile image uploads require a storage integration.');
  }

  Future<void> requestAccountDeletion() async {
    _ensureAuthenticated();
    await _runWithLoading(() async {
      final requestedAt = DateTime.now().toUtc();
      final scheduledFor = requestedAt.add(_deletionGracePeriod);

      final payload = await _post(
        '/users/profile/deletion',
        requiresAuth: true,
        body: {
          'requested_at': requestedAt.toIso8601String(),
          'scheduled_for': scheduledFor.toIso8601String(),
        },
      );

      final data = _extractData(payload);
      final profileData = _extractProfilePayload(data);
      final schedule = _parseDeletionSchedule(
            profileData ?? data,
            fallbackRequestedAt: requestedAt,
            fallbackScheduledFor: scheduledFor,
          ) ??
          DeletionSchedule(requestedAt: requestedAt, scheduledFor: scheduledFor);

      await _saveDeletionSchedule(schedule);

      if (profileData != null) {
        _profile = UserProfile.fromMap(profileData);
        _applyDeletionScheduleToProfile();
      } else {
        await _fetchProfile();
      }
    });

    notifyListeners();
  }

  Future<void> cancelAccountDeletion() async {
    _ensureAuthenticated();
    await _runWithLoading(() async {
      final payload = await _post(
        '/users/profile/deletion/cancel',
        requiresAuth: true,
      );

      final data = _extractData(payload);
      await _removeDeletionSchedule();

      final profileData = _extractProfilePayload(data);
      if (profileData != null) {
        _profile = UserProfile.fromMap(profileData);
        _applyDeletionScheduleToProfile();
      } else {
        await _fetchProfile();
      }
    });

    notifyListeners();
  }

  Future<bool> _handlePendingDeletionOnLogin() async {
    if (_deletionSchedule == null) {
      return false;
    }

    if (_deletionSchedule!.isExpired) {
      await _performRemoteDeletion();
      return false;
    }

    final payload = await _post(
      '/users/profile/deletion/cancel',
      requiresAuth: true,
    );

    final data = _extractData(payload);
    await _removeDeletionSchedule();

    final profileData = _extractProfilePayload(data);
    if (profileData != null) {
      _profile = UserProfile.fromMap(profileData);
      _applyDeletionScheduleToProfile();
    } else {
      await _fetchProfile();
    }

    return true;
  }

  Future<void> _performRemoteDeletion() async {
    try {
      await _delete('/users/profile', requiresAuth: true);
    } catch (e) {
      debugPrint('Failed to delete account after grace period: $e');
    } finally {
      await _clearSession();
      notifyListeners();
    }
  }

  Future<void> _fetchProfile() async {
    final response = await _get('/users/profile', requiresAuth: true);
    final data = _extractData(response);
    if (data is Map<String, dynamic>) {
      final profile = UserProfile.fromMap(data);
      await _synchronizeDeletionSchedule(profile);
      _profile = profile;
      _applyDeletionScheduleToProfile();
    }
  }

  Future<void> _updateProfile(Map<String, dynamic> fields) async {
    Map<String, dynamic> payload = Map<String, dynamic>.from(fields);

    Future<void> sendUpdate(Map<String, dynamic> body) async {
      final response = await _put('/users/profile', body: body, requiresAuth: true);
      final data = _extractData(response);
      if (data is Map<String, dynamic>) {
        _profile = UserProfile.fromMap(_mergeProfileWithDeletion(data));
      }
    }

    try {
      await sendUpdate(payload);
    } on AuthException catch (error) {
      if (_looksLikeWhitelistError(error)) {
        payload = Map<String, dynamic>.fromEntries(
          payload.entries.where((entry) => _allowedProfileFields.contains(entry.key)),
        );
        if (payload.isEmpty) {
          rethrow;
        }
        await sendUpdate(payload);
      } else {
        rethrow;
      }
    }
  }

  Map<String, dynamic> _mergeProfileWithDeletion(Map<String, dynamic> data) {
    final merged = Map<String, dynamic>.from(data);
    if (_deletionSchedule != null) {
      merged['deletion_status'] = 'pending';
      merged['deletion_requested_at'] = _deletionSchedule!.requestedAt.toIso8601String();
      merged['deletion_scheduled_for'] = _deletionSchedule!.scheduledFor.toIso8601String();
    } else {
      merged['deletion_status'] = 'active';
      merged['deletion_requested_at'] = null;
      merged['deletion_scheduled_for'] = null;
    }
    return merged;
  }

  Future<SignInResult> _authenticate({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Attempting to authenticate user: $email');
      final response = await _post(
        '/auth/signin',
        body: {
          'email': email,
          'password': password,
        },
      );
      debugPrint('Authentication response: $response');

      final data = _extractData(response);
      debugPrint('Extracted data: $data');
      final user = data['user'] as Map<String, dynamic>?;
      final session = data['session'] as Map<String, dynamic>?;

      if (session == null || user == null) {
        throw const AuthException('Invalid authentication response from server.');
      }

      final accessToken = session['access_token'] as String?;
      if (accessToken == null || accessToken.isEmpty) {
        throw const AuthException('Authentication token missing from response.');
      }

      final refreshToken = session['refresh_token'] as String?;
      final expiresIn = session['expires_in'] as int?;
      final userId = user['id'] as String?;
      final userEmail = user['email'] as String? ?? email;

      await _saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresIn: expiresIn,
        userId: userId,
        email: userEmail,
      );

      await _loadDeletionSchedule();
      await _fetchProfile();
      final canceledDeletion = await _handlePendingDeletionOnLogin();
      notifyListeners();

      return SignInResult(canceledDeletion: canceledDeletion);
    } catch (e) {
      debugPrint('Authentication error: $e');
      rethrow;
    }
  }

  Future<void> _saveSession({
    required String accessToken,
    String? refreshToken,
    int? expiresIn,
    String? userId,
    required String email,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _userId = userId;
    _userEmail = email;

    if (expiresIn != null) {
      _accessTokenExpiresAt = DateTime.now().toUtc().add(Duration(seconds: expiresIn));
    } else {
      _accessTokenExpiresAt = null;
    }

    await _secureStorage.write(key: _accessTokenKey, value: _accessToken);
    await _secureStorage.write(key: 'supabase_access_token', value: _accessToken);
    if (_refreshToken != null) {
      await _secureStorage.write(key: _refreshTokenKey, value: _refreshToken);
    } else {
      await _secureStorage.delete(key: _refreshTokenKey);
    }

    if (_accessTokenExpiresAt != null) {
      await _secureStorage.write(key: _tokenExpiryKey, value: _accessTokenExpiresAt!.toIso8601String());
    } else {
      await _secureStorage.delete(key: _tokenExpiryKey);
    }

    if (_userId != null) {
      await _secureStorage.write(key: _userIdKey, value: _userId);
    }
    await _secureStorage.write(key: _userEmailKey, value: _userEmail);
  }

  Future<void> _clearSession() async {
    if (_userId != null) {
      await _secureStorage.delete(key: _deletionStorageKey(_userId!));
    }
    _accessToken = null;
    _refreshToken = null;
    _accessTokenExpiresAt = null;
    _userId = null;
    _userEmail = null;
    _profile = null;
    _deletionSchedule = null;

    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _tokenExpiryKey);
    await _secureStorage.delete(key: _userIdKey);
    await _secureStorage.delete(key: _userEmailKey);
    await _secureStorage.delete(key: 'supabase_access_token');
  }

  Future<void> _runWithLoading(Future<void> Function() action) async {
    if (_isPerformingRequest) {
      debugPrint('AuthState: Ignoring request because another auth request is already running.');
      return;
    }
    debugPrint('AuthState: Starting authenticated request.');
    _isPerformingRequest = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _isPerformingRequest = false;
      notifyListeners();
      debugPrint('AuthState: Finished authenticated request.');
    }
  }

  Future<void> _loadDeletionSchedule() async {
    if (_userId == null) {
      _deletionSchedule = null;
      return;
    }

    final raw = await _secureStorage.read(key: _deletionStorageKey(_userId!));
    if (raw == null || raw.isEmpty) {
      _deletionSchedule = null;
      return;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _deletionSchedule = DeletionSchedule.fromJson(decoded);
      _applyDeletionScheduleToProfile();
    } catch (e) {
      debugPrint('Failed to load deletion schedule: $e');
      _deletionSchedule = null;
    }
  }

  Future<void> _clearDeletionSchedule() async {
    await _removeDeletionSchedule();
  }

  void _applyDeletionScheduleToProfile() {
    if (_profile == null) return;
    if (_deletionSchedule == null) {
      _profile = _profile!.copyWith(
        deletionStatus: 'active',
        deletionRequestedAt: null,
        deletionScheduledFor: null,
      );
    } else {
      _profile = _profile!.copyWith(
        deletionStatus: 'pending',
        deletionRequestedAt: _deletionSchedule!.requestedAt,
        deletionScheduledFor: _deletionSchedule!.scheduledFor,
      );
    }
  }

  String _deletionStorageKey(String userId) => '$_deletionInfoPrefix$userId';

  Future<void> _saveDeletionSchedule(DeletionSchedule schedule, {bool updateProfile = true}) async {
    final existing = _deletionSchedule;
    final matchesExisting = existing != null &&
        existing.requestedAt.isAtSameMomentAs(schedule.requestedAt) &&
        existing.scheduledFor.isAtSameMomentAs(schedule.scheduledFor);

    _deletionSchedule = schedule;
    if (!matchesExisting && _userId != null) {
      await _secureStorage.write(
        key: _deletionStorageKey(_userId!),
        value: jsonEncode(schedule.toJson()),
      );
    }
    if (updateProfile) {
      _applyDeletionScheduleToProfile();
    }
  }

  Future<void> _removeDeletionSchedule({bool updateProfile = true}) async {
    final hadSchedule = _deletionSchedule != null;
    _deletionSchedule = null;
    if (_userId != null) {
      await _secureStorage.delete(key: _deletionStorageKey(_userId!));
    }
    if (updateProfile && (hadSchedule || _profile != null)) {
      _applyDeletionScheduleToProfile();
    }
  }

  Future<void> _synchronizeDeletionSchedule(UserProfile profile) async {
    if (profile.deletionStatus == 'pending' && profile.deletionScheduledFor != null) {
      final requestedAt = (profile.deletionRequestedAt ??
              profile.deletionScheduledFor!.subtract(_deletionGracePeriod))
          .toUtc();
      final scheduledFor = profile.deletionScheduledFor!.toUtc();
      await _saveDeletionSchedule(
        DeletionSchedule(requestedAt: requestedAt, scheduledFor: scheduledFor),
        updateProfile: false,
      );
    } else if (_deletionSchedule != null) {
      await _removeDeletionSchedule(updateProfile: false);
    }
  }

  Map<String, dynamic>? _extractProfilePayload(Map<String, dynamic> data) {
    final profile = data['profile'];
    if (profile is Map<String, dynamic>) {
      return Map<String, dynamic>.from(profile);
    }
    if (data.containsKey('id') && data.containsKey('email')) {
      return data;
    }
    return null;
  }

  DeletionSchedule? _parseDeletionSchedule(
    Map<String, dynamic> data, {
    DateTime? fallbackRequestedAt,
    DateTime? fallbackScheduledFor,
  }) {
    final requestedAt = _parseDateTime(
          data['deletion_requested_at'] ?? data['requested_at'] ?? data['requestedAt'],
        ) ??
        fallbackRequestedAt;

    DateTime? scheduledFor = _parseDateTime(
      data['deletion_scheduled_for'] ?? data['scheduled_for'] ?? data['scheduledFor'],
    );

    if (scheduledFor == null && fallbackScheduledFor != null) {
      scheduledFor = fallbackScheduledFor;
    } else if (scheduledFor == null && requestedAt != null) {
      scheduledFor = requestedAt.add(_deletionGracePeriod);
    }

    if (requestedAt != null && scheduledFor != null) {
      return DeletionSchedule(requestedAt: requestedAt.toUtc(), scheduledFor: scheduledFor.toUtc());
    }

    return null;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) {
      return value.toUtc();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value).toUtc();
    }
    if (value is String && value.isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      return parsed?.toUtc();
    }
    return null;
  }

  void _ensureAuthenticated() {
    if (_accessToken == null) {
      throw const AuthException('You need to be signed in to continue.');
    }
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data);
    }
    if (data is List) {
      return {
        'items': data,
      };
    }
    if (data == null) {
      return <String, dynamic>{};
    }
    return {
      'value': data,
    };
  }

  bool _looksLikeWhitelistError(AuthException error) {
    final message = error.message.toLowerCase();
    return message.contains('non-whitelisted') || message.contains('should not exist');
  }

  String? _formatDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) {
      return value.toUtc().toIso8601String().split('T').first;
    }
    if (value is String && value.isNotEmpty) {
      if (value.length >= 10) {
        return value.substring(0, 10);
      }
      return value;
    }
    return null;
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    bool requiresAuth = false,
  }) async {
    return _request('GET', path, requiresAuth: requiresAuth);
  }

  Future<Map<String, dynamic>> _post(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    return _request('POST', path, body: body, requiresAuth: requiresAuth);
  }

  Future<Map<String, dynamic>> _put(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    return _request('PUT', path, body: body, requiresAuth: requiresAuth);
  }

  Future<Map<String, dynamic>> _delete(
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    return _request('DELETE', path, body: body, requiresAuth: requiresAuth);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    if (BackendApiService.baseUrls.isEmpty) {
      _serviceAvailable = false;
      throw const AuthException('Authentication service is not configured.');
    }

    if (requiresAuth && _accessToken == null) {
      throw const AuthException('You need to be signed in to continue.', statusCode: 401);
    }

    try {
      dynamic response;
      switch (method) {
        case 'GET':
          response = await _backendApi.get(path);
          break;
        case 'POST':
          response = await _backendApi.post(path, body: body);
          break;
        case 'PUT':
          response = await _backendApi.put(path, body: body);
          break;
        case 'DELETE':
          response = await _backendApi.delete(path);
          break;
        default:
          throw AuthException('Unsupported HTTP method: $method');
      }

      _serviceAvailable = true;
      return _wrapBackendResponse(response);
    } on AuthException {
      rethrow;
    } on BackendApiException catch (error) {
      debugPrint('Backend API error: ${error.statusCode} - ${error.message}');
      if (error.statusCode == 401 && requiresAuth) {
        await _clearSession();
      }
      throw AuthException(error.message, statusCode: error.statusCode);
    } on SocketException {
      _serviceAvailable = false;
      notifyListeners();
      throw const AuthException('Unable to reach the PocketLLM service. Check your internet connection.');
    } catch (error) {
      debugPrint('Request error: $error');
      throw AuthException(error.toString());
    }
  }

  Map<String, dynamic> _wrapBackendResponse(dynamic response) {
    Map<String, dynamic>? metadata;
    dynamic payload = response;

    if (response is Map<String, dynamic>) {
      final hasSuccessFlag = response.containsKey('success');
      final success = hasSuccessFlag ? response['success'] == true : true;

      if (hasSuccessFlag && !success) {
        final message = _extractBackendErrorMessage(response['error'], response['message']);
        throw AuthException(message);
      }

      metadata = response['metadata'] as Map<String, dynamic>?;
      payload = response.containsKey('data') ? response['data'] : response;
    }

    return {
      'data': _normalizeResponseData(payload),
      if (metadata != null) 'metadata': metadata,
    };
  }

  Map<String, dynamic> _normalizeResponseData(dynamic data) {
    if (data == null) {
      return <String, dynamic>{};
    }

    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data);
    }

    if (data is List) {
      return {
        'items': data,
      };
    }

    return {
      'value': data,
    };
  }

  String _extractBackendErrorMessage(dynamic error, dynamic fallbackMessage) {
    String? resolveMessage(dynamic value) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is Map<String, dynamic>) {
        for (final key in ['message', 'error', 'detail', 'description']) {
          final candidate = value[key];
          if (candidate is String && candidate.trim().isNotEmpty) {
            return candidate.trim();
          }
        }
      }
      return null;
    }

    return resolveMessage(error) ??
        resolveMessage(fallbackMessage) ??
        'Authentication request failed. Please try again.';
  }

  @override
  void dispose() {
    super.dispose();
  }
}

typedef AuthState = AuthStateNotifier;
