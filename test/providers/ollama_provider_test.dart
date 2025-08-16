import 'package:flutter_test/flutter_test.dart';
import 'package:kavi/providers/ollama/ollama_provider.dart';
import 'package:kavi/providers/base/provider_config.dart';

void main() {
  group('OllamaProvider', () {
    late OllamaProvider provider;
    late AiProviderConfig config;

    setUp(() {
      config = const AiProviderConfig(
        apiKey: '', // Not used for Ollama
        baseUrl: 'http://localhost:11434',
        defaultModel: 'llama3.2',
      );
      provider = OllamaProvider(config);
    });

    test('should have correct name', () {
      expect(provider.name, equals('Ollama'));
    });

    test('should have correct default model', () {
      expect(provider.defaultModel, equals('llama3.2'));
    });

    test('should validate config without throwing', () {
      expect(() => provider.validate(), returnsNormally);
    });

    test('should validate invalid base URL', () {
      final invalidConfig = const AiProviderConfig(
        apiKey: '',
        baseUrl: 'invalid-url',
      );
      final invalidProvider = OllamaProvider(invalidConfig);
      
      expect(() => invalidProvider.validate(), throwsStateError);
    });

    test('should build correct URI', () {
      final uri = provider._buildUri(path: 'api/generate');
      expect(uri.toString(), equals('http://localhost:11434/api/generate'));
    });

    test('should build URI with custom base URL', () {
      final customConfig = const AiProviderConfig(
        apiKey: '',
        baseUrl: 'http://192.168.1.100:11434',
      );
      final customProvider = OllamaProvider(customConfig);
      final uri = customProvider._buildUri(path: 'api/generate');
      expect(uri.toString(), equals('http://192.168.1.100:11434/api/generate'));
    });

    test('should build URI with default base URL when not provided', () {
      final defaultConfig = const AiProviderConfig(apiKey: '');
      final defaultProvider = OllamaProvider(defaultConfig);
      final uri = defaultProvider._buildUri(path: 'api/generate');
      expect(uri.toString(), equals('http://localhost:11434/api/generate'));
    });

    test('should have correct headers', () {
      final headers = provider._headers();
      expect(headers['Content-Type'], equals('application/json'));
    });

    test('should include extra headers', () {
      final configWithHeaders = AiProviderConfig(
        apiKey: '',
        extraHeaders: {'X-Custom-Header': 'custom-value'},
      );
      final providerWithHeaders = OllamaProvider(configWithHeaders);
      final headers = providerWithHeaders._headers();
      expect(headers['X-Custom-Header'], equals('custom-value'));
    });
  });
}