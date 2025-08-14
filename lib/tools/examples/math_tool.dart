import '../base/tool.dart';

class MathTool implements Tool<String, num> {
  @override
  String get name => 'math_eval';

  @override
  String get description => 'Evaluate a simple arithmetic expression (only + - * / and parentheses).';

  @override
  Future<num> call(String input) async {
    // Extremely minimal safe parser, intended for demo. For anything real, use a vetted parser.
    final sanitized = input.replaceAll(RegExp(r'[^0-9+\-*/(). ]'), '');
    return _evaluate(sanitized);
  }

  num _evaluate(String expr) {
    // Shunting-yard to RPN, then evaluate. Minimal and intentionally small.
    final output = <String>[];
    final ops = <String>[];
    final tokens = RegExp(r"\d+|[+\-*/()]|")
        .allMatches(expr)
        .map((m) => m.group(0)!)
        .where((t) => t.isNotEmpty)
        .toList();
    int prec(String op) => (op == '+' || op == '-') ? 1 : (op == '*' || op == '/') ? 2 : 0;
    bool isOp(String t) => t == '+' || t == '-' || t == '*' || t == '/';

    for (final t in tokens) {
      if (RegExp(r'^\d+$').hasMatch(t)) {
        output.add(t);
      } else if (isOp(t)) {
        while (ops.isNotEmpty && isOp(ops.last) && prec(ops.last) >= prec(t)) {
          output.add(ops.removeLast());
        }
        ops.add(t);
      } else if (t == '(') {
        ops.add(t);
      } else if (t == ')') {
        while (ops.isNotEmpty && ops.last != '(') {
          output.add(ops.removeLast());
        }
        if (ops.isNotEmpty && ops.last == '(') ops.removeLast();
      }
    }
    while (ops.isNotEmpty) {
      output.add(ops.removeLast());
    }

    final stack = <num>[];
    for (final t in output) {
      if (RegExp(r'^\d+$').hasMatch(t)) {
        stack.add(num.parse(t));
      } else if (isOp(t)) {
        final b = stack.removeLast();
        final a = stack.removeLast();
        switch (t) {
          case '+':
            stack.add(a + b);
            break;
          case '-':
            stack.add(a - b);
            break;
          case '*':
            stack.add(a * b);
            break;
          case '/':
            stack.add(a / b);
            break;
        }
      }
    }
    return stack.single;
  }
} 