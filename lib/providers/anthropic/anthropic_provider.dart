import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../base/ai_provider.dart';
import '../base/provider_config.dart';

class AnthropicProvider extends AiProvider {
  static const String _baseUrl = 'https://api.anthropic.com/v1';
  static const String _defaultModel = 'claude-3-sonnet-20240229';

  AnthropicProvider(AiProviderConfig config) : super(config);

  @override
  String get name => 'Anthropic Claude';

  @override
  List<String> get availableModels => [
    'claude-3-opus-20240229',
    'claude-3-sonnet-20240229',
    'claude-3-haiku-20240307',
    'claude-3-5-sonnet-20241022',
    'claude-3-5-haiku-20241022',
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
    
    final requestBody = {
      'model': model ?? defaultModel,
      'max_tokens': maxTokens ?? 4096,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'stream': true,
    };

    if (temperature != null) {
      requestBody['temperature'] = temperature;
    }

    if (parameters != null) {
      requestBody.addAll(parameters as Map<String, Object>);
    }

    final request = http.Request('POST', Uri.parse('$_baseUrl/messages'));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'x-api-key': config.apiKey,
      'anthropic-version': '2023-06-01',
    });
    request.body = jsonEncode(requestBody);

    try {
      final response = await http.Client().send(request);
      
      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        throw Exception('Anthropic API error: ${response.statusCode} - $errorBody');
      }

      await for (final chunk in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .where((line) => line.startsWith('data: '))
          .map((line) => line.substring(6))
          .where((data) => data != '[DONE]')) {
        try {
          final json = jsonDecode(chunk);
          if (json['type'] == 'content_block_delta') {
            final text = json['delta']['text'] ?? '';
            if (text.isNotEmpty) {
              yield text;
            }
          }
        } catch (e) {
          // Skip invalid JSON chunks
        }
      }
    } catch (e) {
      throw Exception('Failed to connect to Anthropic API: $e');
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
    
    final requestBody = {
      'model': model ?? defaultModel,
      'max_tokens': maxTokens ?? 4096,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
    };

    if (temperature != null) {
      requestBody['temperature'] = temperature;
    }

    if (parameters != null) {
      requestBody.addAll(parameters);
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': config.apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        throw Exception('Anthropic API error: ${response.statusCode} - ${response.body}');
      }

      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['content'][0]['text'] ?? '';
    } catch (e) {
      throw Exception('Failed to connect to Anthropic API: $e');
    }
  }

  @override
  void validate() {
    if (config.apiKey.isEmpty) {
      throw StateError('Anthropic apiKey is required');
    }
  }
}