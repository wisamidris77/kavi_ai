import 'provider_config.dart';

/// Base interface for any AI text provider.
abstract class AiProvider {
  const AiProvider(this.config);

  /// Runtime configuration for the provider instance (API key, base URL, etc.).
  final AiProviderConfig config;

  /// A human-friendly name for the provider, e.g. "OpenAI" or "DeepSeek".
  String get name;

  /// Default model for the provider if none is explicitly provided per call.
  String get defaultModel;

  /// Generate a single non-streamed text completion.
  Future<String> generateText({
    required String prompt,
    String? model,
    double? temperature,
    int? maxTokens,
    Map<String, dynamic>? parameters,
  });

  /// Stream token deltas for a text completion.
  Stream<String> streamText({
    required String prompt,
    String? model,
    double? temperature,
    int? maxTokens,
    Map<String, dynamic>? parameters,
  });

  /// Validate the configuration (e.g., API key presence) and throw on error.
  void validate();
} 