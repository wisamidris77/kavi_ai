// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => AppSettings(
  activeProvider: $enumDecode(_$AiProviderTypeEnumMap, json['activeProvider']),
  providers: AppSettings._providersFromJson(
    json['providers'] as Map<String, dynamic>,
  ),
  defaultTemperature: (json['defaultTemperature'] as num?)?.toDouble() ?? 0.7,
  defaultMaxTokens: (json['defaultMaxTokens'] as num?)?.toInt(),
  themeMode: json['themeMode'] == null
      ? ThemeMode.system
      : AppSettings._themeModeFromJson(json['themeMode']),
  primaryColorSeed: (json['primaryColorSeed'] as num?)?.toInt() ?? 4284955319,
  startOnOpenMode: json['startOnOpenMode'] == null
      ? StartOnOpenMode.newChat
      : AppSettings._startModeFromJson(json['startOnOpenMode']),
  mcpServers:
      (json['mcpServers'] as List<dynamic>?)
          ?.map((e) => McpServerConfig.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  mcpEnabled: json['mcpEnabled'] as bool? ?? false,
);

Map<String, dynamic> _$AppSettingsToJson(AppSettings instance) =>
    <String, dynamic>{
      'activeProvider': _$AiProviderTypeEnumMap[instance.activeProvider]!,
      'providers': AppSettings._providersToJson(instance.providers),
      'defaultTemperature': instance.defaultTemperature,
      'defaultMaxTokens': instance.defaultMaxTokens,
      'themeMode': AppSettings._themeModeToJson(instance.themeMode),
      'primaryColorSeed': instance.primaryColorSeed,
      'startOnOpenMode': AppSettings._startModeToJson(instance.startOnOpenMode),
      'mcpServers': instance.mcpServers.map((e) => e.toJson()).toList(),
      'mcpEnabled': instance.mcpEnabled,
    };

const _$AiProviderTypeEnumMap = {
  AiProviderType.openAI: 'openAI',
  AiProviderType.deepSeek: 'deepSeek',
  AiProviderType.mock: 'mock',
};

ProviderSettings _$ProviderSettingsFromJson(Map<String, dynamic> json) =>
    ProviderSettings(
      enabled: json['enabled'] as bool,
      apiKey: json['apiKey'] as String,
      baseUrl: json['baseUrl'] as String?,
      defaultModel: json['defaultModel'] as String?,
      customModels:
          (json['customModels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$ProviderSettingsToJson(ProviderSettings instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'apiKey': instance.apiKey,
      'baseUrl': instance.baseUrl,
      'defaultModel': instance.defaultModel,
      'customModels': instance.customModels,
    };
