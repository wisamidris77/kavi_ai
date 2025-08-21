import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';

void main() async {
  // 3. Construct a RAG prompt template
  final promptTemplate = ChatPromptValue([ChatMessage.humanText('say hi!')]);

  // 4. Define the final chain
  final model = ChatOpenAI(
    apiKey: 'sk-b12882e844704743b9df76fa3d7fbcdc',
    baseUrl: 'https://api.deepseek.com/v1',
    defaultOptions: const ChatOpenAIOptions(model: 'deepseek-chat'),
  );
  const outputParser = StringOutputParser<ChatResult>();
  final chain = Runnable.fromMap<String>({'question': Runnable.passthrough()}).pipe(promptTemplate).pipe(model).pipe(outputParser);

  // 5. Run the pipeline
  final res = await chain.invoke('Who created LangChain.dart?');
  print(res);
}
