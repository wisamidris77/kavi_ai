import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../base/ai_provider.dart';
import '../base/provider_config.dart';

class OllamaProvider extends AiProvider {
  OllamaProvider(AiProviderConfig config)
      : _http = Dio(BaseOptions(
          connectTimeout: config.timeout,
          receiveTimeout: config.timeout,
        )),
        super(config);

  final Dio _http;

  @override
  String get name => 'Ollama';

  @override
  String get defaultModel => config.defaultModel ?? 'llama3.2';

  Uri _buildUri({required String path}) {
    final base = config.baseUrl?.replaceAll(RegExp(r'/$'), '') ?? 'http://localhost:11434';
    return Uri.parse('$base/$path');
  }

  Map<String, String> _headers() {
    return <String, String>{
      'Content-Type': 'application/json',
      ...config.extraHeaders,
    };
  }

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
    final uri = _buildUri(path: 'api/generate');
    final payload = <String, dynamic>{
      'model': model ?? defaultModel,
      'prompt': prompt,
      'stream': false,
      if (temperature != null) 'temperature': temperature,
      if (maxTokens != null) 'num_predict': maxTokens,
      ...?parameters,
    };

    try {
      final resp = await _http.postUri(
        uri, 
        data: jsonEncode(payload), 
        options: Options(headers: _headers())
      );
      
      final data = resp.data is String 
          ? jsonDecode(resp.data as String) 
          : resp.data as Map<String, dynamic>;
      
      return data['response'] as String? ?? '';
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw StateError('Model ${model ?? defaultModel} not found. Please pull it first with: ollama pull ${model ?? defaultModel}');
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
    validate();
    final uri = _buildUri(path: 'api/generate');
    final payload = <String, dynamic>{
      'model': model ?? defaultModel,
      'prompt': prompt,
      'stream': true,
      if (temperature != null) 'temperature': temperature,
      if (maxTokens != null) 'num_predict': maxTokens,
      ...?parameters,
    };

    try {
      final request = await _http.postUri(
        uri,
        data: jsonEncode(payload),
        options: Options(
          headers: _headers(),
          responseType: ResponseType.stream,
        ),
      );

      final stream = request.data.stream as Stream<List<int>>;
      
      await for (final chunk in stream) {
        final lines = utf8.decode(chunk).split('\n');
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          
          try {
            final data = jsonDecode(line) as Map<String, dynamic>;
            final response = data['response'] as String?;
            if (response != null && response.isNotEmpty) {
              yield response;
            }
            
            // Check if the stream is done
            if (data['done'] == true) {
              return;
            }
          } catch (e) {
            // Skip malformed JSON lines
            continue;
          }
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw StateError('Model ${model ?? defaultModel} not found. Please pull it first with: ollama pull ${model ?? defaultModel}');
      }
      rethrow;
    }
  }
}