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
    required this.level,
    required this.activity,
    required this.showHearts,
    required this.heartProgress,
  });

  final CatMood mood;
  final CatStage stage;
  final String accessory;
  final double bounce;
  final int breedIndex;
  final int level;
  final CatActivity activity;
  final bool showHearts;
  final double heartProgress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final roomWidth = constraints.maxWidth;
        final catWidth = (roomWidth * .46).clamp(170.0, 245.0).toDouble();
        final catAlignment = _catAlignment(activity);
        final catScale = _catScale(activity);
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
                      level: level,
                      activity: activity,
                      bankProgress: mood == CatMood.thriving
                          ? 1
                          : mood == CatMood.distressed || mood == CatMood.hissing
                              ? .35
                              : .68,
                    ),
                  ),
                ),
                AnimatedAlign(
                  duration: const Duration(milliseconds: 950),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment(catAlignment.x, (catAlignment.y + .27).clamp(-1.0, 1.0).toDouble()),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 950),
                    curve: Curves.easeInOutCubic,
                    scale: catScale,
                    child: SizedBox(
                      width: catWidth * .72,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x55000000),
                              blurRadius: 34,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: SizedBox(height: 8),
                      ),
                    ),
                  ),
                ),
                AnimatedAlign(
                  duration: const Duration(milliseconds: 950),
                  curve: Curves.easeInOutCubic,
                  alignment: catAlignment,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 950),
                    curve: Curves.easeInOutCubic,
                    scale: catScale,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, .0015)
                        ..rotateX(-.06)
                        ..rotateZ(_catLean(activity, bounce)),
                      child: SizedBox(
                        width: catWidth,
                        height: catWidth * .8,
                        child: CustomPaint(
                          painter: CatPainter(
                            mood: mood,
                            stage: stage,
                            accessory: accessory,
                            bounce: bounce,
                            breedIndex: breedIndex,
                            activity: activity,
                          ),
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

  Alignment _catAlignment(CatActivity activity) {
    return switch (activity) {
      CatActivity.sleep => const Alignment(-.62, .36),
      CatActivity.eat => const Alignment(-.18, .78),
      CatActivity.play => const Alignment(-.52, .78),
      CatActivity.idle => const Alignment(.02, .56),
    };
  }

  double _catScale(CatActivity activity) {
    return switch (activity) {
      CatActivity.sleep => .72,
      CatActivity.eat => .82,
      CatActivity.play => .9,
      CatActivity.idle => .95,
    };
  }

  double _catLean(CatActivity activity, double bounce) {
    return switch (activity) {
      CatActivity.play => math.sin(bounce * math.pi * 2) * .04,
      CatActivity.eat => -.03,
      CatActivity.sleep => .02,
      CatActivity.idle => math.sin(bounce * math.pi * 2) * .012,
    };
  }
}

class RoomPainter extends CustomPainter {
  RoomPainter({
    required this.mood,
    required this.bounce,
    required this.level,
    required this.activity,
    required this.bankProgress,
  });

  final CatMood mood;
  final double bounce;
  final int level;
  final CatActivity activity;
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

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFAEC), Color(0xFFFFE1C6)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(_quad(0, 0, size.width, 0, backWall.right, backWall.top, backWall.left, backWall.top), Paint()..color = const Color(0xFFFFFDF4));
    canvas.drawPath(
      _quad(0, 0, backWall.left, backWall.top, backWall.left, backWall.bottom, 0, size.height),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFE4C7), Color(0xFFFFCFA8)],
        ).createShader(Rect.fromLTWH(0, 0, backWall.left, size.height)),
    );
    canvas.drawPath(
      _quad(size.width, 0, backWall.right, backWall.top, backWall.right, backWall.bottom, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFECD8), Color(0xFFFFD4B1)],
        ).createShader(Rect.fromLTWH(backWall.right, 0, size.width - backWall.right, size.height)),
    );
    canvas.drawPath(
      _quad(0, size.height, backWall.left, backWall.bottom, backWall.right, backWall.bottom, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD8B27D), Color(0xFFB67E45)],
        ).createShader(Rect.fromLTWH(0, backWall.bottom, size.width, size.height - backWall.bottom)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(backWall, const Radius.circular(10)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8D8), Color(0xFFFFE0A9)],
        ).createShader(backWall),
    );
    _drawRoomLight(canvas, size);
    _drawBaseboard(canvas, size, backWall);

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
    if (level >= 2) _drawCarpet(canvas, size);
    if (level >= 1) _drawFoodBowl(canvas, size);
    if (level >= 3) _drawBed(canvas, size);
    if (level >= 4) _drawTable(canvas, size);
    if (level >= 6) _drawBank(canvas, size);
    if (level >= 5) _drawToys(canvas, size);
    if (level >= 8) _drawWindow(canvas, size);
    if (level >= 9) _drawScratchPost(canvas, size);
    if (level >= 12) _drawLamp(canvas, size);
    if (level >= 16) _drawCrownStand(canvas, size);
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
    final glow = Rect.fromCenter(
      center: Offset(size.width * .52, size.height * .78),
      width: size.width * .72,
      height: size.height * .32,
    );
    canvas.drawOval(
      glow,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: .26), Colors.white.withValues(alpha: 0)],
        ).createShader(glow),
    );
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

  void _drawRoomLight(Canvas canvas, Size size) {
    final sun = Rect.fromCircle(center: Offset(size.width * .74, size.height * .22), radius: size.width * .34);
    canvas.drawOval(
      sun,
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.white.withValues(alpha: .36), Colors.white.withValues(alpha: 0)],
        ).createShader(sun),
    );
  }

  void _drawBaseboard(Canvas canvas, Size size, Rect backWall) {
    final rail = Paint()
      ..color = const Color(0xAA9C6644)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(backWall.left + 8, backWall.bottom), Offset(backWall.right - 8, backWall.bottom), rail);
    canvas.drawLine(Offset(6, size.height - 4), Offset(backWall.left + 8, backWall.bottom), rail..strokeWidth = 4);
    canvas.drawLine(Offset(size.width - 6, size.height - 4), Offset(backWall.right - 8, backWall.bottom), rail);
  }

  void _drawGroundShadow(Canvas canvas, Offset center, double width, double height) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: width, height: height),
      Paint()
        ..shader = RadialGradient(
          colors: [Colors.black.withValues(alpha: .2), Colors.black.withValues(alpha: 0)],
        ).createShader(Rect.fromCenter(center: center, width: width, height: height)),
    );
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

    if (level >= 5) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(size.width * .1, size.height * .28, size.width * .24, 12), const Radius.circular(6)),
        Paint()..color = const Color(0xFF8B5E34),
      );
      canvas.drawCircle(Offset(size.width * .18, size.height * .24), 14, Paint()..color = const Color(0xFFFFB703));
      canvas.drawCircle(Offset(size.width * .27, size.height * .235), 10, Paint()..color = const Color(0xFF7C3AED));
    }
  }

  void _drawBed(Canvas canvas, Size size) {
    final x = size.width * .05;
    final y = size.height * .56;
    final w = size.width * .3;
    final h = size.height * .16;
    _drawGroundShadow(canvas, Offset(x + w * .52, y + h * .76), w * 1.05, h * .8);
    canvas.drawPath(
      Path()
        ..moveTo(x, y + h * .12)
        ..lineTo(x + w * .14, y - h * .48)
        ..lineTo(x + w, y - h * .32)
        ..lineTo(x + w * .9, y + h * .44)
        ..lineTo(x + w * .04, y + h)
        ..close(),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B74FF), Color(0xFF2842B5)],
        ).createShader(Rect.fromLTWH(x, y - h * .5, w, h * 1.5)),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x + w * .16, y + h * .04, w * .7, h * .48), const Radius.circular(12)),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFFFE3BC), Color(0xFFECA86F)]).createShader(Rect.fromLTWH(x, y, w, h)),
    );
  }

  void _drawTable(Canvas canvas, Size size) {
    final x = size.width * .72;
    final y = size.height * .52;
    final w = size.width * .2;
    final h = size.height * .14;
    _drawGroundShadow(canvas, Offset(x + w * .46, y + h * 1.18), w * .95, h * .55);
    canvas.drawPath(
      Path()
        ..moveTo(x, y)
        ..lineTo(x + w, y + 8)
        ..lineTo(x + w * .86, y + h * .35)
        ..lineTo(x - w * .08, y + h * .25)
        ..close(),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFC18152), Color(0xFF75441F)]).createShader(Rect.fromLTWH(x, y, w, h)),
    );
    final leg = Paint()..color = const Color(0xFF6F4518);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + w * .05, y + h * .18, 10, h), const Radius.circular(4)), leg);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + w * .78, y + h * .25, 10, h), const Radius.circular(4)), leg);
    canvas.drawCircle(Offset(x + w * .42, y - 4 + math.sin(bounce * math.pi) * -2), 15, Paint()..color = const Color(0xFF18A999));
  }

  void _drawBank(Canvas canvas, Size size) {
    final x = size.width * .74;
    final y = size.height * .72;
    final bankRect = Rect.fromLTWH(x, y, size.width * .16, size.height * .12);
    _drawGroundShadow(canvas, bankRect.center + const Offset(0, 18), bankRect.width * 1.05, bankRect.height * .55);
    canvas.drawOval(
      bankRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD166), Color(0xFFE89B00)],
        ).createShader(bankRect),
    );
    canvas.drawOval(
      Rect.fromLTWH(x + size.width * .035, y + size.height * .015, size.width * .055, size.height * .035),
      Paint()..color = Colors.white.withValues(alpha: .28),
    );
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
    final ballCenter = Offset(
      size.width * .18 + (activity == CatActivity.play ? math.sin(bounce * math.pi * 2) * 12 : 0),
      size.height * .86,
    );
    final yarnLine = Paint()
      ..color = const Color(0xFFFFCCD5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    _drawGroundShadow(canvas, ballCenter + const Offset(0, 18), 58, 16);
    canvas.drawCircle(
      ballCenter,
      22,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.35, -.45),
          colors: [Color(0xFFFF8FA3), Color(0xFFE63946), Color(0xFF8A1230)],
        ).createShader(Rect.fromCircle(center: ballCenter, radius: 22)),
    );
    canvas.drawArc(Rect.fromCircle(center: ballCenter, radius: 18), -.8, 2.2, false, yarnLine);
    canvas.drawArc(Rect.fromCircle(center: ballCenter, radius: 12), 1.2, 2.6, false, yarnLine);

    if (level < 11) return;
    final mx = size.width * .62;
    final my = size.height * .86;
    canvas.drawOval(Rect.fromLTWH(mx, my, 48, 24), Paint()..color = const Color(0xFF9AA5B1));
    canvas.drawCircle(Offset(mx + 9, my - 4), 7, Paint()..color = const Color(0xFF9AA5B1));
  }

  void _drawFoodBowl(Canvas canvas, Size size) {
    final x = size.width * .34;
    final y = size.height * .88;
    _drawGroundShadow(canvas, Offset(x, y + 10), 72, 16);
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 58, height: 18), Paint()..color = const Color(0xFF263D96));
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y - 3), width: 62, height: 22), Paint()..color = const Color(0xFF4361EE));
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y - 7), width: 44, height: 12), Paint()..color = activity == CatActivity.eat ? const Color(0xFFFFB703) : Colors.white);
  }

  void _drawWindow(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * .68, size.height * .12, size.width * .16, size.height * .18),
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFFBDE0FE));
    final windowLine = Paint()
      ..color = Colors.white
      ..strokeWidth = 3;
    canvas.drawLine(Offset(rect.outerRect.center.dx, rect.outerRect.top), Offset(rect.outerRect.center.dx, rect.outerRect.bottom), windowLine);
    canvas.drawLine(Offset(rect.outerRect.left, rect.outerRect.center.dy), Offset(rect.outerRect.right, rect.outerRect.center.dy), windowLine);
  }

  void _drawScratchPost(Canvas canvas, Size size) {
    final x = size.width * .09;
    final y = size.height * .72;
    _drawGroundShadow(canvas, Offset(x + 10, y + 99), 90, 24);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 20, 92), const Radius.circular(8)), Paint()..color = const Color(0xFFB08968));
    canvas.drawOval(Rect.fromCenter(center: Offset(x + 10, y + 94), width: 72, height: 18), Paint()..color = const Color(0xFF7F5539));
  }

  void _drawLamp(Canvas canvas, Size size) {
    final x = size.width * .9;
    final y = size.height * .44;
    final lampGlow = Rect.fromCircle(center: Offset(x, y + 24), radius: 76);
    canvas.drawOval(
      lampGlow,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFFFD166).withValues(alpha: .28), const Color(0xFFFFD166).withValues(alpha: 0)],
        ).createShader(lampGlow),
    );
    final pole = Paint()
      ..color = const Color(0xFF6B7280)
      ..strokeWidth = 5;
    canvas.drawLine(Offset(x, y), Offset(x, y + 120), pole);
    canvas.drawPath(
      Path()..moveTo(x - 34, y)..lineTo(x + 34, y)..lineTo(x + 22, y + 38)..lineTo(x - 22, y + 38)..close(),
      Paint()..color = const Color(0xFFFFD166),
    );
  }

  void _drawCrownStand(Canvas canvas, Size size) {
    final x = size.width * .53;
    final y = size.height * .32;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 72, 12), const Radius.circular(6)), Paint()..color = const Color(0xFF9C6644));
    canvas.drawPath(
      Path()..moveTo(x + 14, y - 4)..lineTo(x + 24, y - 28)..lineTo(x + 36, y - 8)..lineTo(x + 48, y - 28)..lineTo(x + 58, y - 4)..close(),
      Paint()..color = const Color(0xFFFFB703),
    );
  }

  void _drawCarpet(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width * .5, size.height * .82),
      width: size.width * .44,
      height: size.height * .2,
    );
    _drawGroundShadow(canvas, rect.center + const Offset(0, 10), rect.width * .98, rect.height * .72);
    canvas.drawOval(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: mood == CatMood.hissing
              ? const [Color(0xFFFFD8DF), Color(0xFFFF8FA3)]
              : const [Color(0xFFF0FFFC), Color(0xFFB8EFE5)],
        ).createShader(rect),
    );
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
    return oldDelegate.mood != mood ||
        oldDelegate.bounce != bounce ||
        oldDelegate.level != level ||
        oldDelegate.activity != activity ||
        oldDelegate.bankProgress != bankProgress;
  }
}

class CatPainter extends CustomPainter {
  CatPainter({
    required this.mood,
    required this.stage,
    required this.accessory,
    required this.bounce,
    required this.breedIndex,
    required this.activity,
  });

  final CatMood mood;
  final CatStage stage;
  final String accessory;
  final double bounce;
  final int breedIndex;
  final CatActivity activity;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 300, size.height / 240);
    canvas.save();
    canvas.translate(size.width / 2, size.height * .56 + math.sin(bounce * math.pi) * -6);
    canvas.scale(scale);

    final bodyRect = Rect.fromCenter(center: const Offset(0, 8), width: 220, height: 250);
    final body = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.38, -.45),
        radius: 1.12,
        colors: [_furHighlightColor, _furColor, _furShadowColor],
        stops: const [.05, .58, 1],
      ).createShader(bodyRect);
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

    final sleeping = activity == CatActivity.sleep;
    final bodyHeight = sleeping ? 92.0 : (stage == CatStage.kitten ? 116.0 : 136.0);
    final bodyWidth = sleeping ? 176.0 : (stage == CatStage.guardian ? 172.0 : 150.0);
    final bodyOval = Rect.fromCenter(center: const Offset(0, 28), width: bodyWidth, height: bodyHeight);
    final headOval = Rect.fromLTWH(sleeping ? -96 : -72, sleeping ? -70 : -96, sleeping ? 120 : 144, sleeping ? 92 : 128);
    canvas.drawOval(bodyOval.shift(const Offset(8, 10)), Paint()..color = Colors.black.withValues(alpha: .1));
    canvas.drawPath(
      Path()..moveTo(-58, -74)..lineTo(-92, -132)..lineTo(-26, -96)..close(),
      Paint()..color = _furShadowColor,
    );
    canvas.drawPath(
      Path()..moveTo(58, -74)..lineTo(92, -132)..lineTo(26, -96)..close(),
      Paint()..color = _furShadowColor,
    );
    canvas.drawPath(Path()..moveTo(-58, -74)..lineTo(-92, -132)..lineTo(-26, -96)..close(), body);
    canvas.drawPath(Path()..moveTo(58, -74)..lineTo(92, -132)..lineTo(26, -96)..close(), body);
    _drawInnerEars(canvas);
    canvas.drawOval(bodyOval, body);
    canvas.drawOval(headOval, body);
    _drawFurHighlights(canvas, bodyOval, headOval);

    if (sleeping) {
      canvas.drawArc(const Rect.fromLTWH(-66, -42, 26, 12), 0, math.pi, false, line);
      canvas.drawArc(const Rect.fromLTWH(-24, -42, 26, 12), 0, math.pi, false, line);
      _drawSleepMarks(canvas);
    } else {
      canvas.drawCircle(const Offset(-34, -38), 9, black);
      canvas.drawCircle(const Offset(34, -38), 9, black);
    }
    if (mood == CatMood.hissing) {
      canvas.drawLine(const Offset(-46, -48), const Offset(-20, -34), line);
      canvas.drawLine(const Offset(46, -48), const Offset(20, -34), line);
    }
    canvas.drawOval(const Rect.fromLTWH(-8, -22, 16, 11), Paint()..color = const Color(0xFFFF8FAB));
    if (!sleeping) _drawMouth(canvas, line);
    _drawWhiskers(canvas, line);
    _drawTail(canvas, line, body);
    canvas.drawOval(
      const Rect.fromLTWH(-38, -4, 76, 42),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.25, -.45),
          colors: [Colors.white, Color(0xFFFFF2D7)],
        ).createShader(const Rect.fromLTWH(-38, -4, 76, 42)),
    );
    _drawPaws(canvas);
    _drawCheeks(canvas);
    _drawAccessory(canvas);
    if (activity == CatActivity.eat) _drawSnack(canvas);
    if (activity == CatActivity.play) _drawPlaySpark(canvas);
    if (mood == CatMood.distressed || mood == CatMood.hissing) _drawDebtFleas(canvas);
    canvas.restore();
  }

  void _drawInnerEars(Canvas canvas) {
    final inner = Paint()..color = const Color(0xFFFFA9B8).withValues(alpha: .78);
    canvas.drawPath(Path()..moveTo(-58, -86)..lineTo(-79, -120)..lineTo(-40, -96)..close(), inner);
    canvas.drawPath(Path()..moveTo(58, -86)..lineTo(79, -120)..lineTo(40, -96)..close(), inner);
  }

  void _drawFurHighlights(Canvas canvas, Rect bodyOval, Rect headOval) {
    final shine = Paint()..color = Colors.white.withValues(alpha: breedIndex == 1 ? .1 : .22);
    canvas.drawOval(Rect.fromLTWH(headOval.left + 28, headOval.top + 18, headOval.width * .32, headOval.height * .18), shine);
    canvas.drawOval(Rect.fromLTWH(bodyOval.left + 34, bodyOval.top + 22, bodyOval.width * .25, bodyOval.height * .18), shine);

    final shade = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withValues(alpha: .12);
    canvas.drawArc(bodyOval.deflate(8), -.2, 1.3, false, shade);
  }

  void _drawPaws(Canvas canvas) {
    final pawPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.35, -.45),
        colors: [_furHighlightColor, _furColor, _furShadowColor],
      ).createShader(const Rect.fromLTWH(-70, 60, 140, 48));
    for (final rect in const [
      Rect.fromLTWH(-58, 70, 42, 28),
      Rect.fromLTWH(16, 70, 42, 28),
    ]) {
      canvas.drawOval(rect.shift(const Offset(4, 5)), Paint()..color = Colors.black.withValues(alpha: .08));
      canvas.drawOval(rect, pawPaint);
      canvas.drawArc(
        rect.deflate(8),
        .2,
        math.pi - .4,
        false,
        Paint()
          ..color = Colors.black.withValues(alpha: .22)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawCheeks(Canvas canvas) {
    final cheek = Paint()..color = const Color(0xFFFF8FAB).withValues(alpha: .18);
    canvas.drawCircle(const Offset(-48, -20), 13, cheek);
    canvas.drawCircle(const Offset(48, -20), 13, cheek);
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
    final normalizedAccessory = accessory.trim().toLowerCase();
    if (normalizedAccessory.isEmpty || normalizedAccessory == 'no item' || normalizedAccessory == 'no item yet') return;

    if (normalizedAccessory.contains('cape') || normalizedAccessory.contains('cloak')) {
      _drawCape(canvas);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-48, -6, 96, 14), const Radius.circular(99)),
      Paint()..color = _accessoryColor,
    );
    if (normalizedAccessory.contains('collar') || normalizedAccessory.contains('bell') || normalizedAccessory.contains('gold')) {
      _drawCollarBell(canvas);
    }
    if (normalizedAccessory.contains('ribbon') || normalizedAccessory.contains('bandana') || normalizedAccessory.contains('scarf')) {
      _drawNeckTie(canvas, normalizedAccessory.contains('scarf') ? const Color(0xFF18A999) : const Color(0xFFE63946));
    }
    if (normalizedAccessory.contains('bowtie')) {
      _drawBowtie(canvas);
    }
    if (normalizedAccessory.contains('glasses')) {
      _drawGlasses(canvas);
    }
    if (normalizedAccessory.contains('backpack') || normalizedAccessory.contains('hoodie')) {
      _drawPack(canvas);
    }
    if (normalizedAccessory.contains('medal') || normalizedAccessory.contains('moon')) {
      _drawCharm(canvas, normalizedAccessory.contains('moon') ? const Color(0xFF18A999) : const Color(0xFFFFB703));
    }
    if (normalizedAccessory.contains('crown') || stage == CatStage.guardian) {
      _drawCrown(canvas);
    }
  }

  void _drawCape(Canvas canvas) {
    final cape = Path()
      ..moveTo(-52, -2)
      ..quadraticBezierTo(-82, 50, -62, 102)
      ..quadraticBezierTo(0, 130, 62, 102)
      ..quadraticBezierTo(82, 50, 52, -2)
      ..close();
    canvas.drawPath(cape, Paint()..color = const Color(0xFF7C3AED).withValues(alpha: .82));
    canvas.drawPath(
      cape,
      Paint()
        ..color = const Color(0xFFFFD166)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawCollarBell(Canvas canvas) {
    canvas.drawCircle(const Offset(0, 10), 10, Paint()..color = const Color(0xFFFFB703));
    canvas.drawCircle(const Offset(0, 10), 4, Paint()..color = const Color(0xFF7F5539));
    canvas.drawLine(
      const Offset(-28, 1),
      const Offset(28, 1),
      Paint()
        ..color = Colors.white.withValues(alpha: .6)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawBowtie(Canvas canvas) {
    final bowPaint = Paint()..color = const Color(0xFF4361EE);
    canvas.drawPath(
      Path()
        ..moveTo(-5, 2)
        ..lineTo(-44, -18)
        ..lineTo(-44, 20)
        ..close(),
      bowPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(5, 2)
        ..lineTo(44, -18)
        ..lineTo(44, 20)
        ..close(),
      bowPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-9, -8, 18, 20), const Radius.circular(5)),
      Paint()..color = const Color(0xFFFFB703),
    );
  }

  void _drawNeckTie(Canvas canvas, Color color) {
    final paint = Paint()..color = color;
    canvas.drawPath(
      Path()
        ..moveTo(26, 2)
        ..lineTo(62, 8)
        ..lineTo(48, 26)
        ..lineTo(22, 12)
        ..close(),
      paint,
    );
    canvas.drawCircle(const Offset(42, 11), 5, Paint()..color = Colors.white.withValues(alpha: .7));
  }

  void _drawGlasses(Canvas canvas) {
    final frame = Paint()
      ..color = const Color(0xFF2B2B2B)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-52, -54, 34, 24), const Radius.circular(8)), frame);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(18, -54, 34, 24), const Radius.circular(8)), frame);
    canvas.drawLine(const Offset(-18, -42), const Offset(18, -42), frame);
  }

  void _drawPack(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(48, 14, 38, 58), const Radius.circular(12)),
      Paint()..color = const Color(0xFF5A3825),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(56, 24, 22, 16), const Radius.circular(5)),
      Paint()..color = const Color(0xFFFFD166),
    );
  }

  void _drawCharm(Canvas canvas, Color color) {
    final line = Paint()
      ..color = const Color(0xFFFFF2D7)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(0, 4), const Offset(0, 25), line);
    canvas.drawCircle(const Offset(0, 30), 11, Paint()..color = color);
    canvas.drawCircle(const Offset(5, 26), 7, Paint()..color = const Color(0xFFFFF2D7).withValues(alpha: .45));
  }

  void _drawCrown(Canvas canvas) {
    final crown = Paint()..color = const Color(0xFFFFB703);
    canvas.drawPath(
      Path()
        ..moveTo(-38, -98)
        ..lineTo(-26, -132)
        ..lineTo(-8, -108)
        ..lineTo(0, -136)
        ..lineTo(8, -108)
        ..lineTo(26, -132)
        ..lineTo(38, -98)
        ..close(),
      crown,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-38, -102, 76, 12), const Radius.circular(5)),
      crown,
    );
    for (final offset in const [Offset(-26, -132), Offset(0, -136), Offset(26, -132)]) {
      canvas.drawCircle(offset, 5, Paint()..color = const Color(0xFFE63946));
    }
  }

  void _drawDebtFleas(Canvas canvas) {
    final flea = Paint()..color = const Color(0xFF5A3825);
    for (final offset in const [Offset(-50, -70), Offset(42, -72), Offset(-58, 20), Offset(52, 28)]) {
      canvas.drawCircle(offset, 4, flea);
    }
  }

  void _drawSleepMarks(Canvas canvas) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Zzz',
        style: TextStyle(color: Color(0xFF4361EE), fontSize: 24, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, const Offset(46, -116));
  }

  void _drawSnack(Canvas canvas) {
    canvas.drawCircle(const Offset(-4, -6), 6, Paint()..color = const Color(0xFFFFB703));
    canvas.drawCircle(const Offset(12, -4), 5, Paint()..color = const Color(0xFFFFB703));
  }

  void _drawPlaySpark(Canvas canvas) {
    final spark = Paint()
      ..color = const Color(0xFF7C3AED)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-102, -52), const Offset(-82, -72), spark);
    canvas.drawLine(const Offset(-102, -72), const Offset(-82, -52), spark);
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

  Color get _furHighlightColor {
    if (mood == CatMood.distressed || mood == CatMood.hissing) return const Color(0xFFE7D6C2);
    return switch (breedIndex) {
      1 => const Color(0xFF686E82),
      2 => const Color(0xFFFFBE7D),
      3 => const Color(0xFFFFF4DE),
      _ => const Color(0xFFFFE08B),
    };
  }

  Color get _furShadowColor {
    if (mood == CatMood.distressed || mood == CatMood.hissing) return const Color(0xFF8E7D68);
    return switch (breedIndex) {
      1 => const Color(0xFF151720),
      2 => const Color(0xFF9E4D16),
      3 => const Color(0xFFB6A98D),
      _ => const Color(0xFFC98413),
    };
  }

  Color get _accessoryColor {
    final normalizedAccessory = accessory.toLowerCase();
    if (normalizedAccessory.contains('cape') || normalizedAccessory.contains('cloak')) return const Color(0xFF7C3AED);
    if (normalizedAccessory.contains('bowtie') || normalizedAccessory.contains('glasses')) return const Color(0xFF4361EE);
    if (normalizedAccessory.contains('crown') || normalizedAccessory.contains('bell') || normalizedAccessory.contains('medal')) return const Color(0xFFFFB703);
    if (normalizedAccessory.contains('ribbon') || normalizedAccessory.contains('bandana')) return const Color(0xFFE63946);
    if (normalizedAccessory.contains('scarf') || normalizedAccessory.contains('moon')) return const Color(0xFF18A999);
    if (normalizedAccessory.contains('backpack') || normalizedAccessory.contains('hoodie')) return const Color(0xFF5A3825);
    return const Color(0xFFD4AF37);
  }

  @override
  bool shouldRepaint(covariant CatPainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.stage != stage ||
        oldDelegate.accessory != accessory ||
        oldDelegate.bounce != bounce ||
        oldDelegate.breedIndex != breedIndex ||
        oldDelegate.activity != activity;
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
