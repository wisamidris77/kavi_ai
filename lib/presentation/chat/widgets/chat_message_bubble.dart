import 'package:flutter/material.dart';
import '../../../core/chat/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String? assistantLabel;

  const ChatMessageBubble({super.key, required this.message, this.assistantLabel});

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.role == ChatRole.user;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: isUser ? colors.primary : colors.secondaryContainer,
              child: Icon(
                isUser ? Icons.person : Icons.smart_toy_outlined,
                color: isUser ? colors.onPrimary : colors.onSecondaryContainer,
                size: 18,
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isUser ? colors.surfaceVariant : colors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colors.outlineVariant,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser && (assistantLabel != null && assistantLabel!.isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        assistantLabel!,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  SelectableText(
                    message.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 