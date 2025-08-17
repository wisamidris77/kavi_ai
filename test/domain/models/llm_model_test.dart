import 'package:flutter_test/flutter_test.dart';
import 'package:kavi/domain/models/llm_model.dart';
import '../../test_utils/test_helpers.dart';

void main() {
  group('LLMModel', () {
    group('Constructor', () {
      test('should create instance with required parameters', () {
        // Arrange & Act
        const model = LLMModel(
          id: 'model-1',
          name: 'Test Model',
          provider: 'test-provider',
        );

        // Assert
        expect(model.id, equals('model-1'));
        expect(model.name, equals('Test Model'));
        expect(model.provider, equals('test-provider'));
        expect(model.description, isNull);
        expect(model.parameters, isNull);
      });

      test('should create instance with all parameters', () {
        // Arrange
        final parameters = {
          'temperature': 0.7,
          'max_tokens': 2048,
          'top_p': 0.9,
        };

        // Act
        final model = LLMModel(
          id: 'model-1',
          name: 'Test Model',
          provider: 'test-provider',
          description: 'A test model for unit testing',
          parameters: parameters,
        );

        // Assert
        expect(model.id, equals('model-1'));
        expect(model.name, equals('Test Model'));
        expect(model.provider, equals('test-provider'));
        expect(model.description, equals('A test model for unit testing'));
        expect(model.parameters, equals(parameters));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON with minimal fields', () {
        // Arrange
        const model = LLMModel(
          id: 'model-1',
          name: 'Test Model',
          provider: 'test-provider',
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['id'], equals('model-1'));
        expect(json['name'], equals('Test Model'));
        expect(json['provider'], equals('test-provider'));
        expect(json['description'], isNull);
        expect(json['parameters'], isNull);
      });

      test('should serialize to JSON with all fields', () {
        // Arrange
        final parameters = {
          'temperature': 0.7,
          'max_tokens': 2048,
          'nested': {
            'value': 'test',
            'number': 42,
          },
        };
        
        final model = LLMModel(
          id: 'model-1',
          name: 'Test Model',
          provider: 'test-provider',
          description: 'A comprehensive test model',
          parameters: parameters,
        );

        // Act
        final json = model.toJson();

        // Assert
        expect(json['id'], equals('model-1'));
        expect(json['name'], equals('Test Model'));
        expect(json['provider'], equals('test-provider'));
        expect(json['description'], equals('A comprehensive test model'));
        expect(json['parameters'], equals(parameters));
      });

      test('should deserialize from JSON with minimal fields', () {
        // Arrange
        final json = {
          'id': 'model-1',
          'name': 'Test Model',
          'provider': 'test-provider',
        };

        // Act
        final model = LLMModel.fromJson(json);

        // Assert
        expect(model.id, equals('model-1'));
        expect(model.name, equals('Test Model'));
        expect(model.provider, equals('test-provider'));
        expect(model.description, isNull);
        expect(model.parameters, isNull);
      });

      test('should deserialize from JSON with all fields', () {
        // Arrange
        final parameters = {
          'temperature': 0.5,
          'max_tokens': 4096,
          'list': [1, 2, 3],
        };
        
        final json = {
          'id': 'model-1',
          'name': 'Test Model',
          'provider': 'test-provider',
          'description': 'Full model description',
          'parameters': parameters,
        };

        // Act
        final model = LLMModel.fromJson(json);

        // Assert
        expect(model.id, equals('model-1'));
        expect(model.name, equals('Test Model'));
        expect(model.provider, equals('test-provider'));
        expect(model.description, equals('Full model description'));
        expect(model.parameters, equals(parameters));
      });

      test('should handle round-trip serialization', () {
        // Arrange
        final original = TestHelpers.generateLLMModel(
          parameters: {
            'complex': TestHelpers.generateJsonData(),
            'simple': 'value',
          },
        );

        // Act
        final json = original.toJson();
        final deserialized = LLMModel.fromJson(json);
        final reserializedJson = deserialized.toJson();

        // Assert
        expect(deserialized.id, equals(original.id));
        expect(deserialized.name, equals(original.name));
        expect(deserialized.provider, equals(original.provider));
        expect(deserialized.description, equals(original.description));
        expect(deserialized.parameters, equals(original.parameters));
        expect(reserializedJson, equals(json));
      });
    });

    group('Edge Cases', () {
      test('should handle empty strings', () {
        // Arrange & Act
        const model = LLMModel(
          id: '',
          name: '',
          provider: '',
        );

        // Assert
        expect(model.id, equals(''));
        expect(model.name, equals(''));
        expect(model.provider, equals(''));
      });

      test('should handle very long strings', () {
        // Arrange
        final longId = 'id' * 500;
        final longName = 'name' * 500;
        final longProvider = 'provider' * 500;
        final longDescription = 'description' * 500;

        // Act
        final model = LLMModel(
          id: longId,
          name: longName,
          provider: longProvider,
          description: longDescription,
        );

        // Assert
        expect(model.id, equals(longId));
        expect(model.name, equals(longName));
        expect(model.provider, equals(longProvider));
        expect(model.description, equals(longDescription));
      });

      test('should handle special characters', () {
        // Arrange
        const specialChars = 'Model with "quotes", \'apostrophes\', \n newlines, \t tabs, emoji 🚀';

        // Act
        const model = LLMModel(
          id: specialChars,
          name: specialChars,
          provider: specialChars,
          description: specialChars,
        );

        // Assert
        expect(model.id, equals(specialChars));
        expect(model.name, equals(specialChars));
        
        // Test serialization
        final json = model.toJson();
        final deserialized = LLMModel.fromJson(json);
        expect(deserialized.id, equals(specialChars));
      });

      test('should handle complex parameters', () {
        // Arrange
        final complexParams = {
          'string': 'value',
          'int': 42,
          'double': 3.14159,
          'bool': true,
          'null': null,
          'array': [1, 'two', 3.0, true, null],
          'nested': {
            'deep': {
              'deeper': {
                'value': 'found',
                'array': [1, 2, 3],
              },
            },
          },
        };

        // Act
        final model = LLMModel(
          id: 'test',
          name: 'Test',
          provider: 'test',
          parameters: complexParams,
        );

        // Assert
        expect(model.parameters, equals(complexParams));
        
        // Test serialization
        final json = model.toJson();
        final deserialized = LLMModel.fromJson(json);
        expect(deserialized.parameters, equals(complexParams));
      });
    });

    group('Provider Tests', () {
      test('should handle various provider names', () {
        final providers = [
          'openai',
          'anthropic',
          'google',
          'mistral',
          'ollama',
          'deepseek',
          'cohere',
          'custom-provider',
          'provider_with_underscore',
          'provider-with-dash',
        ];

        for (final provider in providers) {
          // Arrange & Act
          final model = LLMModel(
            id: 'test',
            name: 'Test',
            provider: provider,
          );

          // Assert
          expect(model.provider, equals(provider));
          
          // Test serialization
          final json = model.toJson();
          expect(json['provider'], equals(provider));
          
          final deserialized = LLMModel.fromJson(json);
          expect(deserialized.provider, equals(provider));
        }
      });
    });

    group('Generated Data Tests', () {
      test('should handle randomly generated models', () {
        // Arrange & Act
        final models = List.generate(50, (_) => TestHelpers.generateLLMModel());

        // Assert
        for (final model in models) {
          expect(model.id, isNotEmpty);
          expect(model.name, isNotEmpty);
          expect(model.provider, isNotEmpty);
          
          // Test serialization
          final json = model.toJson();
          expect(json, isNotEmpty);
          
          final deserialized = LLMModel.fromJson(json);
          expect(deserialized.id, equals(model.id));
          expect(deserialized.name, equals(model.name));
          expect(deserialized.provider, equals(model.provider));
        }
      });
    });

    group('Performance Tests', () {
      test('should handle rapid creation', () {
        // Arrange
        final stopwatch = Stopwatch()..start();
        
        // Act
        final models = List.generate(1000, (i) => 
          LLMModel(
            id: 'model-$i',
            name: 'Model $i',
            provider: 'provider-$i',
          )
        );
        
        stopwatch.stop();

        // Assert
        expect(models.length, equals(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('should handle rapid serialization', () {
        // Arrange
        final models = List.generate(100, (_) => TestHelpers.generateLLMModel());
        final stopwatch = Stopwatch()..start();
        
        // Act
        for (final model in models) {
          final json = model.toJson();
          LLMModel.fromJson(json);
        }
        
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      });
    });

    group('Fixture Tests', () {
      test('should work with test fixtures', () {
        // Arrange
        final openAI = TestFixtures.openAIModel;
        final anthropic = TestFixtures.anthropicModel;

        // Assert OpenAI model
        expect(openAI.id, equals('gpt-4'));
        expect(openAI.name, equals('GPT-4'));
        expect(openAI.provider, equals('openai'));
        expect(openAI.parameters?['temperature'], equals(0.7));
        
        // Assert Anthropic model
        expect(anthropic.id, equals('claude-3'));
        expect(anthropic.name, equals('Claude 3'));
        expect(anthropic.provider, equals('anthropic'));
        expect(anthropic.parameters?['temperature'], equals(0.5));
        
        // Test serialization
        final openAIJson = openAI.toJson();
        final anthropicJson = anthropic.toJson();
        
        expect(openAIJson['provider'], equals('openai'));
        expect(anthropicJson['provider'], equals('anthropic'));
      });
    });
  });
}