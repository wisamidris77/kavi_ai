import 'package:flutter/material.dart';
import 'dart:async'; // Added for Timer

class MessageTimestamp extends StatefulWidget {
  final DateTime timestamp;
  final bool showRelative;
  final bool showAbsolute;
  final TextStyle? style;
  final VoidCallback? onTap;

  const MessageTimestamp({
    super.key,
    required this.timestamp,
    this.showRelative = true,
    this.showAbsolute = false,
    this.style,
    this.onTap,
  });

  @override
  State<MessageTimestamp> createState() => _MessageTimestampState();
}

class _MessageTimestampState extends State<MessageTimestamp> {
  Timer? _timer;
  String _relativeTime = '';
  bool _showAbsolute = false;

  @override
  void initState() {
    super.initState();
    _updateRelativeTime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _updateRelativeTime();
        });
      }
    });
  }

  void _updateRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(widget.timestamp);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        _relativeTime = 'Yesterday';
      } else if (difference.inDays < 7) {
        _relativeTime = '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        _relativeTime = weeks == 1 ? '1 week ago' : '$weeks weeks ago';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        _relativeTime = months == 1 ? '1 month ago' : '$months months ago';
      } else {
        final years = (difference.inDays / 365).floor();
        _relativeTime = years == 1 ? '1 year ago' : '$years years ago';
      }
    } else if (difference.inHours > 0) {
      _relativeTime = difference.inHours == 1 
          ? '1 hour ago' 
          : '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      _relativeTime = difference.inMinutes == 1 
          ? '1 minute ago' 
          : '${difference.inMinutes} minutes ago';
    } else {
      _relativeTime = 'Just now';
    }
  }

  String _getAbsoluteTime() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      widget.timestamp.year, 
      widget.timestamp.month, 
      widget.timestamp.day,
    );

    if (messageDate == today) {
      // Today - show time only
      return _formatTime(widget.timestamp);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday - show "Yesterday" and time
      return 'Yesterday at ${_formatTime(widget.timestamp)}';
    } else if (now.difference(widget.timestamp).inDays < 7) {
      // This week - show day and time
      return '${_formatDay(widget.timestamp)} at ${_formatTime(widget.timestamp)}';
    } else {
      // Older - show full date and time
      return '${_formatDate(widget.timestamp)} at ${_formatTime(widget.timestamp)}';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDay(DateTime time) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[time.weekday - 1];
  }

  String _formatDate(DateTime time) {
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final year = time.year.toString();
    return '$month/$day/$year';
  }

  void _toggleTimeDisplay() {
    setState(() {
      _showAbsolute = !_showAbsolute;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final displayText = _showAbsolute ? _getAbsoluteTime() : _relativeTime;
    final textStyle = widget.style ?? theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    Widget timestampWidget = Text(
      displayText,
      style: textStyle,
    );

    if (widget.onTap != null || (widget.showRelative && widget.showAbsolute)) {
      timestampWidget = GestureDetector(
        onTap: widget.onTap ?? _toggleTimeDisplay,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: timestampWidget,
        ),
      );
    }

    return timestampWidget;
  }
}

class MessageTimestampWithTooltip extends StatelessWidget {
  final DateTime timestamp;
  final bool showRelative;
  final bool showAbsolute;
  final TextStyle? style;
  final VoidCallback? onTap;

  const MessageTimestampWithTooltip({
    super.key,
    required this.timestamp,
    this.showRelative = true,
    this.showAbsolute = false,
    this.style,
    this.onTap,
  });

  String _getFullTimestamp() {
    final date = timestamp.toLocal();
    final dateStr = '${date.day}/${date.month}/${date.year}';
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '$dateStr at $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _getFullTimestamp(),
      child: MessageTimestamp(
        timestamp: timestamp,
        showRelative: showRelative,
        showAbsolute: showAbsolute,
        style: style,
        onTap: onTap,
      ),
    );
  }
}

class MessageTimestampGroup extends StatelessWidget {
  final List<DateTime> timestamps;
  final bool showRelative;
  final bool showAbsolute;
  final TextStyle? style;
  final VoidCallback? onTap;

  const MessageTimestampGroup({
    super.key,
    required this.timestamps,
    this.showRelative = true,
    this.showAbsolute = false,
    this.style,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (timestamps.isEmpty) return const SizedBox.shrink();
    
    final sortedTimestamps = List<DateTime>.from(timestamps)..sort();
    final firstTimestamp = sortedTimestamps.first;
    final lastTimestamp = sortedTimestamps.last;
    
    // If all timestamps are within 5 minutes, show a single timestamp
    if (lastTimestamp.difference(firstTimestamp).inMinutes <= 5) {
      return MessageTimestampWithTooltip(
        timestamp: firstTimestamp,
        showRelative: showRelative,
        showAbsolute: showAbsolute,
        style: style,
        onTap: onTap,
      );
    }
    
    // Otherwise show a range
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MessageTimestampWithTooltip(
          timestamp: firstTimestamp,
          showRelative: showRelative,
          showAbsolute: showAbsolute,
          style: style,
          onTap: onTap,
        ),
        const Text(' - '),
        MessageTimestampWithTooltip(
          timestamp: lastTimestamp,
          showRelative: showRelative,
          showAbsolute: showAbsolute,
          style: style,
          onTap: onTap,
        ),
      ],
    );
  }
}