class AiProviderConfig {
  const AiProviderConfig({
    required this.apiKey,
    this.baseUrl,
    this.defaultModel,
    this.timeout = const Duration(seconds: 60),
    this.extraHeaders = const {},
  });

  /// Secret key for authenticating with the provider.
  final String apiKey;

  /// Optional base URL override for self-hosted or proxy endpoints.
  final String? baseUrl;

  /// Optional default model override for this provider instance.
  final String? defaultModel;

  /// Network timeout for requests.
  final Duration timeout;

  /// Additional headers merged into the default set per provider.
  final Map<String, String> extraHeaders;
} 