import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../providers/providers.dart';

class ProviderHealthChecker extends ChangeNotifier {
  final Map<AiProviderType, ProviderHealth> _healthStatus = {};
  final Map<AiProviderType, Timer> _healthCheckTimers = {};
  
  static const Duration _checkInterval = Duration(minutes: 5);
  static const Duration _timeout = Duration(seconds: 10);

  ProviderHealthChecker() {
    _initializeHealthStatus();
  }

  void _initializeHealthStatus() {
    for (final type in AiProviderType.values) {
      _healthStatus[type] = ProviderHealth(
        type: type,
        status: HealthStatus.unknown,
        lastChecked: null,
        errorMessage: null,
        responseTime: null,
      );
    }
  }

  Map<AiProviderType, ProviderHealth> get healthStatus => Map.unmodifiable(_healthStatus);

  Future<void> checkProviderHealth(
    AiProviderType providerType,
    AiProviderConfig config,
  ) async {
    final startTime = DateTime.now();
    
    try {
      // Update status to checking
      _updateHealthStatus(
        providerType,
        status: HealthStatus.checking,
        lastChecked: startTime,
      );

      // Create provider instance
      final provider = AiProviderFactory.create(
        type: providerType,
        config: config,
      );

      // Test connection with timeout
      final result = await _testProviderWithTimeout(provider);
      
      final responseTime = DateTime.now().difference(startTime);
      
      _updateHealthStatus(
        providerType,
        status: result ? HealthStatus.healthy : HealthStatus.unhealthy,
        lastChecked: DateTime.now(),
        responseTime: responseTime,
      );

    } catch (e) {
      _updateHealthStatus(
        providerType,
        status: HealthStatus.unhealthy,
        lastChecked: DateTime.now(),
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> _testProviderWithTimeout(AiProvider provider) async {
    try {
      // Try to list models as a health check
      final models = await provider.listModels().timeout(_timeout);
      return models.isNotEmpty;
    } catch (e) {
      // If listModels fails, try a simple validation
      try {
        provider.validate();
        return true;
      } catch (e) {
        return false;
      }
    }
  }

  void startPeriodicHealthChecks(Map<AiProviderType, AiProviderConfig> configs) {
    stopPeriodicHealthChecks();
    
    for (final entry in configs.entries) {
      final providerType = entry.key;
      final config = entry.value;
      
      if (config.apiKey.isNotEmpty) {
        final timer = Timer.periodic(_checkInterval, (_) {
          checkProviderHealth(providerType, config);
        });
        
        _healthCheckTimers[providerType] = timer;
        
        // Perform initial check
        checkProviderHealth(providerType, config);
      }
    }
  }

  void stopPeriodicHealthChecks() {
    for (final timer in _healthCheckTimers.values) {
      timer.cancel();
    }
    _healthCheckTimers.clear();
  }

  void _updateHealthStatus(
    AiProviderType providerType, {
    required HealthStatus status,
    DateTime? lastChecked,
    String? errorMessage,
    Duration? responseTime,
  }) {
    _healthStatus[providerType] = _healthStatus[providerType]!.copyWith(
      status: status,
      lastChecked: lastChecked,
      errorMessage: errorMessage,
      responseTime: responseTime,
    );
    
    notifyListeners();
  }

  ProviderHealth getProviderHealth(AiProviderType providerType) {
    return _healthStatus[providerType] ?? ProviderHealth(
      type: providerType,
      status: HealthStatus.unknown,
    );
  }

  bool isProviderHealthy(AiProviderType providerType) {
    final health = _healthStatus[providerType];
    return health?.status == HealthStatus.healthy;
  }

  List<AiProviderType> getHealthyProviders() {
    return _healthStatus.entries
        .where((entry) => entry.value.status == HealthStatus.healthy)
        .map((entry) => entry.key)
        .toList();
  }

  @override
  void dispose() {
    stopPeriodicHealthChecks();
    super.dispose();
  }
}

class ProviderHealth {
  final AiProviderType type;
  final HealthStatus status;
  final DateTime? lastChecked;
  final String? errorMessage;
  final Duration? responseTime;

  const ProviderHealth({
    required this.type,
    required this.status,
    this.lastChecked,
    this.errorMessage,
    this.responseTime,
  });

  ProviderHealth copyWith({
    AiProviderType? type,
    HealthStatus? status,
    DateTime? lastChecked,
    String? errorMessage,
    Duration? responseTime,
  }) {
    return ProviderHealth(
      type: type ?? this.type,
      status: status ?? this.status,
      lastChecked: lastChecked ?? this.lastChecked,
      errorMessage: errorMessage ?? this.errorMessage,
      responseTime: responseTime ?? this.responseTime,
    );
  }

  String get statusText {
    switch (status) {
      case HealthStatus.healthy:
        return 'Healthy';
      case HealthStatus.unhealthy:
        return 'Unhealthy';
      case HealthStatus.checking:
        return 'Checking...';
      case HealthStatus.unknown:
        return 'Unknown';
    }
  }

  Color get statusColor {
    switch (status) {
      case HealthStatus.healthy:
        return Colors.green;
      case HealthStatus.unhealthy:
        return Colors.red;
      case HealthStatus.checking:
        return Colors.orange;
      case HealthStatus.unknown:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case HealthStatus.healthy:
        return Icons.check_circle;
      case HealthStatus.unhealthy:
        return Icons.error;
      case HealthStatus.checking:
        return Icons.hourglass_empty;
      case HealthStatus.unknown:
        return Icons.help;
    }
  }
}

enum HealthStatus {
  healthy,
  unhealthy,
  checking,
  unknown,
}