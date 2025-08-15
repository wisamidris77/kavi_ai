import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../base/ai_provider.dart';
import '../base/provider_config.dart';

/// Alternative DeepSeek provider with full streaming support
/// Use this if you want to try true SSE streaming
class DeepSeekStreamingProvider extends AiProvider {
  DeepSeekStreamingProvider(AiProviderConfig config)
      : _http = Dio(BaseOptions(
          connectTimeout: config.timeout,
          receiveTimeout: const Duration(minutes: 5), // Longer timeout for streaming
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
    if (baseUrl != null && baseUrl.isNotEmpty && !baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
      final base = 'https://api.deepseek.com/v1';
      return Uri.parse('$base/$path');
    }
    
    final base = (baseUrl?.isEmpty ?? true) 
        ? 'https://api.deepseek.com/v1'
        : baseUrl!.replaceAll(RegExp(r'/$'), '');
    
    return Uri.parse('$base/$path');
  }

  Map<String, String> _headers() {
    return <String, String>{
      'Authorization': 'Bearer ${config.apiKey}',
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      ...config.extraHeaders,
    };
  }

  /// Parse flattened prompt back into structured messages
  List<Map<String, String>> _parsePromptToMessages(String prompt) {
    final messages = <Map<String, String>>[];
    final lines = prompt.split('\n');
    
    String? currentRole;
    final contentBuffer = StringBuffer();
    
    for (final line in lines) {
      if (line.startsWith('System: ')) {
        // Save previous message if exists
        if (currentRole != null && contentBuffer.isNotEmpty) {
          messages.add({
            'role': currentRole,
            'content': contentBuffer.toString().trim(),
          });
          contentBuffer.clear();
        }
        currentRole = 'system';
        contentBuffer.writeln(line.substring(8)); // Remove "System: "
      } else if (line.startsWith('User: ')) {
        // Save previous message if exists
        if (currentRole != null && contentBuffer.isNotEmpty) {
          messages.add({
            'role': currentRole,
            'content': contentBuffer.toString().trim(),
          });
          contentBuffer.clear();
        }
        currentRole = 'user';
        contentBuffer.writeln(line.substring(6)); // Remove "User: "
      } else if (line.startsWith('Assistant: ')) {
        // Save previous message if exists
        if (currentRole != null && contentBuffer.isNotEmpty) {
          messages.add({
            'role': currentRole,
            'content': contentBuffer.toString().trim(),
          });
          contentBuffer.clear();
        }
        currentRole = 'assistant';
        final content = line.substring(11); // Remove "Assistant: "
        if (content.isNotEmpty) {
          contentBuffer.writeln(content);
        }
      } else if (line.startsWith('Tool: ')) {
        // For tool messages, we'll include them as system messages
        if (currentRole != null && contentBuffer.isNotEmpty) {
          messages.add({
            'role': currentRole,
            'content': contentBuffer.toString().trim(),
          });
          contentBuffer.clear();
        }
        currentRole = 'system';
        contentBuffer.writeln(line); // Keep the full tool result
      } else if (currentRole != null) {
        // Continue adding to current message
        contentBuffer.writeln(line);
      }
    }
    
    // Add the last message if exists (but not if it's an empty assistant message)
    if (currentRole != null && contentBuffer.isNotEmpty) {
      final content = contentBuffer.toString().trim();
      if (!(currentRole == 'assistant' && content.isEmpty)) {
        messages.add({
          'role': currentRole,
          'content': content,
        });
      }
    }
    
    return messages;
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
    
    // Parse the flattened prompt into structured messages
    final messages = _parsePromptToMessages(prompt);
    
    final payload = <String, dynamic>{
      'model': model ?? defaultModel,
      'messages': messages,
      'stream': false,
      if (temperature != null) 'temperature': temperature,
      if (maxTokens != null) 'max_tokens': maxTokens,
      ...?parameters,
    };

    try {
      final resp = await _http.postUri(
        uri, 
        data: jsonEncode(payload), 
        options: Options(headers: _headers()),
      );
      
      final data = resp.data is String ? jsonDecode(resp.data as String) : resp.data as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        return '';
      }
      final message = (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
      final content = message?['content'] as String?;
      return content ?? '';
    } catch (e) {
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
    final uri = _buildUri(path: 'chat/completions');
    
    // Parse the flattened prompt into structured messages
    final messages = _parsePromptToMessages(prompt);
    
    final payload = <String, dynamic>{
      'model': model ?? defaultModel,
      'messages': messages,
      'stream': true,
      if (temperature != null) 'temperature': temperature,
      if (maxTokens != null) 'max_tokens': maxTokens,
      ...?parameters,
    };

    print('DeepSeek Streaming: Starting request to $uri');
    
    try {
      final cancelToken = CancelToken();
      final response = await _http.post(
        uri.toString(),
        data: jsonEncode(payload),
        options: Options(
          headers: _headers(),
          responseType: ResponseType.stream,
          validateStatus: (status) => status! < 500,
        ),
        cancelToken: cancelToken,
      );

      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'HTTP ${response.statusCode}',
        );
      }

      final stream = response.data.stream as Stream<List<int>>;
      String buffer = '';
      
      await for (final chunk in stream) {
        buffer += utf8.decode(chunk, allowMalformed: true);
        
        // Process complete lines
        while (buffer.contains('\n')) {
          final lineEnd = buffer.indexOf('\n');
          final line = buffer.substring(0, lineEnd).trim();
          buffer = buffer.substring(lineEnd + 1);
          
          if (line.isEmpty) continue;
          if (!line.startsWith('data: ')) continue;
          
          final data = line.substring(6);
          if (data == '[DONE]') {
            return;
          }
          
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List<dynamic>?;
            if (choices != null && choices.isNotEmpty) {
              final choice = choices.first as Map<String, dynamic>;
              final delta = choice['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                yield content;
              }
            }
          } catch (e) {
            print('DeepSeek Streaming: Error parsing JSON: $e');
            print('DeepSeek Streaming: Line was: $line');
          }
        }
      }
      
      // Process any remaining data in buffer
      if (buffer.trim().isNotEmpty && buffer.startsWith('data: ')) {
        final data = buffer.substring(6).trim();
        if (data != '[DONE]') {
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List<dynamic>?;
            if (choices != null && choices.isNotEmpty) {
              final choice = choices.first as Map<String, dynamic>;
              final delta = choice['delta'] as Map<String, dynamic>?;
              final content = delta?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                yield content;
              }
            }
          } catch (e) {
            print('DeepSeek Streaming: Error parsing final buffer: $e');
          }
        }
      }
    } catch (e) {
      print('DeepSeek Streaming Error: $e');
      if (e is DioException) {
        print('Response data: ${e.response?.data}');
        print('Status code: ${e.response?.statusCode}');
      }
      
      // Fallback to non-streaming
      print('DeepSeek Streaming: Falling back to non-streaming mode');
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
} 