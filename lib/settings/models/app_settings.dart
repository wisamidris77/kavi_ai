import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';
import '../../providers/base/provider_type.dart';
import '../../mcp/models/mcp_server_config.dart';

part 'app_settings.g.dart';

@JsonSerializable(explicitToJson: true)
class AppSettings {
	const AppSettings({
		required this.activeProvider,
		required this.providers,
		this.defaultTemperature = 0.7,
		this.defaultMaxTokens,
		this.themeMode = ThemeMode.system,
		this.primaryColorSeed = 0xFF673AB7,
		this.startOnOpenMode = StartOnOpenMode.newChat,
		this.mcpServers = const [],
		this.mcpEnabled = false,
	});

	factory AppSettings.initial() => AppSettings(
			activeProvider: AiProviderType.openAI,
			providers: {
				AiProviderType.openAI: const ProviderSettings(
					enabled: true,
					apiKey: '',
				),
				AiProviderType.deepSeek: const ProviderSettings(
					enabled: false,
					apiKey: '',
				),
				AiProviderType.ollama: const ProviderSettings(
					enabled: false,
					apiKey: '', // Not used for Ollama but kept for consistency
					baseUrl: 'http://localhost:11434',
					defaultModel: 'llama3.2',
				),
			},
		);

	final AiProviderType activeProvider;

	@JsonKey(fromJson: _providersFromJson, toJson: _providersToJson)
	final Map<AiProviderType, ProviderSettings> providers;

	@JsonKey(defaultValue: 0.7)
	final double defaultTemperature;

	final int? defaultMaxTokens;

	@JsonKey(fromJson: _themeModeFromJson, toJson: _themeModeToJson)
	final ThemeMode themeMode;

	/// Stored as ARGB int value
	@JsonKey(defaultValue: 0xFF673AB7)
	final int primaryColorSeed;

	@JsonKey(fromJson: _startModeFromJson, toJson: _startModeToJson)
	final StartOnOpenMode startOnOpenMode;

	@JsonKey(defaultValue: <McpServerConfig>[])
	final List<McpServerConfig> mcpServers;

	@JsonKey(defaultValue: false)
	final bool mcpEnabled;

	AppSettings copyWith({
		AiProviderType? activeProvider,
		Map<AiProviderType, ProviderSettings>? providers,
		double? defaultTemperature,
		int? defaultMaxTokens,
		ThemeMode? themeMode,
		int? primaryColorSeed,
		StartOnOpenMode? startOnOpenMode,
		List<McpServerConfig>? mcpServers,
		bool? mcpEnabled,
	}) {
		return AppSettings(
			activeProvider: activeProvider ?? this.activeProvider,
			providers: providers ?? this.providers,
			defaultTemperature: defaultTemperature ?? this.defaultTemperature,
			defaultMaxTokens: defaultMaxTokens ?? this.defaultMaxTokens,
			themeMode: themeMode ?? this.themeMode,
			primaryColorSeed: primaryColorSeed ?? this.primaryColorSeed,
			startOnOpenMode: startOnOpenMode ?? this.startOnOpenMode,
			mcpServers: mcpServers ?? this.mcpServers,
			mcpEnabled: mcpEnabled ?? this.mcpEnabled,
		);
	}

	factory AppSettings.fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);
	Map<String, dynamic> toJson() => _$AppSettingsToJson(this);

	static Map<AiProviderType, ProviderSettings> _providersFromJson(Map<String, dynamic> json) {
		final result = <AiProviderType, ProviderSettings>{};
		json.forEach((key, value) {
			final AiProviderType type = AiProviderType.values.firstWhere(
					(e) => e.name == key,
					orElse: () => AiProviderType.openAI,
				);
			result[type] = ProviderSettings.fromJson(value as Map<String, dynamic>);
		});
		return result;
	}

	static Map<String, dynamic> _providersToJson(Map<AiProviderType, ProviderSettings> map) {
		return map.map((key, value) => MapEntry(key.name, value.toJson()));
	}

	static ThemeMode _themeModeFromJson(Object? value) {
		final String name = (value is String ? value : null) ?? ThemeModeValues.system;
		switch (name) {
			case ThemeModeValues.light:
				return ThemeMode.light;
			case ThemeModeValues.dark:
				return ThemeMode.dark;
			case ThemeModeValues.system:
			default:
				return ThemeMode.system;
		}
	}

	static String _themeModeToJson(ThemeMode mode) {
		switch (mode) {
			case ThemeMode.light:
				return ThemeModeValues.light;
			case ThemeMode.dark:
				return ThemeModeValues.dark;
			case ThemeMode.system:
			return ThemeModeValues.system;
		}
	}

	static StartOnOpenMode _startModeFromJson(Object? value) {
		final String name = (value is String ? value : null) ?? StartOnOpenModeValues.newChat;
		switch (name) {
			case StartOnOpenModeValues.firstChat:
				return StartOnOpenMode.firstChat;
			case StartOnOpenModeValues.lastChat:
				return StartOnOpenMode.lastChat;
			case StartOnOpenModeValues.newChat:
			default:
				return StartOnOpenMode.newChat;
		}
	}

	static String _startModeToJson(StartOnOpenMode mode) {
		switch (mode) {
			case StartOnOpenMode.firstChat:
				return StartOnOpenModeValues.firstChat;
			case StartOnOpenMode.lastChat:
				return StartOnOpenModeValues.lastChat;
			case StartOnOpenMode.newChat:
			default:
				return StartOnOpenModeValues.newChat;
		}
	}
}

class ThemeModeValues {
	static const String system = 'system';
	static const String light = 'light';
	static const String dark = 'dark';
}

enum StartOnOpenMode { newChat, firstChat, lastChat }

class StartOnOpenModeValues {
	static const String newChat = 'newChat';
	static const String firstChat = 'firstChat';
	static const String lastChat = 'lastChat';
}

@JsonSerializable()
class ProviderSettings {
	const ProviderSettings({
		required this.enabled,
		required this.apiKey,
		this.baseUrl,
		this.defaultModel,
		this.customModels = const <String>[],
	});

	final bool enabled;
	final String apiKey;
	final String? baseUrl;
	final String? defaultModel;

	@JsonKey(defaultValue: <String>[])
	final List<String> customModels;

	  ProviderSettings copyWith({
    bool? enabled,
    String? apiKey,
    String? baseUrl,
    String? defaultModel,
    List<String>? customModels,
  }) {
    // Clean up invalid base URLs
    String? cleanBaseUrl = baseUrl ?? this.baseUrl;
    if (cleanBaseUrl != null && 
        (cleanBaseUrl.isEmpty || 
         cleanBaseUrl == 'http' || 
         cleanBaseUrl == 'https' ||
         cleanBaseUrl == 'http:' ||
         cleanBaseUrl == 'https:' ||
         cleanBaseUrl == 'http://' ||
         cleanBaseUrl == 'https://')) {
      cleanBaseUrl = null;
    }
    
    return ProviderSettings(
      enabled: enabled ?? this.enabled,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: cleanBaseUrl,
      defaultModel: defaultModel ?? this.defaultModel,
      customModels: customModels ?? this.customModels,
    );
  }

	  factory ProviderSettings.fromJson(Map<String, dynamic> json) {
    final settings = _$ProviderSettingsFromJson(json);
    // Clean up invalid base URLs when loading from JSON
    if (settings.baseUrl != null && 
        (settings.baseUrl!.isEmpty || 
         settings.baseUrl == 'http' || 
         settings.baseUrl == 'https' ||
         settings.baseUrl == 'http:' ||
         settings.baseUrl == 'https:' ||
         settings.baseUrl == 'http://' ||
         settings.baseUrl == 'https://')) {
      return ProviderSettings(
        enabled: settings.enabled,
        apiKey: settings.apiKey,
        baseUrl: null, // Clear invalid base URL
        defaultModel: settings.defaultModel,
        customModels: settings.customModels,
      );
    }
    return settings;
  }
  
  Map<String, dynamic> toJson() => _$ProviderSettingsToJson(this);
} 