import 'package:flutter/material.dart';
import '../theme.dart';

/// Pulsante grande con effetto metallo rosso lucido.
class MetalButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onPressed;

  const MetalButton({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.metalRed,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: AppColors.highlight.withValues(alpha: 0.45), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: AppColors.red.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onPressed,
          child: Stack(
            children: [
              // Riflesso lucido sulla metà superiore
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.topCenter,
                  heightFactor: 0.5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(22)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.22),
                          Colors.white.withValues(alpha: 0.0)
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                child: Row(
                  children: [
                    Icon(icon, size: 44, color: Colors.white),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label,
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(subtitle,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
