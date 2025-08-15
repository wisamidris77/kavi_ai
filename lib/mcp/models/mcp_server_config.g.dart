// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_server_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

McpServerConfig _$McpServerConfigFromJson(Map<String, dynamic> json) =>
    McpServerConfig(
      name: json['name'] as String,
      command: json['command'] as String,
      args:
          (json['args'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      enabled: json['enabled'] as bool? ?? true,
      env:
          (json['env'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          {},
    );

Map<String, dynamic> _$McpServerConfigToJson(McpServerConfig instance) =>
    <String, dynamic>{
      'name': instance.name,
      'command': instance.command,
      'args': instance.args,
      'enabled': instance.enabled,
      'env': instance.env,
    };
