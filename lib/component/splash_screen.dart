/// File Overview:
/// - Purpose: Animated splash experience shown during initial service
///   initialization.
/// - Backend Migration: Keep for UX polish; ensure animation duration matches
///   backend initialization once remote boot becomes faster.
import 'package:flutter/material.dart';
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  final VoidCallback onAnimationComplete;
  const SplashScreen({Key? key, required this.onAnimationComplete}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _logoRotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );
    
    _logoRotation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();
    Future.delayed(const Duration(milliseconds: 3800), () {
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
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Background particles
          AnimatedBuilder(
            animation: _particleAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlesPainter(
                  progress: _particleAnimation.value,
                  primaryColor: const Color(0xFF8B5CF6),
                  secondaryColor: const Color(0xFF4F46E5),
                ),
                size: MediaQuery.of(context).size,
              );
            },
          ),
          
          // Radial gradient background with smoother animation
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      const Color(0xFF8B5CF6).withOpacity(0.2 * _glowAnimation.value),
                      const Color(0xFF4F46E5).withOpacity(0.1 * _glowAnimation.value),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              );
            },
          ),
          
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow
                    Transform.scale(
                      scale: 1.0 + (_glowAnimation.value * 0.15),
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withOpacity(_glowAnimation.value * 0.4),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withOpacity(_glowAnimation.value * 0.3),
                              blurRadius: 60,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Logo with minimal animation (no rotation)
                    Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Modern gradient logo container
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF9F7AEA),
                                    Color(0xFF7C3AED),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C3AED).withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Animated inner circles with smoother, more minimal animation
                                    AnimatedBuilder(
                                      animation: _controller,
                                      builder: (context, child) {
                                        return Positioned.fill(
                                          child: CustomPaint(
                                            painter: MinimalCirclesPainter(
                                              progress: _controller.value,
                                              color: Colors.white.withOpacity(0.2),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    // Modern logo letter with cleaner styling
                                    Text(
                                      "P",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 80,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins',
                                        letterSpacing: -1,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // App name with modern typography
                              Text(
                                'PocketLLM',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                  shadows: [
                                    Shadow(
                                      color: const Color(0xFF8B5CF6).withOpacity(0.8),
                                      blurRadius: 12,
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Tagline with elegant styling
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'AI in your pocket',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w300,
                                    fontFamily: 'Poppins',
                                  ),
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
          
          // Professional loading indicator
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      // Modern linear progress indicator
                      Container(
                        width: 120,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: LinearProgressIndicator(
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF8B5CF6),
                          ),
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Initializing...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for particle effect
class ParticlesPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final List<Particle> particles = [];
  
  ParticlesPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  }) {
    if (particles.isEmpty) {
      // Initialize particles with more controlled randomness
      for (int i = 0; i < 80; i++) {
        particles.add(Particle(
          x: math.Random().nextDouble(),
          y: math.Random().nextDouble() * 0.8, // Keep particles more centered
          size: math.Random().nextDouble() * 2 + 1,
          speed: math.Random().nextDouble() * 0.01 + 0.005,
          color: Color.lerp(primaryColor, secondaryColor, math.Random().nextDouble())!,
          opacity: math.Random().nextDouble() * 0.4 + 0.2,
        ));
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Clear background with slight transparency for trailing effect
    canvas.drawColor(Colors.transparent, BlendMode.clear);
    
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity * progress.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      
      // Smoother movement with easing
      final easedProgress = Curves.easeInOut.transform(progress);
      final x = (particle.x + particle.speed * easedProgress * 3) % 1.0;
      final y = (particle.y + particle.speed * easedProgress * 2) % 1.0;
      
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        particle.size * easedProgress,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) => true;
}

class Particle {
  double x;
  double y;
  double size;
  double speed;
  Color color;
  double opacity;
  
  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
    required this.opacity,
  });
}

// Custom painter for minimal animated circles in the logo
class MinimalCirclesPainter extends CustomPainter {
  final double progress;
  final Color color;
  
  MinimalCirclesPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw two circles with subtle pulsing
    for (int i = 1; i <= 2; i++) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      // Calculate radius with very subtle pulse
      final pulseOffset = math.sin(progress * math.pi) * 2;
      final circleRadius = (radius * 0.6 * i / 2) + (i == 2 ? pulseOffset : 0);
      
      canvas.drawCircle(center, circleRadius, paint);
    }
  }

  @override
  bool shouldRepaint(MinimalCirclesPainter oldDelegate) => 
      progress != oldDelegate.progress;
}

class CirclesPainter extends CustomPainter {
  final double progress;
  final Color color;
  
  CirclesPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw multiple circles with varying sizes based on animation progress
    for (int i = 1; i <= 3; i++) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      // Calculate dynamic radius with wave effect
      final waveOffset = math.sin((progress * 2 * math.pi) + (i * math.pi / 3)) * 5;
      final circleRadius = (radius * 0.5 * i / 3) + waveOffset;
      
      canvas.drawCircle(center, circleRadius, paint);
    }
  }

  @override
  bool shouldRepaint(CirclesPainter oldDelegate) => true;
}