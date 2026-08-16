import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'main_nav_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Les 7 lettres de "Buy More" (sans l'espace) sont réparties tout autour
  // du monogramme et tournent en continu, comme un texte qui défile en
  // orbite autour du logo plutôt que de rester statique dessous.
  static const String _letters = 'BuyMore';
  static const double _orbitRadius = 108;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..forward();

  // Rotation continue de l'orbite + de l'anneau décoratif + pulsation du
  // monogramme — tout reste en mouvement en permanence, jamais figé.
  late final AnimationController _orbit = AnimationController(vsync: this, duration: const Duration(milliseconds: 9000))..repeat();
  late final AnimationController _ring = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat();
  late final AnimationController _idle = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();

  late final Animation<double> _monogramFade = CurvedAnimation(parent: _intro, curve: const Interval(0.0, 0.2, curve: Curves.easeOut));
  late final Animation<double> _monogramDrop = CurvedAnimation(parent: _intro, curve: const Interval(0.0, 0.42, curve: Curves.elasticOut));

  bool _minDurationElapsed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _minDurationElapsed = true);
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _orbit.dispose();
    _ring.dispose();
    _idle.dispose();
    super.dispose();
  }

  /// Fenêtre d'animation d'entrée de la lettre [index] : elle apparaît en se
  /// rapprochant de son rayon d'orbite final, une après l'autre.
  Animation<double> _letterAnim(int index, int total) {
    final start = 0.15 + (index / total) * 0.65;
    final end = (start + 0.22).clamp(0.0, 1.0);
    return CurvedAnimation(parent: _intro, curve: Interval(start, end, curve: Curves.easeOutBack));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.loading || !_minDurationElapsed) {
      return Scaffold(
        backgroundColor: AppColors.ink,
        body: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_intro, _orbit, _ring, _idle]),
            builder: (context, _) {
              final idlePulse = math.sin(_idle.value * 2 * math.pi);
              final orbitAngle = _orbit.value * 2 * math.pi;
              return SizedBox(
                width: 280, height: 280,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Lettres de "Buy More" en orbite continue autour du monogramme.
                    for (int i = 0; i < _letters.length; i++)
                      Builder(builder: (context) {
                        final anim = _letterAnim(i, _letters.length);
                        final baseAngle = -math.pi / 2 + i * (2 * math.pi / _letters.length);
                        final angle = baseAngle + orbitAngle;
                        final radius = _orbitRadius * (0.55 + 0.45 * anim.value);
                        final dx = radius * math.cos(angle);
                        final dy = radius * math.sin(angle);
                        return Opacity(
                          opacity: anim.value.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(dx, dy),
                            child: Transform.scale(
                              scale: anim.value.clamp(0.0, 1.0),
                              child: Text(_letters[i],
                                  style: GoogleFonts.fraunces(
                                      color: AppColors.ivory,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      shadows: [Shadow(color: AppColors.gold.withOpacity(0.5), blurRadius: 8)])),
                            ),
                          ),
                        );
                      }),

                    // Monogramme central : tombe avec rebond, cerclé d'un
                    // anneau segmenté façon interface qui tourne en continu.
                    Transform.translate(
                      offset: Offset(0, -140 * (1 - _monogramDrop.value)),
                      child: FadeTransition(
                        opacity: _monogramFade,
                        child: SizedBox(
                          width: 100, height: 100,
                          child: Stack(alignment: Alignment.center, children: [
                            Transform.rotate(
                              angle: _ring.value * 2 * math.pi,
                              child: CustomPaint(size: const Size(100, 100), painter: _RingPainter(color: AppColors.gold.withOpacity(0.85))),
                            ),
                            Transform.scale(
                              scale: 1 + (idlePulse * 0.035),
                              child: Container(
                                width: 72, height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.ink,
                                  border: Border.all(color: AppColors.gold, width: 2),
                                  boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.3 + idlePulse.abs() * 0.2), blurRadius: 20, spreadRadius: 2)],
                                ),
                                alignment: Alignment.center,
                                child: Text('BM', style: GoogleFonts.fraunces(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    // Que le client soit connecté ou non, la boutique reste consultable ;
    // la connexion n'est demandée qu'au moment de commander (voir CheckoutScreen).
    return const MainNavScreen();
  }
}

/// Anneau segmenté (traits courts + espaces) façon interface futuriste,
/// dessiné à la main pour tourner en continu autour du monogramme.
class _RingPainter extends CustomPainter {
  final Color color;
  final int segments;
  _RingPainter({required this.color, this.segments = 10});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final radius = size.width / 2 - 2;
    final center = Offset(size.width / 2, size.height / 2);
    final sweep = (2 * math.pi / segments) * 0.55;
    for (int i = 0; i < segments; i++) {
      final start = (2 * math.pi / segments) * i;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.color != color || oldDelegate.segments != segments;
}
