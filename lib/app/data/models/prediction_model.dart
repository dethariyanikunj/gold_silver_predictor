class PredictionFactor {
  final String key;
  final String label;
  final int strength; // 1-10

  const PredictionFactor({
    required this.key,
    required this.label,
    required this.strength,
  });

  factory PredictionFactor.fromMap(Map<String, dynamic> m) =>
      PredictionFactor(
        key: m['key'] ?? '',
        label: m['label'] ?? '',
        strength: (m['strength'] as num?)?.toInt() ?? 5,
      );

  Map<String, dynamic> toMap() =>
      {'key': key, 'label': label, 'strength': strength};
}

class HorizonPrediction {
  final String horizon; // day | week | month
  final double predictedPriceInr;
  final double rangeLowInr;
  final double rangeHighInr;
  final double predictedPriceUsd;
  final String direction; // BULLISH | BEARISH | NEUTRAL | HIGH_UNCERTAINTY
  final double changePercent;
  final int confidence; // 0-100
  final String riskLevel; // LOW | MEDIUM | HIGH
  final int sentimentScore; // 0-100
  final List<PredictionFactor> bullishFactors;
  final List<PredictionFactor> bearishFactors;
  final List<String> uncertaintyFlags;
  final String explanation;
  final List<String> majorEventsThisPeriod;

  const HorizonPrediction({
    required this.horizon,
    required this.predictedPriceInr,
    required this.rangeLowInr,
    required this.rangeHighInr,
    required this.predictedPriceUsd,
    required this.direction,
    required this.changePercent,
    required this.confidence,
    required this.riskLevel,
    required this.sentimentScore,
    required this.bullishFactors,
    required this.bearishFactors,
    required this.uncertaintyFlags,
    required this.explanation,
    required this.majorEventsThisPeriod,
  });

  factory HorizonPrediction.fromMap(Map<String, dynamic> m, String horizon) {
    return HorizonPrediction(
      horizon: horizon,
      predictedPriceInr:
          (m['predicted_price_inr'] as num?)?.toDouble() ?? 0,
      rangeLowInr: (m['range_low_inr'] as num?)?.toDouble() ?? 0,
      rangeHighInr: (m['range_high_inr'] as num?)?.toDouble() ?? 0,
      predictedPriceUsd:
          (m['predicted_price_usd'] as num?)?.toDouble() ?? 0,
      direction: m['direction'] ?? 'NEUTRAL',
      changePercent: (m['change_percent'] as num?)?.toDouble() ?? 0,
      confidence: (m['confidence'] as num?)?.toInt() ?? 50,
      riskLevel: m['risk_level'] ?? 'MEDIUM',
      sentimentScore: (m['sentiment_score'] as num?)?.toInt() ?? 50,
      bullishFactors: (m['bullish_factors'] as List<dynamic>? ?? [])
          .map((e) => PredictionFactor.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      bearishFactors: (m['bearish_factors'] as List<dynamic>? ?? [])
          .map((e) => PredictionFactor.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      uncertaintyFlags: List<String>.from(m['uncertainty_flags'] ?? []),
      explanation: m['explanation'] ?? '',
      majorEventsThisPeriod:
          List<String>.from(m['major_events_this_period'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'horizon': horizon,
        'predicted_price_inr': predictedPriceInr,
        'range_low_inr': rangeLowInr,
        'range_high_inr': rangeHighInr,
        'predicted_price_usd': predictedPriceUsd,
        'direction': direction,
        'change_percent': changePercent,
        'confidence': confidence,
        'risk_level': riskLevel,
        'sentiment_score': sentimentScore,
        'bullish_factors': bullishFactors.map((f) => f.toMap()).toList(),
        'bearish_factors': bearishFactors.map((f) => f.toMap()).toList(),
        'uncertainty_flags': uncertaintyFlags,
        'explanation': explanation,
        'major_events_this_period': majorEventsThisPeriod,
      };
}

class MetalPrediction {
  final String metal; // gold | silver
  final double currentPriceInr;
  final double currentPriceUsd;
  final HorizonPrediction nextDay;
  final HorizonPrediction nextWeek;
  final HorizonPrediction nextMonth;
  final int overallSentiment;
  final String overallTheme;

  const MetalPrediction({
    required this.metal,
    required this.currentPriceInr,
    required this.currentPriceUsd,
    required this.nextDay,
    required this.nextWeek,
    required this.nextMonth,
    required this.overallSentiment,
    required this.overallTheme,
  });

  factory MetalPrediction.fromMap(
      Map<String, dynamic> m, String metal, double priceInr, double priceUsd) {
    return MetalPrediction(
      metal: metal,
      currentPriceInr: priceInr,
      currentPriceUsd: priceUsd,
      nextDay: HorizonPrediction.fromMap(
          Map<String, dynamic>.from(m['next_day'] ?? {}), 'day'),
      nextWeek: HorizonPrediction.fromMap(
          Map<String, dynamic>.from(m['next_week'] ?? {}), 'week'),
      nextMonth: HorizonPrediction.fromMap(
          Map<String, dynamic>.from(m['next_month'] ?? {}), 'month'),
      overallSentiment: (m['overall_sentiment'] as num?)?.toInt() ?? 50,
      overallTheme: m['overall_theme'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'metal': metal,
        'currentPriceInr': currentPriceInr,
        'currentPriceUsd': currentPriceUsd,
        'next_day': nextDay.toMap(),
        'next_week': nextWeek.toMap(),
        'next_month': nextMonth.toMap(),
        'overall_sentiment': overallSentiment,
        'overall_theme': overallTheme,
      };
}

class PredictionResult {
  final MetalPrediction gold;
  final MetalPrediction silver;
  final String marketCondition;
  final String keyTheme;
  final DateTime generatedAt;

  const PredictionResult({
    required this.gold,
    required this.silver,
    required this.marketCondition,
    required this.keyTheme,
    required this.generatedAt,
  });

  factory PredictionResult.fromGeminiJson(
    Map<String, dynamic> json,
    double goldInr,
    double goldUsd,
    double silverInr,
    double silverUsd,
  ) {
    final overview =
        Map<String, dynamic>.from(json['market_overview'] ?? {});
    return PredictionResult(
      gold: MetalPrediction.fromMap(
          Map<String, dynamic>.from(json['gold'] ?? {}),
          'gold',
          goldInr,
          goldUsd),
      silver: MetalPrediction.fromMap(
          Map<String, dynamic>.from(json['silver'] ?? {}),
          'silver',
          silverInr,
          silverUsd),
      marketCondition: overview['market_condition'] ?? 'NEUTRAL',
      keyTheme: overview['key_theme'] ?? '',
      generatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'gold': gold.toMap(),
        'silver': silver.toMap(),
        'marketCondition': marketCondition,
        'keyTheme': keyTheme,
        'generatedAt': generatedAt.toIso8601String(),
      };
}

class AccuracyLogEntry {
  final String id;
  final String metal;
  final String horizon;
  final DateTime predictedAt;
  final DateTime targetDate;
  final double currentPriceAtPrediction;
  final double predictedPriceInr;
  final String predictedDirection;
  final int confidence;

  // Filled in after target date passes
  double? actualPriceInr;
  String? actualDirection;
  bool? directionalCorrect;
  double? priceErrorPct;

  AccuracyLogEntry({
    required this.id,
    required this.metal,
    required this.horizon,
    required this.predictedAt,
    required this.targetDate,
    required this.currentPriceAtPrediction,
    required this.predictedPriceInr,
    required this.predictedDirection,
    required this.confidence,
    this.actualPriceInr,
    this.actualDirection,
    this.directionalCorrect,
    this.priceErrorPct,
  });

  factory AccuracyLogEntry.fromMap(Map m) => AccuracyLogEntry(
        id: m['id'] ?? '',
        metal: m['metal'] ?? '',
        horizon: m['horizon'] ?? '',
        predictedAt: DateTime.parse(m['predictedAt']),
        targetDate: DateTime.parse(m['targetDate']),
        currentPriceAtPrediction:
            (m['currentPriceAtPrediction'] as num).toDouble(),
        predictedPriceInr: (m['predictedPriceInr'] as num).toDouble(),
        predictedDirection: m['predictedDirection'] ?? '',
        confidence: (m['confidence'] as num).toInt(),
        actualPriceInr: (m['actualPriceInr'] as num?)?.toDouble(),
        actualDirection: m['actualDirection'],
        directionalCorrect: m['directionalCorrect'],
        priceErrorPct: (m['priceErrorPct'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'metal': metal,
        'horizon': horizon,
        'predictedAt': predictedAt.toIso8601String(),
        'targetDate': targetDate.toIso8601String(),
        'currentPriceAtPrediction': currentPriceAtPrediction,
        'predictedPriceInr': predictedPriceInr,
        'predictedDirection': predictedDirection,
        'confidence': confidence,
        'actualPriceInr': actualPriceInr,
        'actualDirection': actualDirection,
        'directionalCorrect': directionalCorrect,
        'priceErrorPct': priceErrorPct,
      };
}
