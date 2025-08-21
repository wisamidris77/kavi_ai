import 'package:kavi/presentation/widgets/message_reactions.dart';

import '../../mcp/models/tool_call_info.dart';

enum ChatRole { user, assistant, system, tool }

class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;
  final String? chatId;
  final List<ToolCallInfo> toolCalls;
  final List<MessageReaction> reactions;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.chatId,
    this.toolCalls = const [],
    this.reactions = const [],
  });

  ChatMessage copyWith({
    String? id,
    ChatRole? role,
    String? content,
    DateTime? createdAt,
    List<ToolCallInfo>? toolCalls,
    List<MessageReaction>? reactions,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      toolCalls: toolCalls ?? this.toolCalls,
      reactions: reactions ?? this.reactions,
    );
  }

  void addReaction(String reaction) {
    if (reactions.any((r) => r.emoji == reaction)) {
      final index = reactions.indexWhere((r) => r.emoji == reaction);
      reactions[index] = reactions[index].copyWith(count: reactions[index].count + 1);
    } else {
      reactions.add(MessageReaction(emoji: reaction, count: 1, users: ['current_user']));
    }
  }

  void removeReaction(MessageReaction reaction) {
    reactions.remove(reaction);
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      role: ChatRole.values.byName(json['role']),
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      reactions: json['reactions'] != null ? (json['reactions'] as List).map((r) => MessageReaction.fromJson(r)).toList() : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'toolCalls': toolCalls.map((toolCall) => toolCall.toJson()).toList(),
      'reactions': reactions.map((reaction) => reaction.toJson()).toList(),
    };
  }
}
