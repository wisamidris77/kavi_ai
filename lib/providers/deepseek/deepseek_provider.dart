import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../base/ai_provider.dart';
import '../base/provider_config.dart';

class DeepSeekProvider extends AiProvider {
  DeepSeekProvider(AiProviderConfig config)
      : _http = Dio(BaseOptions(
          connectTimeout: config.timeout,
          receiveTimeout: config.timeout,
          sendTimeout: config.timeout,
          headers: {
            'User-Agent': 'Kavi-AI/1.0',
          },
        )),
        super(config);

  final Dio _http;

  @override
  String get name => 'DeepSeek';

  @override
  String get defaultModel => config.defaultModel ?? 'deepseek-chat';

  Uri _buildUri({required String path}) {
    final baseUrl = config.baseUrl;
    print('DeepSeek: baseUrl from config: "$baseUrl"');
    
    // Check if baseUrl is valid
    if (baseUrl != null && baseUrl.isNotEmpty && !baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
      print('DeepSeek: Invalid base URL, using default');
      final base = 'https://api.deepseek.com/v1';
      return Uri.parse('$base/$path');
    }
    
    final base = (baseUrl?.isEmpty ?? true) 
        ? 'https://api.deepseek.com/v1'
        : baseUrl!.replaceAll(RegExp(r'/$'), '');
    
    print('DeepSeek: Final base URL: "$base"');
    return Uri.parse('$base/$path');
  }

  Map<String, String> _headers() {
    return <String, String>{
      'Authorization': 'Bearer ${config.apiKey}',
      'Content-Type': 'application/json',
      ...config.extraHeaders,
    };
  }

  @override
  void validate() {
    if (config.apiKey.isEmpty) {
      throw StateError('DeepSeek apiKey is required');
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
    final uri = _buildUri(path: 'chat/completions');
    final payload = <String, dynamic>{
      'model': model ?? defaultModel,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      if (temperature != null) 'temperature': temperature,
      if (maxTokens != null) 'max_tokens': maxTokens,
      ...?parameters,
    };

    print('DeepSeek: Sending request to $uri');
    print('DeepSeek: Model: ${model ?? defaultModel}');
    print('DeepSeek: Message: $prompt');
    
    try {
      final resp = await _http.postUri(
        uri, 
        data: jsonEncode(payload), 
        options: Options(headers: _headers()),
      );
      
      print('DeepSeek: Response received, status: ${resp.statusCode}');
      
      final data = resp.data is String ? jsonDecode(resp.data as String) : resp.data as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        print('DeepSeek: No choices in response');
        return '';
      }
      final message = (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;
      return content ?? '';
    } catch (e) {
      print('DeepSeek Error: $e');
      if (e is DioException) {
        print('DeepSeek DioException type: ${e.type}');
        print('DeepSeek DioException message: ${e.message}');
        print('DeepSeek DioException response: ${e.response?.data}');
      }
      rethrow;
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
    // For now, use non-streaming mode as DeepSeek's streaming might have issues
    print('DeepSeek Stream: Using non-streaming mode for reliability');
    
    try {
      final full = await generateText(
        prompt: prompt,
        model: model,
        temperature: temperature,
        maxTokens: maxTokens,
        parameters: parameters,
      );
      
      // Simulate streaming by yielding chunks
      const chunkSize = 20; // Characters per chunk
      for (int i = 0; i < full.length; i += chunkSize) {
        final end = (i + chunkSize < full.length) ? i + chunkSize : full.length;
        yield full.substring(i, end);
        // Small delay to simulate streaming
        await Future.delayed(const Duration(milliseconds: 30));
      }
    } catch (e) {
      print('DeepSeek Stream Error: $e');
      rethrow;
    }
  }
} 