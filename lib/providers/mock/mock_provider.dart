import 'dart:async';
import 'dart:math';

import '../base/ai_provider.dart';
import '../base/provider_config.dart';

class MockProvider extends AiProvider {
  MockProvider(AiProviderConfig config)
      : _rand = Random(),
        super(config);

  final Random _rand;

  @override
  String get name => 'Mock';

  @override
  String get defaultModel => config.defaultModel ?? 'mock-sim';

  @override
  void validate() {
    // No validation required for mock
  }

  @override
  Future<String> generateText({
    required String prompt,
    String? model,
    double? temperature,
    int? maxTokens,
    Map<String, dynamic>? parameters,
  }) async {
    validate();
    return _buildSimulatedResponse(prompt);
  }

  @override
  Stream<String> streamText({
    required String prompt,
    String? model,
    double? temperature,
    int? maxTokens,
    Map<String, dynamic>? parameters,
  }) async* {
    final full = await generateText(prompt: prompt, model: model, temperature: temperature, maxTokens: maxTokens, parameters: parameters);
    // Stream in small chunks to simulate tokens
    for (int i = 0; i < full.length; i += 12) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      yield full.substring(0, i + 12 > full.length ? full.length : i + 12);
    }
  }

  String _buildSimulatedResponse(String prompt) {
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