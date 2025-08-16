import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

class EnhancedChatInput extends StatefulWidget {
  final bool isBusy;
  final Function(String) onSend;
  final VoidCallback? onStop;
  final Function(PlatformFile)? onFileSelected;
  
  const EnhancedChatInput({
    super.key,
    required this.isBusy,
    required this.onSend,
    this.onStop,
    this.onFileSelected,
  });

  @override
  State<EnhancedChatInput> createState() => _EnhancedChatInputState();
}

class _EnhancedChatInputState extends State<EnhancedChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;
  bool _isVoiceMode = false;
  bool _isRecording = false;
  List<PlatformFile> _attachedFiles = [];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;
    
    widget.onSend(text);
    _controller.clear();
    setState(() {
      _isComposing = false;
      _attachedFiles.clear();
    });
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _attachedFiles.addAll(result.files);
        });
        
        for (final file in result.files) {
          widget.onFileSelected?.call(file);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  void _toggleVoiceMode() {
    setState(() {
      _isVoiceMode = !_isVoiceMode;
      if (!_isVoiceMode && _isRecording) {
        _isRecording = false;
      }
    });
  }

  void _handleVoiceRecord() {
    setState(() {
      _isRecording = !_isRecording;
    });
    
    if (_isRecording) {
      // TODO: Implement voice recording
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice input coming soon!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attached files preview
          if (_attachedFiles.isNotEmpty)
            Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _attachedFiles.length,
                itemBuilder: (context, index) {
                  final file = _attachedFiles[index];
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.insert_drive_file,
                              color: colors.onSecondaryContainer,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              file.name,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => _removeFile(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          
          // Main input area
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Action buttons
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: widget.isBusy ? null : _pickFile,
                    tooltip: 'Attach file',
                  ),
                  IconButton(
                    icon: Icon(_isVoiceMode ? Icons.keyboard : Icons.mic),
                    onPressed: widget.isBusy ? null : _toggleVoiceMode,
                    tooltip: _isVoiceMode ? 'Switch to keyboard' : 'Voice input',
                  ),
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    onPressed: widget.isBusy ? null : () {
                      // TODO: Implement emoji picker
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Emoji picker coming soon!')),
                      );
                    },
                    tooltip: 'Emoji',
                  ),
                ],
              ),
              
              // Text input or voice recording
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isVoiceMode
                      ? _buildVoiceInput(colors)
                      : _buildTextInput(colors),
                ),
              ),
              
              // Send/Stop button
              const SizedBox(width: 8),
              if (widget.isBusy)
                IconButton.filled(
                  icon: const Icon(Icons.stop),
                  onPressed: widget.onStop,
                  tooltip: 'Stop generating',
                )
              else if (_isVoiceMode)
                IconButton.filled(
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  onPressed: _handleVoiceRecord,
                  tooltip: _isRecording ? 'Stop recording' : 'Start recording',
                  style: IconButton.styleFrom(
                    backgroundColor: _isRecording ? colors.error : colors.primary,
                    foregroundColor: _isRecording ? colors.onError : colors.onPrimary,
                  ),
                )
              else
                IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: _isComposing ? _handleSubmit : null,
                  tooltip: 'Send message',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput(ColorScheme colors) {
    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.enter): _handleSubmit,
        const SingleActivator(LogicalKeyboardKey.enter, shift: true): () {
          _controller.text = '${_controller.text}\n';
          _controller.selection = TextSelection.collapsed(
            offset: _controller.text.length,
          );
        },
      },
      child: TextField(
        key: const ValueKey('text-input'),
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: 'Type a message...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colors.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        maxLines: 5,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (text) {
          setState(() {
            _isComposing = text.trim().isNotEmpty;
          });
        },
        enabled: !widget.isBusy,
      ),
    );
  }

  Widget _buildVoiceInput(ColorScheme colors) {
    return Container(
      key: const ValueKey('voice-input'),
      height: 48,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isRecording) ...[
              Icon(Icons.mic, color: colors.error),
              const SizedBox(width: 8),
              Text(
                'Recording...',
                style: TextStyle(color: colors.error),
              ),
            ] else
              const Text('Tap mic to start recording'),
          ],
        ),
      ),
    );
  }
} 