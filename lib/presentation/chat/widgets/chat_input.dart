import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatInput extends StatefulWidget {
  final bool isBusy;
  final VoidCallback? onStop;
  final ValueChanged<String> onSend;

  const ChatInput({
    super.key,
    required this.isBusy,
    required this.onSend,
    this.onStop,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _SubmitIntent extends Intent {
  const _SubmitIntent();
}

class _InsertNewlineIntent extends Intent {
  const _InsertNewlineIntent();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;
    if (widget.isBusy) widget.onStop?.call();
    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _insertNewline() {
    final selection = _controller.selection;
    final fullText = _controller.text;
    final int start = selection.start;
    final int end = selection.end;
    if (start < 0 || end < 0) {
      _controller.text = '$fullText\n';
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
      return;
    }
    final String newText = fullText.replaceRange(start, end, '\n');
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: Shortcuts(
                shortcuts: <ShortcutActivator, Intent>{
                  const SingleActivator(LogicalKeyboardKey.enter): const _SubmitIntent(),
                  const SingleActivator(LogicalKeyboardKey.enter, shift: true): const _InsertNewlineIntent(),
                },
                child: Actions(
                  actions: <Type, Action<Intent>>{
                    _SubmitIntent: CallbackAction<_SubmitIntent>(onInvoke: (_) {
                      _submit();
                      return null;
                    }),
                    _InsertNewlineIntent: CallbackAction<_InsertNewlineIntent>(onInvoke: (_) {
                      _insertNewline();
                      return null;
                    }),
                  },
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 6,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Message ChatGPT…',
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (widget.isBusy)
              FilledButton.tonal(
                onPressed: widget.onStop,
                child: const Icon(Icons.stop),
              )
            else
              FilledButton(
                onPressed: _submit,
                child: const Icon(Icons.send),
              ),
          ],
        ),
      ),
    );
  }
} 