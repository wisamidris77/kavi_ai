import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:kavi/core/token/token_tracker.dart';
import '../../../core/chat/chat_message.dart';
import 'tool_call_badge.dart';
import '../../widgets/code_block_widget.dart';
import '../../widgets/message_timestamp.dart';
import '../../widgets/message_reactions.dart';
import '../../widgets/message_editing.dart';
import '../../widgets/token_usage_widget.dart';
import '../../widgets/latex_rendering.dart';

enum MessageStatus { sending, sent, error, delivered }

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String? assistantLabel;
  final bool showRegenerate;
  final VoidCallback? onRegenerate;
  final void Function(ChatMessage message)? onCopy;
  final MessageStatus? status;
  final String? errorMessage;
  final int? tokenCount;
  final bool showTimestamp;
  final bool enableReactions;
  final bool enableEditing;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.assistantLabel,
    this.showRegenerate = false,
    this.onRegenerate,
    this.onCopy,
    this.status,
    this.errorMessage,
    this.tokenCount,
    this.showTimestamp = true,
    this.enableReactions = true,
    this.enableEditing = true,
  });

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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: avatarFg),
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
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser && (assistantLabel != null && assistantLabel!.isNotEmpty))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(assistantLabel!, style: Theme.of(context).textTheme.labelSmall),
                        ),
                      _MessageMarkdown(content: message.content),
                      if (tokenCount != null && tokenCount! > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TokenUsageWidget(
                            usage: TokenUsage(lastUsed: message.createdAt, totalTokens: tokenCount!),
                            cost: CostEstimate(totalCost: _estimateCost(tokenCount!), lastReset: message.createdAt),
                          ),
                        ),
                    ],
                  ),
                ),
                // Tool call badges
                if (message.toolCalls.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...message.toolCalls.map(
                    (toolCall) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ToolCallBadge(toolCall: toolCall),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Timestamp
                    if (showTimestamp)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: MessageTimestamp(timestamp: message.createdAt ?? DateTime.now()),
                      ),
                    // Status indicator
                    if (status != null && message.role == ChatRole.user)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _MessageStatusIndicator(status: status!, errorMessage: errorMessage),
                      ),
                    // Reactions
                    if (enableReactions)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: MessageReactions(
                          // messageId: message.id,
                          reactions: const [],
                          onReactionAdded: (reaction) {
                            // Handle reaction added
                          },
                          onReactionRemoved: (reaction) {
                            // Handle reaction removed
                          },
                        ),
                      ),
                    // Edit button for user messages
                    if (enableEditing && message.role == ChatRole.user)
                      IconButton(
                        tooltip: 'Edit message',
                        icon: const Icon(Icons.edit, size: 18),
                        padding: const EdgeInsets.all(4),
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed: () {
                          _showEditDialog(context);
                        },
                      ),
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

  double _estimateCost(int tokens) {
    // Rough estimate based on common pricing
    return tokens * 0.00002; // $0.02 per 1K tokens
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MessageEditing(
        message: message,
        onSave: (newContent) {
          // Handle message edit
          Navigator.of(context).pop();
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GptMarkdown(
        content,
        style: TextStyle(color: colors.onSurface, fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize),
      ),
    );

    // // Check if content contains LaTeX patterns
    // final hasLatex = _containsLatex(content);

    // if (hasLatex) {
    //   // Use LaTeX rendering for mathematical content
    //   return LaTeXRendering(
    //     content: content,
    //     style: TextStyle(color: colors.onSurface, fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize),
    //     enableMath: true,
    //   );
    // }

    // // Parse content to identify code blocks
    // final List<Widget> widgets = [];
    // final RegExp codeBlockRegex = RegExp(r'```(\w+)?\n([\s\S]*?)```');
    // final RegExp inlineCodeRegex = RegExp(r'`([^`]+)`');

    // int lastEnd = 0;
    // for (final match in codeBlockRegex.allMatches(content)) {
    //   // Add text before code block
    //   if (match.start > lastEnd) {
    //     final textContent = content.substring(lastEnd, match.start);
    //     if (textContent.trim().isNotEmpty) {
    //       // Check if this text portion contains LaTeX
    //       if (_containsLatex(textContent)) {
    //         widgets.add(
    //           Padding(
    //             padding: const EdgeInsets.only(bottom: 8),
    //             child: LaTeXRendering(
    //               content: textContent,
    //               style: TextStyle(color: colors.onSurface, fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize),
    //             ),
    //           ),
    //         );
    //       } else {
    //         widgets.add(
    //           ,
    //         );
    //       }
    //     }
    //   }

    //   // Add code block
    //   final language = match.group(1) ?? 'plaintext';
    //   final code = match.group(2) ?? '';

    //   // Check if it's LaTeX code
    //   if (language == 'latex' || language == 'tex') {
    //     widgets.add(
    //       Padding(
    //         padding: const EdgeInsets.only(bottom: 8),
    //         child: LaTeXRendering(
    //           content: code,
    //           style: TextStyle(color: colors.onSurface, fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize),
    //         ),
    //       ),
    //     );
    //   } else {
    //     widgets.add(
    //       Padding(
    //         padding: const EdgeInsets.only(bottom: 8),
    //         child: CodeBlockWidget(code: code, language: language, showLineNumbers: code.split('\n').length > 5),
    //       ),
    //     );
    //   }

    //   lastEnd = match.end;
    // }

    // // Add remaining text
    // if (lastEnd < content.length) {
    //   final remainingContent = content.substring(lastEnd);
    //   if (remainingContent.trim().isNotEmpty) {
    //     if (_containsLatex(remainingContent)) {
    //       widgets.add(
    //         LaTeXRendering(
    //           content: remainingContent,
    //           style: TextStyle(color: colors.onSurface, fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize),
    //         ),
    //       );
    //     } else {
    //       widgets.add(
    //         GptMarkdown(
    //           remainingContent,
    //           style: TextStyle(color: colors.onSurface, fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize),
    //         ),
    //       );
    //     }
    //   }
    // }

    // // If no code blocks found, just use regular markdown or LaTeX
    // if (widgets.isEmpty) {
    //   if (hasLatex) {
    //     return LaTeXRendering(
    //       content: content,
    //       style: TextStyle(color: colors.onSurface, fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize),
    //     );
    //   } else {
    //     return GptMarkdown(
    //       content,
    //       style: TextStyle(color: colors.onSurface, fontSize: Theme.of(context).textTheme.bodyLarge?.fontSize),
    //     );
    //   }
    // }

    // return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  bool _containsLatex(String text) {
    // Check for common LaTeX patterns
    return text.contains(r'$$') || // Block math
        text.contains(r'$') || // Inline math
        text.contains(r'\[') || // Block math alternative
        text.contains(r'\(') || // Inline math alternative
        text.contains(r'\begin{') || // LaTeX environments
        text.contains(r'\frac') || // Common LaTeX commands
        text.contains(r'\sum') ||
        text.contains(r'\int') ||
        text.contains(r'\sqrt');
  }
}

class _MessageStatusIndicator extends StatelessWidget {
  final MessageStatus status;
  final String? errorMessage;

  const _MessageStatusIndicator({required this.status, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    switch (status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(colors.primary)),
        );
      case MessageStatus.sent:
        return Icon(Icons.check, size: 16, color: colors.primary);
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 16, color: colors.primary);
      case MessageStatus.error:
        return Tooltip(
          message: errorMessage ?? 'Error sending message',
          child: Icon(Icons.error_outline, size: 16, color: colors.error),
        );
    }
  }
}
