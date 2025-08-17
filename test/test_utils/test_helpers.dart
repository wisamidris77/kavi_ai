import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kavi/domain/models/chat_message_model.dart';
import 'package:kavi/domain/models/chat_model.dart';
import 'package:kavi/domain/models/chat_role.dart';
import 'package:kavi/domain/models/llm_model.dart';
import 'package:kavi/providers/base/provider_type.dart';

/// Test helpers and utilities for comprehensive unit testing
class TestHelpers {
  static final faker = Faker();

  /// Generate a random ChatMessageModel for testing
  static ChatMessageModel generateChatMessage({
    String? id,
    ChatRole? role,
    String? content,
    List<String>? toolCallIds,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessageModel(
      id: id ?? faker.guid.guid(),
      role: role ?? ChatRole.values[faker.randomGenerator.integer(ChatRole.values.length)],
      content: content ?? faker.lorem.sentences(faker.randomGenerator.integer(5, min: 1)).join(' '),
      toolCallIds: toolCallIds ?? [],
      createdAt: createdAt ?? faker.date.dateTime(),
      metadata: metadata,
    );
  }

  /// Generate a list of ChatMessageModels for testing
  static List<ChatMessageModel> generateChatMessages(int count) {
    return List.generate(count, (_) => generateChatMessage());
  }

  /// Generate a random ChatModel for testing
  static ChatModel generateChatModel({
    String? id,
    String? title,
    AiProviderType? providerType,
    String? model,
    List<ChatMessageModel>? messages,
    Map<String, dynamic>? metadata,
  }) {
    return ChatModel(
      id: id ?? faker.guid.guid(),
      title: title ?? faker.lorem.sentence(),
      providerType: providerType ?? AiProviderType.values[faker.randomGenerator.integer(AiProviderType.values.length)],
      model: model,
      messages: messages ?? generateChatMessages(faker.randomGenerator.integer(10, min: 1)),
      metadata: metadata,
    );
  }

  /// Generate a random LLMModel for testing
  static LLMModel generateLLMModel({
    String? id,
    String? name,
    String? provider,
    String? description,
    Map<String, dynamic>? parameters,
  }) {
    return LLMModel(
      id: id ?? faker.guid.guid(),
      name: name ?? faker.company.name(),
      provider: provider ?? faker.randomGenerator.element(['openai', 'anthropic', 'google', 'mistral', 'ollama']),
      description: description ?? faker.lorem.sentence(),
      parameters: parameters ?? {
        'temperature': faker.randomGenerator.decimal(),
        'max_tokens': faker.randomGenerator.integer(4096, min: 100),
      },
    );
  }

  /// Create a test widget wrapper for widget testing
  static Widget createTestWidget(Widget child, {ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: Scaffold(body: child),
    );
  }

  /// Helper to pump widget and settle for async operations
  static Future<void> pumpAndSettle(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(createTestWidget(widget));
    await tester.pumpAndSettle();
  }

  /// Generate random JSON data for testing
  static Map<String, dynamic> generateJsonData({int depth = 2}) {
    if (depth <= 0) {
      return {
        'value': faker.randomGenerator.element([
          faker.lorem.word(),
          faker.randomGenerator.integer(1000),
          faker.randomGenerator.decimal(),
          faker.randomGenerator.boolean(),
        ]),
      };
    }

    final Map<String, dynamic> json = {};
    final fieldCount = faker.randomGenerator.integer(5, min: 1);
    
    for (int i = 0; i < fieldCount; i++) {
      final key = faker.lorem.word();
      final valueType = faker.randomGenerator.integer(4);
      
      switch (valueType) {
        case 0:
          json[key] = faker.lorem.word();
          break;
        case 1:
          json[key] = faker.randomGenerator.integer(1000);
          break;
        case 2:
          json[key] = generateJsonData(depth: depth - 1);
          break;
        case 3:
          json[key] = List.generate(
            faker.randomGenerator.integer(5, min: 1),
            (_) => faker.lorem.word(),
          );
          break;
      }
    }
    
    return json;
  }

  /// Create a test stream for async testing
  static Stream<T> createTestStream<T>(List<T> values, {Duration? delay}) {
    return Stream.fromIterable(values).asyncMap((value) async {
      if (delay != null) {
        await Future.delayed(delay);
      }
      return value;
    });
  }

  /// Test matcher for comparing DateTime with tolerance
  static Matcher isCloseTo(DateTime expected, {Duration tolerance = const Duration(seconds: 1)}) {
    return predicate<DateTime>(
      (actual) => actual.difference(expected).abs() <= tolerance,
      'is close to $expected (±${tolerance.inSeconds}s)',
    );
  }
}

/// Custom test matchers
class CustomMatchers {
  /// Matcher for checking if a string contains all of the given substrings
  static Matcher containsAll(List<String> substrings) {
    return predicate<String>(
      (actual) => substrings.every((substring) => actual.contains(substring)),
      'contains all of $substrings',
    );
  }

  /// Matcher for checking if a map contains all of the given keys
  static Matcher containsAllKeys(List<String> keys) {
    return predicate<Map>(
      (actual) => keys.every((key) => actual.containsKey(key)),
      'contains all keys $keys',
    );
  }

  /// Matcher for checking if a list has unique elements
  static Matcher hasUniqueElements() {
    return predicate<List>(
      (actual) => actual.length == actual.toSet().length,
      'has unique elements',
    );
  }
}

/// Test data fixtures
class TestFixtures {
  static const systemMessage = ChatMessageModel(
    id: 'test-system-1',
    role: ChatRole.system,
    content: 'You are a helpful assistant.',
    toolCallIds: [],
  );

  static const userMessage = ChatMessageModel(
    id: 'test-user-1',
    role: ChatRole.user,
    content: 'Hello, how are you?',
    toolCallIds: [],
  );

  static const assistantMessage = ChatMessageModel(
    id: 'test-assistant-1',
    role: ChatRole.assistant,
    content: 'I am doing well, thank you for asking!',
    toolCallIds: [],
  );

  static final sampleChat = ChatModel(
    id: 'test-chat-1',
    title: 'Test Chat',
    providerType: AiProviderType.openAI,
    model: 'gpt-4',
    messages: const [systemMessage, userMessage, assistantMessage],
  );

  static final openAIModel = LLMModel(
    id: 'gpt-4',
    name: 'GPT-4',
    provider: 'openai',
    description: 'OpenAI GPT-4 model',
    parameters: {
      'temperature': 0.7,
      'max_tokens': 2048,
    },
  );

  static final anthropicModel = LLMModel(
    id: 'claude-3',
    name: 'Claude 3',
    provider: 'anthropic',
    description: 'Anthropic Claude 3 model',
    parameters: {
      'temperature': 0.5,
      'max_tokens': 4096,
    },
  );
}