import 'package:flutter/material.dart';
import '../../../core/chat/chat_message.dart';
import 'chat_message_bubble.dart';

class ChatMessagesList extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController? controller;
  final String? assistantLabel;
  final VoidCallback? onRegenerateLast;
  final void Function(ChatMessage message)? onCopyMessage;
  final bool isBusy;
  final bool showTypingIndicator;

  const ChatMessagesList({
    super.key, 
    required this.messages, 
    this.controller, 
    this.assistantLabel, 
    this.onRegenerateLast, 
    this.onCopyMessage,
    this.isBusy = false,
    this.showTypingIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    final allItems = <Widget>[];
    
    // Add all messages
    for (int i = 0; i < messages.length; i++) {
      final ChatMessage message = messages[i];
      final bool isLastAssistant = message.role == ChatRole.assistant && i == messages.length - 1;
      
      allItems.add(ChatMessageBubble(
        message: message,
        assistantLabel: assistantLabel,
        showRegenerate: isLastAssistant && !isBusy,
        onRegenerate: isLastAssistant && !isBusy ? onRegenerateLast : null,
        onCopy: onCopyMessage,
      ));
      
      if (i < messages.length - 1) {
        allItems.add(const SizedBox(height: 4));
      }
    }
    
    // Add typing indicator if needed
    if (showTypingIndicator && isBusy) {
      if (allItems.isNotEmpty) {
        allItems.add(const SizedBox(height: 4));
      }
      allItems.add(const _TypingIndicator());
    }
    
    return ListView(
      controller: controller,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      children: allItems,
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primary,
              child: Text(
                'K',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Row(
                            children: [
                              _buildDot(0),
                              const SizedBox(width: 4),
                              _buildDot(1),
                              const SizedBox(width: 4),
                              _buildDot(2),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final delay = index * 0.2;
        final animationValue = (_animation.value + delay) % 1.0;
        final opacity = (animationValue * 2).clamp(0.0, 1.0);
        
        return Opacity(
          opacity: opacity,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
} 