import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:kavi/core/chat/chat_message.dart';
import '../../domain/models/chat_message_model.dart' as domain_msg;

class MessageEditing extends StatefulWidget {
  final ChatMessage message;
  final Function(String newContent)? onSave;
  final VoidCallback? onCancel;
  final bool isEditing;

  const MessageEditing({
    super.key,
    required this.message,
    this.onSave,
    this.onCancel,
    this.isEditing = false,
  });

  @override
  State<MessageEditing> createState() => _MessageEditingState();
}

class _MessageEditingState extends State<MessageEditing> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.message.content);
    _focusNode = FocusNode();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasChanges = _controller.text != widget.message.content;
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  void _handleSave() {
    if (_hasChanges && widget.onSave != null) {
      widget.onSave!(_controller.text.trim());
    }
  }

  void _handleCancel() {
    if (_hasChanges) {
      _showDiscardDialog();
    } else {
      widget.onCancel?.call();
    }
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onCancel?.call();
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.edit,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Editing Message',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (_hasChanges)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Modified',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Text field
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            maxLines: null,
            minLines: 3,
            decoration: InputDecoration(
              hintText: 'Edit your message...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _handleCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _hasChanges ? _handleSave : null,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EditableMessage extends StatefulWidget {
  final domain_msg.ChatMessageModel message;
  final Widget Function(domain_msg.ChatMessageModel) messageBuilder;
  final Function(String newContent)? onEdit;
  final VoidCallback? onDelete;
  final bool showEditButton;
  final bool showDeleteButton;

  const EditableMessage({
    super.key,
    required this.message,
    required this.messageBuilder,
    this.onEdit,
    this.onDelete,
    this.showEditButton = true,
    this.showDeleteButton = true,
  });

  @override
  State<EditableMessage> createState() => _EditableMessageState();
}

class _EditableMessageState extends State<EditableMessage> {
  bool _isEditing = false;

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _saveEdit(String newContent) {
    widget.onEdit?.call(newContent);
    setState(() {
      _isEditing = false;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return MessageEditing(
        message: widget.message,
        onSave: _saveEdit,
        onCancel: _cancelEdit,
        isEditing: true,
      );
    }

    return Stack(
      children: [
        widget.messageBuilder(widget.message),
        
        // Edit/Delete buttons (positioned absolutely)
        Positioned(
          top: 4,
          right: 4,
          child: _MessageActionButtons(
            message: widget.message,
            onEdit: _startEditing,
            onDelete: widget.onDelete,
            showEditButton: widget.showEditButton,
            showDeleteButton: widget.showDeleteButton,
          ),
        ),
      ],
    );
  }
}

class _MessageActionButtons extends StatefulWidget {
  final domain_msg.ChatMessageModel message;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showEditButton;
  final bool showDeleteButton;

  const _MessageActionButtons({
    required this.message,
    this.onEdit,
    this.onDelete,
    this.showEditButton = true,
    this.showDeleteButton = true,
  });

  @override
  State<_MessageActionButtons> createState() => _MessageActionButtonsState();
}

class _MessageActionButtonsState extends State<_MessageActionButtons> {
  bool _showButtons = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _showButtons = true),
      onExit: (_) => setState(() => _showButtons = false),
      child: AnimatedOpacity(
        opacity: _showButtons ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showEditButton)
                IconButton(
                  icon: const Icon(Icons.edit, size: 16),
                  onPressed: widget.onEdit,
                  tooltip: 'Edit message',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              if (widget.showDeleteButton)
                IconButton(
                  icon: const Icon(Icons.delete, size: 16),
                  onPressed: () => _showDeleteConfirmation(),
                  tooltip: 'Delete message',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text(
          'Are you sure you want to delete this message? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class MessageEditManager extends ChangeNotifier {
  final Map<String, String> _originalContents = {};
  final Map<String, String> _editedContents = {};

  bool isEditing(String messageId) {
    return _editedContents.containsKey(messageId);
  }

  String? getEditedContent(String messageId) {
    return _editedContents[messageId];
  }

  void startEditing(String messageId, String originalContent) {
    _originalContents[messageId] = originalContent;
    _editedContents[messageId] = originalContent;
    notifyListeners();
  }

  void updateEdit(String messageId, String newContent) {
    _editedContents[messageId] = newContent;
    notifyListeners();
  }

  void saveEdit(String messageId) {
    _originalContents.remove(messageId);
    _editedContents.remove(messageId);
    notifyListeners();
  }

  void cancelEdit(String messageId) {
    _originalContents.remove(messageId);
    _editedContents.remove(messageId);
    notifyListeners();
  }

  bool hasChanges(String messageId) {
    final original = _originalContents[messageId];
    final edited = _editedContents[messageId];
    return original != null && edited != null && original != edited;
  }

  void clearAll() {
    _originalContents.clear();
    _editedContents.clear();
    notifyListeners();
  }
}