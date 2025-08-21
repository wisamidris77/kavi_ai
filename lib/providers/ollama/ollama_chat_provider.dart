// import 'dart:async';

// import 'package:ollama_dart/ollama_dart.dart';

// import '../../domain/models/chat_message_model.dart';
// import '../base/provider_config.dart';

// /// Enhanced Ollama provider with chat capabilities
// class OllamaChatProvider {
//   OllamaChatProvider({
//     required this.config,
//     String? baseUrl,
//   }) : _client = OllamaClient(
//           baseUrl: baseUrl ?? config.baseUrl ?? 'http://localhost:11434',
//           headers: config.extraHeaders,
//         );

//   final AiProviderConfig config;
//   final OllamaClient _client;

//   String get defaultModel => config.defaultModel ?? 'llama3.2';

//   /// Generate a chat completion with message history
//   Future<String> generateChatCompletion({
//     required List<ChatMessageModel> messages,
//     String? model,
//     double? temperature,
//     int? maxTokens,
//     Map<String, dynamic>? parameters,
//   }) async {
//     final ollamaMessages = _convertToOllamaMessages(messages);
    
//     try {
//       final request = GenerateChatCompletionRequest(
//         model: model ?? defaultModel,
//         messages: ollamaMessages,
//         stream: false,
//         options: RequestOptions(
//           temperature: temperature,
//           numPredict: maxTokens,
//         ),
//       );

//       final response = await _client.generateChatCompletion(request: request);
//       return response.message?.content ?? '';
//     } on OllamaClientException catch (e) {
//       if (e.message?.contains('model') ?? false) {
//         throw StateError(
//           'Model ${model ?? defaultModel} not found. '
//           'Please pull it first with: ollama pull ${model ?? defaultModel}',
//         );
//       }
//       throw StateError('Ollama chat error: ${e.message}');
//     } catch (e) {
//       throw StateError('Failed to generate chat completion: $e');
//     }
//   }

//   /// Stream a chat completion with message history
//   Stream<String> streamChatCompletion({
//     required List<ChatMessageModel> messages,
//     String? model,
//     double? temperature,
//     int? maxTokens,
//     Map<String, dynamic>? parameters,
//   }) async* {
//     final ollamaMessages = _convertToOllamaMessages(messages);
    
//     try {
//       final request = GenerateChatCompletionRequest(
//         model: model ?? defaultModel,
//         messages: ollamaMessages,
//         stream: true,
//         options: RequestOptions(
//           temperature: temperature,
//           numPredict: maxTokens,
//         ),
//       );

//       final stream = _client.generateChatCompletionStream(request: request);
      
//       await for (final response in stream) {
//         final content = response.message?.content;
//         if (content != null && content.isNotEmpty) {
//           yield content;
//         }
        
//         if (response.done ?? false) {
//           break;
//         }
//       }
//     } on OllamaClientException catch (e) {
//       if (e.message?.contains('model') ?? false) {
//         throw StateError(
//           'Model ${model ?? defaultModel} not found. '
//           'Please pull it first with: ollama pull ${model ?? defaultModel}',
//         );
//       }
//       throw StateError('Ollama chat error: ${e.message}');
//     } catch (e) {
//       throw StateError('Failed to stream chat completion: $e');
//     }
//   }

//   /// Generate embeddings for text
//   Future<List<double>> generateEmbeddings({
//     required String text,
//     String? model,
//   }) async {
//     try {
//       final request = GenerateEmbeddingRequest(
//         model: model ?? 'nomic-embed-text',
//         prompt: text,
//       );

//       final response = await _client.generateEmbedding(request: request);
//       return response.embedding ?? [];
//     } catch (e) {
//       throw StateError('Failed to generate embeddings: $e');
//     }
//   }

//   /// Get list of available models
//   Future<List<OllamaModel>> getModels() async {
//     try {
//       final response = await _client.listModels();
//       return response.models ?? [];
//     } catch (e) {
//       throw StateError('Failed to get models: $e');
//     }
//   }

//   /// Get detailed information about a specific model
//   Future<ModelInfo?> getModelInfo(String modelName) async {
//     try {
//       final response = await _client.showModelInfo(
//         request: ModelInfoRequest(model: modelName),
//       );
//       return response;
//     } catch (e) {
//       return null;
//     }
//   }

//   /// Check if server is running
//   Future<bool> isServerRunning() async {
//     try {
//       await _client.listModels();
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }

//   /// Pull a model with progress updates
//   Stream<PullModelResponse> pullModel(String modelName) {
//     return _client.pullModelStream(
//       request: PullModelRequest(model: modelName),
//     );
//   }

//   /// Delete a model
//   Future<void> deleteModel(String modelName) async {
//     try {
//       await _client.deleteModel(
//         request: DeleteModelRequest(model: modelName),
//       );
//     } catch (e) {
//       throw StateError('Failed to delete model: $e');
//     }
//   }

//   /// Convert ChatMessageModel to Ollama Message format
//   List<Message> _convertToOllamaMessages(List<ChatMessageModel> messages) {
//     return messages.map((msg) {
//       MessageRole role;
//       switch (msg.role) {
//         case 'system':
//           role = MessageRole.system;
//           break;
//         case 'assistant':
//           role = MessageRole.assistant;
//           break;
//         case 'user':
//         default:
//           role = MessageRole.user;
//           break;
//       }

//       return Message(
//         role: role,
//         content: msg.content,
//       );
//     }).toList();
//   }
// }