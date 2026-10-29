import 'package:flutter/material.dart';

/// Original elephant companion, drawn locally; no remote images or font icons.
class ElephantBuddy extends StatelessWidget {
  const ElephantBuddy({this.size = 88, super.key});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _ElephantPainter()),
    ),
  );
}

class _ElephantPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    final paint = Paint()..color = const Color(0xFFAAA4FF);
    canvas.drawOval(const Rect.fromLTWH(5, 28, 35, 48), paint);
    canvas.drawOval(const Rect.fromLTWH(60, 28, 35, 48), paint);
    paint.color = const Color(0xFF746BE8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(24, 16, 52, 66),
        const Radius.circular(25),
      ),
      paint,
    );
    final trunk = Path()
      ..moveTo(53, 57)
      ..cubicTo(53, 76, 46, 91, 65, 88)
      ..cubicTo(76, 86, 77, 76, 72, 74);
    canvas.drawPath(
      trunk,
      Paint()
        ..color = const Color(0xFF746BE8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round,
    );
    paint.color = const Color(0xFF242047);
    canvas.drawCircle(const Offset(38, 44), 3, paint);
    canvas.drawCircle(const Offset(62, 44), 3, paint);
    paint.color = const Color(0xFFFFB5AC);
    canvas.drawOval(const Rect.fromLTWH(28, 51, 10, 6), paint);
    canvas.drawOval(const Rect.fromLTWH(64, 51, 10, 6), paint);
    paint.color = const Color(0xFFFFCD62);
    canvas.drawCircle(const Offset(78, 15), 8, paint);
    canvas.drawPath(
      Path()
        ..moveTo(78, 9)
        ..lineTo(78, 21)
        ..moveTo(72, 15)
        ..lineTo(84, 15),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LiftButton extends StatelessWidget {
  const LiftButton({
    required this.label,
    required this.onPressed,
    this.icon = Icons.play_arrow_rounded,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: onPressed == null
            ? []
            : [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: .35),
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    ),
  );
}

class MetricPill extends StatelessWidget {
  const MetricPill({required this.icon, required this.label, super.key});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
      ],
    ),
  );
}
