import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../base/ai_provider.dart';

class MistralProvider extends AiProvider {
  static const String _baseUrl = 'https://api.mistral.ai/v1';
  static const String _defaultModel = 'mistral-large-latest';

  MistralProvider(super.config);

  @override
  String get name => 'Mistral AI';

  @override
  List<String> get availableModels => [
    'mistral-large-latest',
    'mistral-medium-latest',
    'mistral-small-latest',
    'mistral-tiny',
    'open-mistral-7b',
    'open-mixtral-8x7b',
    'mistral-embed',
  ];

  @override
  String get defaultModel => config.defaultModel ?? _defaultModel;

  @override
  bool get isEnabled => config.apiKey.isNotEmpty;

  @override
  Stream<String> streamText({
    required String prompt,
    String? model,
    double? temperature,
    int? maxTokens,
    Map<String, dynamic>? parameters,
  }) async* {
    validate();
    
    final modelName = model ?? defaultModel;
    final url = '$_baseUrl/chat/completions';
    
    final requestBody = {
      'model': modelName,
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        },
      ],
      'stream': true,
      if (temperature != null) 'temperature': temperature,
      if (maxTokens != null) 'max_tokens': maxTokens,
      'top_p': parameters?['topP'] ?? 1.0,
      'top_k': parameters?['topK'] ?? 40,
      'safe_prompt': parameters?['safePrompt'] ?? false,
    };

    try {
      final request = http.Request('POST', Uri.parse(url));
      request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] = 'Bearer ${config.apiKey}';
      request.body = jsonEncode(requestBody);

      final streamedResponse = await request.send();
      
      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception('Mistral API error: ${streamedResponse.statusCode} - $errorBody');
      }

      String buffer = '';
      
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;
        
        // Process complete lines
        final lines = buffer.split('\n');
        buffer = lines.removeLast(); // Keep incomplete line in buffer
        
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data == '[DONE]') break;
            
            try {
              final jsonData = jsonDecode(data);
              final choices = jsonData['choices'] as List?;
              
              if (choices != null && choices.isNotEmpty) {
                final choice = choices.first;
                final delta = choice['delta'];
                
                if (delta != null) {
                  final content = delta['content'] as String?;
                  if (content != null && content.isNotEmpty) {
                    yield content;
                  }
                }
              }
            } catch (e) {
              // Skip malformed JSON
              continue;
            }
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to stream from Mistral: $e');
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
    
    final modelName = model ?? defaultModel;
    final url = '$_baseUrl/chat/completions';
    
    final requestBody = {
      'model': modelName,
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        },
      ],
      if (temperature != null) 'temperature': temperature,
      if (maxTokens != null) 'max_tokens': maxTokens,
      'top_p': parameters?['topP'] ?? 1.0,
      'top_k': parameters?['topK'] ?? 40,
      'safe_prompt': parameters?['safePrompt'] ?? false,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${config.apiKey}',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception('Mistral API error: ${response.statusCode} - ${response.body}');
      }

      final jsonResponse = jsonDecode(response.body);
      final choices = jsonResponse['choices'] as List?;
      
      if (choices == null || choices.isEmpty) {
        throw Exception('No response from Mistral API');
      }

      final choice = choices.first;
      final message = choice['message'];
      
      if (message == null) {
        throw Exception('Invalid response format from Mistral API');
      }

      final content = message['content'] as String?;
      if (content == null) {
        throw Exception('No content in Mistral response');
      }

      return content;
    } catch (e) {
      throw Exception('Failed to generate text from Mistral: $e');
    }
  }

  @override
  void validate() {
    if (config.apiKey.isEmpty) {
      throw StateError('Mistral API key is required');
    }
  }

  @override
  Future<List<String>> listModels() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/models'),
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to list Mistral models: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body);
      final models = jsonResponse['data'] as List?;
      
      if (models == null) {
        return availableModels;
      }

      return models
          .map((model) => model['id'] as String)
          .where((id) => !id.contains('embed')) // Filter out embedding models
          .toList();
    } catch (e) {
      // Return default models if API call fails
      return availableModels;
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      await generateText(
        prompt: 'Hello',
        maxTokens: 10,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}