import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Buzzer Super Admin splash.
///
/// Uses ONLY `Theme.of(context).colorScheme` -> light/dark works automatically.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.onFinished,
    this.loadingDuration = const Duration(milliseconds: 2800),
  });

  /// Called when the progress bar completes. Navigate to login/dashboard here.
  /// (Run your real startup work -> token check, config -> and call this when done.)
  final VoidCallback? onFinished;

  /// How long the progress bar takes to fill.
  final Duration loadingDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro; // logo + text entrance
  late final AnimationController _progress; // loading bar
  late final AnimationController _loop; // ripples, waves, floating orb

  late final Animation<double> _logoScale;
  late final Animation<double> _logoTurn;
  late final Animation<double> _title;
  late final Animation<double> _subtitle;
  late final Animation<double> _tagline;
  late final Animation<double> _barFade;

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _loop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _progress = AnimationController(
      vsync: this,
      duration: widget.loadingDuration,
    );

    Animation<double> interval(double a, double b, Curve c) => CurvedAnimation(
      parent: _intro,
      curve: Interval(a, b, curve: c),
    );

    _logoScale = interval(0.0, 0.55, Curves.easeOutBack);
    _logoTurn = interval(0.0, 0.55, Curves.easeOutCubic);
    _title = interval(0.30, 0.70, Curves.easeOutCubic);
    _subtitle = interval(0.42, 0.80, Curves.easeOutCubic);
    _tagline = interval(0.55, 1.0, Curves.easeOutCubic);
    _barFade = interval(0.70, 1.0, Curves.easeOut);

    _intro.forward();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _progress.forward();
    });

    _progress.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (mounted) widget.onFinished?.call();
      }
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _progress.dispose();
    _loop.dispose();
    super.dispose();
  }

  Widget _reveal(Animation<double> anim, Widget child, {double dy = 0.25}) {
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, dy),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: cs.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: cs.brightness,
      ),
      child: Scaffold(
        backgroundColor: cs.surface,
        body: Stack(
          children: [
            // ---- Background gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cs.surface,
                      cs.surfaceContainerLow,
                      cs.primaryContainer.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),
            ),

            // ---- Waves at the bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: MediaQuery.sizeOf(context).height * 0.34,
              child: AnimatedBuilder(
                animation: _loop,
                builder: (context, _) => CustomPaint(
                  painter: _WavePainter(
                    phase: _loop.value * 2 * math.pi,
                    colorA: cs.primary.withValues(alpha: 0.12),
                    colorB: cs.tertiary.withValues(alpha: 0.12),
                    colorC: cs.secondary.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),

            // ---- Floating orb
            AnimatedBuilder(
              animation: _loop,
              builder: (context, _) {
                final size = MediaQuery.sizeOf(context);
                final dy = math.sin(_loop.value * 2 * math.pi) * 12;
                return Positioned(
                  right: size.width * 0.08,
                  top: size.height * 0.62 + dy,
                  child: FadeTransition(
                    opacity: _barFade,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.3, -0.3),
                          colors: [
                            cs.primary.withValues(alpha: 0.55),
                            cs.tertiary.withValues(alpha: 0.25),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // ---- Center content
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 5),
                  _buildLogo(cs),
                  const SizedBox(height: 28),
                  _reveal(
                    _title,
                    ShaderMask(
                      shaderCallback: (rect) =>
                          LinearGradient(colors: [cs.primary, cs.tertiary])
                              .createShader(rect),
                      child: Text(
                        'Buzzer',
                        style: text.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: Colors.white, // masked by the gradient shader
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _reveal(
                    _subtitle,
                    Text(
                      'Super Admin',
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _reveal(
                    _tagline,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        'Manage games. Monitor players.\nKeep the competition fair.',
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 4),
                  FadeTransition(
                    opacity: _barFade,
                    child: _ProgressBar(animation: _progress),
                  ),
                  const SizedBox(height: 56),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(ColorScheme cs) {
    const double size = 112;
    return SizedBox(
      width: size * 2.2,
      height: size * 2.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Expanding ripple rings
          AnimatedBuilder(
            animation: _loop,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: List.generate(2, (i) {
                  final t = (_loop.value * 2 + i * 0.5) % 1.0;
                  final scale = 1 + t * 0.9;
                  return Opacity(
                    opacity: (1 - t) * 0.35,
                    child: Container(
                      width: size * scale,
                      height: size * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.primary, width: 2),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          // Logo
          AnimatedBuilder(
            animation: Listenable.merge([_intro, _loop]),
            builder: (context, _) {
              final glow = (math.sin(_loop.value * 2 * math.pi * 2) + 1) / 2;
              return Transform.rotate(
                angle: (1 - _logoTurn.value) * -0.5,
                child: Transform.scale(
                  scale: _logoScale.value.clamp(0.0, 1.3),
                  child: Opacity(
                    opacity: _logoTurn.value.clamp(0.0, 1.0),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [cs.primary, cs.tertiary],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(
                              alpha: 0.30 + 0.2 * glow,
                            ),
                            blurRadius: 28 + 16 * glow,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.bolt_rounded,
                        size: 72,
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// Loading bar
// ======================================================================

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
    );

    return Semantics(
      label: 'Loading',
      child: Container(
        width: 120,
        height: 5,
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(3),
        ),
        child: AnimatedBuilder(
          animation: progress,
          builder: (context, _) => Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress.value.clamp(0.04, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// Soft animated waves
// ======================================================================

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.phase,
    required this.colorA,
    required this.colorB,
    required this.colorC,
  });

  final double phase;
  final Color colorA;
  final Color colorB;
  final Color colorC;

  Path _wave(Size size, double yBase, double amp, double shift, double freq) {
    final path = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 4) {
      final y =
          yBase +
          math.sin((x / size.width) * 2 * math.pi * freq + phase + shift) * amp;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _wave(size, size.height * 0.35, 18, 0, 1.0),
      Paint()..color = colorA,
    );
    canvas.drawPath(
      _wave(size, size.height * 0.5, 22, 1.8, 1.3),
      Paint()..color = colorB,
    );
    canvas.drawPath(
      _wave(size, size.height * 0.68, 16, 3.6, 0.9),
      Paint()..color = colorC,
    );
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => old.phase != phase;
}
