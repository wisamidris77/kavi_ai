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
                      isDense: true,
                      hintText: 'Message assistant…',
                      filled: true,
                      fillColor: colors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: colors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: colors.primary),
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: widget.isBusy
                            ? IconButton(
                                tooltip: 'Stop',
                                icon: const Icon(Icons.stop),
                                color: colors.onPrimary,
                                style: IconButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  minimumSize: const Size(40, 40),
                                  padding: const EdgeInsets.all(10),
                                ),
                                onPressed: widget.onStop,
                              )
                            : IconButton(
                                tooltip: 'Send',
                                icon: const Icon(Icons.send),
                                color: colors.onPrimary,
                                style: IconButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  minimumSize: const Size(40, 40),
                                  padding: const EdgeInsets.all(10),
                                ),
                                onPressed: _submit,
                              ),
                      ),
                      suffixIconConstraints: const BoxConstraints(minHeight: 40, minWidth: 40),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 