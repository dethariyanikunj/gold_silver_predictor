import '../models/market_data_model.dart';
import '../services/yahoo_finance_service.dart';
import '../services/gold_api_service.dart';
import '../services/fred_service.dart';
import '../../../core/config/app_config.dart';

class MarketRepository {
  final YahooFinanceService _yahoo = YahooFinanceService();
  final GoldApiService _goldApi = GoldApiService();
  final FredService _fred = FredService();

  Future<MarketDataModel> fetchAllMarketData() async {
    // 1. Fetch quotes for all configured symbols
    final allSymbols = AppConfig.yahooSymbols.values.toList();

    final [quotesDetailed, macro, goldHistory, silverHistory, gldHoldings, goldApiPrices] =
        await Future.wait([
      _yahoo.fetchQuotesDetailed(allSymbols),
      AppConfig.enableMarketOverviewApi
          ? _fred.fetchAllMacro()
          : Future.value(<String, Map<String, dynamic>?>{}),
      _yahoo.fetchHistoricalCloses('GC=F', range: '1y'),
      _yahoo.fetchHistoricalCloses('SI=F', range: '1y'),
      AppConfig.enableMarketOverviewApi
          ? _yahoo.fetchGldHoldings()
          : Future.value(null),
      AppConfig.enableGoldApi ? _goldApi.fetchPrices() : Future.value(null),
    ]);

    final qDetailed = quotesDetailed as Map<String, YahooQuote>;
    final q = qDetailed.map((k, v) => MapEntry(k, v.price));
    final m = macro as Map<String, Map<String, dynamic>?>;
    final goldCloses = goldHistory as List<double>;
    final silverCloses = silverHistory as List<double>;
    final gld = gldHoldings as double?;
    final gApi = goldApiPrices as GoldApiPriceResult?;

    // 2. Compute technical indicators
    final goldSma20 = YahooFinanceService.sma(goldCloses, 20);
    final goldSma50 = YahooFinanceService.sma(goldCloses, 50);
    final goldSma100 = YahooFinanceService.sma(goldCloses, 100);
    final goldSma200 = YahooFinanceService.sma(goldCloses, 200);
    final gold52wHigh = YahooFinanceService.periodHigh(goldCloses, 252);
    final gold52wLow = YahooFinanceService.periodLow(goldCloses, 252);
    final goldPivots = YahooFinanceService.pivotLevels(goldCloses);

    final silverSma20 = YahooFinanceService.sma(silverCloses, 20);
    final silverSma50 = YahooFinanceService.sma(silverCloses, 50);
    final silverSma100 = YahooFinanceService.sma(silverCloses, 100);
    final silverSma200 = YahooFinanceService.sma(silverCloses, 200);
    final silver52wHigh = YahooFinanceService.periodHigh(silverCloses, 252);
    final silver52wLow = YahooFinanceService.periodLow(silverCloses, 252);
    final silverPivots = YahooFinanceService.pivotLevels(silverCloses);

    final goldRsi = YahooFinanceService.rsi(goldCloses);
    final silverRsi = YahooFinanceService.rsi(silverCloses);

    final usdInr = q['INR=X'];
    var goldUsd = q['GC=F'];
    var silverUsd = q['SI=F'];
    var marketTime = qDetailed['GC=F']?.marketTime ??
        qDetailed['SI=F']?.marketTime ??
        DateTime.now();

    // 3. Determine Gold & Silver prices based on active flags
    double? goldInr;
    double? silverInr;

    if (AppConfig.enableGoldApi && gApi != null) {
      // Direct spot pricing from goldapi.io
      goldInr = gApi.gold.priceInr;
      silverInr = gApi.silver.priceInr;
      goldUsd = gApi.gold.priceUsd ?? goldUsd;
      silverUsd = gApi.silver.priceUsd ?? silverUsd;
      marketTime = gApi.gold.timestamp ?? marketTime;
    }

    // Fallback or Yahoo mode if goldInr/silverInr still null
    if (goldInr == null && goldUsd != null && usdInr != null) {
      goldInr = (goldUsd / 31.1034768) * 10 * usdInr * 1.09;
    }
    if (silverInr == null && silverUsd != null && usdInr != null) {
      silverInr = (silverUsd / 31.1034768) * 1000 * usdInr * 1.09;
    }

    final goldSilverRatio =
        (goldUsd != null && silverUsd != null && silverUsd > 0)
            ? goldUsd / silverUsd
            : null;

    // 4. Market condition
    String? marketCondition;
    if (goldUsd != null && goldSma20 != null && goldSma50 != null) {
      if (goldUsd > goldSma20 && goldSma20 > goldSma50) {
        marketCondition = 'BULL';
      } else if (goldUsd < goldSma20 && goldSma20 < goldSma50) {
        marketCondition = 'BEAR';
      } else {
        marketCondition = 'NEUTRAL';
      }
    }

    // 5. Seasonal data & wedding calendar
    final seasonal = _computeSeasonalData();

    // 6. Extract macro observations
    double? extractVal(String key) {
      final obs = m[key];
      if (obs == null) return null;
      return double.tryParse(obs['value']?.toString() ?? '');
    }

    final cpi = extractVal('CPI');
    final corePce = extractVal('CORE_PCE');
    final realYield = extractVal('REAL_YIELD_10Y');
    final breakeven = extractVal('BREAKEVEN_10Y');
    final fedFunds = extractVal('FED_FUNDS') ?? extractVal('FEDFUNDS');
    final unemployment = extractVal('UNEMPLOYMENT');
    final debtToGdp = extractVal('DEBT_TO_GDP');
    final cpiDate = m['CPI']?['date']?.toString();

    return MarketDataModel(
      goldUsd: goldUsd,
      goldInr: goldInr,
      silverUsd: silverUsd,
      silverInr: silverInr,
      usdInr: usdInr,
      dxy: q['DX-Y.NYB'],
      vix: q['^VIX'],
      us10YYield: q['^TNX'],
      us2YYield: q['^IRX'],
      brentCrude: q['BZ=F'],
      sp500: q['^GSPC'],
      nifty50: q['^NSEI'],
      eurUsd: q['EURUSD=X'],
      usdCny: q['USDCNY=X'],
      btcUsd: q['BTC-USD'],
      regionalBankIndex: q['KRE'],
      goldBeesInr: q['GOLDBEES.NS'],
      silverBeesInr: q['SILVERBEES.NS'],
      goldSilverRatio: goldSilverRatio,
      goldSma20: goldSma20,
      goldSma50: goldSma50,
      goldSma100: goldSma100,
      goldSma200: goldSma200,
      gold52wHigh: gold52wHigh,
      gold52wLow: gold52wLow,
      goldSupport1: goldPivots?['s1'],
      goldResistance1: goldPivots?['r1'],
      silverSma20: silverSma20,
      silverSma50: silverSma50,
      silverSma100: silverSma100,
      silverSma200: silverSma200,
      silver52wHigh: silver52wHigh,
      silver52wLow: silver52wLow,
      silverSupport1: silverPivots?['s1'],
      silverResistance1: silverPivots?['r1'],
      goldRsi14: goldRsi,
      silverRsi14: silverRsi,
      usInflationCpi: cpi,
      usCorePce: corePce,
      realYield10Y: realYield,
      breakeven10Y: breakeven,
      fedFundsRate: fedFunds,
      usUnemployment: unemployment,
      usDebtToGdp: debtToGdp,
      cpiDate: cpiDate,
      gldHoldingsTonnes: gld,
      daysToDhanteras: seasonal['dhanteras'] as int?,
      daysToAkshayaTritiya: seasonal['akshaya'] as int?,
      nextFestivalName: seasonal['nextName'] as String?,
      daysToNextFestival: seasonal['nextDays'] as int?,
      isWeddingSeason: seasonal['isWeddingSeason'] as bool,
      weddingSeasonLabel: seasonal['weddingLabel'] as String?,
      marketCondition: marketCondition,
      fetchedAt: marketTime,
    );
  }

  Map<String, dynamic> _computeSeasonalData() {
    final now = DateTime.now();
    final currentYear = now.year;

    int daysBetween(DateTime target) {
      final diff = target.difference(now).inDays;
      if (diff < 0) {
        // Already passed this year — use next year
        return DateTime(currentYear + 1, target.month, target.day)
            .difference(now)
            .inDays;
      }
      return diff;
    }

    final dhanteras = DateTime(currentYear, 10, 20);
    final akshaya = DateTime(currentYear, 5, 10);

    final festivals = AppConfig.festivalCalendar.map((f) {
      final date = DateTime(currentYear, f['month'] as int, f['day'] as int);
      return {
        'name': f['name'] as String,
        'days': daysBetween(date),
      };
    }).toList();

    festivals.sort((a, b) => (a['days'] as int).compareTo(b['days'] as int));
    final nextFestival = festivals.first;

    final isPeakWedding = AppConfig.weddingSeasonMonths.contains(now.month);
    final weddingLabel = isPeakWedding
        ? 'Active Peak Wedding Season (High Physical Retail Demand)'
        : 'Off-Peak Season (Normalized Retail Buying)';

    return {
      'dhanteras': daysBetween(dhanteras),
      'akshaya': daysBetween(akshaya),
      'nextName': nextFestival['name'],
      'nextDays': nextFestival['days'],
      'isWeddingSeason': isPeakWedding,
      'weddingLabel': weddingLabel,
    };
  }

  Future<double?> fetchQuoteDirect(String symbol) async {
    final quotes = await _yahoo.fetchQuotes([symbol]);
    return quotes[symbol];
  }
}
