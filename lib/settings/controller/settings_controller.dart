import 'package:flutter/foundation.dart';

import '../../providers/base/provider_type.dart';
import '../models/app_settings.dart';
import '../repository/settings_repository.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._repository);

  final SettingsRepository _repository;

  AppSettings _settings = AppSettings.initial();
  AppSettings get settings => _settings;

  bool _onboardingComplete = false;
  bool get onboardingComplete => _onboardingComplete;

  Future<void> load() async {
    _settings = await _repository.load();
    _onboardingComplete = await _repository.isOnboardingComplete();
    notifyListeners();
  }

  Future<void> save() async {
    await _repository.save(_settings);
  }

  Future<void> setOnboardingComplete(bool value) async {
    _onboardingComplete = value;
    notifyListeners();
    await _repository.setOnboardingComplete(value);
  }

  /// Replace all settings at once.
  /// If [persist] is true, the new settings are saved to storage.
  void replaceSettings(AppSettings newSettings, {bool persist = false}) {
    _settings = newSettings;
    notifyListeners();
    if (persist) {
      save();
    }
  }

  void setActiveProvider(AiProviderType type) {
    _settings = _settings.copyWith(activeProvider: type);
    notifyListeners();
    save();
  }

  void setProviderEnabled(AiProviderType type, bool enabled) {
    final current = Map<AiProviderType, ProviderSettings>.from(_settings.providers);
    final ProviderSettings ps = (current[type] ?? const ProviderSettings(enabled: false, apiKey: ''))
        .copyWith(enabled: enabled);
    current[type] = ps;
    _settings = _settings.copyWith(providers: current);
    notifyListeners();
    save();
  }

  void setApiKey(AiProviderType type, String apiKey) {
    final current = Map<AiProviderType, ProviderSettings>.from(_settings.providers);
    final ProviderSettings ps = (current[type] ?? const ProviderSettings(enabled: false, apiKey: ''))
        .copyWith(apiKey: apiKey);
    current[type] = ps;
    _settings = _settings.copyWith(providers: current);
    notifyListeners();
    save();
  }

  void setBaseUrl(AiProviderType type, String? baseUrl) {
    final current = Map<AiProviderType, ProviderSettings>.from(_settings.providers);
    final ProviderSettings ps = (current[type] ?? const ProviderSettings(enabled: false, apiKey: ''))
        .copyWith(baseUrl: baseUrl);
    current[type] = ps;
    _settings = _settings.copyWith(providers: current);
    notifyListeners();
    save();
  }

  void setDefaultModel(AiProviderType type, String? model) {
    final current = Map<AiProviderType, ProviderSettings>.from(_settings.providers);
    final ProviderSettings ps = (current[type] ?? const ProviderSettings(enabled: false, apiKey: ''))
        .copyWith(defaultModel: model);
    current[type] = ps;
    _settings = _settings.copyWith(providers: current);
    notifyListeners();
    save();
  }

  void addCustomModel(AiProviderType type, String modelName) {
    final current = Map<AiProviderType, ProviderSettings>.from(_settings.providers);
    final ProviderSettings existing = current[type] ?? const ProviderSettings(enabled: false, apiKey: '');
    final List<String> updated = List<String>.from(existing.customModels);
    if (!updated.contains(modelName) && modelName.trim().isNotEmpty) {
      updated.add(modelName.trim());
      current[type] = existing.copyWith(customModels: updated);
      _settings = _settings.copyWith(providers: current);
      notifyListeners();
      save();
    }
  }

  void removeCustomModel(AiProviderType type, String modelName) {
    final current = Map<AiProviderType, ProviderSettings>.from(_settings.providers);
    final ProviderSettings existing = current[type] ?? const ProviderSettings(enabled: false, apiKey: '');
    final List<String> updated = List<String>.from(existing.customModels)..remove(modelName);
    current[type] = existing.copyWith(customModels: updated);
    _settings = _settings.copyWith(providers: current);
    notifyListeners();
    save();
  }

  void setDefaultTemperature(double value) {
    _settings = _settings.copyWith(defaultTemperature: value);
    notifyListeners();
    save();
  }

  void setDefaultMaxTokens(int? value) {
    _settings = _settings.copyWith(defaultMaxTokens: value);
    notifyListeners();
    save();
  }
} 