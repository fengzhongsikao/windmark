import 'package:flutter/material.dart';

import 'package:windmark/app/theme.dart';

class HexagramFigure extends StatelessWidget {
  const HexagramFigure({
    super.key,
    required this.lines,
    this.changingIndexes = const <int>{},
    this.width = 120,
  });

  final List<bool> lines;
  final Set<int> changingIndexes;
  final double width;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, width * 0.92),
      painter: _HexagramPainter(
        lines: lines,
        changingIndexes: changingIndexes,
      ),
    );
  }
}

class YaoStroke extends StatelessWidget {
  const YaoStroke({
    super.key,
    required this.yang,
    required this.changing,
  });

  final bool yang;
  final bool changing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(
              changing ? (yang ? '○' : '×') : '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.cinnabar,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: CustomPaint(
              painter: _StrokePainter(yang: yang),
            ),
          ),
        ],
      ),
    );
  }
}

class _HexagramPainter extends CustomPainter {
  const _HexagramPainter({
    required this.lines,
    required this.changingIndexes,
  });

  final List<bool> lines;
  final Set<int> changingIndexes;

  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()..color = AppColors.ink;
    final markPaint = Paint()
      ..color = AppColors.cinnabar
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final slot = size.height / 6;
    final barHeight = slot * 0.28;
    final barWidth = size.width * 0.76;

    for (var visual = 0; visual < 6; visual++) {
      final index = 5 - visual;
      final top = visual * slot + (slot - barHeight) / 2;
      if (lines[index]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, top, barWidth, barHeight),
            const Radius.circular(2),
          ),
          barPaint,
        );
      } else {
        final segment = barWidth * 0.42;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, top, segment, barHeight),
            const Radius.circular(2),
          ),
          barPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(barWidth - segment, top, segment, barHeight),
            const Radius.circular(2),
          ),
          barPaint,
        );
      }
      if (changingIndexes.contains(index)) {
        final center = Offset(barWidth + (size.width - barWidth) / 2, top + barHeight / 2);
        if (lines[index]) {
          canvas.drawCircle(center, slot * 0.16, markPaint);
        } else {
          final arm = slot * 0.14;
          canvas.drawLine(center + Offset(-arm, -arm), center + Offset(arm, arm), markPaint);
          canvas.drawLine(center + Offset(-arm, arm), center + Offset(arm, -arm), markPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HexagramPainter oldDelegate) => true;
}

class _StrokePainter extends CustomPainter {
  const _StrokePainter({required this.yang});

  final bool yang;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.ink;
    final height = size.height * 0.36;
    final top = (size.height - height) / 2;
    if (yang) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, top, size.width, height),
          const Radius.circular(2),
        ),
        paint,
      );
      return;
    }
    final segment = size.width * 0.42;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, top, segment, height),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - segment, top, segment, height),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) {
    return oldDelegate.yang != yang;
  }
}
