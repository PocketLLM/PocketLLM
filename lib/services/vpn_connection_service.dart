import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/vpn_models.dart';

/// Manages connection state, available locations, and usage analytics for the
/// VPN dashboard experience.
class VpnConnectionService extends ChangeNotifier {
  VpnConnectionService() {
    _liveQuality = _selectedLocation.quality;
  }

  final Random _random = Random();

  ConnectionStatus _status = ConnectionStatus.disconnected;
  VpnLocation _selectedLocation = const VpnLocation(
    city: 'New York #1 · United States',
    countryCode: 'US',
    latencyMs: 24,
  );

  final List<VpnLocation> _locations = const <VpnLocation>[
    VpnLocation(city: 'New York #1 · United States', countryCode: 'US', latencyMs: 24),
    VpnLocation(city: 'San Francisco · United States', countryCode: 'US', latencyMs: 32),
    VpnLocation(city: 'Toronto · Canada', countryCode: 'CA', latencyMs: 41),
    VpnLocation(city: 'London · United Kingdom', countryCode: 'GB', latencyMs: 48),
    VpnLocation(city: 'Amsterdam · Netherlands', countryCode: 'NL', latencyMs: 52),
    VpnLocation(city: 'Frankfurt · Germany', countryCode: 'DE', latencyMs: 56),
    VpnLocation(city: 'Stockholm · Sweden', countryCode: 'SE', latencyMs: 64),
    VpnLocation(city: 'Dubai · United Arab Emirates', countryCode: 'AE', latencyMs: 92, isPremium: true),
    VpnLocation(city: 'Mumbai · India', countryCode: 'IN', latencyMs: 104, isPremium: true),
    VpnLocation(city: 'Singapore · Singapore', countryCode: 'SG', latencyMs: 118, isPremium: true),
    VpnLocation(city: 'Tokyo · Japan', countryCode: 'JP', latencyMs: 128, isPremium: true),
    VpnLocation(city: 'Sydney · Australia', countryCode: 'AU', latencyMs: 182, isPremium: true),
  ];

  Timer? _sessionTimer;
  DateTime? _connectedAt;
  Duration _sessionDuration = Duration.zero;
  double _sessionDataUsageMb = 0;
  double _lifetimeUsageMb = 0;
  int? _activeHistoryIndex;
  ConnectionQuality _liveQuality = ConnectionQuality.good;
  final List<HistoryEntry> _history = <HistoryEntry>[];
  final List<String> _alerts = <String>[
    'Enable Smart Kill Switch to protect against sudden drops.',
    'Multi-hop is available on premium routes for extra privacy.',
  ];

  double _monthlyUsageMb = 5120; // 5 GB used by default to show progress.
  final double _monthlyLimitMb = 51200; // 50 GB monthly limit.

  ConnectionStatus get status => _status;
  VpnLocation get selectedLocation => _selectedLocation;
  Duration get sessionDuration => _sessionDuration;
  double get sessionDataUsageMb => _sessionDataUsageMb;
  double get lifetimeUsageMb => _lifetimeUsageMb;
  double get monthlyUsageMb => _monthlyUsageMb;
  double get monthlyLimitMb => _monthlyLimitMb;

  ConnectionQuality get connectionQuality =>
      _status == ConnectionStatus.connected ? _liveQuality : _selectedLocation.quality;

  List<VpnLocation> get locations => List<VpnLocation>.unmodifiable(_locations);
  List<HistoryEntry> get history => List<HistoryEntry>.unmodifiable(_history);
  List<String> get alerts => List<String>.unmodifiable(_alerts.take(3));

  bool get isBusy => _status == ConnectionStatus.connecting;
  bool get isConnected => _status == ConnectionStatus.connected;

  String get formattedSessionDuration {
    if (_sessionDuration.inSeconds == 0) return '00:00:00';
    final hours = _sessionDuration.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = _sessionDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _sessionDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String get formattedSessionUsage => _formatDataSize(_sessionDataUsageMb);
  String get formattedMonthlyUsage => _formatDataSize(_monthlyUsageMb);
  String get formattedMonthlyLimit => _formatDataSize(_monthlyLimitMb);

  double get monthlyUsagePercent =>
      (_monthlyUsageMb / _monthlyLimitMb).clamp(0.0, 1.0);

  Future<void> toggleConnection() async {
    if (_status == ConnectionStatus.connecting) {
      return;
    }
    if (_status == ConnectionStatus.connected) {
      _disconnect(addHistory: true, reason: 'Disconnected manually');
      return;
    }
    await _connect();
  }

  Future<void> _connect() async {
    _status = ConnectionStatus.connecting;
    _alerts.removeWhere((alert) => alert.contains('Connected'));
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 600));

    _connectedAt = DateTime.now();
    _sessionDuration = Duration.zero;
    _sessionDataUsageMb = 0;
    _liveQuality = ConnectionQuality.mix(
      _selectedLocation.quality,
      randomQuality(_random),
    );
    _status = ConnectionStatus.connected;

    final entry = HistoryEntry.connection(
      timestamp: DateTime.now(),
      location: _selectedLocation,
      status: ConnectionStatus.connected,
      duration: Duration.zero,
      dataUsageMb: 0,
      quality: _liveQuality,
    );
    _history.insert(0, entry);
    _activeHistoryIndex = 0;

    _alerts.insert(0, 'Connected to ${_selectedLocation.city}.');
    while (_alerts.length > 5) {
      _alerts.removeLast();
    }

    _startSessionTimer();
    notifyListeners();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    int tick = 0;
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_status != ConnectionStatus.connected || _connectedAt == null) {
        return;
      }
      tick += 1;
      _sessionDuration = DateTime.now().difference(_connectedAt!);
      final usageIncrement = 0.35 + _random.nextDouble() * 0.25;
      _sessionDataUsageMb += usageIncrement;

      if (tick % 6 == 0) {
        _liveQuality = ConnectionQuality.mix(
          _selectedLocation.quality,
          randomQuality(_random),
        );
      }

      _updateActiveHistoryEntry(
        duration: _sessionDuration,
        dataUsageMb: _sessionDataUsageMb,
        quality: _liveQuality,
      );

      notifyListeners();
    });
  }

  void _disconnect({required bool addHistory, required String reason}) {
    if (_status == ConnectionStatus.disconnected) {
      return;
    }
    _sessionTimer?.cancel();
    _sessionTimer = null;

    if (_connectedAt != null) {
      _sessionDuration = DateTime.now().difference(_connectedAt!);
    }

    _lifetimeUsageMb += _sessionDataUsageMb;
    _monthlyUsageMb += _sessionDataUsageMb;

    _updateActiveHistoryEntry(
      duration: _sessionDuration,
      dataUsageMb: _sessionDataUsageMb,
      status: ConnectionStatus.disconnected,
      quality: _selectedLocation.quality,
    );

    if (_activeHistoryIndex == null && addHistory) {
      _history.insert(
        0,
        HistoryEntry.connection(
          timestamp: DateTime.now(),
          location: _selectedLocation,
          status: ConnectionStatus.disconnected,
          duration: _sessionDuration,
          dataUsageMb: _sessionDataUsageMb,
          quality: _selectedLocation.quality,
        ),
      );
    }

    _alerts.insert(0, reason);
    while (_alerts.length > 5) {
      _alerts.removeLast();
    }

    _status = ConnectionStatus.disconnected;
    _connectedAt = null;
    _activeHistoryIndex = null;
    _sessionDuration = Duration.zero;
    _sessionDataUsageMb = 0;

    notifyListeners();
  }

  void disconnect({String reason = 'Connection ended'}) {
    _disconnect(addHistory: true, reason: reason);
  }

  Future<void> selectLocation(VpnLocation location) async {
    if (_status == ConnectionStatus.connecting ||
        identical(location, _selectedLocation)) {
      return;
    }

    final wasConnected = _status == ConnectionStatus.connected;
    if (wasConnected) {
      _disconnect(addHistory: true, reason: 'Switching to ${location.city}');
    }

    _selectedLocation = location;
    _liveQuality = location.quality;
    notifyListeners();

    if (wasConnected) {
      await _connect();
    }
  }

  void addSpeedTestResult(SpeedTestResult result) {
    _history.insert(0, HistoryEntry.speedTest(result: result));
    notifyListeners();
  }

  void removeHistoryEntry(HistoryEntry entry) {
    _history.remove(entry);
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  void _updateActiveHistoryEntry({
    Duration? duration,
    double? dataUsageMb,
    ConnectionStatus? status,
    ConnectionQuality? quality,
  }) {
    final index = _activeHistoryIndex;
    if (index == null || index >= _history.length) {
      return;
    }
    final current = _history[index];
    if (current.type != HistoryEntryType.connection) {
      return;
    }
    _history[index] = HistoryEntry.connection(
      timestamp: current.timestamp,
      location: current.location,
      status: status ?? current.status,
      duration: duration ?? current.duration,
      dataUsageMb: dataUsageMb ?? current.dataUsageMb,
      quality: quality ?? current.quality,
    );
  }

  static String _formatDataSize(double valueMb) {
    if (valueMb >= 1024) {
      final gb = valueMb / 1024;
      return '${gb.toStringAsFixed(gb >= 10 ? 1 : 2)} GB';
    }
    return '${valueMb.toStringAsFixed(valueMb >= 10 ? 1 : 2)} MB';
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}
