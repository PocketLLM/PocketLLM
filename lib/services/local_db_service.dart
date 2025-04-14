import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class User {
  final String id;
  final String email;
  final String? fullName;
  final String? username;
  final String? bio;
  final DateTime? dateOfBirth;
  final String? profession;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? surveyCompleted;

  User({
    required this.id,
    required this.email,
    this.fullName,
    this.username,
    this.bio,
    this.dateOfBirth,
    this.profession,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.surveyCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'username': username,
      'bio': bio,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'profession': profession,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'survey_completed': surveyCompleted == true ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      fullName: map['full_name'],
      username: map['username'],
      bio: map['bio'],
      dateOfBirth: map['date_of_birth'] != null ? DateTime.parse(map['date_of_birth']) : null,
      profession: map['profession'],
      avatarUrl: map['avatar_url'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      surveyCompleted: map['survey_completed'] == 1,
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? username,
    String? bio,
    DateTime? dateOfBirth,
    String? profession,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? surveyCompleted,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profession: profession ?? this.profession,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      surveyCompleted: surveyCompleted ?? this.surveyCompleted,
    );
  }
}

class LocalDBService {
  static final LocalDBService _instance = LocalDBService._internal();
  static Database? _database;
  final _secureStorage = const FlutterSecureStorage();
  final String _currentUserKey = 'current_user';
  
  // Private constructor
  LocalDBService._internal();
  
  // Singleton pattern
  factory LocalDBService() => _instance;
  
  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  // Initialize database
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pocketllm.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }
  
  // Create database tables
  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        full_name TEXT,
        username TEXT,
        bio TEXT,
        date_of_birth TEXT,
        profession TEXT,
        avatar_url TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        survey_completed INTEGER DEFAULT 0
      )
    ''');
  }
  
  // Current user getter
  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  
  // Initialize and check for saved user
  Future<void> initialize() async {
    try {
      final userId = await _secureStorage.read(key: _currentUserKey);
      if (userId != null) {
        final user = await getUserById(userId);
        if (user != null) {
          _currentUser = user;
        }
      }
    } catch (e) {
      debugPrint('Error initializing LocalDBService: $e');
    }
  }
  
  // Register a new user
  Future<User> register({
    required String email,
    required String password,
    String? fullName,
    String? username,
  }) async {
    // Check if user already exists
    final existingUser = await getUserByEmail(email);
    if (existingUser != null) {
      throw Exception('A user with this email already exists');
    }
    
    final db = await database;
    final uuid = const Uuid();
    final userId = uuid.v4();
    final now = DateTime.now();
    
    // Hash the password (in a real app, use a proper password hashing algorithm)
    final passwordHash = base64Encode(utf8.encode(password));
    
    // Create the user
    final user = User(
      id: userId,
      email: email,
      fullName: fullName,
      username: username,
      createdAt: now,
      updatedAt: now,
    );
    
    // Insert into database
    final userMap = user.toMap();
    userMap['password_hash'] = passwordHash;
    
    await db.insert('users', userMap);
    
    // Set as current user
    _currentUser = user;
    await _secureStorage.write(key: _currentUserKey, value: userId);
    
    return user;
  }
  
  // Login user
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final db = await database;
    
    // Hash the password
    final passwordHash = base64Encode(utf8.encode(password));
    
    // Find user with matching email and password
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email, passwordHash],
    );
    
    if (results.isEmpty) {
      throw Exception('Invalid email or password');
    }
    
    final user = User.fromMap(results.first);
    
    // Set as current user
    _currentUser = user;
    await _secureStorage.write(key: _currentUserKey, value: user.id);
    
    return user;
  }
  
  // Get user by ID
  Future<User?> getUserById(String id) async {
    final db = await database;
    
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (results.isEmpty) {
      return null;
    }
    
    return User.fromMap(results.first);
  }
  
  // Login with user ID
  Future<User> loginWithId(String userId) async {
    final user = await getUserById(userId);
    
    if (user == null) {
      throw Exception('User not found');
    }
    
    // Set as current user
    _currentUser = user;
    await _secureStorage.write(key: _currentUserKey, value: user.id);
    
    return user;
  }
  
  // Get user by email
  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    
    if (results.isEmpty) {
      return null;
    }
    
    return User.fromMap(results.first);
  }
  
  // Update user profile
  Future<User> updateUserProfile({
    required String userId,
    String? fullName,
    String? username,
    String? bio,
    DateTime? dateOfBirth,
    String? profession,
    String? avatarUrl,
    bool? surveyCompleted,
  }) async {
    final db = await database;
    final now = DateTime.now();
    
    // Get current user data
    final currentData = await getUserById(userId);
    if (currentData == null) {
      throw Exception('User not found');
    }
    
    // Create updated user object
    final updatedUser = currentData.copyWith(
      fullName: fullName,
      username: username,
      bio: bio,
      dateOfBirth: dateOfBirth,
      profession: profession,
      avatarUrl: avatarUrl,
      updatedAt: now,
      surveyCompleted: surveyCompleted,
    );
    
    // Update in database
    await db.update(
      'users',
      updatedUser.toMap(),
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    // Update current user if it's the logged-in user
    if (_currentUser?.id == userId) {
      _currentUser = updatedUser;
    }
    
    return updatedUser;
  }
  
  // Logout
  Future<void> logout() async {
    _currentUser = null;
    await _secureStorage.delete(key: _currentUserKey);
  }
  
  // Change password
  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final db = await database;
    
    // Hash the passwords
    final currentHash = base64Encode(utf8.encode(currentPassword));
    final newHash = base64Encode(utf8.encode(newPassword));
    
    // Verify current password
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'id = ? AND password_hash = ?',
      whereArgs: [userId, currentHash],
    );
    
    if (results.isEmpty) {
      throw Exception('Current password is incorrect');
    }
    
    // Update password
    await db.update(
      'users',
      {'password_hash': newHash, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
  
  // Reset password (simplified version for local implementation)
  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final db = await database;
    final user = await getUserByEmail(email);
    
    if (user == null) {
      throw Exception('User not found');
    }
    
    // Hash the new password
    final newHash = base64Encode(utf8.encode(newPassword));
    
    // Update password
    await db.update(
      'users',
      {'password_hash': newHash, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
  
  // Delete user
  Future<void> deleteUser(String userId) async {
    final db = await database;
    
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    // If this was the current user, log them out
    if (_currentUser?.id == userId) {
      await logout();
    }
  }
} 