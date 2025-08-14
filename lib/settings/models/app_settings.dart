import 'package:json_annotation/json_annotation.dart';
import '../../providers/base/provider_type.dart';

part 'app_settings.g.dart';

@JsonSerializable(explicitToJson: true)
class AppSettings {
	const AppSettings({
		required this.activeProvider,
		required this.providers,
		this.defaultTemperature = 0.7,
		this.defaultMaxTokens,
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
			},
		);

	final AiProviderType activeProvider;

	@JsonKey(fromJson: _providersFromJson, toJson: _providersToJson)
	final Map<AiProviderType, ProviderSettings> providers;

	@JsonKey(defaultValue: 0.7)
	final double defaultTemperature;

	final int? defaultMaxTokens;

	AppSettings copyWith({
		AiProviderType? activeProvider,
		Map<AiProviderType, ProviderSettings>? providers,
		double? defaultTemperature,
		int? defaultMaxTokens,
	}) {
		return AppSettings(
			activeProvider: activeProvider ?? this.activeProvider,
			providers: providers ?? this.providers,
			defaultTemperature: defaultTemperature ?? this.defaultTemperature,
			defaultMaxTokens: defaultMaxTokens ?? this.defaultMaxTokens,
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
		return ProviderSettings(
			enabled: enabled ?? this.enabled,
			apiKey: apiKey ?? this.apiKey,
			baseUrl: baseUrl ?? this.baseUrl,
			defaultModel: defaultModel ?? this.defaultModel,
			customModels: customModels ?? this.customModels,
		);
	}

	factory ProviderSettings.fromJson(Map<String, dynamic> json) => _$ProviderSettingsFromJson(json);
	Map<String, dynamic> toJson() => _$ProviderSettingsToJson(this);
} 