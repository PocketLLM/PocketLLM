import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

class SupabaseService {
  SupabaseService._internal();

  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() => _instance;

  SupabaseClient? _client;
  bool _isInitialized = false;
  String? _initializationError;

  bool get isConfigured =>
      AppConfig.supabaseUrl.isNotEmpty && AppConfig.supabaseAnonKey.isNotEmpty;

  bool get isInitialized => _isInitialized;

  String? get initializationError => _initializationError;

  SupabaseClient get client {
    final supabaseClient = _client;
    if (supabaseClient == null) {
      throw StateError(
        'Supabase has not been initialized. Call initialize() before accessing the client.',
      );
    }
    return supabaseClient;
  }

  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    if (!isConfigured) {
      _initializationError =
          'Supabase credentials are missing. Provide SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.';
      if (kDebugMode) {
        debugPrint(_initializationError);
      }
      return false;
    }

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        debug: kDebugMode,
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
      _initializationError = null;
      return true;
    } catch (error, stackTrace) {
      _initializationError = error.toString();
      if (kDebugMode) {
        debugPrint('Supabase initialization failed: $error');
        debugPrint(stackTrace.toString());
      }
      return false;
    }
  }
}
