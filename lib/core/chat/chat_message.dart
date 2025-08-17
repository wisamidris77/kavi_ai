
import '../../mcp/models/tool_call_info.dart';

enum ChatRole {
  user,
  assistant,
  system,
}

class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;
  final List<ToolCallInfo> toolCalls;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.toolCalls = const [],
  });

  ChatMessage copyWith({
    String? id,
    ChatRole? role,
    String? content,
    DateTime? createdAt,
    List<ToolCallInfo>? toolCalls,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      toolCalls: toolCalls ?? this.toolCalls,
    );
  }
} 