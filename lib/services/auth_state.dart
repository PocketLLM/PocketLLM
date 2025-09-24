import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

class SignInResult {
  final bool canceledDeletion;
  const SignInResult({this.canceledDeletion = false});
}

class SignUpResult {
  final String? userId;
  final bool emailConfirmationRequired;
  const SignUpResult({required this.userId, this.emailConfirmationRequired = false});
}

class AuthState extends ChangeNotifier {
  AuthState() {
    _initialize();
  }

  static const String _profilesTable = 'profiles';
  static const String _storageBucket = 'user_assets';

  final Completer<void> _readyCompleter = Completer<void>();

  SupabaseClient? _client;
  User? _supabaseUser;
  UserProfile? _profile;
  bool _supabaseAvailable = true;
  StreamSubscription<AuthStateChangeEvent>? _authSubscription;
  RealtimeChannel? _profileChannel;

  bool _isPerformingRequest = false;

  Future<void> get ready => _readyCompleter.future;

  SupabaseClient? get client => _client;
  User? get supabaseUser => _supabaseUser;
  UserProfile? get profile => _profile;
  bool get isAuthenticated => _supabaseUser != null;
  bool get supabaseAvailable => _supabaseAvailable;
  bool get isPerformingRequest => _isPerformingRequest;

  Future<void> _initialize() async {
    try {
      _client = Supabase.instance.client;
    } catch (_) {
      _supabaseAvailable = false;
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
      notifyListeners();
      return;
    }

    _authSubscription = _client!.auth.onAuthStateChange.listen((event) async {
      _supabaseUser = event.session?.user;
      if (_supabaseUser != null) {
        await _ensureProfileRow();
        await _loadProfile();
        await _handlePendingDeletionOnLogin();
        _subscribeToProfileChanges();
      } else {
        _unsubscribeFromProfileChanges();
        _profile = null;
      }
      notifyListeners();
    });

    final session = _client!.auth.currentSession;
    _supabaseUser = session?.user;
    if (_supabaseUser != null) {
      await _ensureProfileRow();
      await _loadProfile();
      await _handlePendingDeletionOnLogin();
      _subscribeToProfileChanges();
    }

    if (!_readyCompleter.isCompleted) {
      _readyCompleter.complete();
    }
    notifyListeners();
  }

  Future<SignUpResult> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    _ensureClient();
    await _runWithLoading(() async {
      final response = await _client!.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        _supabaseUser = user;
        await _ensureProfileRow(emailOverride: email);
        await _loadProfile();
        _subscribeToProfileChanges();
      }

      notifyListeners();
    });

    final requiresConfirmation = _client!.auth.currentUser == null;
    final currentUserId = _client!.auth.currentUser?.id ?? _supabaseUser?.id;
    return SignUpResult(
      userId: currentUserId,
      emailConfirmationRequired: requiresConfirmation,
    );
  }

  Future<SignInResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _ensureClient();
    bool canceledDeletion = false;

    await _runWithLoading(() async {
      final response = await _client!.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _supabaseUser = response.user;
      if (_supabaseUser != null) {
        await _ensureProfileRow();
        await _loadProfile();
        canceledDeletion = await _handlePendingDeletionOnLogin();
        _subscribeToProfileChanges();
      }
      notifyListeners();
    });

    return SignInResult(canceledDeletion: canceledDeletion);
  }

  Future<void> signOut() async {
    if (_client == null) return;
    await _client!.auth.signOut();
    _supabaseUser = null;
    _profile = null;
    _unsubscribeFromProfileChanges();
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (_client == null || _supabaseUser == null) return;
    await _loadProfile();
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
    final userId = _supabaseUser!.id;
    final update = {
      'id': userId,
      'full_name': fullName,
      'username': username,
      'bio': bio,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'profession': profession,
      'heard_from': heardFrom,
      'avatar_url': avatarUrl,
      'survey_completed': true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    await _client!
        .from(_profilesTable)
        .upsert(update, onConflict: 'id')
        .eq('id', userId);

    await _loadProfile();
    notifyListeners();
  }

  Future<void> updateProfileFields(Map<String, dynamic> fields) async {
    _ensureAuthenticated();
    if (fields.isEmpty) return;
    final update = {
      ...fields,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await _client!
        .from(_profilesTable)
        .update(update)
        .eq('id', _supabaseUser!.id);
    await _loadProfile();
    notifyListeners();
  }

  Future<void> updatePassword(String newPassword) async {
    _ensureAuthenticated();
    await _client!.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    _ensureAuthenticated();
    try {
      final fileBytes = await imageFile.readAsBytes();
      final path = 'public/avatars/${_supabaseUser!.id}-${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _client!.storage.from(_storageBucket).uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
      return _client!.storage.from(_storageBucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      rethrow;
    }
  }

  Future<void> requestAccountDeletion() async {
    _ensureAuthenticated();
    final now = DateTime.now().toUtc();
    final scheduled = now.add(const Duration(days: 30));
    final update = {
      'deletion_status': 'pending',
      'deletion_requested_at': now.toIso8601String(),
      'deletion_scheduled_for': scheduled.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
    await _client!
        .from(_profilesTable)
        .update(update)
        .eq('id', _supabaseUser!.id);
    await _loadProfile();
    notifyListeners();
  }

  Future<void> cancelAccountDeletion() async {
    _ensureAuthenticated();
    final update = {
      'deletion_status': 'active',
      'deletion_requested_at': null,
      'deletion_scheduled_for': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await _client!
        .from(_profilesTable)
        .update(update)
        .eq('id', _supabaseUser!.id);
    await _loadProfile();
    notifyListeners();
  }

  Future<bool> _handlePendingDeletionOnLogin() async {
    if (_profile == null) return false;
    final scheduled = _profile!.deletionScheduledFor;
    if (scheduled == null) return false;

    final now = DateTime.now();
    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      await signOut();
      throw AuthException('Account pending deletion');
    }

    await cancelAccountDeletion();
    return true;
  }

  Future<void> _ensureProfileRow({String? emailOverride}) async {
    _ensureAuthenticated();
    try {
      final existing = await _client!
          .from(_profilesTable)
          .select<Map<String, dynamic>?>()
          .eq('id', _supabaseUser!.id)
          .maybeSingle();
      if (existing == null) {
        await _client!.from(_profilesTable).insert({
          'id': _supabaseUser!.id,
          'email': emailOverride ?? _supabaseUser!.email,
          'survey_completed': false,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
          'deletion_status': 'active',
        });
      }
    } catch (e) {
      debugPrint('Error ensuring profile row: $e');
      rethrow;
    }
  }

  Future<void> _loadProfile() async {
    _ensureAuthenticated();
    try {
      final data = await _client!
          .from(_profilesTable)
          .select<Map<String, dynamic>?>()
          .eq('id', _supabaseUser!.id)
          .maybeSingle();
      if (data != null) {
        _profile = UserProfile.fromMap(data);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  void _subscribeToProfileChanges() {
    _unsubscribeFromProfileChanges();
    if (_client == null || _supabaseUser == null) return;

    _profileChannel = _client!
        .channel('public:profiles')
      ..on(
        RealtimeListenTypes.postgresChanges,
        const ChannelFilter(event: '*', schema: 'public', table: _profilesTable),
        (payload, [ref]) async {
          final recordId = payload.newRecord?['id'] ?? payload.oldRecord?['id'];
          if (recordId == _supabaseUser!.id) {
            await _loadProfile();
            notifyListeners();
          }
        },
      )
      ..subscribe();
  }

  void _unsubscribeFromProfileChanges() {
    if (_profileChannel != null) {
      _profileChannel!.unsubscribe();
      _profileChannel = null;
    }
  }

  Future<void> _runWithLoading(Future<void> Function() action) async {
    if (_isPerformingRequest) return;
    _isPerformingRequest = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _isPerformingRequest = false;
      notifyListeners();
    }
  }

  void _ensureAuthenticated() {
    if (_client == null || _supabaseUser == null) {
      throw StateError('No authenticated user');
    }
  }

  void _ensureClient() {
    if (_client == null) {
      throw StateError('Supabase is not configured');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _unsubscribeFromProfileChanges();
    super.dispose();
  }
}
