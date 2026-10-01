import 'package:flutter_dotenv/flutter_dotenv.dart';

// Core configuration constants
class AppConfig {
  static const String appName = 'Gold & Silver AI';
  static const String appVersion = '1.0.0';

  // Feature Flags from .env or compile-time environments
  static bool get enableGoldApi {
    final envVal = dotenv.env['ENABLE_GOLD_API']?.toLowerCase().trim();
    if (envVal != null && envVal.isNotEmpty) {
      return envVal == 'true' || envVal == '1';
    }
    return const bool.fromEnvironment('ENABLE_GOLD_API', defaultValue: true);
  }

  static bool get enableYahooApi {
    final envVal = dotenv.env['ENABLE_YAHOO_API']?.toLowerCase().trim();
    if (envVal != null && envVal.isNotEmpty) {
      return envVal == 'true' || envVal == '1';
    }
    return const bool.fromEnvironment('ENABLE_YAHOO_API', defaultValue: false);
  }

  static const bool showMarketOverview = false;
  static const bool enableMarketOverviewApi = false;
  static const bool enableMockIfNoApiKey = true;

  // GoldAPI.io
  static String get goldApiKey {
    final envKey = dotenv.env['GOLD_API_KEY']?.trim();
    if (envKey != null && envKey.isNotEmpty && !envKey.startsWith('YOUR_')) {
      return envKey;
    }
    return const String.fromEnvironment('GOLD_API_KEY', defaultValue: '');
  }
  static const String goldApiBaseUrl = 'https://www.goldapi.io/api/price';
  // Flag to control fetching USD spot price from GoldAPI (kept disabled to prevent redundant API calls and conserve quota)
  static const bool enableGoldApiUsd = false;
  static const int goldApiTtlMin = 15; // 15-minute cache to conserve free monthly quota

  // Gemini
  static String get geminiApiKey {
    final envKey = dotenv.env['GEMINI_API_KEY']?.trim();
    if (envKey != null && envKey.isNotEmpty && !envKey.startsWith('YOUR_')) {
      return envKey;
    }
    return const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  }
  static const String geminiModel = 'gemini-1.5-flash';
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // FRED API
  static String get fredApiKey {
    final envKey = dotenv.env['FRED_API_KEY']?.trim();
    if (envKey != null && envKey.isNotEmpty && !envKey.startsWith('YOUR_')) {
      return envKey;
    }
    return const String.fromEnvironment('FRED_API_KEY', defaultValue: '');
  }
  static const String fredBaseUrl = 'https://api.stlouisfed.org/fred/series/observations';

  // Yahoo Finance
  static const String yahooFinanceBase =
      'https://query1.finance.yahoo.com/v8/finance/chart';

  // GoodReturns
  static const String goodReturnsGoldUrl =
      'https://www.goodreturns.in/gold-rates/';

  // Cache TTLs (minutes)
  static const int pricesTtlMin = 5;
  static const int macroTtlMin = 720; // 12 hours
  static const int newsTtlMin = 30;
  static const int predictionTtlMin = 30;
  static const int cftcTtlMin = 10080; // 7 days

  // Yahoo Finance symbols
  static const Map<String, String> yahooSymbols = {
    'GOLD_USD': 'GC=F',
    'SILVER_USD': 'SI=F',
    'USD_INR': 'INR=X',
    'DXY': 'DX-Y.NYB',
    'VIX': '^VIX',
    'US_10Y': '^TNX',
    'US_2Y': '^IRX',
    'BRENT': 'BZ=F',
    'SP500': '^GSPC',
    'NIFTY': '^NSEI',
    'EUR_USD': 'EURUSD=X',
    'USD_CNY': 'USDCNY=X',
    'BTC_USD': 'BTC-USD',
    'GOLD_BEES': 'GOLDBEES.NS',
    'SILVER_BEES': 'SILVERBEES.NS',
    'REGIONAL_BANKS': 'KRE',
  };

  // FRED series
  static const Map<String, String> fredSeries = {
    'CPI': 'CPIAUCSL',
    'CORE_CPI': 'CPILFESL',
    'CORE_PCE': 'PCEPILFE',
    'REAL_YIELD_10Y': 'DFII10',
    'BREAKEVEN_10Y': 'T10YIE',
    'FED_FUNDS': 'FEDFUNDS',
    'UNEMPLOYMENT': 'UNRATE',
    'DEBT_TO_GDP': 'GFDEGDQ188S',
  };

  // India festival calendar (approximate DOY)
  static const List<Map<String, dynamic>> festivalCalendar = [
    {'name': 'Akshaya Tritiya', 'month': 5, 'day': 10},
    {'name': 'Dhanteras', 'month': 10, 'day': 20},
    {'name': 'Diwali', 'month': 10, 'day': 23},
    {'name': 'Navratri', 'month': 10, 'day': 2},
    {'name': 'Dussehra', 'month': 10, 'day': 12},
    {'name': 'Ganesh Chaturthi', 'month': 9, 'day': 5},
    {'name': 'Pushya Nakshatra', 'month': 10, 'day': 16},
  ];

  // Indian wedding peak season months (1-indexed: Nov, Dec, Jan, Feb, Apr, May)
  static const List<int> weddingSeasonMonths = [1, 2, 4, 5, 11, 12];
}
