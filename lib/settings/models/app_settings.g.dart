// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => AppSettings(
  activeProvider: $enumDecode(_$AiProviderTypeEnumMap, json['activeProvider']),
  providers: (json['providers'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(
      $enumDecode(_$AiProviderTypeEnumMap, k),
      ProviderSettings.fromJson(e as Map<String, dynamic>),
    ),
  ),
  defaultTemperature: (json['defaultTemperature'] as num?)?.toDouble() ?? 0.7,
  defaultMaxTokens: (json['defaultMaxTokens'] as num?)?.toInt(),
);

Map<String, dynamic> _$AppSettingsToJson(AppSettings instance) =>
    <String, dynamic>{
      'activeProvider': _$AiProviderTypeEnumMap[instance.activeProvider]!,
      'providers': instance.providers.map(
        (k, e) => MapEntry(_$AiProviderTypeEnumMap[k]!, e.toJson()),
      ),
      'defaultTemperature': instance.defaultTemperature,
      'defaultMaxTokens': instance.defaultMaxTokens,
    };

const _$AiProviderTypeEnumMap = {
  AiProviderType.openAI: 'openAI',
  AiProviderType.deepSeek: 'deepSeek',
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
