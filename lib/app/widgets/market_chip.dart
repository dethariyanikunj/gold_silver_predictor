import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MarketChip extends StatelessWidget {
  final String label;
  final String value;
  final double? change;

  const MarketChip({
    super.key,
    required this.label,
    required this.value,
    this.change,
  });

  @override
  Widget build(BuildContext context) {
    Color changeColor = AppColors.textSecondary;
    if (change != null) {
      changeColor = change! > 0 ? AppColors.bullish : change! < 0 ? AppColors.bearish : AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          if (change != null)
            Text(
              '${change! >= 0 ? '+' : ''}${change!.toStringAsFixed(2)}%',
              style: TextStyle(color: changeColor, fontSize: 10),
            ),
        ],
      ),
    );
  }
}
