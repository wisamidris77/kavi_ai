abstract class Tool<TInput, TResult> {
  String get name;
  String get description;

  Future<TResult> call(TInput input);
}

class ToolCall<TInput> {
  ToolCall({required this.toolName, required this.input});
  final String toolName;
  final TInput input;
} 