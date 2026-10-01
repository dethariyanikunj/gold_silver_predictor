import 'dart:convert';
import 'package:get/get.dart';
import '../data/models/market_data_model.dart';
import '../data/models/news_article_model.dart';
import '../data/models/prediction_model.dart';
import '../data/repositories/market_repository.dart';
import '../data/services/rss_service.dart';
import '../data/services/gemini_service.dart';
import '../../core/services/hive_service.dart';
import '../../core/config/app_config.dart';

enum PredictionState { idle, fetchingData, predicting, done, error }

class PredictionController extends GetxController {
  final _marketRepo = MarketRepository();
  final _rssService = RssService();
  final _geminiService = GeminiService();

  final state = PredictionState.idle.obs;
  final statusMessage = ''.obs;
  final errorMessage = ''.obs;

  final market = Rxn<MarketDataModel>();
  final news = <NewsArticleModel>[].obs;
  final prediction = Rxn<PredictionResult>();

  // Selected metal for prediction detail
  final selectedMetal = 'gold'.obs;
  // Selected horizon
  final selectedHorizon = 'week'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCachedPrediction();
    _evaluatePastPredictions();
  }

  void _loadCachedPrediction() {
    final cached = HiveService.getIfFresh(
      HiveService.predictionBox,
      'last_prediction',
    );
    if (cached != null) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(cached));
        // Re-hydrate from cache
        final goldMap = map['gold'] as Map<String, dynamic>;
        final silverMap = map['silver'] as Map<String, dynamic>;
        final goldPriceInr = (goldMap['currentPriceInr'] as num?)?.toDouble() ?? 0.0;
        // Ignore stale cache from old price models
        if (goldPriceInr < 100000 && goldPriceInr > 0) {
          HiveService.delete(HiveService.predictionBox, 'last_prediction');
          return;
        }

        prediction.value = PredictionResult(
          gold: MetalPrediction.fromMap(
              goldMap, 'gold', goldPriceInr,
              (goldMap['currentPriceUsd'] as num?)?.toDouble() ?? 0.0),
          silver: MetalPrediction.fromMap(
              silverMap, 'silver', (silverMap['currentPriceInr'] as num?)?.toDouble() ?? 0.0,
              (silverMap['currentPriceUsd'] as num?)?.toDouble() ?? 0.0),
          marketCondition: map['marketCondition'] ?? 'NEUTRAL',
          keyTheme: map['keyTheme'] ?? '',
          generatedAt: DateTime.parse(map['generatedAt']),
        );
        state.value = PredictionState.done;
      } catch (_) {}
    }
  }

  Future<void> runPrediction() async {
    if (state.value == PredictionState.fetchingData ||
        state.value == PredictionState.predicting) {
      return;
    }

    errorMessage.value = '';
    state.value = PredictionState.fetchingData;
    statusMessage.value = 'Fetching live market data...';

    try {
      // Step 1: Fetch all market data
      final [fetchedMarket, fetchedNews] = await Future.wait([
        _marketRepo.fetchAllMarketData(),
        _rssService.fetchAllNews(),
      ]);

      market.value = fetchedMarket as MarketDataModel;
      news.assignAll(fetchedNews as List<NewsArticleModel>);

      // Step 2: Generate Gemini prediction
      state.value = PredictionState.predicting;
      statusMessage.value = 'Analyzing with AI (Gemini ${AppConfig.geminiModel})...';

      final result = await _geminiService.generatePrediction(
        market.value!,
        news,
      );
      prediction.value = result;

      // Step 3: Cache the result
      await HiveService.setWithTtl(
        HiveService.predictionBox,
        'last_prediction',
        jsonEncode(result.toMap()),
        AppConfig.predictionTtlMin,
      );

      // Step 4: Save to accuracy log
      await _saveToAccuracyLog(result, market.value!);

      state.value = PredictionState.done;
      statusMessage.value = 'Prediction ready';
    } catch (e) {
      state.value = PredictionState.error;
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> _saveToAccuracyLog(
      PredictionResult result, MarketDataModel mkt) async {
    final now = DateTime.now();
    for (final metal in ['gold', 'silver']) {
      final mp = metal == 'gold' ? result.gold : result.silver;
      for (final horizon in [mp.nextDay, mp.nextWeek, mp.nextMonth]) {
        final targetDays =
            horizon.horizon == 'day' ? 1 : horizon.horizon == 'week' ? 7 : 30;
        final entry = AccuracyLogEntry(
          id: '${metal}_${horizon.horizon}_${now.millisecondsSinceEpoch}',
          metal: metal,
          horizon: horizon.horizon,
          predictedAt: now,
          targetDate: now.add(Duration(days: targetDays)),
          currentPriceAtPrediction:
              metal == 'gold' ? (mkt.goldInr ?? 0) : (mkt.silverInr ?? 0),
          predictedPriceInr: horizon.predictedPriceInr,
          predictedDirection: horizon.direction,
          confidence: horizon.confidence,
        );
        await HiveService.appendAccuracyEntry(entry.toMap());
      }
    }
  }

  Future<void> _evaluatePastPredictions() async {
    final entries = HiveService.getAllAccuracyEntries();
    final now = DateTime.now();
    for (int i = 0; i < entries.length; i++) {
      final entry = AccuracyLogEntry.fromMap(entries[i]);
      if (entry.directionalCorrect != null) continue;
      if (now.isBefore(entry.targetDate)) continue;

      // Target date has passed — fetch actual price
      try {
        final symbol =
            entry.metal == 'gold' ? 'GC=F' : 'SI=F';
        final quotes = await _marketRepo.fetchQuoteDirect(symbol);
        if (quotes == null) continue;

        // Convert to INR
        final usdInr = await _marketRepo.fetchQuoteDirect('INR=X');
        double? actualInr;
        if (entry.metal == 'gold' && usdInr != null) {
          actualInr = quotes / 31.1035 * 10 * usdInr;
        } else if (entry.metal == 'silver' && usdInr != null) {
          actualInr = quotes / 31.1035 * 1000 * usdInr;
        }

        if (actualInr == null) continue;

        final actualDirection = actualInr > entry.currentPriceAtPrediction
            ? 'BULLISH'
            : actualInr < entry.currentPriceAtPrediction
                ? 'BEARISH'
                : 'NEUTRAL';

        final updated = entry.toMap();
        updated['actualPriceInr'] = actualInr;
        updated['actualDirection'] = actualDirection;
        updated['directionalCorrect'] =
            entry.predictedDirection == actualDirection ||
                (entry.predictedDirection == 'HIGH_UNCERTAINTY');
        updated['priceErrorPct'] =
            ((entry.predictedPriceInr - actualInr) / actualInr * 100).abs();

        await HiveService.updateAccuracyEntry(i, updated);
      } catch (_) {}
    }
  }

  HorizonPrediction? get currentHorizonPrediction {
    final pred = prediction.value;
    if (pred == null) return null;
    final mp = selectedMetal.value == 'gold' ? pred.gold : pred.silver;
    switch (selectedHorizon.value) {
      case 'day':
        return mp.nextDay;
      case 'week':
        return mp.nextWeek;
      case 'month':
        return mp.nextMonth;
      default:
        return mp.nextWeek;
    }
  }

  // Accuracy stats from local log
  Map<String, String> get accuracyStats {
    final entries = HiveService.getAllAccuracyEntries()
        .map((e) => AccuracyLogEntry.fromMap(e))
        .where((e) => e.directionalCorrect != null)
        .toList();

    if (entries.isEmpty) return {'total': '0', 'directional': 'N/A'};

    final correct = entries.where((e) => e.directionalCorrect == true).length;
    return {
      'total': entries.length.toString(),
      'directional': '${(correct / entries.length * 100).toStringAsFixed(0)}%',
    };
  }
}
