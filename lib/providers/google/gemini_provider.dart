import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../base/ai_provider.dart';

class GeminiProvider extends AiProvider {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String _defaultModel = 'gemini-1.5-flash';

  GeminiProvider(super.config);

  @override
  String get name => 'Google Gemini';

  @override
  List<String> get availableModels => [
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-1.0-pro',
    'gemini-1.0-pro-vision',
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
    final url = '$_baseUrl/models/$modelName:streamGenerateContent';
    
    final requestBody = {
      'contents': [
        {
          'parts': [
            {
              'text': prompt,
            },
          ],
        },
      ],
      'generationConfig': {
        if (temperature != null) 'temperature': temperature,
        if (maxTokens != null) 'maxOutputTokens': maxTokens,
        'topP': parameters?['topP'] ?? 0.8,
        'topK': parameters?['topK'] ?? 40,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
      ],
    };

    try {
      final request = http.Request('POST', Uri.parse('$url?key=${config.apiKey}'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(requestBody);

      final streamedResponse = await request.send();
      
      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception('Gemini API error: ${streamedResponse.statusCode} - $errorBody');
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
              final candidates = jsonData['candidates'] as List?;
              
              if (candidates != null && candidates.isNotEmpty) {
                final candidate = candidates.first;
                final content = candidate['content'];
                
                if (content != null) {
                  final parts = content['parts'] as List?;
                  if (parts != null && parts.isNotEmpty) {
                    final text = parts.first['text'] as String?;
                    if (text != null && text.isNotEmpty) {
                      yield text;
                    }
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
      throw Exception('Failed to stream from Gemini: $e');
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
    final url = '$_baseUrl/models/$modelName:generateContent';
    
    final requestBody = {
      'contents': [
        {
          'parts': [
            {
              'text': prompt,
            },
          ],
        },
      ],
      'generationConfig': {
        if (temperature != null) 'temperature': temperature,
        if (maxTokens != null) 'maxOutputTokens': maxTokens,
        'topP': parameters?['topP'] ?? 0.8,
        'topK': parameters?['topK'] ?? 40,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
        },
      ],
    };

    try {
      final response = await http.post(
        Uri.parse('$url?key=${config.apiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception('Gemini API error: ${response.statusCode} - ${response.body}');
      }

      final jsonResponse = jsonDecode(response.body);
      final candidates = jsonResponse['candidates'] as List?;
      
      if (candidates == null || candidates.isEmpty) {
        throw Exception('No response from Gemini API');
      }

      final candidate = candidates.first;
      final content = candidate['content'];
      
      if (content == null) {
        throw Exception('Invalid response format from Gemini API');
      }

      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw Exception('No content parts in Gemini response');
      }

      final text = parts.first['text'] as String?;
      if (text == null) {
        throw Exception('No text content in Gemini response');
      }

      return text;
    } catch (e) {
      throw Exception('Failed to generate text from Gemini: $e');
    }
  }

  @override
  void validate() {
    if (config.apiKey.isEmpty) {
      throw StateError('Gemini API key is required');
    }
  }

  @override
  Future<List<String>> listModels() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/models?key=${config.apiKey}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to list Gemini models: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body);
      final models = jsonResponse['models'] as List?;
      
      if (models == null) {
        return availableModels;
      }

      return models
          .map((model) => model['name'] as String)
          .where((name) => name.startsWith('models/'))
          .map((name) => name.replaceFirst('models/', ''))
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