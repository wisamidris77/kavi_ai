import 'package:json_annotation/json_annotation.dart';

part 'mcp_server_config.g.dart';

@JsonSerializable()
class McpServerConfig {
  const McpServerConfig({
    required this.name,
    required this.command,
    this.args = const [],
    this.enabled = true,
    this.env = const {},
  });

  final String name;
  final String command;
  @JsonKey(defaultValue: <String>[])
  final List<String> args;
  @JsonKey(defaultValue: true)
  final bool enabled;
  @JsonKey(defaultValue: <String, String>{})
  final Map<String, String> env;

  McpServerConfig copyWith({
    String? name,
    String? command,
    List<String>? args,
    bool? enabled,
    Map<String, String>? env,
  }) {
    return McpServerConfig(
      name: name ?? this.name,
      command: command ?? this.command,
      args: args ?? this.args,
      enabled: enabled ?? this.enabled,
      env: env ?? this.env,
    );
  }

  factory McpServerConfig.fromJson(Map<String, dynamic> json) => 
      _$McpServerConfigFromJson(json);
  
  Map<String, dynamic> toJson() => _$McpServerConfigToJson(this);

  String get fullCommand => [command, ...args].join(' ');
} 