import 'dart:async';

import 'package:ollama_dart/ollama_dart.dart';

import '../base/ai_provider.dart';
import '../base/provider_config.dart';
import 'ollama_chat_provider.dart';

/// Ollama provider implementation using the ollama_dart package
class OllamaProvider extends AiProvider {
  OllamaProvider(AiProviderConfig config)
      : _client = OllamaClient(
          baseUrl: config.baseUrl ?? 'http://localhost:11434',
          headers: config.extraHeaders,
        ),
        _chatProvider = OllamaChatProvider(
          config: config,
          baseUrl: config.baseUrl,
        ),
        super(config);

  final OllamaClient _client;
  final OllamaChatProvider _chatProvider;

  @override
  String get name => 'Ollama';

  @override
  String get defaultModel => config.defaultModel ?? 'llama3.2';

  @override
  void validate() {
    // Ollama doesn't require an API key for local instances
    // But we can validate the base URL if provided
    if (config.baseUrl != null) {
      try {
        Uri.parse(config.baseUrl!);
      } catch (e) {
        throw StateError('Invalid Ollama base URL: ${config.baseUrl}');
      }
    }
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
    
    // Check if the prompt looks like a chat format
    if (_isChatFormat(prompt)) {
      // Parse and use chat completion for better results
      final messages = _parsePromptToMessages(prompt);
      return _chatProvider.generateChatCompletion(
        messages: messages,
        model: model,
        temperature: temperature,
        maxTokens: maxTokens,
        parameters: parameters,
      );
    }
    
    // Use regular completion for simple prompts
    try {
      final request = GenerateCompletionRequest(
        model: model ?? defaultModel,
        prompt: prompt,
        stream: false,
        options: RequestOptions(
          temperature: temperature,
          numPredict: maxTokens,
        ),
      );

      final response = await _client.generateCompletion(request: request);
      return response.response ?? '';
    } on OllamaClientException catch (e) {
      if (e.message?.contains('model') ?? false) {
        throw StateError(
          'Model ${model ?? defaultModel} not found. '
          'Please pull it first with: ollama pull ${model ?? defaultModel}',
        );
      }
      throw StateError('Ollama error: ${e.message}');
    } catch (e) {
      throw StateError('Failed to generate text: $e');
    }
  }

  @override
  Stream<String> streamText({
    required String prompt,
    String? model,
    double? temperature,
    int? maxTokens,
    Map<String, dynamic>? parameters,
  }) async* {
    validate();
    
    // Check if the prompt looks like a chat format
    if (_isChatFormat(prompt)) {
      // Parse and use chat completion for better results
      final messages = _parsePromptToMessages(prompt);
      yield* _chatProvider.streamChatCompletion(
        messages: messages,
        model: model,
        temperature: temperature,
        maxTokens: maxTokens,
        parameters: parameters,
      );
      return;
    }
    
    // Use regular completion for simple prompts
    try {
      final request = GenerateCompletionRequest(
        model: model ?? defaultModel,
        prompt: prompt,
        stream: true,
        options: RequestOptions(
          temperature: temperature,
          numPredict: maxTokens,
        ),
      );

      final stream = _client.generateCompletionStream(request: request);
      
      await for (final response in stream) {
        final text = response.response;
        if (text != null && text.isNotEmpty) {
          yield text;
        }
        
        if (response.done ?? false) {
          break;
        }
      }
    } on OllamaClientException catch (e) {
      if (e.message?.contains('model') ?? false) {
        throw StateError(
          'Model ${model ?? defaultModel} not found. '
          'Please pull it first with: ollama pull ${model ?? defaultModel}',
        );
      }
      throw StateError('Ollama error: ${e.message}');
    } catch (e) {
      throw StateError('Failed to stream text: $e');
    }
  }

  /// Get list of available models from Ollama
  Future<List<String>> getAvailableModels() async {
    try {
      final models = await _client.listModels();
      return models.models?.map((m) => m.name ?? '').where((name) => name.isNotEmpty).toList() ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Check if Ollama server is running
  Future<bool> isServerRunning() async {
    try {
      await _client.listModels();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Pull a model from Ollama registry
  Stream<String> pullModel(String modelName) async* {
    try {
      final stream = _client.pullModelStream(
        request: PullModelRequest(model: modelName),
      );
      
      await for (final response in stream) {
        if (response.status != null) {
          yield response.status!;
        }
      }
    } catch (e) {
      yield 'Error pulling model: $e';
    }
  }

  /// Check if prompt looks like a chat format
  bool _isChatFormat(String prompt) {
    return prompt.contains('System:') || 
           prompt.contains('User:') || 
           prompt.contains('Assistant:');
  }

  /// Parse a chat-formatted prompt into messages
  List<dynamic> _parsePromptToMessages(String prompt) {
    final lines = prompt.split('\n');
    final messages = [];
    String? currentRole;
    final contentBuffer = StringBuffer();

    for (final line in lines) {
      if (line.startsWith('System:')) {
        if (currentRole != null) {
          messages.add(_createMessage(currentRole, contentBuffer.toString().trim()));
          contentBuffer.clear();
        }
        currentRole = 'system';
        contentBuffer.writeln(line.substring(7).trim());
      } else if (line.startsWith('User:')) {
        if (currentRole != null) {
          messages.add(_createMessage(currentRole, contentBuffer.toString().trim()));
          contentBuffer.clear();
        }
        currentRole = 'user';
        contentBuffer.writeln(line.substring(5).trim());
      } else if (line.startsWith('Assistant:')) {
        if (currentRole != null) {
          messages.add(_createMessage(currentRole, contentBuffer.toString().trim()));
          contentBuffer.clear();
        }
        currentRole = 'assistant';
        final content = line.substring(10).trim();
        if (content.isNotEmpty) {
          contentBuffer.writeln(content);
        }
      } else if (currentRole != null && line.isNotEmpty) {
        contentBuffer.writeln(line);
      }
    }

    // Add the last message if there's content
    if (currentRole != null && contentBuffer.isNotEmpty) {
      messages.add(_createMessage(currentRole, contentBuffer.toString().trim()));
    }

    return messages;
  }

  dynamic _createMessage(String role, String content) {
    // Import the chat message model
    return ChatMessageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: role,
      content: content,
      createdAt: DateTime.now(),
    );
  }
}

// Import the chat message model for parsing
class ChatMessageModel {
  final String id;
  final String role;
  final String content;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });
}