/// Comprehensive Test Suite for Kavi Project
/// 
/// This file runs all unit, integration, and widget tests for the project.
/// Run with: flutter test test/all_tests.dart
/// 
/// For coverage report: flutter test --coverage test/all_tests.dart
/// Then: genhtml coverage/lcov.info -o coverage/html

import 'package:flutter_test/flutter_test.dart';

// Domain Layer Tests
import 'domain/models/chat_message_model_test.dart' as chat_message_tests;
import 'domain/models/chat_model_test.dart' as chat_model_tests;
import 'domain/models/llm_model_test.dart' as llm_model_tests;

// Provider Layer Tests
import 'providers/ai_provider_test.dart' as provider_tests;

// Widget Tests
import 'widget_test.dart' as widget_tests;

void main() {
  group('Kavi Application Test Suite', () {
    group('Domain Layer Tests', () {
      chat_message_tests.main();
      chat_model_tests.main();
      llm_model_tests.main();
    });

    group('Provider Layer Tests', () {
      provider_tests.main();
    });

    group('Widget Tests', () {
      widget_tests.main();
    });
  });
}