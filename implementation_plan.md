# Gold & Silver Price Prediction — Revised Personal App Plan

> **Platform**: Flutter (Android / iOS / Web) · GetX · Dio  
> **Usage**: Personal only — no auth, no backend, no hosting, no DB  
> **Cost target**: ₹0/month (free APIs only + Gemini free tier)  
> **Model**: Single-click → fetch live data → Gemini prediction → display result

---

## Answers to Open Questions — Summary

| Question | Decision |
|---|---|
| MCX Data | Use free public sources only (Yahoo Finance, GoodReturns scraping) |
| LLM Provider | Gemini API — free tier (Gemini 1.5 Flash) |
| Auth | No auth required — personal use only |
| Backend/Hosting | None — app runs fully on-device |
| Database | None — local Hive cache only |
| News Budget | Free RSS feeds only (Reuters, ET, Bloomberg, Moneycontrol) |
| Distribution | Personal only — no Play Store / App Store publishing required |

---

## Revised Architecture — No Backend

```
┌────────────────────────────────────────────────────────────────────┐
│                    FLUTTER APP (On-Device)                          │
│            Android / iOS / Web  ─  GetX  ─  Dio                   │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────────┐  │
│  │  Dashboard   │  │  Prediction  │  │  News & Factors Screen  │  │
│  │  Screen      │  │  Screen      │  │                         │  │
│  └──────┬───────┘  └──────┬───────┘  └────────────┬────────────┘  │
│         └─────────────────┴──────────────────────┘               │
│                            │ GetX Controllers                      │
│  ┌─────────────────────────▼──────────────────────────────────┐   │
│  │                  Data Aggregation Layer                     │   │
│  │   Fetches all live data → structures into prediction prompt │   │
│  └──────────────────────────┬─────────────────────────────────┘   │
│                             │                                      │
│  ┌──────────────────────────▼─────────────────────────────────┐   │
│  │               Hive Local Cache                              │   │
│  │   Stores last fetched data, last prediction result,         │   │
│  │   and basic accuracy log (predicted vs. actual)             │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────┬──────────────────────────────────────────────┘
                      │  Dio HTTP calls
         ┌────────────┼──────────────────────────────┐
         ▼            ▼                              ▼
  ┌─────────────┐ ┌──────────────┐         ┌────────────────────┐
  │ Price APIs  │ │ Macro APIs   │         │   Gemini API       │
  │ (Free)      │ │ (Free)       │         │ (Prediction Engine)│
  └─────────────┘ └──────────────┘         └────────────────────┘
         ▼            ▼
  ┌──────────────────────────┐
  │    Free News RSS Feeds   │
  └──────────────────────────┘
```

**Key principle**: The app collects all data itself, structures it, and sends it to Gemini with a carefully engineered prompt. Gemini returns a structured JSON prediction. The app renders the result.

---

## Free Data Sources

### Gold & Silver Prices (India)

| Data | Source | Method | Free? |
|---|---|---|---|
| MCX Gold / Silver (India, ₹) | Yahoo Finance (`GC=F`, `SI=F` + MCX symbols) | Dio HTTP | ✅ Free |
| Gold/Silver price India (₹/10g) | GoodReturns.in | HTML scrape via Dio | ✅ Free |
| Gold 24K/22K daily (India) | gold.org / GoodReturns | Scrape | ✅ Free |
| International Gold (USD/oz) | Yahoo Finance (`GC=F`) | Dio HTTP | ✅ Free |
| International Silver (USD/oz) | Yahoo Finance (`SI=F`) | Dio HTTP | ✅ Free |
| MCX Futures | Yahoo Finance MCX tickers | Dio HTTP | ✅ Free |

### Exchange Rates & Market Indicators

| Data | Source | Free? |
|---|---|---|
| USD/INR | Yahoo Finance (`INR=X`) | ✅ Free |
| DXY (Dollar Index) | Yahoo Finance (`DX-Y.NYB`) | ✅ Free |
| VIX (Fear Index) | Yahoo Finance (`^VIX`) | ✅ Free |
| US 10-Year Treasury Yield | Yahoo Finance (`^TNX`) | ✅ Free |
| US 2-Year Treasury Yield | Yahoo Finance (`^IRX`) | ✅ Free |
| Gold/Silver Ratio | Computed from GC=F / SI=F | ✅ Computed |
| S&P 500 | Yahoo Finance (`^GSPC`) | ✅ Free |
| Nifty 50 | Yahoo Finance (`^NSEI`) | ✅ Free |
| Crude Oil (Brent) | Yahoo Finance (`BZ=F`) | ✅ Free |

> **Yahoo Finance Approach**: Use the unofficial Yahoo Finance query endpoint:  
> `https://query1.finance.yahoo.com/v8/finance/chart/{symbol}?interval=1d&range=3mo`  
> This is publicly accessible and widely used.

### Macro Economic Data (FRED — Completely Free)

| Data | FRED Series ID | Update Frequency |
|---|---|---|
| US CPI (YoY) | `CPIAUCSL` | Monthly |
| Core CPI | `CPILFESL` | Monthly |
| PCE | `PCEPI` | Monthly |
| Core PCE | `PCEPILFE` | Monthly |
| US 10Y Real Yield (TIPS) | `DFII10` | Daily |
| TIPS Breakeven 10Y | `T10YIE` | Daily |
| US Fed Funds Rate | `FEDFUNDS` | Monthly |
| US Unemployment Rate | `UNRATE` | Monthly |
| US GDP Growth (QoQ) | `A191RL1Q225SBEA` | Quarterly |
| MOVE Index (Bond Volatility) | `MOVEINDEX` | Daily |
| Global Economic Policy Uncertainty | `GEPUCURRENT` | Monthly |
| Geopolitical Risk Index | External: policyuncertainty.com | Monthly |

> **FRED API**: Free with API key registration at `fred.stlouisfed.org`.  
> Rate limit: 120 requests/minute. Well within personal app usage.

### News (Free RSS Feeds)

| Source | RSS URL | Category |
|---|---|---|
| Reuters Business | `https://feeds.reuters.com/reuters/businessNews` | General finance |
| Reuters Commodities | `https://feeds.reuters.com/reuters/companyNews` | Commodities |
| Bloomberg Markets | `https://feeds.bloomberg.com/markets/news.rss` | Markets |
| Economic Times Markets | `https://economictimes.indiatimes.com/markets/rss.cms` | India |
| Economic Times Commodities | `https://economictimes.indiatimes.com/commodities-rss.cms` | India commodities |
| Moneycontrol Commodities | `https://www.moneycontrol.com/rss/commodity.xml` | India MCX |
| Kitco News (Gold) | `https://www.kitco.com/rss/` | Gold/Silver specific |
| Mining.com | `https://www.mining.com/feed/` | Mining supply |
| World Gold Council | `https://www.gold.org/goldhub/rss` | WGC reports |

> **Note**: RSS parsing is done locally in the app using Dart XML parser.  
> No news API key or subscription needed.

### ETF & Positioning (Free)

| Data | Source | Method |
|---|---|---|
| GLD ETF holdings (tonnes) | `spdrgoldshares.com/library/csvs/open-end-series.csv` | CSV download |
| SLV ETF holdings | `ishares.com` / Bloomberg free | CSV download |
| Indian Gold ETF NAV | NSE India website (public) | Scrape |
| CFTC COT Gold/Silver | `cftc.gov/MarketReports/CommitmentsofTraders` | CSV download (weekly) |
| World Gold Council demand data | `gold.org` open data | Download |

---

## Gemini API Strategy (Free Tier)

### Free Tier Limits (Gemini 1.5 Flash — as of 2026)
- 15 requests per minute
- 1 million tokens per minute  
- 1,500 requests per day

**Personal app usage**: 1 prediction request ≈ ~3,000–5,000 tokens.  
At 10 predictions/day → ~50,000 tokens/day → well within free tier.

### Why Gemini Instead of a Traditional ML Model (Revised Decision)

Since there is:
- No backend server
- No ability to train and host ML models on-device at scale
- No historical database for backtesting

The revised approach is:

> **Gemini acts as the prediction engine, receiving all fetched real-time data as structured context, and returning a structured JSON prediction.**

This is NOT a simple "will gold go up?" question. It is a **highly structured, data-grounded prompt** where Gemini:
1. Receives actual current numerical data (prices, rates, yields, sentiment)
2. Receives recent news headlines with category labels
3. Receives historical context (fetched from Yahoo Finance 3-month history)
4. Uses its trained knowledge of gold/silver market relationships
5. Returns a structured JSON response (not free-form text)

### Gemini Prompt Architecture

```
SYSTEM PROMPT (fixed, loaded from local asset):
  "You are a quantitative gold and silver price analyst AI...
   You have deep knowledge of: [full factor list from planning]...
   You must return ONLY valid JSON in the exact schema provided.
   Never fabricate data. If data is missing, note it explicitly.
   Your prediction must be grounded in the provided real-time data..."

USER PROMPT (dynamic, assembled at runtime):
  [CURRENT MARKET DATA]
  Gold (International): $2,480/oz (+0.3% today)
  Gold (India MCX): ₹72,450/10g (+₹210 today)
  Silver (International): $29.40/oz
  USD/INR: 83.72 (+0.15% today)
  DXY: 104.2 (-0.3%)
  US 10Y Yield: 4.28% (-0.04% today)
  US 10Y Real Yield (TIPS): 2.1%
  TIPS Breakeven Inflation: 2.18%
  VIX: 18.4
  Brent Crude: $81.20
  Gold/Silver Ratio: 84.2
  
  [MACRO CONTEXT — Last Released Values]
  US CPI (latest, June 2026): 3.2% YoY
  Core CPI: 3.0%
  Core PCE: 2.8%
  Fed Funds Rate: 4.75%
  US Unemployment: 4.1%
  
  [3-MONTH PRICE TREND]
  Gold high (3M): $2,530 | Low: $2,310 | Current: $2,480
  Gold 20-day SMA: $2,451 | 50-day SMA: $2,398 (price above both = bullish)
  Silver high (3M): $31.2 | Low: $26.8
  
  [RECENT NEWS — Last 48 Hours]
  1. [FED/INFLATION] "Fed Chair signals possible rate cut in September" — Kitco — 6h ago
  2. [GEOPOLITICS] "Middle East tensions escalate as Iran threatens..." — Reuters — 12h ago
  3. [CHINA] "PBoC adds 8 tonnes to gold reserves in July" — Bloomberg — 18h ago
  4. [INDIA] "India gold imports surge ahead of festival season" — ET — 24h ago
  5. [SILVER] "Solar installations hit record; silver demand outlook upgraded" — Mining.com — 36h ago
  
  [INDIA SEASONAL CALENDAR]
  Days to Dhanteras: 67 days
  Days to Akshaya Tritiya: 245 days
  Current season: Post-monsoon (moderate demand)
  
  Please provide Gold and Silver predictions for:
  1. Next Day (24h)
  2. Next Week (7 days)
  3. Next Month (30 days)
  
  Return ONLY the following JSON schema:
  { "gold": { "next_day": {...}, "next_week": {...}, "next_month": {...} },
    "silver": { ... },
    "market_overview": { ... } }
```

### Gemini Response Schema (JSON)

```json
{
  "gold": {
    "next_day": {
      "predicted_price_inr": 72800,
      "range_low_inr": 72100,
      "range_high_inr": 73400,
      "predicted_price_usd": 2492,
      "direction": "BULLISH",
      "change_percent": 0.48,
      "confidence": 68,
      "risk_level": "MEDIUM",
      "sentiment_score": 71,
      "bullish_factors": [
        { "factor": "FED_RATE_CUT_SIGNAL", "label": "Fed Chair signals September rate cut", "strength": 9 },
        { "factor": "DXY_WEAKNESS", "label": "Dollar weakening (-0.3% today)", "strength": 7 },
        { "factor": "GEOPOLITICAL_RISK", "label": "Middle East tensions → safe-haven demand", "strength": 6 }
      ],
      "bearish_factors": [
        { "factor": "TECHNICAL_OVERBOUGHT", "label": "Gold near 3-month high; profit-taking likely", "strength": 5 }
      ],
      "uncertainty_flags": [],
      "explanation": "Gold is positioned for a moderately bullish next 24 hours...",
      "major_events_next_period": ["No major scheduled releases in next 24h"]
    },
    "next_week": { ... },
    "next_month": { ... }
  },
  "silver": {
    "next_day": { ... },
    ...
  },
  "market_overview": {
    "overall_gold_sentiment": 71,
    "overall_silver_sentiment": 63,
    "market_condition": "RISK_OFF",
    "key_theme": "Fed pivot expectations + geopolitical risk driving safe-haven demand"
  },
  "data_quality": {
    "missing_data_warnings": [],
    "data_freshness": "All data current as of fetch time"
  }
}
```

---

## Flutter App Architecture (Revised — No Backend)

### Project Structure

```
lib/
├── main.dart
├── app/
│   ├── bindings/
│   │   └── home_binding.dart
│   ├── controllers/
│   │   ├── prediction_controller.dart   ← Core controller
│   │   ├── market_data_controller.dart  ← Price + macro fetching
│   │   ├── news_controller.dart         ← RSS fetching + parsing
│   │   └── accuracy_controller.dart     ← Local prediction log
│   ├── data/
│   │   ├── models/
│   │   │   ├── prediction_model.dart
│   │   │   ├── price_model.dart
│   │   │   ├── macro_model.dart
│   │   │   ├── news_article_model.dart
│   │   │   └── accuracy_log_model.dart
│   │   ├── services/
│   │   │   ├── yahoo_finance_service.dart   ← Price data
│   │   │   ├── fred_service.dart             ← Macro data
│   │   │   ├── rss_service.dart              ← News RSS
│   │   │   ├── goodreturns_service.dart      ← India gold scrape
│   │   │   ├── cftc_service.dart             ← COT data
│   │   │   └── gemini_service.dart           ← LLM prediction
│   │   └── repositories/
│   │       ├── market_repository.dart        ← Aggregates all data sources
│   │       └── prediction_repository.dart    ← Builds prompt + calls Gemini
│   ├── modules/
│   │   ├── splash/
│   │   ├── dashboard/                        ← Main screen
│   │   ├── prediction_detail/                ← Full prediction view
│   │   ├── news/                             ← News feed
│   │   └── accuracy_log/                     ← Local history log
│   ├── routes/
│   │   ├── app_pages.dart
│   │   └── app_routes.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── app_colors.dart
│   └── widgets/
│       ├── price_card.dart
│       ├── prediction_card.dart
│       ├── sentiment_gauge.dart
│       ├── factor_list_tile.dart
│       ├── direction_badge.dart
│       ├── confidence_ring.dart
│       └── news_impact_chip.dart
└── core/
    ├── config/
    │   ├── api_keys.dart          ← FRED key + Gemini key (local only)
    │   └── app_config.dart
    ├── services/
    │   ├── dio_service.dart
    │   ├── hive_service.dart      ← Local cache
    │   └── prompt_builder.dart    ← Assembles Gemini prompt from data
    ├── interceptors/
    │   ├── retry_interceptor.dart
    │   └── logger_interceptor.dart
    └── utils/
        ├── currency_formatter.dart
        ├── rss_parser.dart
        └── date_helper.dart
```

### Key Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  get: ^4.6.6                      # GetX state management + routing
  dio: ^5.4.0                      # HTTP client
  hive: ^2.2.3                     # Local storage (cache + accuracy log)
  hive_flutter: ^1.1.0
  xml: ^6.5.0                      # RSS XML parsing
  fl_chart: ^0.68.0                # Charts
  syncfusion_flutter_charts: ^24.x # Candlestick charts
  intl: ^0.19.0                    # Date/currency formatting
  connectivity_plus: ^6.0.0        # Network check
  flutter_dotenv: ^5.1.0           # API key management
  html: ^0.15.4                    # HTML scraping helper
  cached_network_image: ^3.3.1     # Image caching
  shimmer: ^3.0.0                  # Loading shimmer effect
  lottie: ^3.0.0                   # Animations

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.8
```

### Dio Service Setup

```dart
class DioService {
  static Dio get instance => _createDio();

  static Dio _createDio() {
    return Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ))
      ..interceptors.addAll([
        RetryInterceptor(retries: 3, delay: const Duration(seconds: 2)),
        if (kDebugMode) LogInterceptor(responseBody: false),
      ]);
  }
}
```

---

## Data Fetching Flow (On "Predict" Button Press)

```
User taps "Get Prediction"
          │
          ▼
Show loading state (shimmer)
          │
          ▼
Parallel fetch (via Dio, using Future.wait):
  ├── Yahoo Finance: Gold, Silver, USD/INR, DXY, VIX, 10Y, 2Y, Brent, S&P, Nifty
  ├── FRED API: CPI, Core PCE, Real TIPS yield, Breakeven inflation, MOVE
  ├── GoodReturns scrape: India MCX gold/silver current price in ₹
  ├── RSS feeds (5 sources): Latest 10 articles each → filter relevant
  ├── CFTC CSV (weekly, cached 7 days): Gold/Silver net positioning
  └── GLD ETF CSV (daily, cached 4 hours): Holdings in tonnes
          │
          ▼
Check Hive cache for each source:
  - If cached and fresh (within TTL) → use cached value
  - If stale/missing → fetch live
          │
          ▼
Compute derived values locally:
  - Gold/Silver ratio
  - 20-day / 50-day SMA (from 3-month price history)
  - RSI 14 (from daily closes)
  - Price vs. SMA (above/below = trend signal)
  - News categorization (keyword matching to category)
  - Days to next major India festival
  - Market condition classification (BULL/BEAR/SIDEWAYS based on SMA)
          │
          ▼
PromptBuilder.buildPredictionPrompt(allData)
  → Assembles structured prompt (see above)
          │
          ▼
GeminiService.predict(prompt)
  → POST to Gemini 1.5 Flash API
  → Parse JSON response
  → Validate schema
          │
          ▼
Store result in Hive:
  - Cache prediction (TTL: 30 minutes)
  - Append to local accuracy log with timestamp and current price
          │
          ▼
Update GetX reactive state
          │
          ▼
UI rebuilds with prediction data
```

---

## Local Hive Cache Design

No external database. All persistence is local Hive boxes.

```dart
// Hive Box: 'predictions_cache'
// Key: 'last_prediction'
// TTL: 30 minutes
// Stores: full PredictionModel JSON

// Hive Box: 'market_cache'
// Key per symbol: 'GOLD_INR', 'DXY', 'US_10Y', etc.
// TTL: 5 minutes for prices, 1 day for macro

// Hive Box: 'news_cache'
// Key: 'rss_articles'
// TTL: 30 minutes
// Stores: last 30 articles with category + impact labels

// Hive Box: 'accuracy_log'
// Append-only list of past predictions with target dates
// Used to show: "My last 10 predictions were X% correct"
// No cloud sync — fully local
```

### Local Accuracy Log (Personal Use)

Every time a prediction is made, store:
```json
{
  "predicted_at": "2026-08-22T18:30:00",
  "target_date": "2026-08-23",
  "horizon": "day",
  "metal": "gold",
  "current_price_inr": 72450,
  "predicted_price_inr": 72800,
  "predicted_direction": "BULLISH",
  "confidence": 68
}
```

Every time the app opens, check if any past predictions have expired target dates.  
If yes, fetch actual price from Yahoo Finance and record:
```json
{
  "actual_price_inr": 73100,
  "actual_direction": "BULLISH",
  "directional_correct": true,
  "price_error_pct": 0.41
}
```

This gives you a **personal accuracy log** over time — no DB, no backend.

---

## App Screen Structure

### Screen 1 — Dashboard (Home)

```
┌─────────────────────────────────────────┐
│  🌟 Gold & Silver AI                 ⚙️  │
│─────────────────────────────────────────│
│  MARKET OVERVIEW STRIP                  │
│  DXY 104.2↓  USD/INR 83.72  VIX 18.4  │
│  10Y 4.28%   Brent $81.2    G/S 84.2  │
│─────────────────────────────────────────│
│  ┌──────────────┐  ┌──────────────┐    │
│  │  GOLD 🪙     │  │  SILVER 🪙   │    │
│  │  ₹72,450     │  │  ₹89,200     │    │
│  │  /10g +₹210  │  │  /kg  -₹300  │    │
│  │  Sentiment   │  │  Sentiment   │    │
│  │  [████░] 71  │  │  [███░░] 63  │    │
│  └──────────────┘  └──────────────┘    │
│─────────────────────────────────────────│
│  [ 🔮 GET AI PREDICTION — ONE TAP ]    │
│─────────────────────────────────────────│
│  LAST PREDICTION (from cache)           │
│  Gold: Bullish · Next 7 days · 68%     │
│  Silver: Neutral · Next 7 days · 55%  │
│─────────────────────────────────────────│
│  📰 TOP NEWS (last 3, with badges)     │
│  🟢 Fed signals rate cut [BULLISH]     │
│  🟡 Iran tensions escalate [NEUTRAL]   │
│  🟢 PBoC adds 8T gold [BULLISH]       │
└─────────────────────────────────────────┘
```

### Screen 2 — Prediction Detail

```
┌─────────────────────────────────────────┐
│  ← Gold Prediction                  📤  │
│─────────────────────────────────────────│
│  Horizon Tabs: [1D]  [7D]  [30D]       │
│─────────────────────────────────────────│
│  GOLD — NEXT 7 DAYS                    │
│                                         │
│  Current:   ₹72,450/10g                │
│  Predicted: ₹73,800/10g    ↑ BULLISH   │
│  Range:     ₹71,500 – ₹74,900          │
│  Change:    +1.87%                      │
│                                         │
│  Confidence: [████████░░] 68%           │
│  Risk Level: 🟡 MEDIUM                  │
│  Sentiment:  71/100                     │
│─────────────────────────────────────────│
│  ✅ BULLISH FACTORS                     │
│  ● Fed rate cut signal     ▓▓▓▓▓▓▓▓░░  │
│  ● Dollar weakening        ▓▓▓▓▓▓▓░░░  │
│  ● Middle East tensions    ▓▓▓▓▓▓░░░░  │
│  ● PBoC gold purchases     ▓▓▓▓▓░░░░░  │
│─────────────────────────────────────────│
│  ❌ BEARISH FACTORS                     │
│  ● Near 3-month high       ▓▓▓▓▓░░░░░  │
│─────────────────────────────────────────│
│  📋 AI EXPLANATION                      │
│  "Gold is positioned for a moderately   │
│   bullish week ahead. The primary       │
│   driver is the Fed Chair's statement   │
│   signaling a September rate cut,       │
│   which has weakened the dollar and     │
│   pushed real yields lower..."          │
│─────────────────────────────────────────│
│  📅 KEY EVENTS THIS WEEK               │
│  • Aug 26: FOMC Minutes release         │
│  • Aug 27: US PCE Data                  │
│─────────────────────────────────────────│
│  📊 MY ACCURACY LOG                     │
│  Next-Day Direction: 7/10 correct (70%) │
│  Next-Week Direction: 5/8 correct (63%) │
└─────────────────────────────────────────┘
```

### Screen 3 — News Feed

```
┌─────────────────────────────────────────┐
│  📰 Market News                         │
│─────────────────────────────────────────│
│  Filters: [All] [Fed] [Geo] [India] ... │
│─────────────────────────────────────────│
│  ┌─────────────────────────────────┐    │
│  │ 🟢 BULLISH · GOLD · HIGH        │    │
│  │ "Fed Chair signals September     │    │
│  │  rate cut in Jackson Hole"       │    │
│  │ Kitco · 6h ago                   │    │
│  │ Impact: Short-Medium term        │    │
│  └─────────────────────────────────┘    │
│  ┌─────────────────────────────────┐    │
│  │ 🟢 BULLISH · SILVER · MEDIUM    │    │
│  │ "Solar installations hit record; │    │
│  │  silver demand outlook upgraded" │    │
│  │ Mining.com · 36h ago             │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

### Screen 4 — My Accuracy Log

Shows local history of past predictions vs. actuals. No cloud sync.

---

## Revised MVP Scope (Phase 1 — Personal Use)

### ✅ Include in MVP

- [ ] Flutter app skeleton (GetX routing, Dio, Hive, theming)
- [ ] Yahoo Finance price fetching (Gold, Silver, USD/INR, DXY, VIX, yields, Brent)
- [ ] FRED API macro data fetching (CPI, PCE, TIPS yield, breakeven)
- [ ] GoodReturns scrape for India gold price in ₹
- [ ] RSS feed parser (5 sources, news categorization)
- [ ] Local SMA-20, SMA-50, RSI-14, Gold/Silver ratio computation
- [ ] CFTC COT CSV fetch + parse (cached weekly)
- [ ] GLD ETF holdings CSV fetch (cached daily)
- [ ] Prompt builder (assembles all data into structured Gemini prompt)
- [ ] Gemini 1.5 Flash API integration (free tier)
- [ ] Structured JSON response parsing + validation
- [ ] Dashboard screen (current prices, market strip, sentiment)
- [ ] Prediction detail screen (all 3 horizons, factors, explanation)
- [ ] News screen (categorized, with impact badges)
- [ ] Local Hive cache (all data sources + predictions)
- [ ] Local accuracy log (past predictions vs. actuals, tracked locally)
- [ ] Responsive UI (Android + iOS + Web)
- [ ] Dark theme + premium design

### ❌ Exclude from MVP (Phase 2)

- Interactive charts (candlestick, S/R levels)
- Price alerts
- Push notifications
- Portfolio tracker
- City-specific prices
- WhatsApp/Telegram/Email alerts
- Gold 22K/24K split (beyond basic)
- Any backend or cloud storage

---

## Cost Estimate (Revised)

| Item | Cost |
|---|---|
| Yahoo Finance API | ✅ ₹0 (unofficial free endpoint) |
| FRED API | ✅ ₹0 (free with key) |
| Gemini 1.5 Flash | ✅ ₹0 (free tier — 1,500 req/day, 1M tokens/min) |
| GoodReturns scraping | ✅ ₹0 |
| RSS feeds | ✅ ₹0 |
| CFTC COT data | ✅ ₹0 |
| GLD/SLV ETF CSV | ✅ ₹0 |
| Flutter app (Android/iOS/Web) | ✅ ₹0 (personal, no store) |
| Hosting | ✅ ₹0 (none needed) |
| **TOTAL** | **₹0/month** |

> The only API keys needed:  
> 1. **FRED API key** — Free registration at fred.stlouisfed.org  
> 2. **Gemini API key** — Free at aistudio.google.com

---

## Development Roadmap (Revised — Personal App)

### Phase 1 — MVP (6–8 Weeks)

```
Week 1–2: Foundation
  ├── Flutter project setup (GetX, Dio, Hive)
  ├── Theming, routing, base widgets
  ├── Yahoo Finance service (all symbols)
  └── FRED service

Week 3: Data Pipeline
  ├── GoodReturns scrape service
  ├── RSS feed parser (5 sources)
  ├── CFTC COT CSV parser
  ├── GLD ETF holdings parser
  ├── Local technical indicator computation (SMA, RSI)
  └── Hive caching layer

Week 4: Gemini Integration
  ├── Prompt builder (structured, data-grounded)
  ├── Gemini API service (Dio)
  ├── Response JSON parser + validator
  └── Error handling (rate limit, network failure, bad JSON)

Week 5–6: UI Screens
  ├── Dashboard screen
  ├── Prediction detail screen (all 3 horizons)
  ├── News screen
  └── Accuracy log screen

Week 7: Polish
  ├── Animations, shimmer loading
  ├── Error states, empty states, retry logic
  ├── Offline fallback (show cached data)
  └── Web layout responsiveness

Week 8: Testing
  ├── Manual testing (Android + iOS + Web)
  ├── Edge cases (API down, bad data, Gemini error)
  └── Final tweaks
```

### Phase 2 — Enhancements (After MVP)

```
  ├── Interactive candlestick charts (syncfusion)
  ├── Historical prediction overlay on chart
  ├── Support/Resistance level visualization
  ├── Technical indicator panel (RSI, MACD, Bollinger)
  ├── Silver industrial demand indicators (PMI, solar data)
  ├── More granular India data (city prices if scrapeable)
  ├── Notification support (local notifications, no push server)
  └── Export accuracy log as CSV
```

---

## Important Limitations to Note

> [!WARNING]
> **Yahoo Finance**: The unofficial endpoint may occasionally break if Yahoo changes their API structure. This is a known risk with free scraping approaches. Monitor and update selectors as needed.

> [!NOTE]
> **Gemini Free Tier**: At 1,500 requests/day limit, this is ample for personal use (you'd need to make 1,500 predictions per day to hit the limit). The model used is Gemini 1.5 Flash which is fast and capable.

> [!NOTE]
> **Prediction Quality**: Without a trained ML model and historical backtesting database, predictions rely on Gemini's knowledge of gold/silver market relationships combined with your live data inputs. Quality will be good for directional analysis but less precise for exact price targets compared to a trained statistical model. This is acceptable for personal decision-support use.

> [!TIP]
> **FRED Data Lag**: Macro data like CPI is released monthly. FRED always has the latest released value. The app should clearly show the data date (e.g., "CPI: 3.2% — June 2026 release") so you know how current the macro context is.
