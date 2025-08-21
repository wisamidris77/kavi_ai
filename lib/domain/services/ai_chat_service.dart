import 'package:kavi/core/chat/chat_message.dart';

import '../../providers/base/ai_provider.dart';
import '../../providers/base/provider_config.dart';
import '../../providers/base/provider_type.dart';
import '../../providers/factory/ai_provider_factory.dart';

class AiChatService {
  AiChatService({
    required AiProviderType providerType,
    required AiProviderConfig config,
  }) : _provider = AiProviderFactory.create(type: providerType, config: config);

  final AiProvider _provider;

  AiProvider get provider => _provider;

  /// Generate a single assistant reply based on the provided chat history
  /// plus a new user input.
  Future<ChatMessage> generateReply({
    required List<ChatMessage> history,
    required String userInput,
    String? model,
    double? temperature,
    int? maxTokens,
  }) async {
    final prompt = _flattenHistoryWithUserInput(history: history, userInput: userInput);
    final text = await _provider.generateText(
      prompt: prompt,
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
    );
    return ChatMessage(
      id: _genId(),
      role: ChatRole.assistant,
      content: text,
      createdAt: DateTime.now(),
    );
  }

  /// Stream the assistant reply token-by-token. Caller is responsible for
  /// aggregating the chunks.
  Stream<String> streamReply({
    required List<ChatMessage> history,
    required String userInput,
    String? model,
    double? temperature,
    int? maxTokens,
  }) {
    final prompt = _flattenHistoryWithUserInput(history: history, userInput: userInput);
    return _provider.streamText(
      prompt: prompt,
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
    );
  }

  String _flattenHistoryWithUserInput({
    required List<ChatMessage> history,
    required String userInput,
  }) {
    final buffer = StringBuffer();
    for (final message in history) {
      final role = switch (message.role) {
        ChatRole.system => 'System',
        ChatRole.user => 'User',
        ChatRole.assistant => 'Assistant',
        ChatRole.tool => 'Tool',
      };
      buffer.writeln('$role: ${message.content}');
    }
    buffer.writeln('User: $userInput');
    buffer.writeln('Assistant:');
    return buffer.toString();
  }
}

String _genId() => DateTime.now().microsecondsSinceEpoch.toString(); 