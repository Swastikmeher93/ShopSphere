import 'dart:math' as math;

import 'package:ecommerce_app/constants/app_colors.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _floatController;
  late final AnimationController _pulseController;
  late final Animation<double> _markScale;
  late final Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _markScale = CurvedAnimation(
      parent: _introController,
      curve: Curves.elasticOut,
    );
    _contentFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.24, 1, curve: Curves.easeOut),
    );
    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.coral,
                  AppColors.warmOrange,
                  AppColors.apricot,
                ],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.12),
                radius: 0.82,
                colors: [AppColors.softWhiteGlow, AppColors.transparentWhite],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxHeight < 650 || constraints.maxWidth < 360;
                return Stack(
                  children: [
                    if (!compact)
                      Positioned(
                        top: 92,
                        right: 30,
                        child: _FloatingTag(
                          controller: _floatController,
                          delay: 0,
                          rotation: 0.12,
                          label: 'GOOD\nFINDS',
                        ),
                      ),
                    if (!compact)
                      Positioned(
                        top: 205,
                        left: 26,
                        child: _FloatingTag(
                          controller: _floatController,
                          delay: 0.5,
                          rotation: -0.16,
                          label: 'JUST\nFOR YOU',
                          compact: true,
                        ),
                      ),
                    if (!compact)
                      Positioned(
                        top: 305,
                        right: 45,
                        child: AnimatedBuilder(
                          animation: _floatController,
                          builder: (context, child) => Transform.translate(
                            offset: Offset(0, 6 * (_floatController.value - 0.5)),
                            child: child,
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            size: 22,
                            color: AppColors.brightWhiteGlow,
                          ),
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 100,
                      child: AnimatedBuilder(
                        animation: _floatController,
                        builder: (context, child) => CustomPaint(
                          painter: _BottomWavePainter(_floatController.value),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        const Spacer(flex: 2),
                        Center(
                          child: ScaleTransition(
                            scale: _markScale,
                            child: _BrandMark(size: compact ? 136 : 166),
                          ),
                        ),
                        SizedBox(height: compact ? 16 : 26),
                        FadeTransition(
                          opacity: _contentFade,
                          child: Column(
                            children: [
                              Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: compact ? 28 : 31,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.1,
                                    shadows: [
                                      Shadow(
                                        color: AppColors.cardShadow,
                                        blurRadius: 14,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  children: const [
                                    TextSpan(text: 'shop'),
                                    TextSpan(
                                      text: 'esphere',
                                      style: TextStyle(fontWeight: FontWeight.w400),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Your friendly marketplace',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 15,
                                  letterSpacing: 0.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(flex: 2),
                        FadeTransition(
                          opacity: _contentFade,
                          child: Column(
                            children: [
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) => Transform.scale(
                                  scale: 0.92 + (_pulseController.value * 0.16),
                                  child: Opacity(
                                    opacity: 0.58 + (_pulseController.value * 0.4),
                                    child: child,
                                  ),
                                ),
                                child: SizedBox(
                                  width: 46,
                                  height: 46,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 13),
                              Text(
                                'A LITTLE JOY, ON ITS WAY',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: compact ? 24 : 48),
                      ],
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

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.paleCream, AppColors.palePeach],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72), width: 2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 38,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.795,
            height: size * 0.795,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.logoBorder, width: 1.5),
            ),
          ),
          Text(
            'S',
            style: TextStyle(
              color: AppColors.deepCoral,
              fontSize: size * 0.566,
              height: 1,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              letterSpacing: -7,
            ),
          ),
          Positioned(
            right: size * 0.066,
            bottom: size * 0.114,
            child: Container(
              width: size * 0.235,
              height: size * 0.235,
              decoration: BoxDecoration(
                color: AppColors.deepCoral,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.logoBadgeBorder, width: 4),
                boxShadow: const [
                  BoxShadow(color: AppColors.logoBadgeShadow, blurRadius: 10),
                ],
              ),
              child: Icon(
                Icons.shopping_bag_rounded,
                size: size * 0.108,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingTag extends StatelessWidget {
  const _FloatingTag({
    required this.controller,
    required this.delay,
    required this.rotation,
    required this.label,
    this.compact = false,
  });

  final AnimationController controller;
  final double delay;
  final double rotation;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 62.0 : 76.0;
    final height = compact ? 45.0 : 54.0;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            6 * math.sin((controller.value + delay) * math.pi * 2),
          ),
          child: Transform.rotate(angle: rotation, child: child),
        );
      },
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.peachOverlay.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.82),
            fontSize: compact ? 8 : 9,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: 1.15,
          ),
        ),
      ),
    );
  }
}

class _BottomWavePainter extends CustomPainter {
  const _BottomWavePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final wave = Path()
      ..moveTo(0, size.height * 0.58)
      ..cubicTo(
        size.width * 0.26,
        size.height * (0.2 + progress * 0.12),
        size.width * 0.66,
        size.height * (0.86 - progress * 0.12),
        size.width,
        size.height * 0.4,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      wave,
      Paint()..color = AppColors.peachGlow,
    );

    final highlight = Path()
      ..moveTo(0, size.height * 0.58)
      ..cubicTo(
        size.width * 0.26,
        size.height * (0.2 + progress * 0.12),
        size.width * 0.66,
        size.height * (0.86 - progress * 0.12),
        size.width,
        size.height * 0.4,
      );
    canvas.drawPath(
      highlight,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _BottomWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
