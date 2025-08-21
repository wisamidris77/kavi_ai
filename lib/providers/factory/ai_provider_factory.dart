import '../base/ai_provider.dart';
import '../base/provider_config.dart';
import '../base/provider_type.dart';
import '../deepseek/deepseek_provider.dart';
import '../openai/openai_provider.dart';
import '../anthropic/anthropic_provider.dart';
import '../google/gemini_provider.dart';
import '../mistral/mistral_provider.dart';
import '../cohere/cohere_provider.dart';
import '../mock/mock_provider.dart';

class AiProviderFactory {
  const AiProviderFactory._();

  static AiProvider create({
    required AiProviderType type,
    required AiProviderConfig config,
  }) {
    switch (type) {
      case AiProviderType.openAI:
        return OpenAiProvider(config);
      case AiProviderType.deepSeek:
        return DeepSeekProvider(config);
      case AiProviderType.anthropic:
        return AnthropicProvider(config);
      case AiProviderType.gemini:
        return GeminiProvider(config);
      case AiProviderType.mistral:
        return MistralProvider(config);
      case AiProviderType.cohere:
        return CohereProvider(config);
      //   return OllamaProvider(config);
      case AiProviderType.ollama:
      case AiProviderType.mock:
        return MockProvider(config);
    }
  }
} 