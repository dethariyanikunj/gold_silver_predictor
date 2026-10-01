import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/app_theme.dart';
import '../../../core/services/hive_service.dart';
import '../../data/models/prediction_model.dart';
import '../../../core/utils/currency_formatter.dart';

class AccuracyLogPage extends StatelessWidget {
  const AccuracyLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final entries = HiveService.getAllAccuracyEntries()
        .map((e) => AccuracyLogEntry.fromMap(e))
        .toList()
        .reversed
        .toList();

    final evaluated = entries.where((e) => e.directionalCorrect != null).toList();
    final correct = evaluated.where((e) => e.directionalCorrect == true).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('My Accuracy Log')),
      body: Column(
        children: [
          // Summary banner
          if (evaluated.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                gradient: LinearGradient(
                  colors: [AppColors.goldGlow, Colors.transparent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statCol('Total Evaluated',
                      evaluated.length.toString(), AppColors.textPrimary),
                  Container(width: 1, height: 40, color: AppColors.border),
                  _statCol('Correct Direction',
                      correct.toString(), AppColors.bullish),
                  Container(width: 1, height: 40, color: AppColors.border),
                  _statCol('Accuracy',
                      '${(correct / evaluated.length * 100).toStringAsFixed(0)}%',
                      AppColors.goldPrimary),
                ],
              ),
            ),

          // List
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.analytics_outlined,
                            color: AppColors.textMuted, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'No predictions logged yet.\nRun a prediction first.',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: entries.length,
                    itemBuilder: (_, i) => _LogEntry(entry: entries[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _LogEntry extends StatelessWidget {
  final AccuracyLogEntry entry;
  const _LogEntry({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isPending = entry.directionalCorrect == null;
    final isCorrect = entry.directionalCorrect == true;
    final statusColor = isPending
        ? AppColors.uncertainty
        : isCorrect
            ? AppColors.bullish
            : AppColors.bearish;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            isPending
                ? Icons.pending_outlined
                : isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
            color: statusColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.metal.capitalizeFirst!,
                      style: TextStyle(
                          color: entry.metal == 'gold'
                              ? AppColors.goldPrimary
                              : AppColors.silverPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const Text(' · ',
                        style: TextStyle(color: AppColors.textMuted)),
                    Text(
                      _horizonLabel(entry.horizon),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Predicted: ${CurrencyFormatter.inr(entry.predictedPriceInr)} · ${entry.predictedDirection}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
                if (entry.actualPriceInr != null)
                  Text(
                    'Actual: ${CurrencyFormatter.inr(entry.actualPriceInr)} · Error: ${entry.priceErrorPct?.toStringAsFixed(2)}%',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isPending ? 'Pending' : isCorrect ? 'Correct' : 'Incorrect',
                style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                'Target: ${_formatDate(entry.targetDate)}',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 10),
              ),
              Text(
                '${entry.confidence}% conf.',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _horizonLabel(String h) => switch (h) {
        'day' => 'Next Day',
        'week' => 'Next Week',
        'month' => 'Next Month',
        _ => h,
      };

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}
