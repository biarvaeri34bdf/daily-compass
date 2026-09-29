import 'package:flutter/material.dart';

import '../assets.dart';
import '../theme.dart';
import '../widgets/painters.dart';

/// Dark ink splash — deliberately nothing like the cream Menu: no CTA,
/// no cards, different palette entirely.
class LoaderScreen extends StatefulWidget {
  const LoaderScreen({super.key});

  @override
  State<LoaderScreen> createState() => _LoaderScreenState();
}

class _LoaderScreenState extends State<LoaderScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _rise;

  @override
  void initState() {
    super.initState();
    // One-shot only. A perpetual controller would keep the window non-idle
    // and stall the screenshot harness.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _rise = Tween<double>(begin: 14, end: 0).animate(_fade);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.loaderDark3,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.bgLoader),
            fit: BoxFit.cover,
            opacity: 0.55,
          ),
          gradient: LinearGradient(
            colors: <Color>[
              AppColors.loaderDark1,
              AppColors.loaderDark2,
              AppColors.loaderDark3,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Static grain — painted once, lifts the frame well clear of a
            // flat gradient without scheduling a single extra repaint.
            const RepaintBoundary(child: _GrainLayer()),
            SafeArea(
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => Opacity(
                    opacity: _fade.value,
                    child: Transform.translate(
                      offset: Offset(0, _rise.value),
                      child: child,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.04),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.28),
                            width: 1,
                          ),
                        ),
                        child: Image.asset(
                          AppAssets.spriteCompassRose,
                          width: 132,
                          height: 132,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 34),
                      const Text(
                        'DAILY COMPASS',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 6.0,
                          color: AppColors.background,
                        ),
                      ),
                      Container(
                        width: 120,
                        height: 1,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        color: AppColors.accent.withValues(alpha: 0.2),
                      ),
                      Text(
                        'FIND YOUR BALANCE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3.0,
                          color: AppColors.secondary.withValues(alpha: 0.95),
                        ),
                      ),
                      const SizedBox(height: 40),
                      const _LoaderProgressBar(),
                      const SizedBox(height: 14),
                      const Text(
                        'LOADING…',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.5,
                          color: Color(0xFF6E7A86),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrainLayer extends StatelessWidget {
  const _GrainLayer();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: StarfieldPainter(),
      size: Size.infinite,
      child: const SizedBox.expand(),
    );
  }
}

/// Determinate bar that settles after 1200ms. A tween stretched across the
/// whole 8s hold would repaint every frame and stall uiautomator.
class _LoaderProgressBar extends StatelessWidget {
  const _LoaderProgressBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 2,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => LinearProgressIndicator(
          value: value,
          minHeight: 2,
          backgroundColor: const Color(0xFF1F2A38),
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
        ),
      ),
    );
  }
}
