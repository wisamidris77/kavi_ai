import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../base/ai_provider.dart';

class OpenAiProvider extends AiProvider {
  OpenAiProvider(super.config)
      : _http = Dio(BaseOptions(
          connectTimeout: config.timeout,
          receiveTimeout: config.timeout,
        ));

  final Dio _http;

  @override
  String get name => 'OpenAI';

  @override
  String get defaultModel => config.defaultModel ?? 'gpt-4o-mini';

  Uri _buildUri({required String path}) {
    final base = config.baseUrl?.replaceAll(RegExp(r'/$'), '') ?? 'https://api.openai.com/v1';
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
      throw StateError('OpenAI apiKey is required');
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

    final resp = await _http.postUri(uri, data: jsonEncode(payload), options: Options(headers: _headers()));
    final data = resp.data is String ? jsonDecode(resp.data as String) : resp.data as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) return '';
    final message = (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    return content ?? '';
  }

  @override
  Stream<String> streamText({
    required String prompt,
    String? model,
    double? temperature,
    int? maxTokens,
    Map<String, dynamic>? parameters,
  }) async* {
    // Basic fallback to non-streaming to keep UI working
    final full = await generateText(
      prompt: prompt,
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
      parameters: parameters,
    );
    if (full.isNotEmpty) yield full;
  }
} 