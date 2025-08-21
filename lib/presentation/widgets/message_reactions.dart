import 'package:flutter/material.dart';

class MessageReactions extends StatefulWidget {
  final List<MessageReaction> reactions;
  final Function(String emoji)? onReactionAdded;
  final Function(MessageReaction reaction)? onReactionRemoved;
  final bool showAddButton;
  final List<String> availableEmojis;

  const MessageReactions({
    super.key,
    required this.reactions,
    this.onReactionAdded,
    this.onReactionRemoved,
    this.showAddButton = true,
    this.availableEmojis = const ['👍', '❤️', '😂', '😮', '😢', '😡', '👏', '🙏'],
  });

  @override
  State<MessageReactions> createState() => _MessageReactionsState();
}

class _MessageReactionsState extends State<MessageReactions> {
  bool _showEmojiPicker = false;

  @override
  Widget build(BuildContext context) {
    if (widget.reactions.isEmpty && !widget.showAddButton) {
      return const SizedBox.shrink();
    }

    return Row(
      spacing: 5,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.reactions.isNotEmpty)
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: widget.reactions.map((reaction) {
              return _ReactionChip(
                reaction: reaction,
                onTap: () => _handleReactionTap(reaction.emoji),
                onLongPress: () => _showReactionDetails(reaction),
              );
            }).toList(),
          ),
        if (widget.showAddButton)
          _AddReactionButton(
            onTap: _showEmojiPickerDialog,
            availableEmojis: widget.availableEmojis,
            onEmojiSelected: _handleEmojiSelected,
          ),
      ],
    );
  }

  void _handleReactionTap(String emoji) {
    final existingReaction = widget.reactions.firstWhere(
      (r) => r.emoji == emoji,
      orElse: () => MessageReaction(emoji: emoji, count: 0, users: []),
    );

    if (existingReaction.users.contains('current_user')) {
      // Remove reaction
      widget.onReactionRemoved?.call(existingReaction);
    } else {
      // Add reaction
      widget.onReactionAdded?.call(emoji);
    }
  }

  void _handleEmojiSelected(String emoji) {
    widget.onReactionAdded?.call(emoji);
    setState(() {
      _showEmojiPicker = false;
    });
  }

  void _showEmojiPickerDialog() {
    showDialog(
      context: context,
      builder: (context) => _EmojiPickerDialog(
        availableEmojis: widget.availableEmojis,
        onEmojiSelected: _handleEmojiSelected,
      ),
    );
  }

  void _showReactionDetails(MessageReaction reaction) {
    showDialog(
      context: context,
      builder: (context) => _ReactionDetailsDialog(reaction: reaction),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final MessageReaction reaction;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ReactionChip({
    required this.reaction,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasUserReacted = reaction.users.contains('current_user');

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: hasUserReacted 
              ? colorScheme.primaryContainer 
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasUserReacted 
                ? colorScheme.primary 
                : colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              reaction.emoji,
              style: const TextStyle(fontSize: 14),
            ),
            if (reaction.count > 1) ...[
              const SizedBox(width: 4),
              Text(
                reaction.count.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: hasUserReacted 
                      ? colorScheme.onPrimaryContainer 
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddReactionButton extends StatelessWidget {
  final VoidCallback onTap;
  final List<String> availableEmojis;
  final Function(String) onEmojiSelected;

  const _AddReactionButton({
    required this.onTap,
    required this.availableEmojis,
    required this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Icon(
          Icons.add_reaction,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _EmojiPickerDialog extends StatelessWidget {
  final List<String> availableEmojis;
  final Function(String) onEmojiSelected;

  const _EmojiPickerDialog({
    required this.availableEmojis,
    required this.onEmojiSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Reaction',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableEmojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    onEmojiSelected(emoji);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionDetailsDialog extends StatelessWidget {
  final MessageReaction reaction;

  const _ReactionDetailsDialog({required this.reaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  reaction.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  '${reaction.count} reaction${reaction.count == 1 ? '' : 's'}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (reaction.users.isNotEmpty) ...[
              Text(
                'Reacted by:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ...reaction.users.map((user) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        user[0].toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(user),
                  ],
                ),
              )),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageReaction {
  final String emoji;
  final int count;
  final List<String> users;

  const MessageReaction({
    required this.emoji,
    required this.count,
    required this.users,
  });

  MessageReaction copyWith({
    String? emoji,
    int? count,
    List<String>? users,
  }) {
    return MessageReaction(
      emoji: emoji ?? this.emoji,
      count: count ?? this.count,
      users: users ?? this.users,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emoji': emoji,
      'count': count,
      'users': users,
    };
  }

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      emoji: json['emoji'] as String,
      count: json['count'] as int,
      users: List<String>.from(json['users'] as List),
    );
  }
}