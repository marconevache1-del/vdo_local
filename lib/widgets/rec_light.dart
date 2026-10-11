import 'package:flutter/material.dart';
import '../theme.dart';

/// Luce rossa lampeggiante: indica che la trasmissione è in corso.
class RecLight extends StatefulWidget {
  final double size;
  const RecLight({super.key, this.size = 28});

  @override
  State<RecLight> createState() => _RecLightState();
}

class _RecLightState extends State<RecLight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              center: Alignment(-0.3, -0.3),
              colors: [AppColors.highlight, AppColors.redBright, AppColors.redDark],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.redBright.withValues(alpha: 0.2 + 0.6 * t),
                blurRadius: 8 + 22 * t,
                spreadRadius: 1 + 5 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}
