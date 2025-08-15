import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../../../core/chat/chat_message.dart';
import 'tool_call_badge.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String? assistantLabel;
  final bool showRegenerate;
  final VoidCallback? onRegenerate;
  final void Function(ChatMessage message)? onCopy;

  const ChatMessageBubble({super.key, required this.message, this.assistantLabel, this.showRegenerate = false, this.onRegenerate, this.onCopy});

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.role == ChatRole.user;
    final ColorScheme colors = Theme.of(context).colorScheme;

    final Color avatarBg = isUser ? colors.secondaryContainer : colors.primary;
    final Color avatarFg = isUser ? colors.onSecondaryContainer : colors.onPrimary;
    final String avatarText = isUser ? 'Y' : 'K';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: avatarBg,
              child: Text(
                avatarText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: avatarFg,
                    ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
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
                      _MessageMarkdown(content: message.content),
                    ],
                  ),
                ),
                // Tool call badges
                if (message.toolCalls.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...message.toolCalls.map((toolCall) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ToolCallBadge(toolCall: toolCall),
                  )),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Copy message',
                      icon: const Icon(Icons.content_copy, size: 18),
                      padding: const EdgeInsets.all(4),
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: message.content));
                        onCopy?.call(message);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copied')));
                      },
                    ),
                    if (showRegenerate)
                      IconButton(
                        tooltip: 'Regenerate',
                        icon: const Icon(Icons.refresh, size: 18),
                        padding: const EdgeInsets.all(4),
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed: onRegenerate,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageMarkdown extends StatelessWidget {
  final String content;

  const _MessageMarkdown({required this.content});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    
    return GptMarkdown(
      content,
      style: TextStyle(
        color: colors.onSurface,
        fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize,
      ),
    );
  }
}