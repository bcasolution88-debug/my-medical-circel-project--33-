import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Monoline icon set on a 24 viewBox, stroke 2, round caps — ported from
/// `Icons.jsx` + `med/medArt.jsx`. Rendered with a tiny SVG path interpreter.
class MedIconData {
  final List<IconShape> shapes;
  const MedIconData(this.shapes);
}

abstract class IconShape {
  const IconShape();
}

class _PathShape extends IconShape {
  final String d;
  const _PathShape(this.d);
}

class _CircleShape extends IconShape {
  final double cx, cy, r;
  const _CircleShape(this.cx, this.cy, this.r);
}

class _RectShape extends IconShape {
  final double x, y, w, h, rx;
  final double rotate; // degrees around (12,12)
  const _RectShape(this.x, this.y, this.w, this.h, this.rx, {this.rotate = 0});
}

class MedIcons {
  MedIcons._();

  static const home = MedIconData([
    _PathShape('M3 10.5 12 3l9 7.5'),
    _PathShape('M5 9.5V21h14V9.5'),
  ]);
  static const plus = MedIconData([_PathShape('M12 5v14M5 12h14')]);
  static const user = MedIconData([
    _CircleShape(12, 8, 4),
    _PathShape('M4 21a8 8 0 0 1 16 0'),
  ]);
  static const headset = MedIconData([
    _PathShape('M4 14 V12 C4 7.6 7.6 4 12 4 C16.4 4 20 7.6 20 12 V14'),
    _RectShape(3, 14, 4, 6, 1.5),
    _RectShape(17, 14, 4, 6, 1.5),
    _PathShape('M20 20 V21 C20 22.1 19.1 23 18 23 H15'),
  ]);
  static const grid = MedIconData([
    _RectShape(3, 3, 7, 7, 1.5),
    _RectShape(14, 3, 7, 7, 1.5),
    _RectShape(3, 14, 7, 7, 1.5),
    _RectShape(14, 14, 7, 7, 1.5),
  ]);
  static const eye = MedIconData([
    _PathShape('M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z'),
    _CircleShape(12, 12, 3),
  ]);
  static const heart = MedIconData([
    _PathShape('M12 19s-7-4.5-9-9.5S6 2 12 7c6-5 11 .5 9 11.5-2 5-9 9.5-9 9.5z'),
  ]);
  static const like = MedIconData([
    _PathShape(
        'M7 10v10H4V10zM7 10l4-7a2 2 0 0 1 3 2v3h5a2 2 0 0 1 2 2.3l-1.4 7A2 2 0 0 1 17 19H7'),
  ]);
  static const close = MedIconData([_PathShape('M6 6l12 12M18 6 6 18')]);
  static const clock = MedIconData([
    _CircleShape(12, 12, 9),
    _PathShape('M12 7v5l3 2'),
  ]);
  static const pin = MedIconData([
    _PathShape('M12 22s7-7.5 7-13a7 7 0 1 0-14 0c0 5.5 7 13 7 13z'),
    _CircleShape(12, 9, 2.5),
  ]);
  static const flower = MedIconData([
    _CircleShape(12, 12, 2),
    _PathShape(
        'M12 8V4M12 20v-4M8 12H4M20 12h-4M8.5 8.5 6 6M18 18l-2.5-2.5M8.5 15.5 6 18M18 6l-2.5 2.5'),
  ]);
  static const chart = MedIconData([
    _PathShape('M4 4v16h16'),
    _PathShape('M7 15l3-4 3 3 4-6'),
  ]);
  static const send = MedIconData([_PathShape('M4 12 21 4l-7 17-3-8z')]);
  static const check = MedIconData([_PathShape('m5 12 5 5L20 7')]);
  static const search = MedIconData([
    _CircleShape(11, 11, 7),
    _PathShape('m20 20-3.5-3.5'),
  ]);
  static const moon = MedIconData([
    _PathShape('M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z'),
  ]);
  static const scan = MedIconData([
    _PathShape(
        'M4 8V5.5A1.5 1.5 0 0 1 5.5 4H8M16 4h2.5A1.5 1.5 0 0 1 20 5.5V8M20 16v2.5a1.5 1.5 0 0 1-1.5 1.5H16M8 20H5.5A1.5 1.5 0 0 1 4 18.5V16M4 12h16'),
  ]);
  static const chevronLeft = MedIconData([_PathShape('m15 5-7 7 7 7')]);
  static const chevronRight = MedIconData([_PathShape('m9 5 7 7-7 7')]);
  static const settings = MedIconData([
    _CircleShape(12, 12, 3),
    _PathShape(
        'M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z'),
  ]);
  static const doc = MedIconData([
    _RectShape(4, 3, 16, 18, 2),
    _PathShape('M8 8h8M8 12h8M8 16h5'),
  ]);
  static const trash = MedIconData([
    _PathShape('M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3'),
  ]);
  static const refresh = MedIconData([
    _PathShape('M20 12a8 8 0 1 1-2.3-5.7'),
    _PathShape('M20 4v5h-5'),
  ]);
  static const handshake = MedIconData([
    _PathShape('M3 8l4-3 5 3 5-3 4 3v8l-4 3-5-3-5 3-4-3z'),
  ]);
  static const bookmark = MedIconData([
    _PathShape('M6 3h12v18l-6-4-6 4z'),
  ]);

  // Medical additions
  static const stethoscope = MedIconData([
    _PathShape('M5 3v5a5 5 0 0 0 10 0V3'),
    _PathShape('M5 3H3.5M15 3h1.5'),
    _PathShape('M10 13v2a5 5 0 0 0 10 0v-1.5'),
    _CircleShape(20, 11.5, 2),
  ]);
  static const pill = MedIconData([
    _RectShape(2.5, 8.5, 19, 7, 3.5, rotate: -45),
    _PathShape('m8.5 8.5 7 7'),
  ]);
  static const heartPulse = MedIconData([
    _PathShape(
        'M20.4 5.6a5.2 5.2 0 0 0-7.4 0L12 6.6l-1-1a5.2 5.2 0 0 0-7.4 7.4l8.4 8.4 8.4-8.4a5.2 5.2 0 0 0 0-7.4z'),
    _PathShape('M3.5 12h4l1.5-2.5 2.5 5 1.5-2.5h7.5'),
  ]);
  static const hospital = MedIconData([
    _PathShape('M4 21V7l8-4 8 4v14'),
    _PathShape('M2 21h20'),
    _PathShape('M12 8v6M9 11h6'),
    _PathShape('M9 21v-3h6v3'),
  ]);
  static const playCross = MedIconData([
    _RectShape(3, 4, 18, 16, 4),
    _PathShape('m10 9 5 3-5 3z'),
  ]);
  static const clipboard = MedIconData([
    _RectShape(5, 4, 14, 17, 2.5),
    _PathShape('M9 4V3h6v1'),
    _PathShape('M12 9v6M9 12h6'),
  ]);
  static const shieldPlus = MedIconData([
    _PathShape('M12 3 4 6v6c0 4.6 3.4 8.2 8 9 4.6-.8 8-4.4 8-9V6z'),
    _PathShape('M12 9v6M9 12h6'),
  ]);
  static const leafCross = MedIconData([
    _PathShape('M5 19c0-8 5-14 15-14 0 10-6 15-14 15'),
    _PathShape('M5 19 13 11'),
  ]);
  static const doctorChat = MedIconData([
    _PathShape('M20 12a8 8 0 0 1-11.5 7.2L4 21l1.8-4.5A8 8 0 1 1 20 12z'),
    _PathShape('M12 8.5v6M9 11.5h6'),
  ]);
  static const medCross = MedIconData([
    _PathShape('M9 3h6v6h6v6h-6v6H9v-6H3V9h6z'),
  ]);

  static const placeholderMotifs = [
    medCross,
    heartPulse,
    leafCross,
    pill,
    stethoscope,
    shieldPlus,
  ];
}

class MedIcon extends StatelessWidget {
  final MedIconData icon;
  final double size;
  final Color color;
  final double stroke;

  const MedIcon(
    this.icon, {
    super.key,
    this.size = 22,
    this.color = const Color(0xFF13322D),
    this.stroke = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MedIconPainter(icon, color, stroke),
      ),
    );
  }
}

class _MedIconPainter extends CustomPainter {
  final MedIconData icon;
  final Color color;
  final double stroke;
  _MedIconPainter(this.icon, this.color, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final s in icon.shapes) {
      if (s is _PathShape) {
        canvas.drawPath(SvgPath.parse(s.d), paint);
      } else if (s is _CircleShape) {
        canvas.drawCircle(Offset(s.cx, s.cy), s.r, paint);
      } else if (s is _RectShape) {
        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(s.x, s.y, s.w, s.h),
          Radius.circular(s.rx),
        );
        if (s.rotate != 0) {
          canvas.save();
          canvas.translate(12, 12);
          canvas.rotate(s.rotate * math.pi / 180);
          canvas.translate(-12, -12);
          canvas.drawRRect(rrect, paint);
          canvas.restore();
        } else {
          canvas.drawRRect(rrect, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MedIconPainter old) =>
      old.icon != icon || old.color != color || old.stroke != stroke;
}

/// Minimal SVG path-data interpreter (M L H V C S Q T A Z, abs + rel).
class SvgPath {
  static final Map<String, Path> _cache = {};

  static Path parse(String d) {
    final cached = _cache[d];
    if (cached != null) return cached;
    final path = Path();
    final tokens = _tokenize(d);
    int i = 0;
    String cmd = '';
    double cx = 0, cy = 0, sx = 0, sy = 0, lcx = 0, lcy = 0;
    String lastCmd = '';

    double next() => tokens[i++] as double;
    bool hasNum() => i < tokens.length && tokens[i] is double;

    while (i < tokens.length) {
      final t = tokens[i];
      if (t is String) {
        cmd = t;
        i++;
      } else if (cmd == 'M') {
        cmd = 'L';
      } else if (cmd == 'm') {
        cmd = 'l';
      }
      switch (cmd) {
        case 'M':
          cx = next();
          cy = next();
          path.moveTo(cx, cy);
          sx = cx;
          sy = cy;
          break;
        case 'm':
          cx += next();
          cy += next();
          path.moveTo(cx, cy);
          sx = cx;
          sy = cy;
          break;
        case 'L':
          while (hasNum()) {
            cx = next();
            cy = next();
            path.lineTo(cx, cy);
          }
          break;
        case 'l':
          while (hasNum()) {
            cx += next();
            cy += next();
            path.lineTo(cx, cy);
          }
          break;
        case 'H':
          while (hasNum()) {
            cx = next();
            path.lineTo(cx, cy);
          }
          break;
        case 'h':
          while (hasNum()) {
            cx += next();
            path.lineTo(cx, cy);
          }
          break;
        case 'V':
          while (hasNum()) {
            cy = next();
            path.lineTo(cx, cy);
          }
          break;
        case 'v':
          while (hasNum()) {
            cy += next();
            path.lineTo(cx, cy);
          }
          break;
        case 'C':
        case 'c':
          while (hasNum()) {
            final rel = cmd == 'c';
            final x1 = (rel ? cx : 0) + next();
            final y1 = (rel ? cy : 0) + next();
            final x2 = (rel ? cx : 0) + next();
            final y2 = (rel ? cy : 0) + next();
            final x = (rel ? cx : 0) + next();
            final y = (rel ? cy : 0) + next();
            path.cubicTo(x1, y1, x2, y2, x, y);
            lcx = x2;
            lcy = y2;
            cx = x;
            cy = y;
          }
          break;
        case 'S':
        case 's':
          while (hasNum()) {
            final rel = cmd == 's';
            double x1, y1;
            if ('CcSs'.contains(lastCmd)) {
              x1 = 2 * cx - lcx;
              y1 = 2 * cy - lcy;
            } else {
              x1 = cx;
              y1 = cy;
            }
            final x2 = (rel ? cx : 0) + next();
            final y2 = (rel ? cy : 0) + next();
            final x = (rel ? cx : 0) + next();
            final y = (rel ? cy : 0) + next();
            path.cubicTo(x1, y1, x2, y2, x, y);
            lcx = x2;
            lcy = y2;
            cx = x;
            cy = y;
            lastCmd = cmd;
          }
          break;
        case 'Q':
        case 'q':
          while (hasNum()) {
            final rel = cmd == 'q';
            final x1 = (rel ? cx : 0) + next();
            final y1 = (rel ? cy : 0) + next();
            final x = (rel ? cx : 0) + next();
            final y = (rel ? cy : 0) + next();
            path.quadraticBezierTo(x1, y1, x, y);
            lcx = x1;
            lcy = y1;
            cx = x;
            cy = y;
          }
          break;
        case 'T':
        case 't':
          while (hasNum()) {
            final rel = cmd == 't';
            double x1, y1;
            if ('QqTt'.contains(lastCmd)) {
              x1 = 2 * cx - lcx;
              y1 = 2 * cy - lcy;
            } else {
              x1 = cx;
              y1 = cy;
            }
            final x = (rel ? cx : 0) + next();
            final y = (rel ? cy : 0) + next();
            path.quadraticBezierTo(x1, y1, x, y);
            lcx = x1;
            lcy = y1;
            cx = x;
            cy = y;
            lastCmd = cmd;
          }
          break;
        case 'A':
        case 'a':
          while (hasNum()) {
            final rel = cmd == 'a';
            final rx = next();
            final ry = next();
            final rot = next();
            final large = next() != 0;
            final sweep = next() != 0;
            final x = (rel ? cx : 0) + next();
            final y = (rel ? cy : 0) + next();
            _arcTo(path, cx, cy, rx, ry, rot, large, sweep, x, y);
            cx = x;
            cy = y;
          }
          break;
        case 'Z':
        case 'z':
          path.close();
          cx = sx;
          cy = sy;
          break;
        default:
          i++;
      }
      lastCmd = cmd;
    }
    _cache[d] = path;
    return path;
  }

  static void _arcTo(Path path, double x1, double y1, double rx, double ry,
      double rotDeg, bool large, bool sweep, double x2, double y2) {
    if (rx == 0 || ry == 0) {
      path.lineTo(x2, y2);
      return;
    }
    if (x1 == x2 && y1 == y2) return;
    final phi = rotDeg * math.pi / 180;
    final cosP = math.cos(phi), sinP = math.sin(phi);
    final dx2 = (x1 - x2) / 2, dy2 = (y1 - y2) / 2;
    final x1p = cosP * dx2 + sinP * dy2;
    final y1p = -sinP * dx2 + cosP * dy2;
    rx = rx.abs();
    ry = ry.abs();
    final lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry);
    if (lambda > 1) {
      final s = math.sqrt(lambda);
      rx *= s;
      ry *= s;
    }
    final rx2 = rx * rx, ry2 = ry * ry;
    final num = rx2 * ry2 - rx2 * y1p * y1p - ry2 * x1p * x1p;
    final den = rx2 * y1p * y1p + ry2 * x1p * x1p;
    double coef = den == 0 ? 0 : math.sqrt(math.max(0, num / den));
    if (large == sweep) coef = -coef;
    final cxp = coef * (rx * y1p / ry);
    final cyp = coef * -(ry * x1p / rx);
    final cx = cosP * cxp - sinP * cyp + (x1 + x2) / 2;
    final cy = sinP * cxp + cosP * cyp + (y1 + y2) / 2;

    double angle(double ux, double uy, double vx, double vy) {
      final dot = ux * vx + uy * vy;
      final len = math.sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy));
      double a = math.acos((dot / len).clamp(-1.0, 1.0));
      if (ux * vy - uy * vx < 0) a = -a;
      return a;
    }

    final theta1 = angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry);
    double dTheta = angle((x1p - cxp) / rx, (y1p - cyp) / ry,
        (-x1p - cxp) / rx, (-y1p - cyp) / ry);
    if (!sweep && dTheta > 0) {
      dTheta -= 2 * math.pi;
    } else if (sweep && dTheta < 0) {
      dTheta += 2 * math.pi;
    }

    // Approximate with cubic beziers (segments of <= 90deg)
    final segs = (dTheta.abs() / (math.pi / 2)).ceil().clamp(1, 4);
    final delta = dTheta / segs;
    final tt = 4 / 3 * math.tan(delta / 4);
    double t1 = theta1;
    for (int s = 0; s < segs; s++) {
      final t2 = t1 + delta;
      final cos1 = math.cos(t1), sin1 = math.sin(t1);
      final cos2 = math.cos(t2), sin2 = math.sin(t2);
      final e1x = cos1 - tt * sin1, e1y = sin1 + tt * cos1;
      final e2x = cos2 + tt * sin2, e2y = sin2 - tt * cos2;
      Offset map(double px, double py) => Offset(
            cx + cosP * rx * px - sinP * ry * py,
            cy + sinP * rx * px + cosP * ry * py,
          );
      final c1 = map(e1x, e1y);
      final c2 = map(e2x, e2y);
      final end = map(cos2, sin2);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
      t1 = t2;
    }
  }

  static List<Object> _tokenize(String d) {
    final out = <Object>[];
    final re = RegExp(r'[MmLlHhVvCcSsQqTtAaZz]|-?\d*\.?\d+(?:e[-+]?\d+)?');
    for (final m in re.allMatches(d)) {
      final s = m.group(0)!;
      if (RegExp(r'^[A-Za-z]$').hasMatch(s)) {
        out.add(s);
      } else {
        out.add(double.parse(s));
      }
    }
    return out;
  }
}
