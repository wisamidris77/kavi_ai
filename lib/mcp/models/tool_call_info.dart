import 'package:json_annotation/json_annotation.dart';

part 'tool_call_info.g.dart';

@JsonSerializable(explicitToJson: true)
class ToolCallInfo {
  const ToolCallInfo({
    required this.toolKey,
    required this.toolName,
    required this.timestamp,
    this.arguments,
    this.result,
    this.error,
    this.duration,
  });

  final String toolKey;
  final String toolName;
  final DateTime timestamp;
  final Map<String, dynamic>? arguments;
  final String? result;
  final String? error;
  final Duration? duration;

  bool get isError => error != null;
  bool get hasResult => result != null;

  factory ToolCallInfo.fromJson(Map<String, dynamic> json) =>
      _$ToolCallInfoFromJson(json);
  
  Map<String, dynamic> toJson() => _$ToolCallInfoToJson(this);
} 