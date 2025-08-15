import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../mcp/models/tool_call_info.dart';

class ToolCallBadge extends StatefulWidget {
  const ToolCallBadge({
    super.key,
    required this.toolCall,
  });

  final ToolCallInfo toolCall;

  @override
  State<ToolCallBadge> createState() => _ToolCallBadgeState();
}

class _ToolCallBadgeState extends State<ToolCallBadge> 
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final badgeColor = widget.toolCall.isError 
        ? colorScheme.errorContainer 
        : colorScheme.primaryContainer;
    final textColor = widget.toolCall.isError
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      child: InkWell(
        onTap: _toggleExpanded,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: badgeColor,
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
                    widget.toolCall.isError 
                        ? Icons.error_outline 
                        : Icons.build_circle,
                    size: 20,
                    color: textColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tool: ${widget.toolCall.toolName}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (widget.toolCall.duration != null)
                    Text(
                      '${widget.toolCall.duration!.inMilliseconds}ms',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      size: 20,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              
              // Expandable content
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tool key
                      _buildInfoRow(
                        'Tool Key:',
                        widget.toolCall.toolKey,
                        textColor,
                      ),
                      const SizedBox(height: 8),
                      
                      // Timestamp
                      _buildInfoRow(
                        'Time:',
                        _formatTimestamp(widget.toolCall.timestamp),
                        textColor,
                      ),
                      
                      // Arguments
                      if (widget.toolCall.arguments != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Arguments:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.3),
                            ),
                          ),
                          child: SelectableText(
                            _formatJson(widget.toolCall.arguments!),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                      
                      // Result or Error
                      if (widget.toolCall.hasResult || widget.toolCall.isError) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.toolCall.isError ? 'Error:' : 'Result:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: SingleChildScrollView(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: widget.toolCall.isError
                                      ? colorScheme.error.withOpacity(0.3)
                                      : colorScheme.outline.withOpacity(0.3),
                                ),
                              ),
                              child: SelectableText(
                                widget.toolCall.error ?? 
                                    widget.toolCall.result ?? 
                                    'No result',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: widget.toolCall.isError
                                      ? colorScheme.error
                                      : textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: textColor.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:'
             '${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatJson(Map<String, dynamic> json) {
    try {
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (e) {
      return json.toString();
    }
  }
} 