import 'package:mocktail/mocktail.dart';
import 'package:kavi/providers/base/ai_provider.dart';
import 'package:kavi/domain/models/chat_message_model.dart';
import 'package:kavi/domain/models/chat_model.dart';
import 'package:kavi/domain/models/llm_model.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider Mocks
class MockAIProvider extends Mock implements AIProvider {}

// HTTP Client Mocks
class MockDio extends Mock implements Dio {}
class MockResponse extends Mock implements Response {}

// Storage Mocks
class MockSharedPreferences extends Mock implements SharedPreferences {}

// Model Mocks
class MockChatMessageModel extends Mock implements ChatMessageModel {}
class MockChatModel extends Mock implements ChatModel {}
class MockLLMModel extends Mock implements LLMModel {}

// Stream Mocks
class MockStreamController<T> extends Mock implements Stream<T> {}

/// Helper class to set up common mock behaviors
class MockSetup {
  /// Set up a mock AI provider with default responses
  static void setupMockAIProvider(MockAIProvider mock, {
    String defaultResponse = 'Mock AI response',
    bool shouldThrow = false,
  }) {
    when(() => mock.sendMessage(any())).thenAnswer((_) async {
      if (shouldThrow) {
        throw Exception('Mock error');
      }
      return Stream.value(defaultResponse);
    });

    when(() => mock.isAvailable()).thenReturn(!shouldThrow);
    when(() => mock.getName()).thenReturn('Mock Provider');
    when(() => mock.getModels()).thenAnswer((_) async => [
      const LLMModel(
        id: 'mock-model-1',
        name: 'Mock Model 1',
        provider: 'mock',
      ),
    ]);
  }

  /// Set up a mock Dio client with default responses
  static void setupMockDio(MockDio mock, {
    Map<String, dynamic>? responseData,
    int statusCode = 200,
    bool shouldThrow = false,
  }) {
    final mockResponse = MockResponse();
    
    when(() => mockResponse.data).thenReturn(responseData ?? {'success': true});
    when(() => mockResponse.statusCode).thenReturn(statusCode);
    
    when(() => mock.post(
      any(),
      data: any(named: 'data'),
      options: any(named: 'options'),
    )).thenAnswer((_) async {
      if (shouldThrow) {
        throw DioException(
          requestOptions: RequestOptions(path: '/test'),
          error: 'Mock error',
        );
      }
      return mockResponse;
    });

    when(() => mock.get(
      any(),
      options: any(named: 'options'),
    )).thenAnswer((_) async {
      if (shouldThrow) {
        throw DioException(
          requestOptions: RequestOptions(path: '/test'),
          error: 'Mock error',
        );
      }
      return mockResponse;
    });
  }

  /// Set up mock SharedPreferences with default values
  static void setupMockSharedPreferences(MockSharedPreferences mock, {
    Map<String, dynamic> initialValues = const {},
  }) {
    final storage = Map<String, dynamic>.from(initialValues);

    // String operations
    when(() => mock.getString(any())).thenAnswer((invocation) {
      final key = invocation.positionalArguments[0] as String;
      return storage[key] as String?;
    });

    when(() => mock.setString(any(), any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      final value = invocation.positionalArguments[1] as String;
      storage[key] = value;
      return true;
    });

    // Int operations
    when(() => mock.getInt(any())).thenAnswer((invocation) {
      final key = invocation.positionalArguments[0] as String;
      return storage[key] as int?;
    });

    when(() => mock.setInt(any(), any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      final value = invocation.positionalArguments[1] as int;
      storage[key] = value;
      return true;
    });

    // Bool operations
    when(() => mock.getBool(any())).thenAnswer((invocation) {
      final key = invocation.positionalArguments[0] as String;
      return storage[key] as bool?;
    });

    when(() => mock.setBool(any(), any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      final value = invocation.positionalArguments[1] as bool;
      storage[key] = value;
      return true;
    });

    // List operations
    when(() => mock.getStringList(any())).thenAnswer((invocation) {
      final key = invocation.positionalArguments[0] as String;
      return storage[key] as List<String>?;
    });

    when(() => mock.setStringList(any(), any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      final value = invocation.positionalArguments[1] as List<String>;
      storage[key] = value;
      return true;
    });

    // Remove and clear operations
    when(() => mock.remove(any())).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      storage.remove(key);
      return true;
    });

    when(() => mock.clear()).thenAnswer((_) async {
      storage.clear();
      return true;
    });

    // Contains key
    when(() => mock.containsKey(any())).thenAnswer((invocation) {
      final key = invocation.positionalArguments[0] as String;
      return storage.containsKey(key);
    });

    // Get keys
    when(() => mock.getKeys()).thenReturn(storage.keys.toSet());
  }

  /// Set up a mock ChatModel with default values
  static void setupMockChatModel(MockChatModel mock, {
    String? id,
    String? title,
    List<ChatMessageModel>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    when(() => mock.id).thenReturn(id ?? 'mock-chat-id');
    when(() => mock.title).thenReturn(title ?? 'Mock Chat');
    when(() => mock.messages).thenReturn(messages ?? []);
    when(() => mock.createdAt).thenReturn(createdAt ?? DateTime.now());
    when(() => mock.updatedAt).thenReturn(updatedAt ?? DateTime.now());
    when(() => mock.toJson()).thenReturn({
      'id': mock.id,
      'title': mock.title,
      'messages': mock.messages.map((m) => m.toJson()).toList(),
      'createdAt': mock.createdAt.toIso8601String(),
      'updatedAt': mock.updatedAt.toIso8601String(),
    });
  }
}

/// Test doubles for specific scenarios
class FakeAIProvider extends Fake implements AIProvider {
  final String name;
  final bool available;
  final List<LLMModel> models;
  final String Function(ChatMessageModel)? responseGenerator;

  FakeAIProvider({
    this.name = 'Fake Provider',
    this.available = true,
    this.models = const [],
    this.responseGenerator,
  });

  @override
  String getName() => name;

  @override
  bool isAvailable() => available;

  @override
  Future<List<LLMModel>> getModels() async => models;

  @override
  Stream<String> sendMessage(ChatMessageModel message) async* {
    if (responseGenerator != null) {
      yield responseGenerator!(message);
    } else {
      yield 'Response to: ${message.content}';
    }
  }

  @override
  Future<void> initialize() async {
    // No-op for testing
  }

  @override
  void dispose() {
    // No-op for testing
  }
}