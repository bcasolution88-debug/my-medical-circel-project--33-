import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/stores.dart';
import '../../theme/med_theme.dart';
import '../../widgets/common.dart';
import '../app_shell.dart';
import 'onboarding_page.dart';

/// 启动图 — aurora background, orbit rings of member avatars, logo, progress bar.
/// Auto-advances after 3.8 s, or on tap. Auth screens always use the day palette.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3800))..forward();
  Timer? _t;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 3800), _go);
  }

  void _go() {
    if (_done || !mounted) return;
    _done = true;
    final auth = context.read<AuthStore>();
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, a, _) => FadeTransition(opacity: a, child: auth.onboarded ? const AppShell() : const OnboardingPage()),
      transitionDuration: const Duration(milliseconds: 350),
    ));
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const T = MedTokens.light;
    return MedTheme(
      tokens: T,
      child: GestureDetector(
        onTap: _go,
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFDDF4EE), Color(0xFFF2F8F6), Color(0xFFFFEADF)]),
            ),
            child: Stack(children: [
              Positioned.fill(child: AnimatedBuilder(animation: _c, builder: (_, _) => CustomPaint(painter: _OrbitPainter(_c.value)))),
              Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const MedLogo(size: 84),
                  const SizedBox(height: 26),
                  const Text('HEALTH CIRCLE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 6, color: Color(0xFF0B7A6E))),
                  const SizedBox(height: 8),
                  const Text('健康圈子', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 8, color: Color(0xFF13322D))),
                  const SizedBox(height: 14),
                  Text('让健康更有温度，让关怀触手可及', style: TextStyle(fontSize: 13.5, color: T.inkMuted, letterSpacing: 1)),
                ]),
              ),
              Positioned(
                left: 60, right: 60, bottom: 70,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (_, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(value: _c.value, minHeight: 4, backgroundColor: Colors.white.withValues(alpha: 0.6), color: T.primary),
                  ),
                ),
              ),
              Positioned(left: 0, right: 0, bottom: 40, child: Text('轻触跳过', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: T.inkSubtle))),
            ]),
          ),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final double t;
  _OrbitPainter(this.t);
  static const _seeds = ['A', 'S', 'M', 'W', 'J', 'F', 'Y', 'L'];
  static const _pal = [Color(0xFFD6F3EC), Color(0xFFFFE6D8), Color(0xFFDCEFFA), Color(0xFFE3F4DA)];
  static const _fg = [Color(0xFF0B7A6E), Color(0xFFC2582E), Color(0xFF1C6FA0), Color(0xFF3F7F2A)];

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 - 20);
    final dash = Paint()
      ..color = const Color(0xFF12A594).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final r in [150.0, 215.0]) {
      final path = Path();
      for (double a = 0; a < 2 * math.pi; a += 0.12) {
        final p1 = c + Offset(math.cos(a), math.sin(a)) * r;
        final p2 = c + Offset(math.cos(a + 0.06), math.sin(a + 0.06)) * r;
        path.moveTo(p1.dx, p1.dy);
        path.lineTo(p2.dx, p2.dy);
      }
      canvas.drawPath(path, dash);
    }
    // ripples
    for (int i = 0; i < 3; i++) {
      final ph = ((t * 1.5) + i / 3) % 1;
      canvas.drawCircle(c, 60 + ph * 120, Paint()
        ..color = const Color(0xFF12A594).withValues(alpha: (1 - ph) * 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
    }
    for (int i = 0; i < _seeds.length; i++) {
      final r = i.isEven ? 150.0 : 215.0;
      final a = (i / _seeds.length) * 2 * math.pi + t * (i.isEven ? 0.8 : -0.5) * math.pi;
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      canvas.drawCircle(p, 16, Paint()..color = Colors.white);
      canvas.drawCircle(p, 14, Paint()..color = _pal[i % 4]);
      final tp = TextPainter(
        text: TextSpan(text: _seeds[i], style: TextStyle(color: _fg[i % 4], fontWeight: FontWeight.w800, fontSize: 12)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter old) => old.t != t;
}
