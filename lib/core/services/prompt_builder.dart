import '../../app/data/models/market_data_model.dart';
import '../../app/data/models/news_article_model.dart';

class PromptBuilder {
  static String buildPredictionPrompt(
    MarketDataModel market,
    List<NewsArticleModel> news,
  ) {
    final newsBlock = _buildNewsBlock(news);
    final technicalBlock = _buildTechnicalBlock(market);
    final fxCryptoBlock = _buildGlobalFxCryptoBlock(market);
    final macroBlock = _buildMacroBlock(market);
    final chinaCentralBankBlock = _buildChinaCentralBankBlock(market);
    final indiaBlock = _buildIndiaBlock(market);

    return '''
You are a senior quantitative gold and silver market analyst with 20+ years of experience covering Indian (MCX/Rajkot/IBJA) and global precious metals markets.

You have deep expertise in analyzing all 25 primary precious metal market drivers:
1. US Interest Rates & Federal Reserve Monetary Policy (Fed dots, rate cuts/hikes, real rates)
2. US Dollar Index (DXY) & de-dollarisation trends
3. US Treasury Yield Curve, 10Y/2Y Yields & Real TIPS Yields
4. Geopolitical & War Escalations (Middle East, Russia-Ukraine, Taiwan, Korea, border tensions)
5. China Physical & Central Bank Demand (PBoC accumulation, Shanghai Gold Exchange withdrawals, Yuan strength)
6. Central Banks Worldwide (RBI, Poland, Turkey, Czech, WGC net buying data)
7. Global & Domestic ETF Flows (SPDR GLD tonnes, Indian Gold BeES, Silver BeES)
8. Global & Domestic Inflation (US CPI/Core PCE, Indian CPI/WPI, TIPS breakeven inflation)
9. Crude Oil (Brent/WTI, OPEC+ supply, Red Sea/Hormuz shipping disruptions)
10. India-Specific Factors (USD/INR, MCX premium/discount, Import Duty & GST structure)
11. Indian Festivals Calendar (Akshaya Tritiya, Dhanteras, Diwali, Navratri, Pushya Nakshatra)
12. Indian Wedding Season Dynamics (Peak vs Off-peak retail jewelry accumulation)
13. Gold Supply & Recycling (Mine output, scrap return rates, Swiss refinery throughput)
14. Major Producing Nations (China, Australia, Russia, Canada, South Africa, Peru, Mexico)
15. Global Equities & Liquidity Squeezes (S&P 500, Nifty 50, VIX fear index)
16. Banking & Financial Stress (Regional banks KRE, liquidity spreads, credit risks)
17. US Sovereign Debt & Fiscal Deficits (US Debt-to-GDP ratio, Treasury issuance pressure)
18. Foreign Central Banks (ECB, Bank of Japan, Bank of England, Swiss National Bank)
19. Key Foreign Exchange Rates (EUR/USD, USD/CNY, USD/INR)
20. High-Impact US Economic Prints (Non-Farm Payrolls, GDP, ISM, PPI, Jobless Claims)
21. Futures & Speculative Positioning (COMEX Open Interest, CFTC Net Long/Short contracts)
22. Technical Support/Resistance Levels (SMA-20/50/100/200, 52W High/Low, Pivot Points, RSI-14)
23. Silver Industrial Complex (Gold/Silver ratio, Solar PV paste demand, green tech supply deficit)
24. Alternative Digital Assets & Crypto (Bitcoin liquidity competition / safe-haven rotation)
25. Black Swan & Tail-Risk Preparedness (Sudden geopolitical shocks, currency devaluations, bank failures)

IMPORTANT RULES:
1. Your prediction MUST be grounded in the provided real-time data below.
2. Gold and Silver must have SEPARATE predictions — do not use the same model for both.
3. Silver prediction must specifically address industrial demand drivers (solar PV, electronics, supply deficits).
4. Return ONLY valid JSON matching the exact schema provided — no markdown, no explanation outside JSON.
5. If signals are conflicting or uncertain, output direction "HIGH_UNCERTAINTY" and reduce confidence.
6. Never fabricate specific numbers — base ranges on current price ± realistic percentage moves for each horizon.
7. Explanation must reference the ACTUAL data provided, not generic statements.

═══════════════════════════════════════════════
REAL-TIME MARKET DATA (as of ${DateTime.now().toLocal()})
═══════════════════════════════════════════════

$technicalBlock

$fxCryptoBlock

$macroBlock

$chinaCentralBankBlock

$indiaBlock

$newsBlock

═══════════════════════════════════════════════
REQUIRED JSON SCHEMA
═══════════════════════════════════════════════

{
  "gold": {
    "overall_sentiment": <0-100 integer>,
    "overall_theme": "<one-line summary>",
    "next_day": {
      "predicted_price_inr": <number>,
      "range_low_inr": <number>,
      "range_high_inr": <number>,
      "predicted_price_usd": <number>,
      "direction": "<BULLISH|BEARISH|NEUTRAL|HIGH_UNCERTAINTY>",
      "change_percent": <number, signed>,
      "confidence": <0-100 integer>,
      "risk_level": "<LOW|MEDIUM|HIGH>",
      "sentiment_score": <0-100 integer>,
      "bullish_factors": [
        {"key": "<FACTOR_KEY>", "label": "<short human label>", "strength": <1-10>}
      ],
      "bearish_factors": [
        {"key": "<FACTOR_KEY>", "label": "<short human label>", "strength": <1-10>}
      ],
      "uncertainty_flags": ["<flag if any>"],
      "explanation": "<2-3 sentence paragraph grounded in actual data above>",
      "major_events_this_period": ["<event if any>"]
    },
    "next_week": { <same structure> },
    "next_month": { <same structure> }
  },
  "silver": {
    "overall_sentiment": <0-100>,
    "overall_theme": "<one-line>",
    "next_day": { <same structure as gold.next_day> },
    "next_week": { <same structure> },
    "next_month": { <same structure> }
  },
  "market_overview": {
    "market_condition": "<RISK_ON|RISK_OFF|NEUTRAL|CRISIS>",
    "key_theme": "<single most important macro theme driving markets today>"
  }
}

Now generate the quantitative precious metals prediction based on all 25 factors above. Return ONLY the JSON object.
''';
  }

  static String _buildTechnicalBlock(MarketDataModel m) {
    final gsRatio = m.goldSilverRatio?.toStringAsFixed(1) ?? 'N/A';
    final goldTrend = _trendSignal(m.goldUsd, m.goldSma20, m.goldSma50);
    final silverTrend = _trendSignal(m.silverUsd, m.silverSma20, m.silverSma50);

    return '''
[1. CURRENT PRICES & TECHNICAL INDICATORS]
Gold (International COMEX): \$${m.goldUsd?.toStringAsFixed(2) ?? 'N/A'}/oz
Gold (India Calculated MCX 10g): ₹${m.goldInr?.toStringAsFixed(0) ?? 'N/A'}/10g
Silver (International COMEX): \$${m.silverUsd?.toStringAsFixed(3) ?? 'N/A'}/oz
Silver (India Calculated MCX 1kg): ₹${m.silverInr?.toStringAsFixed(0) ?? 'N/A'}/kg
Gold/Silver Ratio: $gsRatio (historical mean ~70; >80 = silver relatively cheap)
VIX (Volatility/Fear Index): ${m.vix?.toStringAsFixed(2) ?? 'N/A'}

[TECHNICAL LEVELS — GOLD]
SMA-20: \$${m.goldSma20?.toStringAsFixed(2) ?? 'N/A'} | SMA-50: \$${m.goldSma50?.toStringAsFixed(2) ?? 'N/A'}
SMA-100: \$${m.goldSma100?.toStringAsFixed(2) ?? 'N/A'} | SMA-200: \$${m.goldSma200?.toStringAsFixed(2) ?? 'N/A'}
RSI-14: ${m.goldRsi14?.toStringAsFixed(1) ?? 'N/A'} ${_rsiLabel(m.goldRsi14)}
52-Week Range: Low \$${m.gold52wLow?.toStringAsFixed(2) ?? 'N/A'} — High \$${m.gold52wHigh?.toStringAsFixed(2) ?? 'N/A'}
Pivot Levels: Support-1: \$${m.goldSupport1?.toStringAsFixed(2) ?? 'N/A'} | Resistance-1: \$${m.goldResistance1?.toStringAsFixed(2) ?? 'N/A'}
Trend: $goldTrend

[TECHNICAL LEVELS — SILVER]
SMA-20: \$${m.silverSma20?.toStringAsFixed(3) ?? 'N/A'} | SMA-50: \$${m.silverSma50?.toStringAsFixed(3) ?? 'N/A'}
SMA-100: \$${m.silverSma100?.toStringAsFixed(3) ?? 'N/A'} | SMA-200: \$${m.silverSma200?.toStringAsFixed(3) ?? 'N/A'}
RSI-14: ${m.silverRsi14?.toStringAsFixed(1) ?? 'N/A'} ${_rsiLabel(m.silverRsi14)}
52-Week Range: Low \$${m.silver52wLow?.toStringAsFixed(3) ?? 'N/A'} — High \$${m.silver52wHigh?.toStringAsFixed(3) ?? 'N/A'}
Pivot Levels: Support-1: \$${m.silverSupport1?.toStringAsFixed(3) ?? 'N/A'} | Resistance-1: \$${m.silverResistance1?.toStringAsFixed(3) ?? 'N/A'}
Trend: $silverTrend

[POSITIONING & ETF FLOWS]
GLD ETF Physical Holdings: ${m.gldHoldingsTonnes?.toStringAsFixed(1) ?? 'N/A'} tonnes
CFTC Gold Net Long Contracts: ${m.cftcGoldNetLong?.toStringAsFixed(0) ?? 'N/A'}
CFTC Silver Net Long Contracts: ${m.cftcSilverNetLong?.toStringAsFixed(0) ?? 'N/A'}''';
  }

  static String _buildGlobalFxCryptoBlock(MarketDataModel m) {
    return '''
[2. GLOBAL FX, EQUITIES & ALTERNATIVE ASSETS]
US Dollar Index (DXY): ${m.dxy?.toStringAsFixed(2) ?? 'N/A'}
EUR/USD: ${m.eurUsd?.toStringAsFixed(4) ?? 'N/A'}
USD/CNY (Chinese Yuan): ${m.usdCny?.toStringAsFixed(4) ?? 'N/A'} (weak Yuan spurs domestic Chinese gold buying)
Bitcoin (BTC/USD): \$${m.btcUsd?.toStringAsFixed(0) ?? 'N/A'} (alternative asset liquidity barometer)
S&P 500: ${m.sp500?.toStringAsFixed(0) ?? 'N/A'}
Nifty 50: ${m.nifty50?.toStringAsFixed(0) ?? 'N/A'}
US Regional Banking ETF (KRE): \$${m.regionalBankIndex?.toStringAsFixed(2) ?? 'N/A'} (banking system stress indicator)
Brent Crude Oil: \$${m.brentCrude?.toStringAsFixed(2) ?? 'N/A'}/bbl''';
  }

  static String _buildMacroBlock(MarketDataModel m) {
    final debtGdpStr = m.usDebtToGdp != null ? '${m.usDebtToGdp!.toStringAsFixed(1)}%' : 'N/A';
    return '''
[3. US MACROECONOMICS, DEBT & MONETARY POLICY]
US CPI Inflation (${m.cpiDate ?? 'latest'}): ${m.usInflationCpi?.toStringAsFixed(2) ?? 'N/A'}%
Core PCE Inflation: ${m.usCorePce?.toStringAsFixed(2) ?? 'N/A'}%
Federal Funds Rate: ${m.fedFundsRate?.toStringAsFixed(2) ?? 'N/A'}%
US Unemployment Rate: ${m.usUnemployment?.toStringAsFixed(1) ?? 'N/A'}%
US 10-Year Real Yield (TIPS): ${m.realYield10Y?.toStringAsFixed(3) ?? 'N/A'}% (CRITICAL: lower/negative real yields are strongly bullish for gold)
10-Year TIPS Breakeven Inflation: ${m.breakeven10Y?.toStringAsFixed(3) ?? 'N/A'}%
US 10-Year Treasury Yield: ${m.us10YYield?.toStringAsFixed(3) ?? 'N/A'}%
US 2-Year Treasury Yield: ${m.us2YYield?.toStringAsFixed(3) ?? 'N/A'}%
US Total Public Debt to GDP: $debtGdpStr (fiscal deficit sustainability concerns support gold hedge)''';
  }

  static String _buildChinaCentralBankBlock(MarketDataModel m) {
    return '''
[4. CHINA & GLOBAL CENTRAL BANK ACCUMULATION]
China PBoC Official Gold Reserves: Continuous multi-month structural reserve accumulation.
Shanghai Gold Exchange (SGE) Premium/Withdrawals: Strong physical wholesale delivery demand in Asia.
Central Bank Reserve Diversification: Persistent net-buying by emerging market central banks (India RBI, China, Turkey, Poland) hedging against foreign reserve sanctions and USD weaponization.''';
  }

  static String _buildIndiaBlock(MarketDataModel m) {
    final goldBeesStr = m.goldBeesInr != null ? '₹${m.goldBeesInr!.toStringAsFixed(2)}/unit' : 'N/A';
    final silverBeesStr = m.silverBeesInr != null ? '₹${m.silverBeesInr!.toStringAsFixed(2)}/unit' : 'N/A';
    final weddingStatus = m.weddingSeasonLabel ?? 'Standard Seasonal Demand';

    return '''
[5. INDIA DOMESTIC MARKET & SEASONAL DYNAMICS]
USD/INR: ${m.usdInr?.toStringAsFixed(2) ?? 'N/A'} (higher USD/INR directly amplifies domestic landed cost)
NSE Gold ETF (GOLDBEES): $goldBeesStr
NSE Silver ETF (SILVERBEES): $silverBeesStr
Landed Duty Structure: Post-Budget 2024 revised ~6% Customs Duty/AIDC + 3% GST (~9% total tax).
Days to Next Major Festival (${m.nextFestivalName ?? 'Dhanteras'}): ${m.daysToNextFestival ?? 'N/A'} days
Days to Dhanteras: ${m.daysToDhanteras ?? 'N/A'} days | Days to Akshaya Tritiya: ${m.daysToAkshayaTritiya ?? 'N/A'} days
Wedding Season Status: $weddingStatus
Notice on Price Elasticity: Domestic physical gold buying in India is price-elastic; extremely high nominal prices may dampen volume even during festive/wedding dates unless supported by rural income and stable spot prices.''';
  }

  static String _buildNewsBlock(List<NewsArticleModel> news) {
    if (news.isEmpty) return '[6. RECENT FINANCIAL & GEOPOLITICAL NEWS]\nNo recent news articles available.';

    final sb = StringBuffer('[6. RECENT FINANCIAL & GEOPOLITICAL NEWS — Last 48 Hours]\n');
    final relevant = news.take(15);
    int i = 1;
    for (final article in relevant) {
      final hoursAgo = article.publishedAt != null
          ? DateTime.now().difference(article.publishedAt!).inHours
          : null;
      final timeLabel = hoursAgo != null ? '${hoursAgo}h ago' : 'recent';
      sb.writeln('$i. [${article.category ?? "Markets"}] "${article.title}" — ${article.source} — $timeLabel');
      i++;
    }
    sb.writeln(
        '\nEvaluate these news events for immediate safe-haven impulse, black-swan risks, and interest rate repricing.');
    return sb.toString();
  }

  static String _rsiLabel(double? rsi) {
    if (rsi == null) return '';
    if (rsi > 70) return '(OVERBOUGHT — bearish reversal risk)';
    if (rsi < 30) return '(OVERSOLD — bullish reversal potential)';
    if (rsi > 60) return '(Mildly overbought)';
    if (rsi < 40) return '(Mildly oversold)';
    return '(Neutral range)';
  }

  static String _trendSignal(
      double? price, double? sma20, double? sma50) {
    if (price == null || sma20 == null || sma50 == null) {
      return 'Insufficient data';
    }
    if (price > sma20 && sma20 > sma50) {
      return 'BULLISH (price > SMA20 > SMA50)';
    }
    if (price < sma20 && sma20 < sma50) {
      return 'BEARISH (price < SMA20 < SMA50)';
    }
    if (price > sma20 && sma20 < sma50) {
      return 'RECOVERING (price above SMA20 but below SMA50)';
    }
    return 'MIXED signals';
  }
}
