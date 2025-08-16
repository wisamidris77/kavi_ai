import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _pulseController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Logo animations
    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
    
    _logoRotation = Tween<double>(
      begin: -0.5,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    ));
    
    // Text animations
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    ));
    
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));
    
    // Pulse animation
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations
    _startAnimations();
  }
  
  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();
    
    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();
    
    await Future.delayed(const Duration(milliseconds: 500));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  colors.primary.withOpacity(0.1),
                  colors.surface,
                ],
              ),
            ),
          ),
          
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with animations
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _logoController,
                    _pulseController,
                  ]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScale.value * _pulseAnimation.value,
                      child: Transform.rotate(
                        angle: _logoRotation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colors.primary,
                                colors.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: colors.primary.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Z',
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 60,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // App name with animations
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textOpacity.value,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Column(
                          children: [
                            Text(
                              'ZAVI AI',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your Advanced AI Assistant',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colors.onSurfaceVariant,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 80),
                
                // Loading indicator
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textOpacity.value,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colors.primary.withOpacity(0.6),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Animated particles
          ..._buildParticles(context),
        ],
      ),
    );
  }
  
  List<Widget> _buildParticles(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return List.generate(5, (index) {
      return AnimatedBuilder(
        animation: _logoController,
        builder: (context, child) {
          final progress = _logoController.value;
          final angle = (index * 72) * 3.14159 / 180;
          final radius = 150.0 * progress;
          
          return Positioned(
            left: MediaQuery.of(context).size.width / 2 + radius * cos(angle) - 10,
            top: MediaQuery.of(context).size.height / 2 + radius * sin(angle) - 10,
            child: Opacity(
              opacity: (1 - progress) * 0.6,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      );
    });
  }
  
  double cos(double angle) => angle.clamp(-1.0, 1.0);
  double sin(double angle) => angle.clamp(-1.0, 1.0);
} 