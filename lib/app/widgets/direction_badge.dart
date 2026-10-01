import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DirectionBadge extends StatelessWidget {
  final String direction;
  final bool compact;

  const DirectionBadge({super.key, required this.direction, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, icon, label) = switch (direction) {
      'BULLISH' => (AppColors.bullish, AppColors.bullishBg, Icons.trending_up_rounded, 'BULLISH'),
      'BEARISH' => (AppColors.bearish, AppColors.bearishBg, Icons.trending_down_rounded, 'BEARISH'),
      'HIGH_UNCERTAINTY' => (AppColors.uncertainty, AppColors.uncertaintyBg, Icons.help_outline_rounded, 'UNCERTAIN'),
      _ => (AppColors.neutral, AppColors.neutralBg, Icons.trending_flat_rounded, 'NEUTRAL'),
    };

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: compact ? 14 : 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
