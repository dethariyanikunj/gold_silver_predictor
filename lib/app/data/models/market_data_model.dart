class MarketDataModel {
  final double? goldUsd;
  final double? silverUsd;
  final double? goldInr;
  final double? silverInr;
  final double? usdInr;
  final double? dxy;
  final double? vix;
  final double? us10YYield;
  final double? us2YYield;
  final double? brentCrude;
  final double? sp500;
  final double? nifty50;
  final double? goldSilverRatio;
  final double? goldSma20;
  final double? goldSma50;
  final double? goldSma100;
  final double? goldSma200;
  final double? gold52wHigh;
  final double? gold52wLow;
  final double? goldSupport1;
  final double? goldResistance1;

  final double? silverSma20;
  final double? silverSma50;
  final double? silverSma100;
  final double? silverSma200;
  final double? silver52wHigh;
  final double? silver52wLow;
  final double? silverSupport1;
  final double? silverResistance1;

  final double? goldRsi14;
  final double? silverRsi14;

  // Global FX & Alternative Assets
  final double? eurUsd;
  final double? usdCny;
  final double? btcUsd;
  final double? regionalBankIndex; // KRE

  // Domestic Indian Rates & ETFs
  final double? goldBeesInr;
  final double? silverBeesInr;

  // FRED macro
  final double? usInflationCpi;
  final double? usCorePce;
  final double? realYield10Y;
  final double? breakeven10Y;
  final double? fedFundsRate;
  final double? usUnemployment;
  final double? usDebtToGdp;
  final String? cpiDate;

  // CFTC
  final double? cftcGoldNetLong;
  final double? cftcSilverNetLong;
  final String? cftcDate;

  // ETF
  final double? gldHoldingsTonnes;
  final String? gldDate;

  // India seasonal & wedding
  final int? daysToDhanteras;
  final int? daysToAkshayaTritiya;
  final String? nextFestivalName;
  final int? daysToNextFestival;
  final bool isWeddingSeason;
  final String? weddingSeasonLabel;

  // Market condition
  final String? marketCondition; // BULL / BEAR / SIDEWAYS

  final DateTime fetchedAt;

  const MarketDataModel({
    this.goldUsd,
    this.silverUsd,
    this.goldInr,
    this.silverInr,
    this.usdInr,
    this.dxy,
    this.vix,
    this.us10YYield,
    this.us2YYield,
    this.brentCrude,
    this.sp500,
    this.nifty50,
    this.goldSilverRatio,
    this.goldSma20,
    this.goldSma50,
    this.goldSma100,
    this.goldSma200,
    this.gold52wHigh,
    this.gold52wLow,
    this.goldSupport1,
    this.goldResistance1,
    this.silverSma20,
    this.silverSma50,
    this.silverSma100,
    this.silverSma200,
    this.silver52wHigh,
    this.silver52wLow,
    this.silverSupport1,
    this.silverResistance1,
    this.goldRsi14,
    this.silverRsi14,
    this.eurUsd,
    this.usdCny,
    this.btcUsd,
    this.regionalBankIndex,
    this.goldBeesInr,
    this.silverBeesInr,
    this.usInflationCpi,
    this.usCorePce,
    this.realYield10Y,
    this.breakeven10Y,
    this.fedFundsRate,
    this.usUnemployment,
    this.usDebtToGdp,
    this.cpiDate,
    this.cftcGoldNetLong,
    this.cftcSilverNetLong,
    this.cftcDate,
    this.gldHoldingsTonnes,
    this.gldDate,
    this.daysToDhanteras,
    this.daysToAkshayaTritiya,
    this.nextFestivalName,
    this.daysToNextFestival,
    this.isWeddingSeason = false,
    this.weddingSeasonLabel,
    this.marketCondition,
    required this.fetchedAt,
  });
}
