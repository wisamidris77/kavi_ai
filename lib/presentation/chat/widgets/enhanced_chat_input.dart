import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class EnhancedChatInput extends StatefulWidget {
  final bool isBusy;
  final VoidCallback? onStop;
  final ValueChanged<String> onSend;
  final ValueChanged<List<File>>? onFilesSelected;
  final List<File>? attachedFiles;
  final VoidCallback? onClearFiles;

  const EnhancedChatInput({
    super.key,
    required this.isBusy,
    required this.onSend,
    this.onStop,
    this.onFilesSelected,
    this.attachedFiles,
    this.onClearFiles,
  });

  @override
  State<EnhancedChatInput> createState() => _EnhancedChatInputState();
}

class _SubmitIntent extends Intent {
  const _SubmitIntent();
}

class _InsertNewlineIntent extends Intent {
  const _InsertNewlineIntent();
}

class _AttachFileIntent extends Intent {
  const _AttachFileIntent();
}

class _EnhancedChatInputState extends State<EnhancedChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<File> _attachedFiles = [];

  @override
  void initState() {
    super.initState();
    if (widget.attachedFiles != null) {
      _attachedFiles.addAll(widget.attachedFiles!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final String text = _controller.text.trim();
    if (text.isEmpty && _attachedFiles.isEmpty) return;
    
    if (widget.isBusy) {
      widget.onStop?.call();
      return;
    }
    
    widget.onSend(text);
    _controller.clear();
    _clearAttachedFiles();
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

  Future<void> _attachFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'txt', 'md', 'pdf', 'doc', 'docx',
          'jpg', 'jpeg', 'png', 'gif', 'webp',
          'mp3', 'wav', 'm4a',
          'mp4', 'mov', 'avi',
          'json', 'csv', 'xml', 'yaml', 'yml',
          'py', 'js', 'ts', 'java', 'cpp', 'c', 'cs',
          'html', 'css', 'php', 'rb', 'go', 'rs',
        ],
      );

      if (result != null) {
        final files = result.paths.map((path) => File(path!)).toList();
        setState(() {
          _attachedFiles.addAll(files);
        });
        widget.onFilesSelected?.call(_attachedFiles);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting files: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
    widget.onFilesSelected?.call(_attachedFiles);
  }

  void _clearAttachedFiles() {
    setState(() {
      _attachedFiles.clear();
    });
    widget.onClearFiles?.call();
  }

  String _getFileSize(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'mp3':
      case 'wav':
      case 'm4a':
        return Icons.audiotrack;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.videocam;
      case 'txt':
      case 'md':
        return Icons.text_snippet;
      case 'json':
      case 'xml':
      case 'yaml':
      case 'yml':
        return Icons.code;
      case 'py':
      case 'js':
      case 'ts':
      case 'java':
      case 'cpp':
      case 'c':
      case 'cs':
      case 'html':
      case 'css':
      case 'php':
      case 'rb':
      case 'go':
      case 'rs':
        return Icons.code;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          // Attached files display
          if (_attachedFiles.isNotEmpty)
            Container(
              height: 80,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _attachedFiles.length,
                itemBuilder: (context, index) {
                  final file = _attachedFiles[index];
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.outline),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getFileIcon(file.path),
                                color: colors.primary,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                file.path.split('/').last,
                                style: colors.onSurfaceVariant.copyWith(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                _getFileSize(file),
                                style: colors.onSurfaceVariant.copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeFile(index),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: colors.error,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 12,
                                color: colors.onError,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          
          // Input field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                // Attach file button
                IconButton(
                  tooltip: 'Attach files',
                  icon: const Icon(Icons.attach_file),
                  color: colors.onSurfaceVariant,
                  onPressed: widget.isBusy ? null : _attachFiles,
                ),
                
                Expanded(
                  child: Shortcuts(
                    shortcuts: <ShortcutActivator, Intent>{
                      const SingleActivator(LogicalKeyboardKey.enter): const _SubmitIntent(),
                      const SingleActivator(LogicalKeyboardKey.enter, shift: true): const _InsertNewlineIntent(),
                      const SingleActivator(LogicalKeyboardKey.keyA, control: true): const _AttachFileIntent(),
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
                        _AttachFileIntent: CallbackAction<_AttachFileIntent>(onInvoke: (_) {
                          _attachFiles();
                          return null;
                        }),
                      },
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 6,
                        textInputAction: TextInputAction.newline,
                        enabled: !widget.isBusy,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: _attachedFiles.isNotEmpty 
                              ? 'Add a message (optional)...'
                              : 'Message assistant…',
                          filled: true,
                          fillColor: colors.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: colors.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: colors.primary, width: 2),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: colors.outlineVariant.withOpacity(0.5)),
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: widget.isBusy
                                ? IconButton(
                                    tooltip: 'Stop generation',
                                    icon: const Icon(Icons.stop),
                                    color: colors.onPrimary,
                                    style: IconButton.styleFrom(
                                      backgroundColor: colors.error,
                                      minimumSize: const Size(40, 40),
                                      padding: const EdgeInsets.all(10),
                                    ),
                                    onPressed: widget.onStop,
                                  )
                                : IconButton(
                                    tooltip: 'Send message',
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
        ],
      ),
    );
  }
}