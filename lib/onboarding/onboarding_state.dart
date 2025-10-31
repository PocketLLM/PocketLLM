import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingModel>((ref) {
  return OnboardingController();
});

final onboardingFutureProvider = FutureProvider<OnboardingModel>((ref) async {
  final controller = ref.read(onboardingControllerProvider.notifier);
  return controller.load();
});

class OnboardingModel {
  final bool completed;
  final Map<String, String> providerKeys;
  final bool smartRouting;
  final bool toolUse;
  final bool memory;
  final bool localHistoryOnly;
  final bool analytics;
  final bool localVectorCache;

  const OnboardingModel({
    required this.completed,
    required this.providerKeys,
    required this.smartRouting,
    required this.toolUse,
    required this.memory,
    required this.localHistoryOnly,
    required this.analytics,
    required this.localVectorCache,
  });

  factory OnboardingModel.initial() => const OnboardingModel(
        completed: false,
        providerKeys: <String, String>{},
        smartRouting: true,
        toolUse: true,
        memory: true,
        localHistoryOnly: true,
        analytics: false,
        localVectorCache: true,
      );

  OnboardingModel copyWith({
    bool? completed,
    Map<String, String>? providerKeys,
    bool? smartRouting,
    bool? toolUse,
    bool? memory,
    bool? localHistoryOnly,
    bool? analytics,
    bool? localVectorCache,
  }) {
    return OnboardingModel(
      completed: completed ?? this.completed,
      providerKeys: providerKeys ?? this.providerKeys,
      smartRouting: smartRouting ?? this.smartRouting,
      toolUse: toolUse ?? this.toolUse,
      memory: memory ?? this.memory,
      localHistoryOnly: localHistoryOnly ?? this.localHistoryOnly,
      analytics: analytics ?? this.analytics,
      localVectorCache: localVectorCache ?? this.localVectorCache,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completed': completed,
      'providerKeys': providerKeys,
      'smartRouting': smartRouting,
      'toolUse': toolUse,
      'memory': memory,
      'localHistoryOnly': localHistoryOnly,
      'analytics': analytics,
      'localVectorCache': localVectorCache,
    };
  }

  factory OnboardingModel.fromJson(Map<String, dynamic> json) {
    return OnboardingModel(
      completed: json['completed'] as bool? ?? false,
      providerKeys: (json['providerKeys'] as Map?)
              ?.map((key, value) => MapEntry(key.toString(), value.toString())) ??
          {},
      smartRouting: json['smartRouting'] as bool? ?? true,
      toolUse: json['toolUse'] as bool? ?? true,
      memory: json['memory'] as bool? ?? true,
      localHistoryOnly: json['localHistoryOnly'] as bool? ?? true,
      analytics: json['analytics'] as bool? ?? false,
      localVectorCache: json['localVectorCache'] as bool? ?? true,
    );
  }
}

class OnboardingController extends StateNotifier<OnboardingModel> {
  OnboardingController() : super(OnboardingModel.initial());

  static const _prefsKey = 'onboarding_state_v1';
  Timer? _debounce;
  bool _hydrated = false;

  bool get isHydrated => _hydrated;

  Future<OnboardingModel> load() async {
    if (_hydrated) return state;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      state = OnboardingModel.initial();
    } else {
      try {
        final jsonMap = json.decode(raw) as Map<String, dynamic>;
        state = OnboardingModel.fromJson(jsonMap);
      } catch (_) {
        state = OnboardingModel.initial();
      }
    }
    _hydrated = true;
    return state;
  }

  void _queueSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _persist);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, json.encode(state.toJson()));
  }

  void updateProviderKey(String provider, String value) {
    final updated = Map<String, String>.from(state.providerKeys);
    if (value.isEmpty) {
      updated.remove(provider);
    } else {
      updated[provider] = value;
    }
    state = state.copyWith(providerKeys: updated);
    _queueSave();
  }

  void toggleSmartRouting(bool value) {
    state = state.copyWith(smartRouting: value);
    _queueSave();
  }

  void toggleToolUse(bool value) {
    state = state.copyWith(toolUse: value);
    _queueSave();
  }

  void toggleMemory(bool value) {
    state = state.copyWith(memory: value);
    _queueSave();
  }

  void toggleLocalHistory(bool value) {
    state = state.copyWith(localHistoryOnly: value);
    _queueSave();
  }

  void toggleAnalytics(bool value) {
    state = state.copyWith(analytics: value);
    _queueSave();
  }

  void toggleLocalVector(bool value) {
    state = state.copyWith(localVectorCache: value);
    _queueSave();
  }

  void complete() {
    state = state.copyWith(completed: true);
    _queueSave();
  }

  void reset() {
    state = OnboardingModel.initial();
    _queueSave();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
