import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  final String? label;
  
  const TypingIndicator({super.key, this.label});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Start animations with delays
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: colors.primary,
              child: Text(
                'Z',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colors.onPrimary,
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
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.outlineVariant,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.label != null && widget.label!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            widget.label!,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (index) {
                          return AnimatedBuilder(
                            animation: _animations[index],
                            builder: (context, child) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                child: Transform.translate(
                                  offset: Offset(0, -4 * _animations[index].value),
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: colors.primary.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }),
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
} 