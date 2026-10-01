import 'package:flutter/material.dart';
import '../data/models/prediction_model.dart';
import '../theme/app_theme.dart';

class FactorTile extends StatelessWidget {
  final PredictionFactor factor;
  final bool isBullish;

  const FactorTile({super.key, required this.factor, required this.isBullish});

  @override
  Widget build(BuildContext context) {
    final color = isBullish ? AppColors.bullish : AppColors.bearish;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isBullish ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              factor.label,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: List.generate(
              10,
              (i) => Container(
                width: 4,
                height: 12,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: i < factor.strength ? color : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
