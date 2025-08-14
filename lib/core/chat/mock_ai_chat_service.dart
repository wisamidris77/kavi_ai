import 'dart:async';
import 'dart:math';

import 'ai_chat_service.dart';
import 'chat_message.dart';

class MockAiChatService implements AiChatService {
  final Map<String, StreamController<ChatMessage>> _controllersById = {};
  final Random _rand = Random();

  @override
  Stream<ChatMessage> sendMessage({
    required List<ChatMessage> history,
    required String prompt,
  }) {
    final String messageId = 'a_${DateTime.now().microsecondsSinceEpoch}';
    final StreamController<ChatMessage> controller = StreamController<ChatMessage>();
    _controllersById[messageId] = controller;

    final String simulated = _buildSimulatedResponse(prompt, history);

    Future<void>.microtask(() async {
      final StringBuffer accumulator = StringBuffer();
      for (int i = 0; i < simulated.length; i++) {
        await Future<void>.delayed(Duration(milliseconds: _rand.nextInt(100)));
        accumulator.write(simulated[i]);
        if (controller.isClosed) break;
        controller.add(ChatMessage(
          id: messageId,
          role: ChatRole.assistant,
          content: accumulator.toString(),
          createdAt: DateTime.now(),
        ));
      }
      await Future<void>.delayed(Duration(milliseconds: _rand.nextInt(1000)));
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

    final List<String> openers = <String>[
      "Sure — here's a detailed take.",
      "Absolutely. Let's unpack this.",
      "Great question! Here's a thorough walk‑through.",
      "Thanks for asking. Here are some thoughts.",
      "Let's explore this step by step.",
    ];
    final List<String> bodies = <String>[
      "First, consider the core idea and any constraints involved. Then evaluate alternatives, trade‑offs, and potential pitfalls.",
      "There are a few practical angles: what you want, what you need, and what is feasible given resources and time.",
      "A simple framework helps: clarify the goal, break it down, validate assumptions, and iterate quickly.",
      "Watch out for edge cases and performance characteristics; optimize only after correctness and clarity are ensured.",
      "Where relevant, add small examples to make the concept concrete, and keep feedback loops short.",
    ];
    final List<String> enders = <String>[
      "If you'd like, I can provide a quick checklist to follow next.",
      "Want me to draft a minimal example or template?",
      "I can also compare approaches side by side if that helps.",
      "From here, a small experiment should validate the direction.",
      "Happy to expand on any part in more depth.",
    ];

    String randomParagraph() {
      final opener = openers[_rand.nextInt(openers.length)];
      final body1 = bodies[_rand.nextInt(bodies.length)];
      final body2 = bodies[_rand.nextInt(bodies.length)];
      final ender = enders[_rand.nextInt(enders.length)];
      return "$opener $body1 $body2 $ender";
    }

    if (trimmed.toLowerCase().contains('hello') || trimmed.toLowerCase().contains('hi')) {
      return "Hello! ${randomParagraph()}";
    }

    if (trimmed.endsWith('?')) {
      return "${randomParagraph()} ${randomParagraph()}";
    }

    return "${randomParagraph()}";
  }
} 