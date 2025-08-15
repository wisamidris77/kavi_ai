import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
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

  // Clean up incomplete markdown that might cause parser issues
  String _sanitizeMarkdown(String text) {
    // Handle incomplete code blocks
    final codeBlockCount = '```'.allMatches(text).length;
    if (codeBlockCount % 2 != 0) {
      // Add closing code block if odd number
      text += '\n```';
    }
    
    // Handle incomplete inline code
    final inlineCodeCount = RegExp(r'`(?!``)').allMatches(text).length;
    if (inlineCodeCount % 2 != 0) {
      text += '`';
    }
    
    // Handle incomplete bold/italic markers
    final boldCount = '**'.allMatches(text).length;
    if (boldCount % 2 != 0) {
      text += '**';
    }
    
    final italicCount = RegExp(r'(?<!\*)\*(?!\*)').allMatches(text).length;
    if (italicCount % 2 != 0) {
      text += '*';
    }
    
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final sanitizedContent = _sanitizeMarkdown(content);
    
    try {
      return MarkdownBody(
        data: sanitizedContent,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          codeblockDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          code: const TextStyle(
            fontFamily: 'monospace',
            backgroundColor: Colors.transparent,
          ),
        ),
        builders: {
          'pre': _CodeBlockBuilder(),
        },
        onTapLink: (text, href, title) {
          if (href == null) return;
        },
      );
    } catch (e) {
      // Fallback to plain text if markdown parsing fails
      print('Markdown parsing error: $e');
      return SelectableText(content);
    }
  }
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  _CodeBlockBuilder();

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final String rawText = element.textContent;
    return _CodeBlock(text: rawText);
  }
}

class _CodeBlock extends StatelessWidget {
  final String text;

  const _CodeBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              text,
              style: TextStyle(fontFamily: 'monospace', color: colors.onSurface),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            tooltip: 'Copy code',
            icon: const Icon(Icons.copy_all, size: 18),
            padding: const EdgeInsets.all(4),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied')));
            },
          ),
        ),
      ],
    );
  }
}