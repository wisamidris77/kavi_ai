import 'package:flutter_test/flutter_test.dart';
import 'package:kavi/domain/models/chat_model.dart';
import 'package:kavi/domain/models/chat_message_model.dart';
import 'package:kavi/domain/models/chat_role.dart';
import 'package:kavi/providers/base/provider_type.dart';
import '../../test_utils/test_helpers.dart';

void main() {
  group('ChatModel', () {
    group('Constructor', () {
      test('should create instance with required parameters', () {
        // Arrange & Act
        const chat = ChatModel(
          id: 'chat-1',
          title: 'Test Chat',
          providerType: AiProviderType.openAI,
        );

        // Assert
        expect(chat.id, equals('chat-1'));
        expect(chat.title, equals('Test Chat'));
        expect(chat.providerType, equals(AiProviderType.openAI));
        expect(chat.model, isNull);
        expect(chat.messages, isEmpty);
        expect(chat.metadata, isNull);
      });

      test('should create instance with all parameters', () {
        // Arrange
        final messages = [
          ChatMessageModel.system('System prompt'),
          ChatMessageModel.user('Hello'),
          ChatMessageModel.assistant('Hi there!'),
        ];
        final metadata = {'session': 'test', 'version': 1};

        // Act
        final chat = ChatModel(
          id: 'chat-1',
          title: 'Test Chat',
          providerType: AiProviderType.anthropic,
          model: 'claude-3-opus',
          messages: messages,
          metadata: metadata,
        );

        // Assert
        expect(chat.id, equals('chat-1'));
        expect(chat.title, equals('Test Chat'));
        expect(chat.providerType, equals(AiProviderType.anthropic));
        expect(chat.model, equals('claude-3-opus'));
        expect(chat.messages, equals(messages));
        expect(chat.metadata, equals(metadata));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON with minimal fields', () {
        // Arrange
        const chat = ChatModel(
          id: 'chat-1',
          title: 'Test Chat',
          providerType: AiProviderType.openAI,
        );

        // Act
        final json = chat.toJson();

        // Assert
        expect(json['id'], equals('chat-1'));
        expect(json['title'], equals('Test Chat'));
        expect(json['providerType'], equals('openAI'));
        expect(json['model'], isNull);
        expect(json['messages'], isEmpty);
        expect(json['metadata'], isNull);
      });

      test('should serialize to JSON with all fields', () {
        // Arrange
        final messages = [
          const ChatMessageModel(
            id: 'msg-1',
            role: ChatRole.user,
            content: 'Hello',
          ),
        ];
        final metadata = {'key': 'value', 'nested': {'data': 123}};
        
        final chat = ChatModel(
          id: 'chat-1',
          title: 'Test Chat',
          providerType: AiProviderType.deepSeek,
          model: 'deepseek-coder',
          messages: messages,
          metadata: metadata,
        );

        // Act
        final json = chat.toJson();

        // Assert
        expect(json['id'], equals('chat-1'));
        expect(json['title'], equals('Test Chat'));
        expect(json['providerType'], equals('deepSeek'));
        expect(json['model'], equals('deepseek-coder'));
        expect(json['messages'], hasLength(1));
        expect(json['messages'][0]['id'], equals('msg-1'));
        expect(json['metadata'], equals(metadata));
      });

      test('should deserialize from JSON with minimal fields', () {
        // Arrange
        final json = {
          'id': 'chat-1',
          'title': 'Test Chat',
          'providerType': 'openAI',
        };

        // Act
        final chat = ChatModel.fromJson(json);

        // Assert
        expect(chat.id, equals('chat-1'));
        expect(chat.title, equals('Test Chat'));
        expect(chat.providerType, equals(AiProviderType.openAI));
        expect(chat.model, isNull);
        expect(chat.messages, isEmpty);
        expect(chat.metadata, isNull);
      });

      test('should deserialize from JSON with all fields', () {
        // Arrange
        final json = {
          'id': 'chat-1',
          'title': 'Test Chat',
          'providerType': 'gemini',
          'model': 'gemini-pro',
          'messages': [
            {
              'id': 'msg-1',
              'role': 'user',
              'content': 'Hello',
              'toolCallIds': [],
            },
            {
              'id': 'msg-2',
              'role': 'assistant',
              'content': 'Hi there!',
              'toolCallIds': [],
            },
          ],
          'metadata': {'session': 'test'},
        };

        // Act
        final chat = ChatModel.fromJson(json);

        // Assert
        expect(chat.id, equals('chat-1'));
        expect(chat.title, equals('Test Chat'));
        expect(chat.providerType, equals(AiProviderType.gemini));
        expect(chat.model, equals('gemini-pro'));
        expect(chat.messages, hasLength(2));
        expect(chat.messages[0].id, equals('msg-1'));
        expect(chat.messages[1].id, equals('msg-2'));
        expect(chat.metadata, equals({'session': 'test'}));
      });

      test('should handle round-trip serialization', () {
        // Arrange
        final original = ChatModel(
          id: 'chat-1',
          title: 'Round Trip Test',
          providerType: AiProviderType.mistral,
          model: 'mistral-large',
          messages: TestHelpers.generateChatMessages(5),
          metadata: {'test': true, 'count': 42},
        );

        // Act
        final json = original.toJson();
        final deserialized = ChatModel.fromJson(json);
        final reserializedJson = deserialized.toJson();

        // Assert
        expect(deserialized.id, equals(original.id));
        expect(deserialized.title, equals(original.title));
        expect(deserialized.providerType, equals(original.providerType));
        expect(deserialized.model, equals(original.model));
        expect(deserialized.messages.length, equals(original.messages.length));
        expect(deserialized.metadata, equals(original.metadata));
        expect(reserializedJson, equals(json));
      });
    });

    group('Provider Type Tests', () {
      test('should handle all provider types', () {
        // Test each provider type
        for (final providerType in AiProviderType.values) {
          // Arrange
          final chat = ChatModel(
            id: 'chat-${providerType.name}',
            title: 'Test ${providerType.name}',
            providerType: providerType,
          );

          // Act
          final json = chat.toJson();
          final deserialized = ChatModel.fromJson(json);

          // Assert
          expect(deserialized.providerType, equals(providerType));
          expect(json['providerType'], equals(providerType.name));
        }
      });
    });

    group('Edge Cases', () {
      test('should handle empty title', () {
        // Arrange & Act
        const chat = ChatModel(
          id: 'chat-1',
          title: '',
          providerType: AiProviderType.openAI,
        );

        // Assert
        expect(chat.title, equals(''));
        
        // Test serialization
        final json = chat.toJson();
        expect(json['title'], equals(''));
      });

      test('should handle very long title', () {
        // Arrange
        final longTitle = 'a' * 1000;

        // Act
        final chat = ChatModel(
          id: 'chat-1',
          title: longTitle,
          providerType: AiProviderType.openAI,
        );

        // Assert
        expect(chat.title, equals(longTitle));
        expect(chat.title.length, equals(1000));
      });

      test('should handle many messages', () {
        // Arrange
        final manyMessages = TestHelpers.generateChatMessages(100);

        // Act
        final chat = ChatModel(
          id: 'chat-1',
          title: 'Many Messages',
          providerType: AiProviderType.ollama,
          messages: manyMessages,
        );

        // Assert
        expect(chat.messages, equals(manyMessages));
        expect(chat.messages.length, equals(100));
        
        // Test serialization
        final json = chat.toJson();
        expect(json['messages'], hasLength(100));
      });

      test('should handle complex metadata', () {
        // Arrange
        final complexMetadata = TestHelpers.generateJsonData(depth: 3);

        // Act
        final chat = ChatModel(
          id: 'chat-1',
          title: 'Complex Metadata',
          providerType: AiProviderType.cohere,
          metadata: complexMetadata,
        );

        // Assert
        expect(chat.metadata, equals(complexMetadata));
        
        // Test serialization
        final json = chat.toJson();
        final deserialized = ChatModel.fromJson(json);
        expect(deserialized.metadata, equals(complexMetadata));
      });

      test('should handle special characters in title', () {
        // Arrange
        const specialTitle = 'Chat with "quotes", \'apostrophes\', \n newlines, \t tabs, and emoji 🚀 🎉';

        // Act
        final chat = ChatModel(
          id: 'chat-1',
          title: specialTitle,
          providerType: AiProviderType.openAI,
        );

        // Assert
        expect(chat.title, equals(specialTitle));
        
        // Test serialization
        final json = chat.toJson();
        final deserialized = ChatModel.fromJson(json);
        expect(deserialized.title, equals(specialTitle));
      });

      test('should preserve message order', () {
        // Arrange
        final messages = [
          ChatMessageModel.system('System'),
          ChatMessageModel.user('User 1'),
          ChatMessageModel.assistant('Assistant 1'),
          ChatMessageModel.user('User 2'),
          ChatMessageModel.assistant('Assistant 2'),
        ];

        // Act
        final chat = ChatModel(
          id: 'chat-1',
          title: 'Order Test',
          providerType: AiProviderType.openAI,
          messages: messages,
        );

        // Assert
        for (int i = 0; i < messages.length; i++) {
          expect(chat.messages[i].content, equals(messages[i].content));
          expect(chat.messages[i].role, equals(messages[i].role));
        }
        
        // Test serialization preserves order
        final json = chat.toJson();
        final deserialized = ChatModel.fromJson(json);
        for (int i = 0; i < messages.length; i++) {
          expect(deserialized.messages[i].content, equals(messages[i].content));
        }
      });
    });

    group('Performance Tests', () {
      test('should handle rapid creation', () {
        // Arrange
        final stopwatch = Stopwatch()..start();
        
        // Act
        final chats = List.generate(1000, (i) => 
          ChatModel(
            id: 'chat-$i',
            title: 'Chat $i',
            providerType: AiProviderType.values[i % AiProviderType.values.length],
          )
        );
        
        stopwatch.stop();

        // Assert
        expect(chats.length, equals(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      test('should handle rapid serialization with messages', () {
        // Arrange
        final chats = List.generate(50, (i) => 
          ChatModel(
            id: 'chat-$i',
            title: 'Chat $i',
            providerType: AiProviderType.openAI,
            messages: TestHelpers.generateChatMessages(10),
            metadata: TestHelpers.generateJsonData(),
          )
        );
        
        final stopwatch = Stopwatch()..start();
        
        // Act
        for (final chat in chats) {
          final json = chat.toJson();
          ChatModel.fromJson(json);
        }
        
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('Integration Tests', () {
      test('should work with generated test data', () {
        // Arrange
        final messages = [
          TestFixtures.systemMessage,
          TestFixtures.userMessage,
          TestFixtures.assistantMessage,
        ];

        // Act
        final chat = ChatModel(
          id: 'integration-test',
          title: 'Integration Test Chat',
          providerType: AiProviderType.openAI,
          model: 'gpt-4',
          messages: messages,
          metadata: {
            'test': true,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        // Assert
        expect(chat.messages, hasLength(3));
        expect(chat.messages[0].role, equals(ChatRole.system));
        expect(chat.messages[1].role, equals(ChatRole.user));
        expect(chat.messages[2].role, equals(ChatRole.assistant));
        
        // Test full serialization cycle
        final json = chat.toJson();
        expect(json, isNotEmpty);
        expect(json['messages'], hasLength(3));
        
        final restored = ChatModel.fromJson(json);
        expect(restored.id, equals(chat.id));
        expect(restored.messages.length, equals(chat.messages.length));
      });
    });
  });
}