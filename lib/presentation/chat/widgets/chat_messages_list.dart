import 'package:flutter/material.dart';
import '../../../core/chat/chat_message.dart';
import 'chat_message_bubble.dart';
import 'typing_indicator.dart';

class ChatMessagesList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController? controller;
  final String? assistantLabel;
  final VoidCallback? onRegenerateLast;
  final void Function(ChatMessage message)? onCopyMessage;
  final bool isBusy;

  const ChatMessagesList({
    super.key, 
    required this.messages, 
    this.controller, 
    this.assistantLabel, 
    this.onRegenerateLast, 
    this.onCopyMessage,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool showTypingIndicator = isBusy && (messages.isEmpty || messages.last.role != ChatRole.assistant);
    final int itemCount = messages.length + (showTypingIndicator ? 1 : 0);
    
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemBuilder: (BuildContext context, int index) {
        // Show typing indicator as the last item if we're busy
        if (index == messages.length && showTypingIndicator) {
          return TypingIndicator(label: assistantLabel);
        }
        
        final ChatMessage message = messages[index];
        final bool isLastAssistant = message.role == ChatRole.assistant && index == messages.length - 1;
        return ChatMessageBubble(
          message: message,
          assistantLabel: assistantLabel,
          showRegenerate: isLastAssistant && !isBusy,
          onRegenerate: isLastAssistant && !isBusy ? onRegenerateLast : null,
          onCopy: onCopyMessage,
        );
      },
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 4),
      itemCount: itemCount,
    );
  }
} 