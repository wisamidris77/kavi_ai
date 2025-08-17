import 'package:flutter/material.dart';
import '../../domain/models/chat_message_model.dart' as domain_msg;
import '../../domain/models/chat_role.dart' as domain_role;

class MessageGroup extends StatelessWidget {
  final List<domain_msg.ChatMessageModel> messages;
  final Widget Function(domain_msg.ChatMessageModel) messageBuilder;
  final bool showSenderInfo;
  final bool showTimestamps;
  final Duration groupingThreshold;

  const MessageGroup({
    super.key,
    required this.messages,
    required this.messageBuilder,
    this.showSenderInfo = true,
    this.showTimestamps = true,
    this.groupingThreshold = const Duration(minutes: 5),
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final firstMessage = messages.first;
    final isUser = firstMessage.role == domain_role.ChatRole.user;

    return Container(
      margin: EdgeInsets.only(
        left: isUser ? 64 : 8,
        right: isUser ? 8 : 64,
        top: 8,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: isUser 
            ? CrossAxisAlignment.end 
            : CrossAxisAlignment.start,
        children: [
          // Sender info (only for first message in group)
          if (showSenderInfo && messages.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                _getSenderName(firstMessage),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Messages
          ...messages.asMap().entries.map((entry) {
            final index = entry.key;
            final message = entry.value;
            final isFirst = index == 0;
            final isLast = index == messages.length - 1;

            return Container(
              margin: EdgeInsets.only(
                bottom: isLast ? 0 : 4,
              ),
              child: _MessageBubble(
                message: message,
                isFirst: isFirst,
                isLast: isLast,
                isUser: isUser,
                child: messageBuilder(message),
              ),
            );
          }),

          // Group timestamp
          if (showTimestamps && messages.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _GroupTimestamp(
                messages: messages,
                groupingThreshold: groupingThreshold,
              ),
            ),
        ],
      ),
    );
  }

  String _getSenderName(domain_msg.ChatMessageModel message) {
    switch (message.role) {
      case domain_role.ChatRole.user:
        return 'You';
      case domain_role.ChatRole.assistant:
        return 'Assistant';
      case domain_role.ChatRole.system:
        return 'System';
      default:
        return 'Unknown';
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final domain_msg.ChatMessageModel message;
  final bool isFirst;
  final bool isLast;
  final bool isUser;
  final Widget child;

  const _MessageBubble({
    required this.message,
    required this.isFirst,
    required this.isLast,
    required this.isUser,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate border radius based on position in group
    BorderRadius borderRadius;
    if (isFirst && isLast) {
      // Single message
      borderRadius = BorderRadius.circular(16);
    } else if (isFirst) {
      // First message in group
      borderRadius = isUser
          ? const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            )
          : const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(16),
            );
    } else if (isLast) {
      // Last message in group
      borderRadius = isUser
          ? const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            )
          : const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            );
    } else {
      // Middle message in group
      borderRadius = isUser
          ? const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            )
          : const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(16),
            );
    }

    return Container(
      decoration: BoxDecoration(
        color: isUser 
            ? colorScheme.primaryContainer 
            : colorScheme.surfaceVariant,
        borderRadius: borderRadius,
        border: Border.all(
          color: isUser 
              ? colorScheme.primary.withOpacity(0.2)
              : colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class _GroupTimestamp extends StatelessWidget {
  final List<domain_msg.ChatMessageModel> messages;
  final Duration groupingThreshold;

  const _GroupTimestamp({
    required this.messages,
    required this.groupingThreshold,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final firstMessage = messages.first;
    final lastMessage = messages.last;
    
    final timeRange = _getTimeRange(firstMessage.createdAt!, lastMessage.createdAt!);

    return Text(
      timeRange,
      style: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontSize: 11,
      ),
    );
  }

  String _getTimeRange(DateTime start, DateTime end) {
    final difference = end.difference(start);
    
    if (difference.inMinutes < 1) {
      return _formatTime(start);
    } else if (difference.inMinutes < 60) {
      return '${_formatTime(start)} - ${_formatTime(end)}';
    } else {
      return '${_formatDate(start)} ${_formatTime(start)} - ${_formatTime(end)}';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}

class MessageGroupingHelper {
  static List<List<domain_msg.ChatMessageModel>> groupMessages(
    List<domain_msg.ChatMessageModel> messages, {
    Duration threshold = const Duration(minutes: 5),
  }) {
    if (messages.isEmpty) return [];

    final groups = <List<domain_msg.ChatMessageModel>>[];
    List<domain_msg.ChatMessageModel> currentGroup = [messages.first];

    for (int i = 1; i < messages.length; i++) {
      final currentMessage = messages[i];
      final previousMessage = messages[i - 1];

      final shouldGroup = _shouldGroupMessages(
        previousMessage,
        currentMessage,
        threshold,
      );

      if (shouldGroup) {
        currentGroup.add(currentMessage);
      } else {
        groups.add(List.from(currentGroup));
        currentGroup = [currentMessage];
      }
    }

    // Add the last group
    groups.add(currentGroup);

    return groups;
  }

  static bool _shouldGroupMessages(
    domain_msg.ChatMessageModel message1,
    domain_msg.ChatMessageModel message2,
    Duration threshold,
  ) {
    // Same sender
    if (message1.role != message2.role) return false;

    // Within time threshold
    final timeDifference = message2.createdAt!.difference(message1.createdAt!);
    if (timeDifference > threshold) return false;

    // Not system messages (they should be separate)
    if (message1.role == domain_role.ChatRole.system) return false;

    return true;
  }

  static List<domain_msg.ChatMessageModel> flattenGroups(
    List<List<domain_msg.ChatMessageModel>> groups,
  ) {
    return groups.expand((group) => group).toList();
  }

  static int getGroupIndex(
    List<List<domain_msg.ChatMessageModel>> groups,
    int messageIndex,
  ) {
    int currentIndex = 0;
    
    for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      final group = groups[groupIndex];
      if (currentIndex <= messageIndex && 
          messageIndex < currentIndex + group.length) {
        return groupIndex;
      }
      currentIndex += group.length;
    }
    
    return -1;
  }

  static int getMessageIndexInGroup(
    List<List<domain_msg.ChatMessageModel>> groups,
    int messageIndex,
  ) {
    int currentIndex = 0;
    
    for (final group in groups) {
      if (currentIndex <= messageIndex && 
          messageIndex < currentIndex + group.length) {
        return messageIndex - currentIndex;
      }
      currentIndex += group.length;
    }
    
    return -1;
  }
}