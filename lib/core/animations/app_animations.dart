import 'package:flutter/material.dart';

class AppAnimations {
  // Page transition animations
  static PageRouteBuilder<T> fadeTransition<T>({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  static PageRouteBuilder<T> slideTransition<T>({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    SlideDirection direction = SlideDirection.right,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        Offset begin;
        switch (direction) {
          case SlideDirection.left:
            begin = const Offset(-1.0, 0.0);
            break;
          case SlideDirection.right:
            begin = const Offset(1.0, 0.0);
            break;
          case SlideDirection.up:
            begin = const Offset(0.0, 1.0);
            break;
          case SlideDirection.down:
            begin = const Offset(0.0, -1.0);
            break;
        }

        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
      },
      transitionDuration: duration,
    );
  }

  static PageRouteBuilder<T> scaleTransition<T>({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: duration,
    );
  }

  // Message animations
  static Widget slideInMessage({
    required Widget child,
    required Animation<double> animation,
    SlideDirection direction = SlideDirection.up,
  }) {
    Offset begin;
    switch (direction) {
      case SlideDirection.left:
        begin = const Offset(-0.3, 0.0);
        break;
      case SlideDirection.right:
        begin = const Offset(0.3, 0.0);
        break;
      case SlideDirection.up:
        begin = const Offset(0.0, 0.3);
        break;
      case SlideDirection.down:
        begin = const Offset(0.0, -0.3);
        break;
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  static Widget bounceInMessage({
    required Widget child,
    required Animation<double> animation,
  }) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.3,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.elasticOut,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  // List item animations
  static Widget staggeredListItem({
    required Widget child,
    required int index,
    Duration staggerDuration = const Duration(milliseconds: 100),
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * staggerDuration.inMilliseconds)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // Button animations
  static Widget animatedButton({
    required Widget child,
    required VoidCallback? onPressed,
    Duration duration = const Duration(milliseconds: 150),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: (_) {
          // Scale down effect
        },
        onTapUp: (_) {
          // Scale up effect
        },
        onTapCancel: () {
          // Reset scale
        },
        child: child,
      ),
    );
  }

  // Loading animations
  static Widget pulseAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.8, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  static Widget rotateAnimation({
    required Widget child,
    Duration duration = const Duration(seconds: 2),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 2 * 3.14159,
          child: child,
        );
      },
      child: child,
    );
  }

  // Typing indicator animation
  static Widget typingIndicator({
    required List<Widget> dots,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: dots.asMap().entries.map((entry) {
        final index = entry.key;
        final dot = entry.value;
        
        return TweenAnimationBuilder<double>(
          duration: duration,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            final delay = index * 0.2;
            final animationValue = (value + delay) % 1.0;
            final opacity = (animationValue * 2).clamp(0.0, 1.0);
            
            return Opacity(
              opacity: opacity,
              child: child,
            );
          },
          child: dot,
        );
      }).toList(),
    );
  }

  // Progress animations
  static Widget progressAnimation({
    required double progress,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: progress),
      builder: (context, value, child) {
        return LinearProgressIndicator(
          value: value,
        );
      },
    );
  }

  // Shake animation for errors
  static Widget shakeAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return TweenAnimationBuilder<double>(
      duration: duration,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        final shake = (value * 10).floor() % 2 == 0 ? 1.0 : -1.0;
        final intensity = (1 - value) * 5;
        
        return Transform.translate(
          offset: Offset(shake * intensity, 0),
          child: child,
        );
      },
      child: child,
    );
  }
}

enum SlideDirection {
  left,
  right,
  up,
  down,
}

// Custom page transitions
class CustomPageTransitions {
  static Route<T> fadeThrough<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route<T> slideFromRight<T>(Widget page) {
    return AppAnimations.slideTransition<T>(
      child: page,
      direction: SlideDirection.right,
    );
  }

  static Route<T> slideFromLeft<T>(Widget page) {
    return AppAnimations.slideTransition<T>(
      child: page,
      direction: SlideDirection.left,
    );
  }

  static Route<T> slideFromBottom<T>(Widget page) {
    return AppAnimations.slideTransition<T>(
      child: page,
      direction: SlideDirection.up,
    );
  }

  static Route<T> slideFromTop<T>(Widget page) {
    return AppAnimations.slideTransition<T>(
      child: page,
      direction: SlideDirection.down,
    );
  }

  static Route<T> scaleIn<T>(Widget page) {
    return AppAnimations.scaleTransition<T>(child: page);
  }
}