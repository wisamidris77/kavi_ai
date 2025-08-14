import 'package:flutter/material.dart';
import '../../../core/chat/chat_message.dart';
import 'chat_message_bubble.dart';

class ChatMessagesList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController? controller;

  const ChatMessagesList({super.key, required this.messages, this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemBuilder: (BuildContext context, int index) {
        final ChatMessage message = messages[index];
        return ChatMessageBubble(message: message);
      },
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 4),
      itemCount: messages.length,
    );
  }
} 