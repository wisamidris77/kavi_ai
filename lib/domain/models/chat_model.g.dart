// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatModel _$ChatModelFromJson(Map<String, dynamic> json) => ChatModel(
  id: json['id'] as String,
  title: json['title'] as String,
  providerType: $enumDecode(_$AiProviderTypeEnumMap, json['providerType']),
  model: json['model'] as String?,
  messages:
      (json['messages'] as List<dynamic>?)
          ?.map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ChatModelToJson(ChatModel instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'providerType': _$AiProviderTypeEnumMap[instance.providerType]!,
  'model': instance.model,
  'messages': instance.messages.map((e) => e.toJson()).toList(),
  'metadata': instance.metadata,
};

const _$AiProviderTypeEnumMap = {
  AiProviderType.openAI: 'openAI',
  AiProviderType.deepSeek: 'deepSeek',
  AiProviderType.mock: 'mock',
};
