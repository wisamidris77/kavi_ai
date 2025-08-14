import '../base/tool.dart';

class ToolRegistry {
  final Map<String, Tool<dynamic, dynamic>> _tools = {};

  void register(Tool<dynamic, dynamic> tool) {
    _tools[tool.name] = tool;
  }

  Tool<TInput, TResult>? resolve<TInput, TResult>(String name) {
    final tool = _tools[name];
    if (tool == null) return null;
    return tool as Tool<TInput, TResult>;
  }

  List<String> get names => _tools.keys.toList(growable: false);

  bool contains(String name) => _tools.containsKey(name);
} 