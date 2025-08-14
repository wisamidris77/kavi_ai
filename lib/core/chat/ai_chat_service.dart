import 'dart:async';

import 'chat_message.dart';

abstract class AiChatService {
  /// Sends a user message and returns a stream of assistant message deltas to support streaming UIs.
  Stream<ChatMessage> sendMessage({
    required List<ChatMessage> history,
    required String prompt,
  });

  /// Optional: abort an in-flight request by message id
  Future<void> abort({required String messageId});
} 