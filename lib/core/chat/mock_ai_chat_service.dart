import 'dart:async';

import 'ai_chat_service.dart';
import 'chat_message.dart';

class MockAiChatService implements AiChatService {
  final Map<String, StreamController<ChatMessage>> _controllersById = {};

  @override
  Stream<ChatMessage> sendMessage({
    required List<ChatMessage> history,
    required String prompt,
  }) {
    final String messageId = DateTime.now().microsecondsSinceEpoch.toString();
    final StreamController<ChatMessage> controller = StreamController<ChatMessage>();
    _controllersById[messageId] = controller;

    final String simulated = _buildSimulatedResponse(prompt, history);

    Future<void>.microtask(() async {
      final StringBuffer accumulator = StringBuffer();
      for (int i = 0; i < simulated.length; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
        accumulator.write(simulated[i]);
        if (controller.isClosed) break;
        controller.add(ChatMessage(
          id: messageId,
          role: ChatRole.assistant,
          content: accumulator.toString(),
          createdAt: DateTime.now(),
        ));
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await controller.close();
      _controllersById.remove(messageId);
    });

    return controller.stream;
  }

  @override
  Future<void> abort({required String messageId}) async {
    final StreamController<ChatMessage>? controller = _controllersById.remove(messageId);
    await controller?.close();
  }

  String _buildSimulatedResponse(String prompt, List<ChatMessage> history) {
    final String trimmed = prompt.trim();
    if (trimmed.isEmpty) return "";

    if (trimmed.toLowerCase().contains('hello') || trimmed.toLowerCase().contains('hi')) {
      return "Hello! How can I help you today?";
    }

    if (trimmed.endsWith('?')) {
      return "That's a great question. Here's a concise answer, plus a few tips to explore further.";
    }

    return "Got it. Let me think through that and provide a helpful response.";
  }
} 