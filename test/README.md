# Kavi Application Test Suite

## Overview

This directory contains comprehensive unit, integration, and widget tests for the Kavi Flutter application. We use Flutter's built-in testing framework along with additional packages for mocking and test data generation.

## Test Structure

```
test/
├── all_tests.dart           # Main test suite runner
├── README.md                # This file
├── widget_test.dart         # Basic widget tests
│
├── test_utils/              # Test utilities and helpers
│   ├── test_helpers.dart    # Common test utilities and data generators
│   └── mocks.dart          # Mock classes and setup helpers
│
├── domain/                  # Domain layer tests
│   └── models/
│       ├── chat_message_model_test.dart
│       ├── chat_model_test.dart
│       └── llm_model_test.dart
│
└── providers/               # Provider layer tests
    └── ai_provider_test.dart
```

## Testing Stack

- **flutter_test**: Core testing framework (built-in)
- **test**: Additional testing utilities
- **mocktail**: Modern mocking library for Dart
- **faker**: Generate realistic test data
- **mockito**: Alternative mocking library

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/domain/models/chat_message_model_test.dart
```

### Run Test Suite
```bash
flutter test test/all_tests.dart
```

### Run with Coverage
```bash
flutter test --coverage
```

### Generate HTML Coverage Report
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Watch Mode (Continuous Testing)
```bash
flutter test --watch
```

## Test Categories

### 1. Unit Tests
- **Models**: Test data models, serialization, and business logic
- **Services**: Test service layer functionality
- **Utilities**: Test helper functions and utilities

### 2. Integration Tests
- **Provider Tests**: Test AI provider integrations
- **API Tests**: Test external API interactions
- **Database Tests**: Test data persistence

### 3. Widget Tests
- **Component Tests**: Test individual UI components
- **Screen Tests**: Test complete screens
- **Navigation Tests**: Test navigation flows

### 4. Performance Tests
- Test response times and resource usage
- Verify no memory leaks
- Check rendering performance

## Writing Tests

### Test Structure
```dart
void main() {
  group('Feature Name', () {
    setUp(() {
      // Setup before each test
    });

    tearDown(() {
      // Cleanup after each test
    });

    test('should do something', () {
      // Arrange
      final input = TestHelpers.generateTestData();
      
      // Act
      final result = functionUnderTest(input);
      
      // Assert
      expect(result, expectedValue);
    });
  });
}
```

### Using Test Helpers
```dart
// Generate test data
final message = TestHelpers.generateChatMessage();
final chat = TestHelpers.generateChatModel();

// Use test fixtures
final systemMsg = TestFixtures.systemMessage;

// Create test widgets
await TestHelpers.pumpAndSettle(tester, widget);
```

### Using Mocks
```dart
// Create mock
final mockProvider = MockAIProvider();

// Setup mock behavior
MockSetup.setupMockAIProvider(mockProvider);

// Use in tests
when(() => mockProvider.generateText(any()))
    .thenAnswer((_) async => 'Mock response');
```

## Test Coverage Goals

- **Overall Coverage**: > 80%
- **Critical Paths**: 100%
- **Models**: > 95%
- **Services**: > 85%
- **UI Components**: > 70%

## Best Practices

1. **Arrange-Act-Assert Pattern**: Structure tests clearly
2. **Descriptive Names**: Use clear, descriptive test names
3. **Test One Thing**: Each test should verify one behavior
4. **Mock External Dependencies**: Don't make real API calls
5. **Use Test Data Generators**: Create realistic test data
6. **Test Edge Cases**: Include boundary and error conditions
7. **Performance Tests**: Include timing assertions for critical paths
8. **Clean Up**: Always clean up resources in tearDown

## Common Test Patterns

### Testing Async Code
```dart
test('async operation', () async {
  final result = await asyncFunction();
  expect(result, isNotNull);
});
```

### Testing Streams
```dart
test('stream emissions', () async {
  final stream = getStream();
  await expectLater(stream, emitsInOrder([1, 2, 3]));
});
```

### Testing Exceptions
```dart
test('throws exception', () {
  expect(() => functionThatThrows(), 
         throwsA(isA<CustomException>()));
});
```

### Testing JSON Serialization
```dart
test('serialization round trip', () {
  final original = Model();
  final json = original.toJson();
  final restored = Model.fromJson(json);
  expect(restored, equals(original));
});
```

## Continuous Integration

Tests are automatically run on:
- Every commit
- Pull requests
- Before deployment

## Troubleshooting

### Test Failures
1. Check test output for specific failure
2. Run single test in isolation
3. Check for timing issues in async tests
4. Verify mock setup is correct

### Coverage Issues
1. Check untested files with coverage report
2. Add tests for uncovered branches
3. Exclude generated files from coverage

## Contributing

When adding new features:
1. Write tests first (TDD approach)
2. Ensure all tests pass
3. Maintain or improve coverage
4. Update this documentation if needed

## Resources

- [Flutter Testing Documentation](https://flutter.dev/docs/testing)
- [Mocktail Documentation](https://pub.dev/packages/mocktail)
- [Faker Documentation](https://pub.dev/packages/faker)
- [Test Coverage Best Practices](https://flutter.dev/docs/testing/coverage)