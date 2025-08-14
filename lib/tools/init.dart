import 'tools.dart';

ToolRegistry createDefaultToolRegistry() {
  final registry = ToolRegistry();
  registry.register(WebSearchTool());
  registry.register(MathTool());
  return registry;
} 