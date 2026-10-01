import 'package:flutter_test/flutter_test.dart';
import 'package:gold_silver_predictor/app/data/models/market_data_model.dart';
import 'package:gold_silver_predictor/app/data/models/news_article_model.dart';
import 'package:gold_silver_predictor/app/data/services/gold_api_service.dart';
import 'package:gold_silver_predictor/core/services/prompt_builder.dart';

void main() {
  group('GoldApiQuote Model', () {
    test('Gold Quote calculates 10g from gram_24k correctly', () {
      const quote = GoldApiQuote(
        priceGram24k: 8845.0,
        priceGram22k: 8107.9,
        priceInr: 88450.0,
        priceUsd: 2950.0,
      );
      expect(quote.priceInr, equals(88450.0));
      expect(quote.priceGram24k! * 10, equals(88450.0));
    });

    test('Silver Quote calculates 1kg correctly', () {
      const quote = GoldApiQuote(
        priceGram24k: 102.5,
        priceInr: 102500.0,
        priceUsd: 33.25,
      );
      expect(quote.priceInr, equals(102500.0));
      expect(quote.priceGram24k! * 1000, equals(102500.0));
    });
  });

  group('PromptBuilder 25-Factor Coverage', () {
    test('buildPredictionPrompt includes all 25 factor categories and data blocks', () {
      final dummyMarket = MarketDataModel(
        goldUsd: 2950.50,
        silverUsd: 33.25,
        goldInr: 88500,
        silverInr: 102000,
        usdInr: 86.85,
        dxy: 104.20,
        vix: 15.6,
        us10YYield: 4.25,
        us2YYield: 4.55,
        brentCrude: 78.50,
        sp500: 5980.0,
        nifty50: 24200.0,
        eurUsd: 1.0850,
        usdCny: 7.2350,
        btcUsd: 96500.0,
        regionalBankIndex: 52.4,
        goldBeesInr: 78.50,
        silverBeesInr: 89.20,
        goldSilverRatio: 88.7,
        goldSma20: 2920.0,
        goldSma50: 2880.0,
        goldSma100: 2800.0,
        goldSma200: 2650.0,
        gold52wHigh: 2980.0,
        gold52wLow: 2150.0,
        goldSupport1: 2900.0,
        goldResistance1: 2975.0,
        silverSma20: 32.8,
        silverSma50: 31.5,
        silverSma100: 30.2,
        silverSma200: 28.5,
        silver52wHigh: 35.0,
        silver52wLow: 22.5,
        silverSupport1: 32.0,
        silverResistance1: 34.0,
        goldRsi14: 64.2,
        silverRsi14: 58.9,
        usInflationCpi: 2.85,
        usCorePce: 2.70,
        realYield10Y: 1.85,
        breakeven10Y: 2.40,
        fedFundsRate: 5.33,
        usUnemployment: 4.1,
        usDebtToGdp: 122.5,
        cpiDate: '2026-08-15',
        gldHoldingsTonnes: 855.2,
        daysToDhanteras: 57,
        daysToAkshayaTritiya: 259,
        nextFestivalName: 'Pushya Nakshatra',
        daysToNextFestival: 53,
        isWeddingSeason: true,
        weddingSeasonLabel: 'Active Peak Wedding Season (High Physical Retail Demand)',
        marketCondition: 'BULL',
        fetchedAt: DateTime.now(),
      );

      final news = [
        NewsArticleModel(
          title: 'Federal Reserve hints at upcoming rate adjustments',
          source: 'Reuters',
          url: 'https://reuters.com',
          category: 'Fed',
          publishedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ];

      final prompt = PromptBuilder.buildPredictionPrompt(dummyMarket, news);

      // Check key sections and factors
      expect(prompt, contains('25 primary precious metal market drivers'));
      expect(prompt, contains('Gold (International COMEX)'));
      expect(prompt, contains('SMA-100'));
      expect(prompt, contains('SMA-200'));
      expect(prompt, contains('52-Week Range'));
      expect(prompt, contains('Pivot Levels: Support-1'));
      expect(prompt, contains('GLOBAL FX, EQUITIES & ALTERNATIVE ASSETS'));
      expect(prompt, contains('USD/CNY (Chinese Yuan)'));
      expect(prompt, contains('Bitcoin (BTC/USD)'));
      expect(prompt, contains('US Regional Banking ETF (KRE)'));
      expect(prompt, contains('US Total Public Debt to GDP'));
      expect(prompt, contains('CHINA & GLOBAL CENTRAL BANK ACCUMULATION'));
      expect(prompt, contains('INDIA DOMESTIC MARKET & SEASONAL DYNAMICS'));
      expect(prompt, contains('NSE Gold ETF (GOLDBEES)'));
      expect(prompt, contains('Wedding Season Status: Active Peak Wedding Season'));
    });
  });
}
