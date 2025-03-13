import 'package:flutter/material.dart';
import 'dart:ui';

class SplashScreen extends StatefulWidget {
  final VoidCallback onAnimationComplete;
  SplashScreen({required this.onAnimationComplete});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _gradientPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _gradientPosition = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
    Future.delayed(const Duration(seconds: 4), () {
      widget.onAnimationComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated gradient layers
          AnimatedBuilder(
            animation: _gradientPosition,
            builder: (context, child) {
              return Stack(
                children: [
                  // Top gradient
                  Positioned(
                    top: -100,
                    left: 0,
                    right: 0,
                    height: 300,
                    child: Transform.translate(
                      offset: Offset(0, _gradientPosition.value * 30),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.topCenter,
                            radius: 1.5,
                            colors: [
                              const Color(0xFF4361EE).withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bottom gradient
                  Positioned(
                    bottom: -100,
                    left: 0,
                    right: 0,
                    height: 300,
                    child: Transform.translate(
                      offset: Offset(0, -_gradientPosition.value * 30),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.bottomCenter,
                            radius: 1.5,
                            colors: [
                              const Color(0xFFB8C6FF).withOpacity(0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Glow effects layer
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  const Color(0xFF4361EE).withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow effect
                    Transform.scale(
                      scale: 1.0 + (_glowAnimation.value * 0.1),
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4361EE).withOpacity(_glowAnimation.value * 0.4),
                              blurRadius: 30,
                              spreadRadius: 15,
                            ),
                            BoxShadow(
                              color: const Color(0xFFB8C6FF).withOpacity(_glowAnimation.value * 0.2),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Logo
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/icons/logo2.png',
                              width: 180,
                              height: 180,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'PocketLLM',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFF4361EE).withOpacity(0.6),
                                    blurRadius: 12,
                                    offset: const Offset(0, 0),
                                  ),
                                  Shadow(
                                    color: const Color(0xFF7209B7).withOpacity(0.3),
                                    blurRadius: 18,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'AI in your pocket',
                              style: TextStyle(
                                fontSize: 16,
                                color: const Color(0xFFB8C6FF),
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w300,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFF4361EE).withOpacity(0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
