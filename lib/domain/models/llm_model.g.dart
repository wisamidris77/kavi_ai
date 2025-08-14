// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'llm_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LlmModel _$LlmModelFromJson(Map<String, dynamic> json) => LlmModel(
  name: json['name'] as String,
  providerType: $enumDecode(_$AiProviderTypeEnumMap, json['providerType']),
  contextWindow: (json['contextWindow'] as num?)?.toInt(),
  supportsTools: json['supportsTools'] as bool? ?? false,
  capabilities: json['capabilities'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$LlmModelToJson(LlmModel instance) => <String, dynamic>{
  'name': instance.name,
  'providerType': _$AiProviderTypeEnumMap[instance.providerType]!,
  'contextWindow': instance.contextWindow,
  'supportsTools': instance.supportsTools,
  'capabilities': instance.capabilities,
};

const _$AiProviderTypeEnumMap = {
  AiProviderType.openAI: 'openAI',
  AiProviderType.deepSeek: 'deepSeek',
  AiProviderType.mock: 'mock',
};
