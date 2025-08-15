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
    final itemCount = isBusy ? messages.length + 1 : messages.length;
    
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemBuilder: (BuildContext context, int index) {
        // Show typing indicator as the last item when busy
        if (isBusy && index == messages.length) {
          return AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.smart_toy, size: 20),
                ),
                const SizedBox(width: 12),
                const TypingIndicator(),
              ],
            ),
          );
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