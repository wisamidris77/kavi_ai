import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../base/ai_provider.dart';
import '../base/provider_config.dart';

class CohereProvider extends AiProvider {
  static const String _baseUrl = 'https://api.cohere.ai/v1';
  static const String _defaultModel = 'command-r-plus';

  CohereProvider(AiProviderConfig config) : super(config);

  @override
  String get name => 'Cohere';

  @override
  List<String> get availableModels => [
    'command-r-plus',
    'command-r',
    'command-light',
    'command',
    'command-nightly',
    'command-light-nightly',
    'base',
    'base-light',
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
    final url = '$_baseUrl/chat';
    
    final requestBody = {
      'model': modelName,
      'message': prompt,
      'stream': true,
      if (temperature != null) 'temperature': temperature,
      if (maxTokens != null) 'max_tokens': maxTokens,
      'p': parameters?['topP'] ?? 0.9,
      'k': parameters?['topK'] ?? 0,
      'stop_sequences': parameters?['stopSequences'] ?? [],
      'citation_quality': parameters?['citationQuality'] ?? 'accurate',
    };

    try {
      final request = http.Request('POST', Uri.parse(url));
      request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] = 'Bearer ${config.apiKey}';
      request.body = jsonEncode(requestBody);

      final streamedResponse = await request.send();
      
      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception('Cohere API error: ${streamedResponse.statusCode} - $errorBody');
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
              final eventType = jsonData['event_type'] as String?;
              
              if (eventType == 'text-generation') {
                final text = jsonData['text'] as String?;
                if (text != null && text.isNotEmpty) {
                  yield text;
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
      throw Exception('Failed to stream from Cohere: $e');
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
    final url = '$_baseUrl/chat';
    
    final requestBody = {
      'model': modelName,
      'message': prompt,
      if (temperature != null) 'temperature': temperature,
      if (maxTokens != null) 'max_tokens': maxTokens,
      'p': parameters?['topP'] ?? 0.9,
      'k': parameters?['topK'] ?? 0,
      'stop_sequences': parameters?['stopSequences'] ?? [],
      'citation_quality': parameters?['citationQuality'] ?? 'accurate',
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
        throw Exception('Cohere API error: ${response.statusCode} - ${response.body}');
      }

      final jsonResponse = jsonDecode(response.body);
      final text = jsonResponse['text'] as String?;
      
      if (text == null) {
        throw Exception('No text content in Cohere response');
      }

      return text;
    } catch (e) {
      throw Exception('Failed to generate text from Cohere: $e');
    }
  }

  @override
  void validate() {
    if (config.apiKey.isEmpty) {
      throw StateError('Cohere API key is required');
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
        throw Exception('Failed to list Cohere models: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body);
      final models = jsonResponse['models'] as List?;
      
      if (models == null) {
        return availableModels;
      }

      return models
          .map((model) => model['name'] as String)
          .where((name) => name.startsWith('command') || name.startsWith('base'))
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