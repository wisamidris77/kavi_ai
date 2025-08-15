// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_call_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolCallInfo _$ToolCallInfoFromJson(Map<String, dynamic> json) => ToolCallInfo(
  toolKey: json['toolKey'] as String,
  toolName: json['toolName'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  arguments: json['arguments'] as Map<String, dynamic>?,
  result: json['result'] as String?,
  error: json['error'] as String?,
  duration: json['duration'] == null
      ? null
      : Duration(microseconds: (json['duration'] as num).toInt()),
);

Map<String, dynamic> _$ToolCallInfoToJson(ToolCallInfo instance) =>
    <String, dynamic>{
      'toolKey': instance.toolKey,
      'toolName': instance.toolName,
      'timestamp': instance.timestamp.toIso8601String(),
      'arguments': instance.arguments,
      'result': instance.result,
      'error': instance.error,
      'duration': instance.duration?.inMicroseconds,
    };
