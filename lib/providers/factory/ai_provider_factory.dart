import '../base/ai_provider.dart';
import '../base/provider_config.dart';
import '../base/provider_type.dart';
import '../deepseek/deepseek_provider.dart';
import '../openai/openai_provider.dart';
import '../ollama/ollama_provider.dart';
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
      case AiProviderType.ollama:
        return OllamaProvider(config);
      case AiProviderType.mock:
        return MockProvider(config);
    }
  }
} 