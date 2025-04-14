import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'local_db_service.dart';
import '../component/models.dart';

class AuthService {
  final LocalDBService _localDBService = LocalDBService();
  final _secureStorage = const FlutterSecureStorage();

  User? get currentUser => _localDBService.currentUser;
  bool get isLoggedIn => currentUser != null;

  // Check if an email exists in the local database
  Future<bool> checkEmailExists(String email) async {
    try {
      final user = await _localDBService.getUserByEmail(email);
      return user != null;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  Future<User> signUp({
    required String email,
    required String password,
    String? fullName,
    String? username,
  }) async {
    try {
      final exists = await checkEmailExists(email);
      if (exists) {
        throw Exception('Email is already in use.');
      }
      
      final user = await _localDBService.register(
        email: email,
        password: password,
        fullName: fullName,
        username: username,
      );
      
      await _storeSession(user.id);
      return user;
    } catch (e) {
      print('Signup error: $e');
      rethrow;
    }
  }

  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _localDBService.login(
        email: email,
        password: password,
      );
      await _storeSession(user.id);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _localDBService.logout();
    await _clearSession();
  }

  Future<void> _storeSession(String userId) async {
    await _secureStorage.write(key: 'user_id', value: userId);
  }

  Future<void> _clearSession() async {
    await _secureStorage.delete(key: 'user_id');
  }

  Future<void> restoreSession() async {
    final userId = await _secureStorage.read(key: 'user_id');
    if (userId != null) {
      try {
        await _localDBService.loginWithId(userId);
      } catch (e) {
        await _clearSession();
      }
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      // Generate a temporary password
      const tempPassword = 'Reset123!';
      await _localDBService.resetPassword(
        email: email,
        newPassword: tempPassword,
      );
      // In a real app, you would send this password via email
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }

  Future<User?> getUserData() async {
    try {
      if (currentUser == null) return null;
      return currentUser;
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
      await _localDBService.updateUserProfile(
        userId: userId,
        fullName: fullName,
        username: username,
        bio: bio,
        dateOfBirth: dateOfBirth,
        profession: profession,
        avatarUrl: avatarUrl,
      );
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }
}