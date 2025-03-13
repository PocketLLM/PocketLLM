import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;
  final _secureStorage = const FlutterSecureStorage();

  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // Improved email existence check using Supabase auth
  Future<bool> checkEmailExists(String email) async {
    try {
      // Use Supabase RPC to check if email exists in auth.users
      final response = await _supabase.rpc('email_exists', params: {'email_param': email});
      
      // RPC should return a boolean indicating if the email exists
      return response as bool;
    } catch (e) {
      print('Error checking email: $e');
      // Fallback: attempt to sign in with a dummy password to check existence
      try {
        await _supabase.auth.signInWithPassword(
          email: email,
          password: 'dummy-password-check', // This will fail if user exists
        );
        return false; // If this succeeds, it means the user doesn't exist yet
      } on AuthException catch (authError) {
        if (authError.message.contains('Invalid login credentials')) {
          return true; // Email exists but password was wrong
        }
        return false; // Email doesn't exist
      } catch (fallbackError) {
        print('Fallback check failed: $fallbackError');
        return false; // Default to false on error
      }
    }
  }

  // Note: You'll need to create this RPC function in Supabase SQL Editor
  // Create this function in Supabase SQL Editor:
  /*
    create or replace function email_exists(email_param text)
    returns boolean as $$
    begin
      return exists (
        select 1
        from auth.users
        where email = email_param
      );
    end;
    $$ language plpgsql security definer;
  */

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    try {
      final exists = await checkEmailExists(email);
      if (exists) {
        throw AuthException('Email is already in use.');
      }
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );
      
      if (response.user == null) {
        throw AuthException('Signup failed: User is null');
      }
      
      try {
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'email': email,
          'updated_at': DateTime.now().toIso8601String(),
          'survey_completed': false,
        });
      } catch (e) {
        print('Error creating profile: $e');
      }
      
      await _storeSession(response.session);
      return response;
    } catch (e) {
      print('Signup error: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await _storeSession(response.session);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _clearSession();
  }

  Future<void> _storeSession(Session? session) async {
    if (session != null) {
      await _secureStorage.write(key: 'access_token', value: session.accessToken);
      await _secureStorage.write(key: 'refresh_token', value: session.refreshToken);
    }
  }

  Future<void> _clearSession() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  Future<void> restoreSession() async {
    final refreshToken = await _secureStorage.read(key: 'refresh_token');
    if (refreshToken != null) {
      try {
        await _supabase.auth.setSession(refreshToken);
      } catch (e) {
        await _clearSession();
      }
    }
  }

  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUser == null) return null;
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();
      return data;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? username,
    String? bio,
    DateTime? dateOfBirth,
    String? profession,
    String? heardFrom,
    String? avatarUrl,
    bool? surveyCompleted,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      if (fullName != null) updateData['full_name'] = fullName;
      if (username != null) updateData['username'] = username;
      if (bio != null) updateData['bio'] = bio;
      if (dateOfBirth != null) updateData['date_of_birth'] = dateOfBirth.toIso8601String();
      if (profession != null) updateData['profession'] = profession;
      if (heardFrom != null) updateData['heard_from'] = heardFrom;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (surveyCompleted != null) updateData['survey_completed'] = surveyCompleted;
      updateData['updated_at'] = DateTime.now().toIso8601String();
      
      await _supabase
          .from('profiles')
          .update(updateData)
          .eq('id', userId);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }
}