import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/prediction_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/direction_badge.dart';
import '../../widgets/confidence_ring.dart';
import '../../widgets/factor_tile.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/market_calendar_helper.dart';
import '../../data/models/prediction_model.dart';

class PredictionDetailPage extends StatelessWidget {
  const PredictionDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PredictionController>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Obx(() => Text(
              ctrl.selectedMetal.value == 'gold'
                  ? '🪙 Gold Prediction'
                  : '🔘 Silver Prediction',
            )),
        actions: [
          // Metal toggle
          Obx(() => Row(
                children: [
                  _MetalTab(
                      label: 'Gold',
                      isSelected: ctrl.selectedMetal.value == 'gold',
                      onTap: () => ctrl.selectedMetal.value = 'gold'),
                  _MetalTab(
                      label: 'Silver',
                      isSelected: ctrl.selectedMetal.value == 'silver',
                      onTap: () => ctrl.selectedMetal.value = 'silver'),
                  const SizedBox(width: 8),
                ],
              )),
        ],
      ),
      body: Obx(() {
        final pred = ctrl.prediction.value;
        if (pred == null) {
          return const Center(
            child: Text('No prediction available. Tap Predict Now on dashboard.',
                style: TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          );
        }

        final mp = ctrl.selectedMetal.value == 'gold' ? pred.gold : pred.silver;
        final baseDate = pred.generatedAt;

        final h = switch (ctrl.selectedHorizon.value) {
          'day' => mp.nextDay,
          'week' => mp.nextWeek,
          'month' => mp.nextMonth,
          _ => mp.nextWeek,
        };

        final daysOffset = switch (ctrl.selectedHorizon.value) {
          'day' => 1,
          'week' => 7,
          'month' => 30,
          _ => 7,
        };
        final targetTradingDate =
            MarketCalendarHelper.getNextTradingDay(baseDate, daysOffset);

        return Column(
          children: [
            // Horizon tabs with dynamic trading target dates
            _HorizonTabs(ctrl: ctrl, baseDate: baseDate),
            // Detail content
            Expanded(
              child: _HorizonDetail(
                prediction: h,
                currentPriceInr: mp.currentPriceInr,
                metal: ctrl.selectedMetal.value,
                accuracyStats: ctrl.accuracyStats,
                baseDate: baseDate,
                targetDate: targetTradingDate,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _MetalTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MetalTab(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.goldPrimary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.goldPrimary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.goldPrimary : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _HorizonTabs extends StatelessWidget {
  final PredictionController ctrl;
  final DateTime baseDate;

  const _HorizonTabs({required this.ctrl, required this.baseDate});

  @override
  Widget build(BuildContext context) {
    final dayStr = MarketCalendarHelper.formatShortTargetDate(baseDate, 1);
    final weekStr = MarketCalendarHelper.formatShortTargetDate(baseDate, 7);
    final monthStr = MarketCalendarHelper.formatShortTargetDate(baseDate, 30);

    return Container(
      color: AppColors.bgCard,
      child: Row(
        children: [
          _tab('day', '1D ($dayStr)', Icons.today_rounded),
          _tab('week', '7D ($weekStr)', Icons.date_range_rounded),
          _tab('month', '30D ($monthStr)', Icons.calendar_month_rounded),
        ],
      ),
    );
  }

  Widget _tab(String horizon, String label, IconData icon) {
    final isSelected = ctrl.selectedHorizon.value == horizon;
    return Expanded(
      child: GestureDetector(
        onTap: () => ctrl.selectedHorizon.value = horizon,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.goldPrimary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected ? AppColors.goldPrimary : AppColors.textMuted),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color:
                      isSelected ? AppColors.goldPrimary : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HorizonDetail extends StatelessWidget {
  final HorizonPrediction prediction;
  final double currentPriceInr;
  final String metal;
  final Map<String, String> accuracyStats;
  final DateTime baseDate;
  final DateTime targetDate;

  const _HorizonDetail({
    required this.prediction,
    required this.currentPriceInr,
    required this.metal,
    required this.accuracyStats,
    required this.baseDate,
    required this.targetDate,
  });

  @override
  Widget build(BuildContext context) {
    final h = prediction;
    final isGold = metal == 'gold';
    final dirColor = switch (h.direction) {
      'BULLISH' => AppColors.bullish,
      'BEARISH' => AppColors.bearish,
      'HIGH_UNCERTAINTY' => AppColors.uncertainty,
      _ => AppColors.neutral,
    };

    final currentTimestamp =
        MarketCalendarHelper.formatCurrentDateTime(baseDate);
    final targetTimestamp =
        MarketCalendarHelper.formatTargetDateTime(targetDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Price Summary Card ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: dirColor.withValues(alpha: 0.4)),
              gradient: LinearGradient(
                colors: [dirColor.withValues(alpha: 0.08), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current Spot Price',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          currentPriceInr > 0
                              ? (isGold
                                  ? '${CurrencyFormatter.inr(currentPriceInr)} /10g'
                                  : '${CurrencyFormatter.inr(currentPriceInr)} /kg')
                              : '—',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'As of: $currentTimestamp',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                    const Spacer(),
                    DirectionBadge(direction: h.direction),
                  ],
                ),
                const Divider(height: 20, color: AppColors.border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statCol(
                        'Target Prediction',
                        h.predictedPriceInr > 0
                            ? (isGold
                                ? '${CurrencyFormatter.inr(h.predictedPriceInr)} /10g'
                                : '${CurrencyFormatter.inr(h.predictedPriceInr)} /kg')
                            : '—',
                        dirColor),
                    _statCol('Expected Move',
                        CurrencyFormatter.percent(h.changePercent), dirColor),
                    ConfidenceRing(confidence: h.confidence, size: 68),
                  ],
                ),
                const SizedBox(height: 12),

                // Target Date Banner
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bgCardLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available_rounded,
                          color: AppColors.goldPrimary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Target Market Session: $targetTimestamp',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Metric pills
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.bgCardLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Range Low',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 10)),
                          const SizedBox(height: 2),
                          Text(CurrencyFormatter.inr(h.rangeLowInr),
                              style: const TextStyle(
                                  color: AppColors.bearish,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Container(width: 1, height: 28, color: AppColors.border),
                      Column(
                        children: [
                          const Text('Range High',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 10)),
                          const SizedBox(height: 2),
                          Text(CurrencyFormatter.inr(h.rangeHighInr),
                              style: const TextStyle(
                                  color: AppColors.bullish,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Container(width: 1, height: 28, color: AppColors.border),
                      Column(
                        children: [
                          const Text('Risk',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 10)),
                          const SizedBox(height: 2),
                          Text(h.riskLevel,
                              style: TextStyle(
                                  color: _riskColor(h.riskLevel),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Container(width: 1, height: 28, color: AppColors.border),
                      Column(
                        children: [
                          const Text('Sentiment',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 10)),
                          const SizedBox(height: 2),
                          Text('${h.sentimentScore}/100',
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── High Uncertainty Banner ──────────────────────────────────────
          if (h.uncertaintyFlags.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.uncertaintyBg,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.uncertainty.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.uncertainty, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Uncertainty Flags',
                            style: TextStyle(
                                color: AppColors.uncertainty,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        ...h.uncertaintyFlags.map((f) => Text(
                              '• $f',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12),
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Bullish Factors ──────────────────────────────────────────────
          if (h.bullishFactors.isNotEmpty) ...[
            _sectionHeader('✅ Bullish Factors', AppColors.bullish),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: h.bullishFactors
                    .map((f) => FactorTile(factor: f, isBullish: true))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Bearish Factors ──────────────────────────────────────────────
          if (h.bearishFactors.isNotEmpty) ...[
            _sectionHeader('❌ Bearish Factors', AppColors.bearish),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: h.bearishFactors
                    .map((f) => FactorTile(factor: f, isBullish: false))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── AI Explanation ───────────────────────────────────────────────
          _sectionHeader('🤖 AI Explanation', AppColors.accent),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              gradient: LinearGradient(
                colors: [AppColors.accentGlow, Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Text(
              h.explanation,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14, height: 1.6),
            ),
          ),
          const SizedBox(height: 16),

          // ── Key Events ───────────────────────────────────────────────────
          if (h.majorEventsThisPeriod.isNotEmpty) ...[
            _sectionHeader(
                '📅 Key Events This Period', AppColors.textSecondary),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: h.majorEventsThisPeriod
                    .map((e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.event_rounded,
                                  color: AppColors.accent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(e,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── My Accuracy ──────────────────────────────────────────────────
          _sectionHeader('📊 My Historical Accuracy', AppColors.textSecondary),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statCol('Total Predictions', accuracyStats['total'] ?? '0',
                    AppColors.textPrimary),
                Container(width: 1, height: 40, color: AppColors.border),
                _statCol(
                    'Directional Accuracy',
                    accuracyStats['directional'] ?? 'N/A',
                    accuracyStats['directional'] != 'N/A'
                        ? AppColors.bullish
                        : AppColors.textMuted),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Text(
      title,
      style:
          TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  Widget _statCol(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: valueColor, fontSize: 15, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Color _riskColor(String risk) => switch (risk) {
        'LOW' => AppColors.bullish,
        'HIGH' => AppColors.bearish,
        _ => AppColors.uncertainty,
      };
}
