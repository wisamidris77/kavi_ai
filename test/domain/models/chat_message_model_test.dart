import 'package:flutter_test/flutter_test.dart';
import 'package:kavi/domain/models/chat_message_model.dart';
import 'package:kavi/domain/models/chat_role.dart';
import '../../test_utils/test_helpers.dart';
import '../../test_utils/mocks.dart';

void main() {
  group('ChatMessageModel', () {
    group('Constructor', () {
      test('should create instance with required parameters', () {
        // Arrange & Act
        const message = ChatMessageModel(
          id: 'test-id',
          role: ChatRole.user,
          content: 'Test content',
        );

        // Assert
        expect(message.id, equals('test-id'));
        expect(message.role, equals(ChatRole.user));
        expect(message.content, equals('Test content'));
        expect(message.toolCallIds, isEmpty);
        expect(message.createdAt, isNull);
        expect(message.metadata, isNull);
      });

      test('should create instance with all parameters', () {
        // Arrange
        final createdAt = DateTime.now();
        final metadata = {'key': 'value', 'count': 42};
        final toolCallIds = ['tool1', 'tool2'];

        // Act
        final message = ChatMessageModel(
          id: 'test-id',
          role: ChatRole.assistant,
          content: 'Test content',
          toolCallIds: toolCallIds,
          createdAt: createdAt,
          metadata: metadata,
        );

        // Assert
        expect(message.id, equals('test-id'));
        expect(message.role, equals(ChatRole.assistant));
        expect(message.content, equals('Test content'));
        expect(message.toolCallIds, equals(toolCallIds));
        expect(message.createdAt, equals(createdAt));
        expect(message.metadata, equals(metadata));
      });
    });

    group('Factory Methods', () {
      test('system() should create system message', () {
        // Act
        final message = ChatMessageModel.system('System prompt');

        // Assert
        expect(message.role, equals(ChatRole.system));
        expect(message.content, equals('System prompt'));
        expect(message.id, isNotEmpty);
        expect(message.createdAt, isNotNull);
        expect(message.createdAt, TestHelpers.isCloseTo(DateTime.now()));
      });

      test('user() should create user message', () {
        // Act
        final message = ChatMessageModel.user('User input');

        // Assert
        expect(message.role, equals(ChatRole.user));
        expect(message.content, equals('User input'));
        expect(message.id, isNotEmpty);
        expect(message.createdAt, isNotNull);
        expect(message.createdAt, TestHelpers.isCloseTo(DateTime.now()));
      });

      test('assistant() should create assistant message', () {
        // Act
        final message = ChatMessageModel.assistant('AI response');

        // Assert
        expect(message.role, equals(ChatRole.assistant));
        expect(message.content, equals('AI response'));
        expect(message.id, isNotEmpty);
        expect(message.createdAt, isNotNull);
        expect(message.createdAt, TestHelpers.isCloseTo(DateTime.now()));
      });

      test('factory methods should generate unique IDs', () {
        // Act
        final messages = [
          ChatMessageModel.system('msg1'),
          ChatMessageModel.user('msg2'),
          ChatMessageModel.assistant('msg3'),
        ];

        // Assert
        final ids = messages.map((m) => m.id).toList();
        expect(ids, CustomMatchers.hasUniqueElements());
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON with minimal fields', () {
        // Arrange
        const message = ChatMessageModel(
          id: 'test-id',
          role: ChatRole.user,
          content: 'Test content',
        );

        // Act
        final json = message.toJson();

        // Assert
        expect(json['id'], equals('test-id'));
        expect(json['role'], equals('user'));
        expect(json['content'], equals('Test content'));
        expect(json['toolCallIds'], isEmpty);
        expect(json.containsKey('createdAt'), isTrue);
        expect(json['createdAt'], isNull);
      });

      test('should serialize to JSON with all fields', () {
        // Arrange
        final createdAt = DateTime(2024, 1, 15, 10, 30);
        final metadata = {'key': 'value', 'nested': {'data': 123}};
        final message = ChatMessageModel(
          id: 'test-id',
          role: ChatRole.assistant,
          content: 'Test content',
          toolCallIds: ['tool1', 'tool2'],
          createdAt: createdAt,
          metadata: metadata,
        );

        // Act
        final json = message.toJson();

        // Assert
        expect(json['id'], equals('test-id'));
        expect(json['role'], equals('assistant'));
        expect(json['content'], equals('Test content'));
        expect(json['toolCallIds'], equals(['tool1', 'tool2']));
        expect(json['createdAt'], equals(createdAt.toIso8601String()));
        expect(json['metadata'], equals(metadata));
      });

      test('should deserialize from JSON with minimal fields', () {
        // Arrange
        final json = {
          'id': 'test-id',
          'role': 'user',
          'content': 'Test content',
        };

        // Act
        final message = ChatMessageModel.fromJson(json);

        // Assert
        expect(message.id, equals('test-id'));
        expect(message.role, equals(ChatRole.user));
        expect(message.content, equals('Test content'));
        expect(message.toolCallIds, isEmpty);
        expect(message.createdAt, isNull);
        expect(message.metadata, isNull);
      });

      test('should deserialize from JSON with all fields', () {
        // Arrange
        final createdAt = DateTime(2024, 1, 15, 10, 30);
        final metadata = {'key': 'value', 'count': 42};
        final json = {
          'id': 'test-id',
          'role': 'assistant',
          'content': 'Test content',
          'toolCallIds': ['tool1', 'tool2'],
          'createdAt': createdAt.toIso8601String(),
          'metadata': metadata,
        };

        // Act
        final message = ChatMessageModel.fromJson(json);

        // Assert
        expect(message.id, equals('test-id'));
        expect(message.role, equals(ChatRole.assistant));
        expect(message.content, equals('Test content'));
        expect(message.toolCallIds, equals(['tool1', 'tool2']));
        expect(message.createdAt, equals(createdAt));
        expect(message.metadata, equals(metadata));
      });

      test('should handle round-trip serialization', () {
        // Arrange
        final original = TestHelpers.generateChatMessage(
          metadata: {'test': 'data', 'number': 123},
          toolCallIds: ['tool1', 'tool2', 'tool3'],
        );

        // Act
        final json = original.toJson();
        final deserialized = ChatMessageModel.fromJson(json);
        final reserializedJson = deserialized.toJson();

        // Assert
        expect(deserialized.id, equals(original.id));
        expect(deserialized.role, equals(original.role));
        expect(deserialized.content, equals(original.content));
        expect(deserialized.toolCallIds, equals(original.toolCallIds));
        expect(deserialized.createdAt, equals(original.createdAt));
        expect(deserialized.metadata, equals(original.metadata));
        expect(reserializedJson, equals(json));
      });
    });

    group('Edge Cases', () {
      test('should handle empty content', () {
        // Arrange & Act
        const message = ChatMessageModel(
          id: 'test-id',
          role: ChatRole.user,
          content: '',
        );

        // Assert
        expect(message.content, equals(''));
        final json = message.toJson();
        expect(json['content'], equals(''));
      });

      test('should handle very long content', () {
        // Arrange
        final longContent = 'a' * 10000;

        // Act
        final message = ChatMessageModel(
          id: 'test-id',
          role: ChatRole.user,
          content: longContent,
        );

        // Assert
        expect(message.content, equals(longContent));
        expect(message.content.length, equals(10000));
      });

      test('should handle special characters in content', () {
        // Arrange
        const specialContent = 'Test with "quotes", \'apostrophes\', \n newlines, \t tabs, and emoji 🚀';

        // Act
        final message = ChatMessageModel(
          id: 'test-id',
          role: ChatRole.user,
          content: specialContent,
        );

        // Assert
        expect(message.content, equals(specialContent));
        
        // Test JSON serialization
        final json = message.toJson();
        final deserialized = ChatMessageModel.fromJson(json);
        expect(deserialized.content, equals(specialContent));
      });

      test('should handle complex metadata structures', () {
        // Arrange
        final complexMetadata = {
          'string': 'value',
          'number': 42,
          'decimal': 3.14,
          'boolean': true,
          'null': null,
          'list': [1, 2, 3, 'four'],
          'nested': {
            'deep': {
              'structure': {
                'value': 'found'
              }
            }
          }
        };

        // Act
        final message = ChatMessageModel(
          id: 'test-id',
          role: ChatRole.user,
          content: 'Test',
          metadata: complexMetadata,
        );

        // Assert
        expect(message.metadata, equals(complexMetadata));
        
        // Test JSON serialization
        final json = message.toJson();
        final deserialized = ChatMessageModel.fromJson(json);
        expect(deserialized.metadata, equals(complexMetadata));
      });

      test('should handle many tool call IDs', () {
        // Arrange
        final manyToolCallIds = List.generate(100, (i) => 'tool_$i');

        // Act
        final message = ChatMessageModel(
          id: 'test-id',
          role: ChatRole.assistant,
          content: 'Test',
          toolCallIds: manyToolCallIds,
        );

        // Assert
        expect(message.toolCallIds, equals(manyToolCallIds));
        expect(message.toolCallIds.length, equals(100));
      });
    });

    group('Generated Data Tests', () {
      test('should handle randomly generated messages', () {
        // Arrange & Act
        final messages = List.generate(50, (_) => TestHelpers.generateChatMessage());

        // Assert
        for (final message in messages) {
          expect(message.id, isNotEmpty);
          expect(message.role, isIn(ChatRole.values));
          expect(message.content, isNotEmpty);
          expect(message.toolCallIds, isNotNull);
          expect(message.createdAt, isNotNull);
          
          // Test serialization
          final json = message.toJson();
          expect(json, isNotEmpty);
          
          final deserialized = ChatMessageModel.fromJson(json);
          expect(deserialized.id, equals(message.id));
          expect(deserialized.role, equals(message.role));
          expect(deserialized.content, equals(message.content));
        }
      });
    });

    group('Performance Tests', () {
      test('should handle rapid creation of messages', () {
        // Arrange
        final stopwatch = Stopwatch()..start();
        
        // Act
        final messages = List.generate(1000, (i) => 
          ChatMessageModel.user('Message $i')
        );
        
        stopwatch.stop();

        // Assert
        expect(messages.length, equals(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should complete in less than 1 second
        
        // Verify all IDs are unique
        final ids = messages.map((m) => m.id).toSet();
        expect(ids.length, equals(1000));
      });

      test('should handle rapid serialization/deserialization', () {
        // Arrange
        final messages = List.generate(100, (_) => TestHelpers.generateChatMessage());
        final stopwatch = Stopwatch()..start();
        
        // Act
        for (final message in messages) {
          final json = message.toJson();
          ChatMessageModel.fromJson(json);
        }
        
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(500)); // Should complete quickly
      });
    });
  });
}