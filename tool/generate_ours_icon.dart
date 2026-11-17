import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void line(img.Image canvas, double x1, double y1, double x2, double y2,
    img.Color color, {int thickness = 18}) {
  img.drawLine(
    canvas,
    x1: x1.round(),
    y1: y1.round(),
    x2: x2.round(),
    y2: y2.round(),
    color: color,
    thickness: thickness,
  );
}

void star(img.Image canvas, double cx, double cy, double radius,
    img.Color color) {
  final points = <math.Point<double>>[];
  for (var i = 0; i < 10; i++) {
    final angle = -math.pi / 2 + i * math.pi / 5;
    final r = i.isEven ? radius : radius * .42;
    points.add(math.Point(cx + math.cos(angle) * r, cy + math.sin(angle) * r));
  }
  for (var i = 0; i < points.length; i++) {
    final a = points[i];
    final b = points[(i + 1) % points.length];
    line(canvas, a.x, a.y, b.x, b.y, color, thickness: 6);
  }
}

void main() {
  final canvas = img.Image(width: 512, height: 512);
  img.fill(canvas, color: img.ColorRgb8(16, 16, 28));

  final gold = img.ColorRgb8(217, 188, 134);
  final violet = img.ColorRgb8(185, 162, 213);
  final glow = img.ColorRgb8(76, 62, 98);

  // A subtle outer frame keeps the mark centered on launcher backgrounds.
  for (var t = 0; t < 360; t += 2) {
    final a = t * math.pi / 180;
    final b = (t + 2) * math.pi / 180;
    line(canvas, 256 + 220 * math.cos(a), 256 + 220 * math.sin(a),
        256 + 220 * math.cos(b), 256 + 220 * math.sin(b), glow,
        thickness: 2);
  }

  // Interlocking gold and lavender halves of the OURS infinity mark.
  const segments = 240;
  double px(double t) => 256 + 150 * math.sin(t);
  double py(double t) => 256 + 96 * math.sin(2 * t);
  for (var i = 0; i < segments; i++) {
    final t1 = i * 2 * math.pi / segments;
    final t2 = (i + 1) * 2 * math.pi / segments;
    final color = i < segments ~/ 2 ? gold : violet;
    line(canvas, px(t1), py(t1), px(t2), py(t2), color, thickness: 24);
  }

  star(canvas, 112, 118, 24, gold);
  star(canvas, 398, 388, 20, violet);
  star(canvas, 398, 122, 10, gold);

  File('assets/ours_icon.png').writeAsBytesSync(img.encodePng(canvas));
}
