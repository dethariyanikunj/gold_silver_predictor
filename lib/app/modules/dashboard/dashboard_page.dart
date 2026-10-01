import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../controllers/prediction_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

import '../../widgets/confidence_ring.dart';
import '../../widgets/market_chip.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/market_calendar_helper.dart';
import '../../data/models/prediction_model.dart';
import '../../../core/config/app_config.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PredictionController>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  AppColors.goldLight,
                  AppColors.goldPrimary,
                ]),
              ),
              child: const Icon(Icons.auto_graph_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Gold & Silver AI'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Accuracy Log',
            onPressed: () => Get.toNamed(AppRoutes.accuracyLog),
          ),
          IconButton(
            icon: const Icon(Icons.newspaper_rounded),
            tooltip: 'News',
            onPressed: () => Get.toNamed(AppRoutes.news),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.goldPrimary,
        backgroundColor: AppColors.bgCard,
        onRefresh: ctrl.runPrediction,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Status Banner ─────────────────────────────────────────────
              _StatusBanner(ctrl: ctrl),
              const SizedBox(height: 16),

              // ── Market Overview Strip (Controlled by Feature Flag) ──────
              if (AppConfig.showMarketOverview) ...[
                _MarketOverviewStrip(ctrl: ctrl),
                const SizedBox(height: 20),
              ],

              // ── Metal Cards ───────────────────────────────────────────────
              Obx(() {
                if (ctrl.state.value == PredictionState.idle) {
                  return const _PredictPromptCard();
                }
                return Column(
                  children: [
                    _MetalCard(metal: 'gold', ctrl: ctrl),
                    const SizedBox(height: 16),
                    _MetalCard(metal: 'silver', ctrl: ctrl),
                  ],
                );
              }),
              const SizedBox(height: 20),

              // ── Top News ──────────────────────────────────────────────────
              _TopNews(ctrl: ctrl),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: ctrl.runPrediction,
        backgroundColor: AppColors.goldPrimary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('Predict Now',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─── Status Banner ────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final PredictionController ctrl;
  const _StatusBanner({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = ctrl.state.value;
      if (state == PredictionState.idle || state == PredictionState.done) {
        if (ctrl.prediction.value != null) {
          final predDate = ctrl.prediction.value!.generatedAt;
          final formattedTime = MarketCalendarHelper.formatCurrentDateTime(predDate);
          final marketStatus = MarketCalendarHelper.getMarketStatusDescription(predDate);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgCardLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.bullish, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Prediction Updated: $formattedTime',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        color: AppColors.goldPrimary, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        marketStatus,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      }

      if (state == PredictionState.error) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.bearishBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.bearish.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.bearish, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ctrl.errorMessage.value,
                  style: const TextStyle(color: AppColors.bearish, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.goldGlow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.goldPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              ctrl.statusMessage.value,
              style: const TextStyle(color: AppColors.goldPrimary, fontSize: 12),
            ),
          ],
        ),
      );
    });
  }
}

// ─── Market Overview Strip ────────────────────────────────────────────────────

class _MarketOverviewStrip extends StatelessWidget {
  final PredictionController ctrl;
  const _MarketOverviewStrip({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mkt = ctrl.market.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Market Overview',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                MarketChip(
                    label: 'DXY',
                    value: mkt?.dxy?.toStringAsFixed(2) ?? '—'),
                const SizedBox(width: 8),
                MarketChip(
                    label: 'USD/INR',
                    value: mkt?.usdInr?.toStringAsFixed(2) ?? '—'),
                const SizedBox(width: 8),
                MarketChip(
                    label: 'VIX',
                    value: mkt?.vix?.toStringAsFixed(2) ?? '—'),
                const SizedBox(width: 8),
                MarketChip(
                    label: 'US 10Y',
                    value: mkt?.us10YYield != null
                        ? '${mkt!.us10YYield!.toStringAsFixed(2)}%'
                        : '—'),
                const SizedBox(width: 8),
                MarketChip(
                    label: 'Brent',
                    value: CurrencyFormatter.usd(mkt?.brentCrude)),
                const SizedBox(width: 8),
                MarketChip(
                    label: 'G/S Ratio',
                    value: mkt?.goldSilverRatio?.toStringAsFixed(1) ?? '—'),
                const SizedBox(width: 8),
                MarketChip(
                    label: 'Nifty 50',
                    value: mkt?.nifty50?.toStringAsFixed(0) ?? '—'),
              ],
            ),
          ),
        ],
      );
    });
  }
}

// ─── Metal Card ───────────────────────────────────────────────────────────────

class _MetalCard extends StatelessWidget {
  final String metal;
  final PredictionController ctrl;

  const _MetalCard({required this.metal, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isGold = metal == 'gold';
      final primaryColor = isGold ? AppColors.goldPrimary : AppColors.silverPrimary;
      final glowColor = isGold ? AppColors.goldGlow : AppColors.silverGlow;

      final pred = ctrl.prediction.value;
      final mp = pred != null
          ? (isGold ? pred.gold : pred.silver)
          : null;
      final mkt = ctrl.market.value;
      final currentPrice =
          isGold ? mkt?.goldInr : mkt?.silverInr;
      final currentUsd = isGold ? mkt?.goldUsd : mkt?.silverUsd;

      final isLoading = ctrl.state.value == PredictionState.fetchingData ||
          ctrl.state.value == PredictionState.predicting;

      final priceTimestamp = MarketCalendarHelper.formatCurrentDateTime(
          mkt?.fetchedAt ?? pred?.generatedAt ?? DateTime.now());
      final baseDate = pred?.generatedAt ?? DateTime.now();

      return GestureDetector(
        onTap: mp == null
            ? null
            : () {
                ctrl.selectedMetal.value = metal;
                Get.toNamed(AppRoutes.predictionDetail);
              },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(color: glowColor, blurRadius: 20, spreadRadius: -5),
            ],
          ),
          child: Column(
            children: [
              // Header with Clean Non-overlapping Sentiment Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor.withValues(alpha: 0.15), Colors.transparent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isGold ? Icons.circle : Icons.hexagon_outlined,
                          color: primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isGold ? 'GOLD (24K)' : 'SILVER (999)',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    if (mp != null) _buildSentimentBadge(mp.overallSentiment),
                  ],
                ),
              ),

              // Price row with Clear Date & Time
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Current Spot Price',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 11)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.bgCardLight,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                priceTimestamp,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        isLoading
                            ? _shimmerBlock(120, 28)
                            : Text(
                                currentPrice != null && currentPrice > 0
                                    ? (isGold
                                        ? '${CurrencyFormatter.inr(currentPrice)} /10g'
                                        : '${CurrencyFormatter.inr(currentPrice)} /kg')
                                    : '—',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                        Text(
                          currentUsd != null && currentUsd > 0
                              ? (isGold
                                  ? '${CurrencyFormatter.usd(currentUsd)} /oz (USD)'
                                  : '${CurrencyFormatter.usd(currentUsd)} /oz (USD)')
                              : '—',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (mp != null) ...[
                      ConfidenceRing(
                          confidence: mp.nextWeek.confidence, size: 64),
                    ],
                  ],
                ),
              ),

              const Divider(height: 1, color: AppColors.border),

              // Prediction summary with Exact Market Open Target Dates
              Padding(
                padding: const EdgeInsets.all(16),
                child: isLoading
                    ? _buildLoadingRow()
                    : mp == null
                        ? const Center(
                            child: Text('Tap "Predict Now" to get AI prediction',
                                style: TextStyle(
                                    color: AppColors.textMuted, fontSize: 13)),
                          )
                        : _buildPredictionRow(mp, isGold, baseDate),
              ),

              if (mp != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          mp.overallTheme,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 13, color: AppColors.textMuted),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSentimentBadge(int score) {
    final isBullish = score >= 60;
    final isBearish = score <= 40;
    final color = isBullish
        ? AppColors.bullish
        : (isBearish ? AppColors.bearish : AppColors.goldPrimary);
    final label = isBullish ? 'Bullish' : (isBearish ? 'Bearish' : 'Neutral');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBullish
                ? Icons.trending_up_rounded
                : (isBearish
                    ? Icons.trending_down_rounded
                    : Icons.trending_flat_rounded),
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '$label $score/100',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionRow(
      MetalPrediction mp, bool isGold, DateTime baseDate) {
    final target1D = MarketCalendarHelper.formatShortTargetDate(baseDate, 1);
    final target7D = MarketCalendarHelper.formatShortTargetDate(baseDate, 7);
    final target30D = MarketCalendarHelper.formatShortTargetDate(baseDate, 30);

    return Row(
      children: [
        _horizonSummary('1D', target1D, mp.nextDay),
        const SizedBox(width: 10),
        _horizonSummary('7D', target7D, mp.nextWeek),
        const SizedBox(width: 10),
        _horizonSummary('30D', target30D, mp.nextMonth),
      ],
    );
  }

  Widget _horizonSummary(
      String horizonCode, String targetDateStr, HorizonPrediction h) {
    final color = switch (h.direction) {
      'BULLISH' => AppColors.bullish,
      'BEARISH' => AppColors.bearish,
      'HIGH_UNCERTAINTY' => AppColors.uncertainty,
      _ => AppColors.neutral,
    };

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              horizonCode,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              targetDateStr,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              h.predictedPriceInr > 0
                  ? CurrencyFormatter.inr(h.predictedPriceInr)
                  : '—',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              CurrencyFormatter.percent(h.changePercent),
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              _dirLabel(h.direction),
              style: TextStyle(
                  color: color, fontSize: 9, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  String _dirLabel(String dir) => switch (dir) {
        'BULLISH' => '▲ Bullish',
        'BEARISH' => '▼ Bearish',
        'HIGH_UNCERTAINTY' => '? Uncertain',
        _ => '→ Neutral',
      };

  Widget _buildLoadingRow() {
    return Row(
      children: List.generate(
          3,
          (i) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _shimmerBlock(double.infinity, 60),
                ),
              )),
    );
  }

  Widget _shimmerBlock(double w, double h) {
    return Shimmer.fromColors(
      baseColor: AppColors.bgCardLight,
      highlightColor: AppColors.border,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: AppColors.bgCardLight,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// ─── Prompt Card ──────────────────────────────────────────────────────────────

class _PredictPromptCard extends StatelessWidget {
  const _PredictPromptCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          colors: [
            AppColors.goldGlow,
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome_rounded,
              color: AppColors.goldPrimary, size: 40),
          const SizedBox(height: 12),
          const Text(
            'AI-Powered Gold & Silver\nPrice Predictions',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap "Predict Now" to fetch live data and generate\nnext-day, next-week, and next-month predictions.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: const [
              _FeatureChip('Live Yahoo Finance data'),
              _FeatureChip('FRED Macro (CPI, Yields)'),
              _FeatureChip('Free RSS News'),
              _FeatureChip('CFTC Positioning'),
              _FeatureChip('Gemini 2.5 Flash AI'),
              _FeatureChip('India Festival Calendar'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  const _FeatureChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgCardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label,
          style:
              const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
    );
  }
}

// ─── Top News ─────────────────────────────────────────────────────────────────

class _TopNews extends StatelessWidget {
  final PredictionController ctrl;
  const _TopNews({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final articles = ctrl.news.take(5).toList();
      if (articles.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Latest News',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.news),
                child: const Text('See all',
                    style: TextStyle(
                        color: AppColors.goldPrimary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...articles.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _categoryColor(a.category),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${a.source ?? ''} · ${CurrencyFormatter.timeAgo(a.publishedAt)} · ${a.category ?? ''}',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      );
    });
  }

  Color _categoryColor(String? cat) {
    if (cat == null) return AppColors.textMuted;
    if (cat.contains('Fed') || cat.contains('Inflation')) return AppColors.uncertainty;
    if (cat.contains('Geopolit') || cat.contains('War')) return AppColors.bearish;
    if (cat.contains('India')) return const Color(0xFF6366F1);
    if (cat.contains('Central')) return AppColors.bullish;
    if (cat.contains('Gold') || cat.contains('Silver')) return AppColors.goldPrimary;
    return AppColors.textMuted;
  }
}

