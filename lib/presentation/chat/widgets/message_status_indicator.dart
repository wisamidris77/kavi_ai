import 'package:flutter/material.dart';

enum MessageStatus {
  sending,
  sent,
  error,
  delivered,
  read,
}

class MessageStatusIndicator extends StatelessWidget {
  final MessageStatus status;
  final DateTime? timestamp;
  
  const MessageStatusIndicator({
    super.key,
    required this.status,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    
    IconData icon;
    Color color;
    String tooltip;
    
    switch (status) {
      case MessageStatus.sending:
        icon = Icons.schedule;
        color = colors.outline;
        tooltip = 'Sending...';
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = colors.outline;
        tooltip = 'Sent';
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = colors.outline;
        tooltip = 'Delivered';
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = colors.primary;
        tooltip = 'Read';
        break;
      case MessageStatus.error:
        icon = Icons.error_outline;
        color = colors.error;
        tooltip = 'Failed to send';
        break;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (timestamp != null)
          Text(
            _formatTime(timestamp!),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.outline,
            ),
          ),
        const SizedBox(width: 4),
        Tooltip(
          message: tooltip,
          child: Icon(
            icon,
            size: 14,
            color: color,
          ),
        ),
      ],
    );
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inSeconds < 60) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
} 