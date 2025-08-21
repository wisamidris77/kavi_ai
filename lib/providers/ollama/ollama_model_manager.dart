// import 'dart:async';

// import 'package:ollama_dart/ollama_dart.dart';

// /// Manages Ollama models - listing, pulling, deleting, and getting info
// class OllamaModelManager {
//   OllamaModelManager({String? baseUrl})
//       : _client = OllamaClient(baseUrl: baseUrl ?? 'http://localhost:11434');

//   final OllamaClient _client;

//   /// Popular Ollama models with descriptions
//   static const Map<String, ModelInfo> popularModels = {
//     'llama3.2': ModelInfo(
//       name: 'llama3.2',
//       description: 'Latest Llama 3.2 model from Meta',
//       size: '3B/1B',
//       capabilities: ['chat', 'completion', 'code'],
//     ),
//     'llama3.2:1b': ModelInfo(
//       name: 'llama3.2:1b',
//       description: 'Llama 3.2 1B - Lightweight version',
//       size: '1B',
//       capabilities: ['chat', 'completion'],
//     ),
//     'llama3.2:3b': ModelInfo(
//       name: 'llama3.2:3b',
//       description: 'Llama 3.2 3B - Balanced performance',
//       size: '3B',
//       capabilities: ['chat', 'completion', 'code'],
//     ),
//     'gemma2': ModelInfo(
//       name: 'gemma2',
//       description: 'Google\'s Gemma 2 model',
//       size: '9B/2B',
//       capabilities: ['chat', 'completion', 'reasoning'],
//     ),
//     'qwen2.5': ModelInfo(
//       name: 'qwen2.5',
//       description: 'Alibaba\'s Qwen 2.5 model',
//       size: '7B/3B/1.5B/0.5B',
//       capabilities: ['chat', 'completion', 'code', 'math'],
//     ),
//     'mistral': ModelInfo(
//       name: 'mistral',
//       description: 'Mistral AI\'s latest model',
//       size: '7B',
//       capabilities: ['chat', 'completion', 'code'],
//     ),
//     'phi3.5': ModelInfo(
//       name: 'phi3.5',
//       description: 'Microsoft\'s Phi 3.5 model',
//       size: '3.8B',
//       capabilities: ['chat', 'completion', 'reasoning'],
//     ),
//     'deepseek-coder-v2': ModelInfo(
//       name: 'deepseek-coder-v2',
//       description: 'DeepSeek\'s coding model',
//       size: '16B/7B',
//       capabilities: ['code', 'completion'],
//     ),
//     'codellama': ModelInfo(
//       name: 'codellama',
//       description: 'Meta\'s Code Llama for programming',
//       size: '7B',
//       capabilities: ['code', 'completion'],
//     ),
//     'nomic-embed-text': ModelInfo(
//       name: 'nomic-embed-text',
//       description: 'Text embedding model',
//       size: '137M',
//       capabilities: ['embeddings'],
//     ),
//   };

//   /// Get list of installed models
//   Future<List<InstalledModel>> getInstalledModels() async {
//     try {
//       final response = await _client.listModels();
//       return (response.models ?? []).map((model) {
//         return InstalledModel(
//           name: model.name ?? '',
//           size: model.size ?? 0,
//           modifiedAt: model.modifiedAt,
//           digest: model.digest ?? '',
//           details: model.details,
//         );
//       }).toList();
//     } catch (e) {
//       throw StateError('Failed to get installed models: $e');
//     }
//   }

//   /// Check if a model is installed
//   Future<bool> isModelInstalled(String modelName) async {
//     try {
//       final models = await getInstalledModels();
//       return models.any((m) => m.name.startsWith(modelName));
//     } catch (e) {
//       return false;
//     }
//   }

//   /// Pull a model with progress tracking
//   Stream<PullProgress> pullModel(String modelName) async* {
//     try {
//       final stream = _client.pullModelStream(
//         request: PullModelRequest(model: modelName),
//       );

//       await for (final response in stream) {
//         yield PullProgress(
//           status: response.status ?? '',
//           digest: response.digest,
//           total: response.total,
//           completed: response.completed,
//         );
//       }
//     } catch (e) {
//       yield PullProgress(
//         status: 'Error: $e',
//         error: true,
//       );
//     }
//   }

//   /// Delete a model
//   Future<void> deleteModel(String modelName) async {
//     try {
//       await _client.deleteModel(
//         request: DeleteModelRequest(model: modelName),
//       );
//     } catch (e) {
//       throw StateError('Failed to delete model $modelName: $e');
//     }
//   }

//   /// Copy a model to create a custom version
//   Future<void> copyModel({
//     required String source,
//     required String destination,
//   }) async {
//     try {
//       await _client.copyModel(
//         request: CopyModelRequest(
//           source: source,
//           destination: destination,
//         ),
//       );
//     } catch (e) {
//       throw StateError('Failed to copy model: $e');
//     }
//   }

//   /// Check if Ollama server is running
//   Future<bool> isServerRunning() async {
//     try {
//       await _client.listModels();
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }

//   /// Get server version info
//   Future<String> getServerVersion() async {
//     try {
//       // The ollama_dart package doesn't have a direct version endpoint,
//       // but we can infer from successful connection
//       await _client.listModels();
//       return 'Connected to Ollama server';
//     } catch (e) {
//       return 'Unable to connect to Ollama server';
//     }
//   }
// }

// /// Model information
// class ModelInfo {
//   const ModelInfo({
//     required this.name,
//     required this.description,
//     required this.size,
//     required this.capabilities,
//   });

//   final String name;
//   final String description;
//   final String size;
//   final List<String> capabilities;
// }

// /// Installed model information
// class InstalledModel {
//   const InstalledModel({
//     required this.name,
//     required this.size,
//     required this.digest,
//     this.modifiedAt,
//     this.details,
//   });

//   final String name;
//   final int size;
//   final String digest;
//   final DateTime? modifiedAt;
//   final ModelDetails? details;

//   String get sizeFormatted {
//     const units = ['B', 'KB', 'MB', 'GB'];
//     var bytes = size.toDouble();
//     var unitIndex = 0;
    
//     while (bytes >= 1024 && unitIndex < units.length - 1) {
//       bytes /= 1024;
//       unitIndex++;
//     }
    
//     return '${bytes.toStringAsFixed(1)} ${units[unitIndex]}';
//   }
// }

// /// Pull progress information
// class PullProgress {
//   const PullProgress({
//     required this.status,
//     this.digest,
//     this.total,
//     this.completed,
//     this.error = false,
//   });

//   final String status;
//   final String? digest;
//   final int? total;
//   final int? completed;
//   final bool error;

//   double get progress {
//     if (total == null || completed == null || total == 0) return 0;
//     return completed! / total!;
//   }

//   String get progressPercentage {
//     return '${(progress * 100).toStringAsFixed(1)}%';
//   }
// }