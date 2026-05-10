import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_models.dart';

class CatRoomScene extends StatelessWidget {
  const CatRoomScene({
    super.key,
    required this.mood,
    required this.stage,
    required this.accessory,
    required this.bounce,
    required this.breedIndex,
    required this.showHearts,
    required this.heartProgress,
  });

  final CatMood mood;
  final CatStage stage;
  final String accessory;
  final double bounce;
  final int breedIndex;
  final bool showHearts;
  final double heartProgress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final roomWidth = constraints.maxWidth;
        final catWidth = (roomWidth * .46).clamp(170.0, 245.0).toDouble();
        return AspectRatio(
          aspectRatio: roomWidth < 520 ? 1.14 : 1.62,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: RoomPainter(
                      mood: mood,
                      bounce: bounce,
                      bankProgress: mood == CatMood.thriving
                          ? 1
                          : mood == CatMood.distressed || mood == CatMood.hissing
                              ? .35
                              : .68,
                    ),
                  ),
                ),
                Positioned(
                  left: roomWidth * .26,
                  right: roomWidth * .26,
                  bottom: 28,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x44000000),
                          blurRadius: 30,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: SizedBox(height: 6),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 34,
                  child: Center(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, .0015)
                        ..rotateX(-.05),
                      child: CustomPaint(
                        size: Size(catWidth, catWidth * .8),
                        painter: CatPainter(
                          mood: mood,
                          stage: stage,
                          accessory: accessory,
                          bounce: bounce,
                          breedIndex: breedIndex,
                        ),
                      ),
                    ),
                  ),
                ),
                if (showHearts)
                  Positioned.fill(
                    child: CustomPaint(painter: HeartBurstPainter(heartProgress)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class RoomPainter extends CustomPainter {
  RoomPainter({
    required this.mood,
    required this.bounce,
    required this.bankProgress,
  });

  final CatMood mood;
  final double bounce;
  final double bankProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final backWall = Rect.fromLTWH(
      size.width * .18,
      size.height * .07,
      size.width * .64,
      size.height * .45,
    );
    final vanishing = Offset(size.width * .5, size.height * .52);

    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFFF7E6));
    canvas.drawPath(_quad(0, 0, size.width, 0, backWall.right, backWall.top, backWall.left, backWall.top), Paint()..color = const Color(0xFFFFFAEA));
    canvas.drawPath(_quad(0, 0, backWall.left, backWall.top, backWall.left, backWall.bottom, 0, size.height), Paint()..color = const Color(0xFFFFDFC2));
    canvas.drawPath(_quad(size.width, 0, backWall.right, backWall.top, backWall.right, backWall.bottom, size.width, size.height), Paint()..color = const Color(0xFFFFE8D6));
    canvas.drawPath(_quad(0, size.height, backWall.left, backWall.bottom, backWall.right, backWall.bottom, size.width, size.height), Paint()..color = const Color(0xFFD2AA78));
    canvas.drawRRect(
      RRect.fromRectAndRadius(backWall, const Radius.circular(10)),
      Paint()..color = const Color(0xFFFFF2D0),
    );

    final cornerPaint = Paint()
      ..color = const Color(0x44845D3C)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final point in [Offset.zero, Offset(size.width, 0), Offset(0, size.height), Offset(size.width, size.height)]) {
      canvas.drawLine(point, vanishing, cornerPaint);
    }
    canvas.drawRRect(RRect.fromRectAndRadius(backWall, const Radius.circular(10)), cornerPaint);

    _drawFloor(canvas, size);
    _drawWallDecor(canvas, size);
    _drawCarpet(canvas, size);
    _drawBed(canvas, size);
    _drawTable(canvas, size);
    _drawBank(canvas, size);
    _drawToys(canvas, size);
  }

  Path _quad(double ax, double ay, double bx, double by, double cx, double cy, double dx, double dy) {
    return Path()
      ..moveTo(ax, ay)
      ..lineTo(bx, by)
      ..lineTo(cx, cy)
      ..lineTo(dx, dy)
      ..close();
  }

  void _drawFloor(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0x33845D3C)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final vanishing = Offset(size.width * .5, size.height * .52);
    for (var i = 0; i < 9; i++) {
      final x = size.width * (.08 + i * .105);
      canvas.drawLine(Offset(x, size.height), vanishing, line);
    }
    for (var i = 0; i < 7; i++) {
      final y = size.height * (.58 + i * .065);
      final inset = (size.height - y) * .18;
      canvas.drawLine(Offset(inset, y), Offset(size.width - inset, y), line);
    }
  }

  void _drawWallDecor(Canvas canvas, Size size) {
    final shadow = Paint()..color = const Color(0x18000000);
    final frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * .38, size.height * .11, size.width * .24, size.height * .14),
      const Radius.circular(8),
    );
    canvas.drawRRect(frame.shift(const Offset(4, 5)), shadow);
    canvas.drawRRect(frame, Paint()..color = const Color(0xFF18A999));
    canvas.drawRRect(RRect.fromRectAndRadius(frame.outerRect.deflate(8), const Radius.circular(6)), Paint()..color = Colors.white);

    final chart = Paint()
      ..color = const Color(0xFFFFB703)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * .42, size.height * .18), Offset(size.width * .48, size.height * .14), chart);
    canvas.drawLine(Offset(size.width * .48, size.height * .14), Offset(size.width * .56, size.height * .19), chart);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * .1, size.height * .28, size.width * .24, 12), const Radius.circular(6)),
      Paint()..color = const Color(0xFF8B5E34),
    );
    canvas.drawCircle(Offset(size.width * .18, size.height * .24), 14, Paint()..color = const Color(0xFFFFB703));
    canvas.drawCircle(Offset(size.width * .27, size.height * .235), 10, Paint()..color = const Color(0xFF7C3AED));
  }

  void _drawBed(Canvas canvas, Size size) {
    final x = size.width * .05;
    final y = size.height * .56;
    final w = size.width * .3;
    final h = size.height * .16;
    canvas.drawPath(
      Path()
        ..moveTo(x, y + h * .12)
        ..lineTo(x + w * .14, y - h * .48)
        ..lineTo(x + w, y - h * .32)
        ..lineTo(x + w * .9, y + h * .44)
        ..lineTo(x + w * .04, y + h)
        ..close(),
      Paint()..color = const Color(0xFF4361EE),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x + w * .16, y + h * .04, w * .7, h * .48), const Radius.circular(12)),
      Paint()..color = const Color(0xFFFFD6A5),
    );
  }

  void _drawTable(Canvas canvas, Size size) {
    final x = size.width * .72;
    final y = size.height * .52;
    final w = size.width * .2;
    final h = size.height * .14;
    canvas.drawPath(
      Path()
        ..moveTo(x, y)
        ..lineTo(x + w, y + 8)
        ..lineTo(x + w * .86, y + h * .35)
        ..lineTo(x - w * .08, y + h * .25)
        ..close(),
      Paint()..color = const Color(0xFF9C6644),
    );
    final leg = Paint()..color = const Color(0xFF6F4518);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + w * .05, y + h * .18, 10, h), const Radius.circular(4)), leg);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + w * .78, y + h * .25, 10, h), const Radius.circular(4)), leg);
    canvas.drawCircle(Offset(x + w * .42, y - 4 + math.sin(bounce * math.pi) * -2), 15, Paint()..color = const Color(0xFF18A999));
  }

  void _drawBank(Canvas canvas, Size size) {
    final x = size.width * .74;
    final y = size.height * .72;
    canvas.drawOval(Rect.fromLTWH(x, y, size.width * .16, size.height * .12), Paint()..color = const Color(0xFFFFB703));
    canvas.drawCircle(Offset(x + size.width * .03, y + size.height * .045), 3.5, Paint()..color = const Color(0xFF2B2B2B));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x + size.width * .07, y + 4, size.width * .05, 5), const Radius.circular(4)),
      Paint()..color = const Color(0xFF2B2B2B),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x + 8, y + size.height * .095, size.width * .13 * bankProgress, 8), const Radius.circular(8)),
      Paint()..color = const Color(0xFF18A999),
    );
  }

  void _drawToys(Canvas canvas, Size size) {
    final ballCenter = Offset(size.width * .18, size.height * .86);
    final yarnLine = Paint()
      ..color = const Color(0xFFFFCCD5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(ballCenter, 22, Paint()..color = const Color(0xFFE63946));
    canvas.drawArc(Rect.fromCircle(center: ballCenter, radius: 18), -.8, 2.2, false, yarnLine);
    canvas.drawArc(Rect.fromCircle(center: ballCenter, radius: 12), 1.2, 2.6, false, yarnLine);

    final mx = size.width * .62;
    final my = size.height * .86;
    canvas.drawOval(Rect.fromLTWH(mx, my, 48, 24), Paint()..color = const Color(0xFF9AA5B1));
    canvas.drawCircle(Offset(mx + 9, my - 4), 7, Paint()..color = const Color(0xFF9AA5B1));
  }

  void _drawCarpet(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width * .5, size.height * .82),
      width: size.width * .44,
      height: size.height * .2,
    );
    canvas.drawOval(rect, Paint()..color = mood == CatMood.hissing ? const Color(0xFFFFCCD5) : const Color(0xFFEAF8F5));
    canvas.drawOval(
      rect.deflate(7),
      Paint()
        ..color = const Color(0xFF18A999)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant RoomPainter oldDelegate) {
    return oldDelegate.mood != mood || oldDelegate.bounce != bounce || oldDelegate.bankProgress != bankProgress;
  }
}

class CatPainter extends CustomPainter {
  CatPainter({
    required this.mood,
    required this.stage,
    required this.accessory,
    required this.bounce,
    required this.breedIndex,
  });

  final CatMood mood;
  final CatStage stage;
  final String accessory;
  final double bounce;
  final int breedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 300, size.height / 240);
    canvas.save();
    canvas.translate(size.width / 2, size.height * .56 + math.sin(bounce * math.pi) * -6);
    canvas.scale(scale);

    final body = Paint()..color = _furColor;
    final line = Paint()
      ..color = const Color(0xFF2B2B2B)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final black = Paint()..color = const Color(0xFF2B2B2B);

    if (mood == CatMood.distressed || mood == CatMood.hissing) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-110, 40, 220, 70), const Radius.circular(8)),
        Paint()..color = const Color(0xFFC78B52),
      );
    }

    final bodyHeight = stage == CatStage.kitten ? 116.0 : 136.0;
    final bodyWidth = stage == CatStage.guardian ? 172.0 : 150.0;
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 28), width: bodyWidth, height: bodyHeight), body);
    canvas.drawOval(const Rect.fromLTWH(-72, -96, 144, 128), body);
    canvas.drawPath(Path()..moveTo(-58, -74)..lineTo(-92, -132)..lineTo(-26, -96)..close(), body);
    canvas.drawPath(Path()..moveTo(58, -74)..lineTo(92, -132)..lineTo(26, -96)..close(), body);

    canvas.drawCircle(const Offset(-34, -38), 9, black);
    canvas.drawCircle(const Offset(34, -38), 9, black);
    if (mood == CatMood.hissing) {
      canvas.drawLine(const Offset(-46, -48), const Offset(-20, -34), line);
      canvas.drawLine(const Offset(46, -48), const Offset(20, -34), line);
    }
    canvas.drawOval(const Rect.fromLTWH(-8, -22, 16, 11), Paint()..color = const Color(0xFFFF8FAB));
    _drawMouth(canvas, line);
    _drawWhiskers(canvas, line);
    canvas.drawOval(const Rect.fromLTWH(-38, -4, 76, 42), Paint()..color = _bellyColor);
    _drawTail(canvas, line, body);
    _drawAccessory(canvas);
    if (mood == CatMood.distressed || mood == CatMood.hissing) _drawDebtFleas(canvas);
    canvas.restore();
  }

  void _drawMouth(Canvas canvas, Paint line) {
    if (mood == CatMood.thriving) {
      canvas.drawArc(const Rect.fromLTWH(-22, -18, 22, 22), 0, math.pi, false, line);
      canvas.drawArc(const Rect.fromLTWH(0, -18, 22, 22), 0, math.pi, false, line);
    } else if (mood == CatMood.distressed) {
      canvas.drawArc(const Rect.fromLTWH(-14, 0, 28, 20), math.pi, math.pi, false, line);
    } else if (mood == CatMood.hissing) {
      canvas.drawOval(const Rect.fromLTWH(-16, -4, 32, 22), Paint()..color = const Color(0xFF2B2B2B));
    } else {
      canvas.drawLine(const Offset(-14, -3), const Offset(14, -3), line);
    }
  }

  void _drawWhiskers(Canvas canvas, Paint line) {
    canvas.drawLine(const Offset(-18, -18), const Offset(-72, -30), line);
    canvas.drawLine(const Offset(-18, -10), const Offset(-76, -8), line);
    canvas.drawLine(const Offset(18, -18), const Offset(72, -30), line);
    canvas.drawLine(const Offset(18, -10), const Offset(76, -8), line);
  }

  void _drawTail(Canvas canvas, Paint line, Paint body) {
    final tail = Path()..moveTo(68, 40)..cubicTo(140, 16, 120, -46, 82, -16);
    canvas.drawPath(tail, line..strokeWidth = 26);
    canvas.drawPath(tail, body..style = PaintingStyle.stroke..strokeWidth = 18..strokeCap = StrokeCap.round);
    body.style = PaintingStyle.fill;
    line.strokeWidth = 4;
  }

  void _drawAccessory(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-48, -6, 96, 14), const Radius.circular(99)),
      Paint()..color = _accessoryColor,
    );
    if (accessory.contains('crown') || stage == CatStage.guardian) {
      canvas.drawPath(
        Path()..moveTo(-34, -100)..lineTo(-22, -128)..lineTo(0, -104)..lineTo(22, -128)..lineTo(34, -100)..close(),
        Paint()..color = const Color(0xFFFFB703),
      );
    }
  }

  void _drawDebtFleas(Canvas canvas) {
    final flea = Paint()..color = const Color(0xFF5A3825);
    for (final offset in const [Offset(-50, -70), Offset(42, -72), Offset(-58, 20), Offset(52, 28)]) {
      canvas.drawCircle(offset, 4, flea);
    }
  }

  Color get _furColor {
    if (mood == CatMood.distressed || mood == CatMood.hissing) return const Color(0xFFC7B6A1);
    return switch (breedIndex) {
      1 => const Color(0xFF30343F),
      2 => const Color(0xFFE89245),
      3 => const Color(0xFFE9DDC7),
      _ => const Color(0xFFFFC857),
    };
  }

  Color get _bellyColor => breedIndex == 1 ? Colors.white : const Color(0xFFFFF2D7);

  Color get _accessoryColor {
    if (accessory.contains('cape')) return const Color(0xFF7C3AED);
    if (accessory.contains('bowtie')) return const Color(0xFF4361EE);
    if (accessory.contains('crown')) return const Color(0xFFFFB703);
    return const Color(0xFFD4AF37);
  }

  @override
  bool shouldRepaint(covariant CatPainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.stage != stage ||
        oldDelegate.accessory != accessory ||
        oldDelegate.bounce != bounce ||
        oldDelegate.breedIndex != breedIndex;
  }
}

class HeartBurstPainter extends CustomPainter {
  HeartBurstPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFF5D8F).withValues(alpha: 1 - progress);
    for (var i = 0; i < 7; i++) {
      final angle = (math.pi * 2 / 7) * i;
      final radius = 34 + progress * 86;
      final center = Offset(
        size.width / 2 + math.cos(angle) * radius,
        size.height / 2 + math.sin(angle) * radius - progress * 24,
      );
      canvas.drawCircle(center, 7 + progress * 5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant HeartBurstPainter oldDelegate) => oldDelegate.progress != progress;
}
