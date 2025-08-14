import 'dart:async';

import '../base/tool.dart';

class WebSearchTool implements Tool<String, List<String>> {
  @override
  String get name => 'web_search';

  @override
  String get description => 'Search the web and return top result titles (stubbed).';

  @override
  Future<List<String>> call(String input) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return [
      'Result 1 for: $input',
      'Result 2 for: $input',
      'Result 3 for: $input',
    ];
  }
} 