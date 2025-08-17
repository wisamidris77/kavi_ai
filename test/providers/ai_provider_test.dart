import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kavi/providers/base/ai_provider.dart';
import 'package:kavi/providers/base/provider_config.dart';
import 'package:kavi/providers/mock/mock_provider.dart';
import '../test_utils/mocks.dart';
import '../test_utils/test_helpers.dart';

void main() {
  group('AIProvider', () {
    late AiProviderConfig testConfig;

    setUp(() {
      testConfig = const AiProviderConfig(
        apiKey: 'test-api-key',
        baseUrl: 'https://api.test.com',
        organizationId: 'test-org',
      );
    });

    group('Mock Provider Tests', () {
      test('should create mock provider with config', () {
        // Arrange & Act
        final provider = MockProvider(testConfig);

        // Assert
        expect(provider.config, equals(testConfig));
        expect(provider.name, equals('Mock'));
        expect(provider.defaultModel, equals('mock-model'));
      });

      test('should generate text with default parameters', () async {
        // Arrange
        final provider = MockProvider(testConfig);

        // Act
        final result = await provider.generateText(
          prompt: 'Hello, world!',
        );

        // Assert
        expect(result, contains('Mock response'));
        expect(result, contains('Hello, world!'));
      });

      test('should generate text with custom parameters', () async {
        // Arrange
        final provider = MockProvider(testConfig);

        // Act
        final result = await provider.generateText(
          prompt: 'Test prompt',
          model: 'custom-model',
          temperature: 0.5,
          maxTokens: 100,
          parameters: {'custom': 'value'},
        );

        // Assert
        expect(result, isNotEmpty);
        expect(result, contains('Mock response'));
      });

      test('should stream text tokens', () async {
        // Arrange
        final provider = MockProvider(testConfig);
        final tokens = <String>[];

        // Act
        await for (final token in provider.streamText(prompt: 'Stream test')) {
          tokens.add(token);
        }

        // Assert
        expect(tokens, isNotEmpty);
        expect(tokens.join(), contains('Mock'));
        expect(tokens.join(), contains('Stream test'));
      });

      test('should validate configuration', () {
        // Arrange
        final provider = MockProvider(testConfig);

        // Act & Assert
        expect(() => provider.validate(), returnsNormally);
      });

      test('should throw on invalid configuration', () {
        // Arrange
        final invalidConfig = const AiProviderConfig(
          apiKey: '', // Empty API key
          baseUrl: 'https://api.test.com',
        );
        final provider = MockProvider(invalidConfig);

        // Act & Assert
        expect(() => provider.validate(), throwsException);
      });
    });

    group('Stream Tests', () {
      test('should handle stream with multiple tokens', () async {
        // Arrange
        final provider = MockProvider(testConfig);
        final tokens = <String>[];

        // Act
        await for (final token in provider.streamText(
          prompt: 'Generate multiple tokens',
          maxTokens: 10,
        )) {
          tokens.add(token);
        }

        // Assert
        expect(tokens.length, greaterThan(1));
        expect(tokens.every((t) => t.isNotEmpty), isTrue);
      });

      test('should handle empty prompt in stream', () async {
        // Arrange
        final provider = MockProvider(testConfig);
        final tokens = <String>[];

        // Act
        await for (final token in provider.streamText(prompt: '')) {
          tokens.add(token);
        }

        // Assert
        expect(tokens, isNotEmpty);
      });

      test('should handle stream cancellation', () async {
        // Arrange
        final provider = MockProvider(testConfig);
        final tokens = <String>[];
        
        // Act
        final stream = provider.streamText(
          prompt: 'Long generation',
          maxTokens: 1000,
        );
        
        int count = 0;
        await for (final token in stream) {
          tokens.add(token);
          count++;
          if (count >= 3) break; // Cancel after 3 tokens
        }

        // Assert
        expect(tokens.length, equals(3));
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        // Arrange
        final errorProvider = _ErrorThrowingProvider(testConfig);

        // Act & Assert
        expect(
          () => errorProvider.generateText(prompt: 'test'),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle stream errors', () async {
        // Arrange
        final errorProvider = _ErrorThrowingProvider(testConfig);

        // Act & Assert
        expect(
          () => errorProvider.streamText(prompt: 'test').toList(),
          throwsA(isA<Exception>()),
        );
      });

      test('should validate required fields', () {
        // Arrange
        final configs = [
          const AiProviderConfig(apiKey: '', baseUrl: 'https://test.com'),
          const AiProviderConfig(apiKey: 'key', baseUrl: ''),
          const AiProviderConfig(apiKey: null, baseUrl: 'https://test.com'),
        ];

        // Act & Assert
        for (final config in configs) {
          final provider = MockProvider(config);
          expect(() => provider.validate(), throwsException);
        }
      });
    });

    group('Parameter Tests', () {
      test('should handle temperature parameter', () async {
        // Arrange
        final provider = MockProvider(testConfig);
        final temperatures = [0.0, 0.5, 1.0, 2.0];

        // Act & Assert
        for (final temp in temperatures) {
          final result = await provider.generateText(
            prompt: 'test',
            temperature: temp,
          );
          expect(result, isNotEmpty);
        }
      });

      test('should handle maxTokens parameter', () async {
        // Arrange
        final provider = MockProvider(testConfig);
        final tokenLimits = [1, 10, 100, 1000, 4096];

        // Act & Assert
        for (final limit in tokenLimits) {
          final result = await provider.generateText(
            prompt: 'test',
            maxTokens: limit,
          );
          expect(result, isNotEmpty);
        }
      });

      test('should handle custom parameters', () async {
        // Arrange
        final provider = MockProvider(testConfig);
        final customParams = {
          'top_p': 0.9,
          'frequency_penalty': 0.5,
          'presence_penalty': 0.5,
          'stop': ['\\n', '.'],
          'user': 'test-user',
        };

        // Act
        final result = await provider.generateText(
          prompt: 'test',
          parameters: customParams,
        );

        // Assert
        expect(result, isNotEmpty);
      });
    });

    group('Configuration Tests', () {
      test('should handle different base URLs', () {
        // Arrange
        final urls = [
          'https://api.openai.com',
          'https://api.anthropic.com',
          'http://localhost:8080',
          'https://custom.domain.com/v1',
        ];

        // Act & Assert
        for (final url in urls) {
          final config = AiProviderConfig(
            apiKey: 'test-key',
            baseUrl: url,
          );
          final provider = MockProvider(config);
          expect(provider.config.baseUrl, equals(url));
        }
      });

      test('should handle organization ID', () {
        // Arrange
        final config = const AiProviderConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.test.com',
          organizationId: 'org-123',
        );

        // Act
        final provider = MockProvider(config);

        // Assert
        expect(provider.config.organizationId, equals('org-123'));
      });

      test('should handle null organization ID', () {
        // Arrange
        final config = const AiProviderConfig(
          apiKey: 'test-key',
          baseUrl: 'https://api.test.com',
          organizationId: null,
        );

        // Act
        final provider = MockProvider(config);

        // Assert
        expect(provider.config.organizationId, isNull);
      });
    });

    group('Performance Tests', () {
      test('should handle rapid sequential requests', () async {
        // Arrange
        final provider = MockProvider(testConfig);
        final stopwatch = Stopwatch()..start();

        // Act
        for (int i = 0; i < 100; i++) {
          await provider.generateText(prompt: 'Test $i');
        }
        
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('should handle concurrent requests', () async {
        // Arrange
        final provider = MockProvider(testConfig);
        final stopwatch = Stopwatch()..start();

        // Act
        final futures = List.generate(50, (i) => 
          provider.generateText(prompt: 'Concurrent test $i')
        );
        final results = await Future.wait(futures);
        
        stopwatch.stop();

        // Assert
        expect(results.length, equals(50));
        expect(results.every((r) => r.isNotEmpty), isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      test('should handle large prompts', () async {
        // Arrange
        final provider = MockProvider(testConfig);
        final largePrompt = 'a' * 10000;

        // Act
        final result = await provider.generateText(prompt: largePrompt);

        // Assert
        expect(result, isNotEmpty);
      });
    });

    group('Integration Tests', () {
      test('should work with test fixtures', () async {
        // Arrange
        final provider = MockProvider(testConfig);
        final message = TestFixtures.userMessage;

        // Act
        final result = await provider.generateText(
          prompt: message.content,
        );

        // Assert
        expect(result, isNotEmpty);
        expect(result, contains('Mock response'));
      });

      test('should handle conversation context', () async {
        // Arrange
        final provider = MockProvider(testConfig);
        final messages = [
          TestFixtures.systemMessage,
          TestFixtures.userMessage,
          TestFixtures.assistantMessage,
        ];

        // Act
        final prompt = messages.map((m) => '${m.role}: ${m.content}').join('\n');
        final result = await provider.generateText(prompt: prompt);

        // Assert
        expect(result, isNotEmpty);
      });

      test('should work with generated test data', () async {
        // Arrange
        final provider = MockProvider(testConfig);
        final messages = TestHelpers.generateChatMessages(5);

        // Act
        for (final message in messages) {
          final result = await provider.generateText(
            prompt: message.content,
          );
          expect(result, isNotEmpty);
        }
      });
    });
  });
}

// Test helper class for error simulation
class _ErrorThrowingProvider extends AiProvider {
  const _ErrorThrowingProvider(AiProviderConfig config) : super(config);

  @override
  String get name => 'Error Provider';

  @override
  String get defaultModel => 'error-model';

  @override
  Future<String> generateText({
    required String prompt,
    String? model,
    double? temperature,
    int? maxTokens,
    Map<String, dynamic>? parameters,
  }) async {
    throw Exception('Simulated network error');
  }

  @override
  Stream<String> streamText({
    required String prompt,
    String? model,
    double? temperature,
    int? maxTokens,
    Map<String, dynamic>? parameters,
  }) async* {
    throw Exception('Simulated stream error');
  }

  @override
  void validate() {
    // No-op for testing
  }
}