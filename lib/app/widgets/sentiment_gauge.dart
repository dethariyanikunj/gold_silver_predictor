import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SentimentGauge extends StatelessWidget {
  final int score;
  final String label;
  final double? width;

  const SentimentGauge({
    super.key,
    required this.score,
    required this.label,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final color = score >= 65
        ? AppColors.bullish
        : score >= 45
            ? AppColors.goldPrimary
            : AppColors.bearish;

    final sentimentLabel = score >= 65
        ? 'Bullish'
        : score >= 45
            ? 'Neutral'
            : 'Bearish';

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label.isNotEmpty)
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              Text(
                '$sentimentLabel $score/100',
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
