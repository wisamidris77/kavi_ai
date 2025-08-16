import 'package:kavi/providers/ollama/ollama_provider.dart';
import 'package:kavi/providers/base/provider_config.dart';

/// Example usage of the Ollama provider
void main() async {
  // Create Ollama provider configuration
  final config = AiProviderConfig(
    apiKey: '', // Not used for Ollama
    baseUrl: 'http://localhost:11434', // Default Ollama URL
    defaultModel: 'llama3.2',
  );

  // Create the provider
  final provider = OllamaProvider(config);

  try {
    // Generate a simple text completion
    final response = await provider.generateText(
      prompt: 'Hello, how are you today?',
      temperature: 0.7,
      maxTokens: 100,
    );

    print('Response: $response');

    // Stream text completion
    print('\nStreaming response:');
    await for (final chunk in provider.streamText(
      prompt: 'Tell me a short story about a cat.',
      temperature: 0.8,
    )) {
      print(chunk);
    }

  } catch (e) {
    print('Error: $e');
    print('Make sure Ollama is running and the model is pulled:');
    print('  ollama serve');
    print('  ollama pull llama3.2');
  }
}