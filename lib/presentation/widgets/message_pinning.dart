import 'package:flutter/material.dart';
import 'dart:async';
import '../../domain/models/chat_message_model.dart' as domain_msg;
import '../../core/pinning/pinning_storage_service.dart';

class MessagePinning extends StatefulWidget {
  final List<domain_msg.ChatMessage> pinnedMessages;
  final Function(domain_msg.ChatMessage)? onMessageSelected;
  final Function(domain_msg.ChatMessage)? onUnpinMessage;
  final bool showUnpinButton;

  const MessagePinning({
    super.key,
    required this.pinnedMessages,
    this.onMessageSelected,
    this.onUnpinMessage,
    this.showUnpinButton = true,
  });

  @override
  State<MessagePinning> createState() => _MessagePinningState();
}

class _MessagePinningState extends State<MessagePinning> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.pinnedMessages.isEmpty) {
      return const SizedBox.shrink();
    }

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
                Icons.push_pin,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Pinned Messages',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${widget.pinnedMessages.length}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.showUnpinButton)
                TextButton(
                  onPressed: _showUnpinAllDialog,
                  child: const Text('Unpin All'),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Pinned messages
          ...widget.pinnedMessages.asMap().entries.map((entry) {
            final index = entry.key;
            final message = entry.value;
            final isLast = index == widget.pinnedMessages.length - 1;

            return _PinnedMessageTile(
              message: message,
              onTap: () => widget.onMessageSelected?.call(message),
              onUnpin: () => widget.onUnpinMessage?.call(message),
              showUnpinButton: widget.showUnpinButton,
              showDivider: !isLast,
            );
          }),
        ],
      ),
    );
  }

  void _showUnpinAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpin All Messages'),
        content: const Text(
          'Are you sure you want to unpin all messages? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              for (final message in widget.pinnedMessages) {
                widget.onUnpinMessage?.call(message);
              }
            },
            child: const Text('Unpin All'),
          ),
        ],
      ),
    );
  }
}

class _PinnedMessageTile extends StatelessWidget {
  final domain_msg.ChatMessage message;
  final VoidCallback? onTap;
  final VoidCallback? onUnpin;
  final bool showUnpinButton;
  final bool showDivider;

  const _PinnedMessageTile({
    required this.message,
    this.onTap,
    this.onUnpin,
    this.showUnpinButton = true,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pin icon
                Icon(
                  Icons.push_pin,
                  size: 14,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),

                // Message content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _truncateText(message.content, 100),
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(message.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Unpin button
                if (showUnpinButton)
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: onUnpin,
                    tooltip: 'Unpin message',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Divider
        if (showDivider)
          Divider(
            height: 1,
            color: colorScheme.outlineVariant,
          ),
      ],
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class PinnedMessageManager extends ChangeNotifier {
  final List<domain_msg.ChatMessage> _pinnedMessages = [];
  final Set<String> _pinnedMessageIds = {};
  final PinningStorageService _storage = PinningStorageService();

  List<domain_msg.ChatMessage> get pinnedMessages => List.unmodifiable(_pinnedMessages);

  bool isPinned(domain_msg.ChatMessage message) {
    return _pinnedMessageIds.contains(message.id);
  }

  void pinMessage(domain_msg.ChatMessage message) {
    if (!isPinned(message)) {
      _pinnedMessages.add(message);
      _pinnedMessageIds.add(message.id);
      notifyListeners();
      _savePinnedMessages();
    }
  }

  void unpinMessage(domain_msg.ChatMessage message) {
    if (isPinned(message)) {
      _pinnedMessages.removeWhere((m) => m.id == message.id);
      _pinnedMessageIds.remove(message.id);
      notifyListeners();
      _savePinnedMessages();
    }
  }

  void unpinAllMessages() {
    _pinnedMessages.clear();
    _pinnedMessageIds.clear();
    notifyListeners();
    _savePinnedMessages();
  }

  Future<void> _savePinnedMessages() async {
    try {
      final pinnedMessages = _pinnedMessages.map((message) {
        return PinnedMessageRecord(
          messageId: message.id,
          chatId: message.chatId ?? '',
          content: message.content,
          role: message.role.name,
          timestamp: message.createdAt,
        );
      }).toList();
      
      await _storage.savePinnedMessages(pinnedMessages);
    } catch (e) {
      // Silently handle storage errors
    }
  }

  Future<void> loadPinnedMessages() async {
    try {
      final records = await _storage.loadPinnedMessages();
      
      _pinnedMessages.clear();
      _pinnedMessageIds.clear();
      
      for (final record in records) {
        final message = domain_msg.ChatMessageModel(
          id: record.messageId,
          role: _parseRole(record.role),
          content: record.content,
          createdAt: record.timestamp,
          chatId: record.chatId,
        );
        
        _pinnedMessages.add(message);
        _pinnedMessageIds.add(message.id);
      }
      
      notifyListeners();
    } catch (e) {
      // Silently handle storage errors
    }
  }

  domain_msg.ChatRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'user':
        return domain_msg.ChatRole.user;
      case 'assistant':
        return domain_msg.ChatRole.assistant;
      case 'system':
        return domain_msg.ChatRole.system;
      default:
        return domain_msg.ChatRole.user;
    }
  }
}

class PinMessageButton extends StatelessWidget {
  final domain_msg.ChatMessage message;
  final bool isPinned;
  final VoidCallback? onPin;
  final VoidCallback? onUnpin;

  const PinMessageButton({
    super.key,
    required this.message,
    required this.isPinned,
    this.onPin,
    this.onUnpin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IconButton(
      icon: Icon(
        isPinned ? Icons.push_pin : Icons.push_pin_outlined,
        color: isPinned ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      onPressed: isPinned ? onUnpin : onPin,
      tooltip: isPinned ? 'Unpin message' : 'Pin message',
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(
        minWidth: 24,
        minHeight: 24,
      ),
    );
  }
}

class PinnedMessageIndicator extends StatelessWidget {
  final int pinnedCount;
  final VoidCallback? onTap;

  const PinnedMessageIndicator({
    super.key,
    required this.pinnedCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (pinnedCount == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.push_pin,
              size: 14,
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              '$pinnedCount pinned',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}