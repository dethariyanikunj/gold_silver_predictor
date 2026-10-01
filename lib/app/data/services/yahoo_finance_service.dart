import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/dio_service.dart';
import '../../../core/services/hive_service.dart';

class YahooQuote {
  final double? price;
  final DateTime? marketTime;

  const YahooQuote({this.price, this.marketTime});
}

class YahooFinanceService {
  final Dio _dio = DioService.yahoo;

  /// Fetch current quotes and market times for Yahoo symbols
  Future<Map<String, YahooQuote>> fetchQuotesDetailed(
      List<String> symbols) async {
    final cacheKey = 'yahoo_quotes_v2_${symbols.join("_")}';
    final cached = HiveService.getIfFresh(HiveService.priceBox, cacheKey);
    if (cached != null) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(cached));
        return map.map((k, v) => MapEntry(
              k,
              YahooQuote(
                price: (v['price'] as num?)?.toDouble(),
                marketTime: v['time'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(v['time'] as int)
                    : null,
              ),
            ));
      } catch (_) {}
    }

    final result = <String, YahooQuote>{};
    await Future.wait(
      symbols.map((symbol) => _fetchSingleQuoteDetailed(symbol, result)),
    );

    try {
      final serializable = result.map((k, v) => MapEntry(k, {
            'price': v.price,
            'time': v.marketTime?.millisecondsSinceEpoch,
          }));
      await HiveService.setWithTtl(
        HiveService.priceBox,
        cacheKey,
        jsonEncode(serializable),
        AppConfig.pricesTtlMin,
      );
    } catch (_) {}

    return result;
  }

  /// Backward-compatible map for prices
  Future<Map<String, double?>> fetchQuotes(List<String> symbols) async {
    final detailed = await fetchQuotesDetailed(symbols);
    return detailed.map((k, v) => MapEntry(k, v.price));
  }

  Future<void> _fetchSingleQuoteDetailed(
      String symbol, Map<String, YahooQuote> result) async {
    try {
      final data = await _fetchChartJson(
          symbol, {'interval': '1d', 'range': '1d'});
      if (data != null && data['chart'] != null) {
        final chart = data['chart']['result'][0];
        final meta = chart['meta'];
        final price = (meta['regularMarketPrice'] as num?)?.toDouble();
        final rawTime = meta['regularMarketTime'] as int?;
        final time = rawTime != null
            ? DateTime.fromMillisecondsSinceEpoch(rawTime * 1000, isUtc: true)
                .toLocal()
            : null;

        result[symbol] = YahooQuote(price: price, marketTime: time);
        return;
      }
    } catch (_) {}
    result[symbol] = const YahooQuote(price: null, marketTime: null);
  }

  /// Fetch 3-month daily closing prices for a symbol
  Future<List<double>> fetchHistoricalCloses(String symbol,
      {String range = '3mo'}) async {
    final cacheKey = 'yahoo_hist_${symbol}_$range';
    final cached = HiveService.getIfFresh(HiveService.priceBox, cacheKey);
    if (cached != null) {
      try {
        return List<double>.from(jsonDecode(cached));
      } catch (_) {}
    }

    try {
      final data = await _fetchChartJson(
          symbol, {'interval': '1d', 'range': range});
      if (data != null && data['chart'] != null) {
        final chart = data['chart']['result'][0];
        final closes = (chart['indicators']['quote'][0]['close'] as List)
            .whereType<num>()
            .map((e) => e.toDouble())
            .toList();

        await HiveService.setWithTtl(
          HiveService.priceBox,
          cacheKey,
          jsonEncode(closes),
          AppConfig.pricesTtlMin,
        );
        return closes;
      }
    } catch (_) {}
    return [];
  }

  /// Internal fetcher with Web CORS fallback
  Future<dynamic> _fetchChartJson(
      String symbol, Map<String, dynamic> queryParams) async {
    // 1. Direct call
    if (!kIsWeb) {
      try {
        final response = await _dio.get(
          '/v8/finance/chart/$symbol',
          queryParameters: queryParams,
        );
        if (response.data != null) return response.data;
      } catch (_) {}
    }

    // 2. Web or fallback with CORS proxy
    final queryStr =
        queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    final targetUrl =
        'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?$queryStr';
    final encodedUrl = Uri.encodeComponent(targetUrl);

    final proxies = [
      'https://api.allorigins.win/raw?url=$encodedUrl',
      'https://corsproxy.io/?url=$encodedUrl',
    ];

    for (final proxyUrl in proxies) {
      try {
        final resp = await DioService.generic.get(proxyUrl);
        var data = resp.data;
        if (data is String) {
          data = jsonDecode(data);
        }
        if (data != null && data['chart'] != null) {
          return data;
        }
      } catch (_) {}
    }

    // If on web and proxy fails, attempt direct call as last resort
    if (kIsWeb) {
      try {
        final response = await _dio.get(
          '/v8/finance/chart/$symbol',
          queryParameters: queryParams,
        );
        if (response.data != null) return response.data;
      } catch (_) {}
    }

    return null;
  }

  /// Calculate SMA
  static double? sma(List<double> prices, int period) {
    if (prices.length < period) return null;
    final slice = prices.sublist(prices.length - period);
    return slice.reduce((a, b) => a + b) / period;
  }

  /// Calculate RSI-14
  static double? rsi(List<double> prices, {int period = 14}) {
    if (prices.length < period + 1) return null;
    final changes = <double>[];
    for (int i = 1; i < prices.length; i++) {
      changes.add(prices[i] - prices[i - 1]);
    }
    final recent = changes.sublist(changes.length - period);
    final gains = recent.where((c) => c > 0).toList();
    final losses = recent.where((c) => c < 0).map((c) => c.abs()).toList();
    final avgGain =
        gains.isEmpty ? 0.0 : gains.reduce((a, b) => a + b) / period;
    final avgLoss =
        losses.isEmpty ? 0.0 : losses.reduce((a, b) => a + b) / period;
    if (avgLoss == 0) return 100;
    final rs = avgGain / avgLoss;
    return 100 - (100 / (1 + rs));
  }

  /// Calculate Period High
  static double? periodHigh(List<double> prices, [int? lookback]) {
    if (prices.isEmpty) return null;
    final slice = (lookback != null && prices.length > lookback)
        ? prices.sublist(prices.length - lookback)
        : prices;
    return slice.reduce((a, b) => a > b ? a : b);
  }

  /// Calculate Period Low
  static double? periodLow(List<double> prices, [int? lookback]) {
    if (prices.isEmpty) return null;
    final slice = (lookback != null && prices.length > lookback)
        ? prices.sublist(prices.length - lookback)
        : prices;
    return slice.reduce((a, b) => a < b ? a : b);
  }

  /// Calculate Classical Support & Resistance Pivot Levels
  static Map<String, double>? pivotLevels(List<double> prices, {int lookback = 30}) {
    if (prices.length < 2) return null;
    final slice = prices.length > lookback ? prices.sublist(prices.length - lookback) : prices;
    final high = slice.reduce((a, b) => a > b ? a : b);
    final low = slice.reduce((a, b) => a < b ? a : b);
    final close = prices.last;

    final p = (high + low + close) / 3;
    final r1 = (2 * p) - low;
    final s1 = (2 * p) - high;
    final r2 = p + (high - low);
    final s2 = p - (high - low);

    return {
      'pivot': p,
      'r1': r1,
      's1': s1,
      'r2': r2,
      's2': s2,
    };
  }

  /// Fetch GLD ETF holdings CSV
  Future<double?> fetchGldHoldings() async {
    final cached =
        HiveService.getIfFresh(HiveService.priceBox, 'gld_holdings');
    if (cached != null) return double.tryParse(cached);

    try {
      final dio = DioService.generic;
      final response = await dio.get(
        'https://www.spdrgoldshares.com/library/csvs/open-end-series.csv',
      );
      final lines = response.data.toString().split('\n');
      final data = lines
          .where((l) => l.trim().isNotEmpty && !l.startsWith('Date'))
          .last
          .split(',');
      if (data.length >= 2) {
        final tonnes = double.tryParse(data[1].trim());
        if (tonnes != null) {
          await HiveService.setWithTtl(
              HiveService.priceBox, 'gld_holdings', tonnes.toString(), 60 * 24);
          return tonnes;
        }
      }
    } catch (_) {}
    return null;
  }
}
