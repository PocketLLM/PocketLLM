import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ErrorService {
  static const String _errorLogKey = 'error_logs';
  static final ErrorService _instance = ErrorService._internal();
  
  // Private constructor
  ErrorService._internal();
  
  // Singleton pattern
  factory ErrorService() => _instance;
  
  // Log an error
  Future<void> logError(String errorMessage, StackTrace? stackTrace) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final errorLogs = prefs.getStringList(_errorLogKey) ?? [];
      
      final errorLog = {
        'timestamp': DateTime.now().toIso8601String(),
        'message': errorMessage,
        'stackTrace': stackTrace?.toString(),
      };
      
      errorLogs.add(jsonEncode(errorLog));
      
      // Keep only the most recent 50 errors
      if (errorLogs.length > 50) {
        errorLogs.removeAt(0);
      }
      
      await prefs.setStringList(_errorLogKey, errorLogs);
      
      // Print to console in debug mode
      if (kDebugMode) {
        print('ERROR: $errorMessage');
        if (stackTrace != null) {
          print(stackTrace);
        }
      }
    } catch (e) {
      // Fallback logging if there's an error with SharedPreferences
      if (kDebugMode) {
        print('Failed to log error: $e');
        print('Original error: $errorMessage');
      }
    }
  }
  
  // Get all error logs
  Future<List<Map<String, dynamic>>> getErrorLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final errorLogs = prefs.getStringList(_errorLogKey) ?? [];
      
      return errorLogs
          .map((log) => jsonDecode(log) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get error logs: $e');
      }
      return [];
    }
  }
  
  // Clear all error logs
  Future<void> clearErrorLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_errorLogKey);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to clear error logs: $e');
      }
    }
  }
  
  // Show an error dialog
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error', style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  // Show a snackbar error message
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
} 