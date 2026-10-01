import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/dio_service.dart';
import '../../../core/services/hive_service.dart';

class GoldApiQuote {
  final double? priceInr; // Gold per 10g in INR, Silver per 1kg in INR
  final double? priceUsd; // Price per oz in USD (if enabled)
  final double? priceGram24k;
  final double? priceGram22k;
  final DateTime? timestamp;

  const GoldApiQuote({
    this.priceInr,
    this.priceUsd,
    this.priceGram24k,
    this.priceGram22k,
    this.timestamp,
  });
}

class GoldApiPriceResult {
  final GoldApiQuote gold;
  final GoldApiQuote silver;

  const GoldApiPriceResult({required this.gold, required this.silver});
}

class GoldApiService {
  final Dio _dio = DioService.generic;
  Future<GoldApiPriceResult?>? _inFlightFetch;

  /// Fetch spot gold and silver prices from goldapi.io
  /// Executes at most once per prediction (1 call for Gold XAU/INR, 1 call for Silver XAG/INR)
  Future<GoldApiPriceResult?> fetchPrices() async {
    if (_inFlightFetch != null) {
      return _inFlightFetch;
    }

    _inFlightFetch = _executeFetch();
    try {
      return await _inFlightFetch;
    } finally {
      _inFlightFetch = null;
    }
  }

  Future<GoldApiPriceResult?> _executeFetch() async {
    final apiKey = AppConfig.goldApiKey.trim();
    if (apiKey.isEmpty || apiKey.startsWith('YOUR_')) {
      return null;
    }

    const cacheKey = 'gold_api_prices_cache';
    final cached = HiveService.getIfFresh(HiveService.priceBox, cacheKey);
    if (cached != null) {
      try {
        final data = jsonDecode(cached) as Map<String, dynamic>;
        return GoldApiPriceResult(
          gold: _quoteFromJson(data['gold'], isGold: true),
          silver: _quoteFromJson(data['silver'], isGold: false),
        );
      } catch (_) {}
    }

    try {
      final headers = {
        'x-access-token': apiKey,
        'Content-Type': 'application/json',
      };

      // Fetch only INR records (1 call for Gold XAU/INR, 1 call for Silver XAG/INR)
      // Endpoint: https://www.goldapi.io/api/price/{metal}/{currency}
      final futures = <Future<Map<String, dynamic>?>>[
        _fetchSymbol('XAU', 'INR', headers),
        _fetchSymbol('XAG', 'INR', headers),
      ];

      // USD endpoints (XAU/USD, XAG/USD) are handled by flag and disabled by default
      // to avoid extra API consumption and redundant requests.
      if (AppConfig.enableGoldApiUsd) {
        futures.add(_fetchSymbol('XAU', 'USD', headers));
        futures.add(_fetchSymbol('XAG', 'USD', headers));
      }

      final responses = await Future.wait(futures);
      final xauInr = responses[0];
      final xagInr = responses[1];
      final xauUsd = AppConfig.enableGoldApiUsd && responses.length > 2
          ? responses[2]
          : null;
      final xagUsd = AppConfig.enableGoldApiUsd && responses.length > 3
          ? responses[3]
          : null;

      if (xauInr == null && xagInr == null) {
        return null;
      }

      final goldQuote = _buildQuote(xauInr, xauUsd, isGold: true);
      final silverQuote = _buildQuote(xagInr, xagUsd, isGold: false);

      final result = GoldApiPriceResult(gold: goldQuote, silver: silverQuote);

      // Cache result for goldApiTtlMin
      final serializable = {
        'gold': _quoteToJson(goldQuote),
        'silver': _quoteToJson(silverQuote),
      };
      await HiveService.setWithTtl(
        HiveService.priceBox,
        cacheKey,
        jsonEncode(serializable),
        AppConfig.goldApiTtlMin,
      );

      return result;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchSymbol(
    String metal,
    String currency,
    Map<String, String> headers,
  ) async {
    try {
      final response = await _dio.get(
        '${AppConfig.goldApiBaseUrl}/$metal/$currency',
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      } else if (response.data is String) {
        return jsonDecode(response.data as String) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  GoldApiQuote _buildQuote(
    Map<String, dynamic>? inrData,
    Map<String, dynamic>? usdData, {
    required bool isGold,
  }) {
    final gram24k = (inrData?['price_gram_24k'] as num?)?.toDouble();
    final gram22k = (inrData?['price_gram_22k'] as num?)?.toDouble();
    final totalInr = (inrData?['price'] as num?)?.toDouble();
    final usdPrice = (usdData?['price'] as num?)?.toDouble();

    final rawTs = inrData?['timestamp'] as int? ?? usdData?['timestamp'] as int?;
    final timestamp = rawTs != null
        ? DateTime.fromMillisecondsSinceEpoch(rawTs * 1000, isUtc: true).toLocal()
        : DateTime.now();

    // Gold: ₹ / 10g; Silver: ₹ / 1kg (1000g)
    double? calculatedInr;
    if (isGold) {
      if (gram24k != null && gram24k > 0) {
        calculatedInr = gram24k * 10;
      } else if (totalInr != null && totalInr > 0) {
        calculatedInr = (totalInr / 31.1034768) * 10;
      }
    } else {
      if (gram24k != null && gram24k > 0) {
        calculatedInr = gram24k * 1000;
      } else if (totalInr != null && totalInr > 0) {
        calculatedInr = (totalInr / 31.1034768) * 1000;
      }
    }

    return GoldApiQuote(
      priceInr: calculatedInr,
      priceUsd: usdPrice,
      priceGram24k: gram24k,
      priceGram22k: gram22k,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> _quoteToJson(GoldApiQuote q) => {
        'priceInr': q.priceInr,
        'priceUsd': q.priceUsd,
        'priceGram24k': q.priceGram24k,
        'priceGram22k': q.priceGram22k,
        'timestamp': q.timestamp?.toIso8601String(),
      };

  GoldApiQuote _quoteFromJson(dynamic json, {required bool isGold}) {
    if (json is! Map) return const GoldApiQuote();
    final map = Map<String, dynamic>.from(json);
    return GoldApiQuote(
      priceInr: (map['priceInr'] as num?)?.toDouble(),
      priceUsd: (map['priceUsd'] as num?)?.toDouble(),
      priceGram24k: (map['priceGram24k'] as num?)?.toDouble(),
      priceGram22k: (map['priceGram22k'] as num?)?.toDouble(),
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String)
          : null,
    );
  }
}
