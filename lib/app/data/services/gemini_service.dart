import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/config/api_keys.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/dio_service.dart';
import '../models/market_data_model.dart';
import '../models/news_article_model.dart';
import '../models/prediction_model.dart';
import '../../../core/services/prompt_builder.dart';

class GeminiService {
  final Dio _dio = DioService.gemini;

  Future<PredictionResult> generatePrediction(
    MarketDataModel market,
    List<NewsArticleModel> news,
  ) async {
    final apiKey = ApiKeys.geminiApiKey.trim();
    final hasValidApiKey = apiKey.isNotEmpty && !apiKey.startsWith('YOUR_');

    if (!hasValidApiKey) {
      if (AppConfig.enableMockIfNoApiKey) {
        return _generateMockPrediction(market, news);
      }
      throw Exception(
        'Gemini API key is not configured. Please add your free Gemini API key to lib/core/config/api_keys.dart',
      );
    }

    final prompt = PromptBuilder.buildPredictionPrompt(market, news);

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'topP': 0.8,
        'maxOutputTokens': 4096,
        'responseMimeType': 'application/json',
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_NONE',
        },
      ],
    };

    try {
      final response = await _dio.post(
        '/v1beta/models/${AppConfig.geminiModel}:generateContent',
        queryParameters: {'key': apiKey},
        data: requestBody,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final candidates = response.data['candidates'] as List;
      if (candidates.isEmpty) throw Exception('Gemini returned no candidates');

      final content = candidates[0]['content']['parts'][0]['text'] as String;
      final cleaned = _extractJson(content);
      final decoded = jsonDecode(cleaned) as Map<String, dynamic>;

      return PredictionResult.fromGeminiJson(
        decoded,
        market.goldInr ?? 82000,
        market.goldUsd ?? 2938,
        market.silverInr ?? 98000,
        market.silverUsd ?? 32.75,
      );
    } on DioException catch (e) {
      if (AppConfig.enableMockIfNoApiKey) {
        return _generateMockPrediction(market, news);
      }
      final errorMsg = e.response?.data?['error']?['message'] ?? e.message;
      throw Exception('Gemini API error: $errorMsg');
    } catch (e) {
      if (AppConfig.enableMockIfNoApiKey) {
        return _generateMockPrediction(market, news);
      }
      throw Exception('Failed to parse Gemini response: $e');
    }
  }

  String _extractJson(String text) {
    final jsonRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final match = jsonRegex.firstMatch(text);
    if (match != null) return match.group(1)!.trim();

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return text.trim();
  }

  PredictionResult _generateMockPrediction(
    MarketDataModel market,
    List<NewsArticleModel> news,
  ) {
    final goldInr = market.goldInr ?? 0.0;
    final goldUsd = market.goldUsd ?? 0.0;
    final silverInr = market.silverInr ?? 0.0;
    final silverUsd = market.silverUsd ?? 0.0;

    return PredictionResult(
      gold: MetalPrediction(
        metal: 'gold',
        currentPriceInr: goldInr,
        currentPriceUsd: goldUsd,
        overallSentiment: 72,
        overallTheme:
            'Steady accumulation by central banks and firm wedding/festival seasonal demand provide strong structural support.',
        nextDay: HorizonPrediction(
          horizon: 'day',
          predictedPriceInr: goldInr * 1.003,
          rangeLowInr: goldInr * 0.995,
          rangeHighInr: goldInr * 1.008,
          predictedPriceUsd: goldUsd * 1.003,
          direction: 'BULLISH',
          changePercent: 0.30,
          confidence: 76,
          riskLevel: 'LOW',
          sentimentScore: 68,
          bullishFactors: const [
            PredictionFactor(
                key: 'central_banks',
                label: 'Strong sovereign central bank reserve accumulation',
                strength: 8),
            PredictionFactor(
                key: 'dxy_weakness',
                label: 'Mild softening in US Dollar index (DXY)',
                strength: 6),
          ],
          bearishFactors: const [
            PredictionFactor(
                key: 'rates',
                label: 'Elevated real interest rates cap immediate upside',
                strength: 5),
          ],
          uncertaintyFlags: const [
            'Upcoming US macroeconomic CPI prints may trigger intraday swings'
          ],
          explanation:
              'Gold exhibits firm short-term support anchored around key moving averages, with physical buyers in domestic hubs accumulating on shallow dips.',
          majorEventsThisPeriod: const [
            'US Initial Jobless Claims release',
            'Fed governor policy commentary'
          ],
        ),
        nextWeek: HorizonPrediction(
          horizon: 'week',
          predictedPriceInr: goldInr * 1.014,
          rangeLowInr: goldInr * 0.988,
          rangeHighInr: goldInr * 1.025,
          predictedPriceUsd: goldUsd * 1.014,
          direction: 'BULLISH',
          changePercent: 1.40,
          confidence: 82,
          riskLevel: 'MEDIUM',
          sentimentScore: 75,
          bullishFactors: const [
            PredictionFactor(
                key: 'seasonal',
                label: 'Domestic festival and wedding retail demand pick-up',
                strength: 8),
            PredictionFactor(
                key: 'safe_haven',
                label: 'Safe-haven allocation hedge against geopolitical risks',
                strength: 7),
          ],
          bearishFactors: const [
            PredictionFactor(
                key: 'profit_booking',
                label: 'Occasional profit taking near multi-month resistance',
                strength: 4),
          ],
          uncertaintyFlags: const [],
          explanation:
              'The 7-day outlook indicates upward momentum fueled by strong retail appetite in India and steady ETF inflows globally.',
          majorEventsThisPeriod: const [
            'FOMC meeting minutes',
            'Global PMI economic releases'
          ],
        ),
        nextMonth: HorizonPrediction(
          horizon: 'month',
          predictedPriceInr: goldInr * 1.032,
          rangeLowInr: goldInr * 0.975,
          rangeHighInr: goldInr * 1.055,
          predictedPriceUsd: goldUsd * 1.032,
          direction: 'BULLISH',
          changePercent: 3.20,
          confidence: 79,
          riskLevel: 'MEDIUM',
          sentimentScore: 80,
          bullishFactors: const [
            PredictionFactor(
                key: 'monetary_cycle',
                label: 'Anticipated global interest rate easing cycle',
                strength: 9),
            PredictionFactor(
                key: 'etf_demand',
                label: 'Long-term institutional ETF allocation turnaround',
                strength: 7),
          ],
          bearishFactors: const [
            PredictionFactor(
                key: 'currency_strength',
                label: 'Potential USD consolidation during key risk events',
                strength: 5),
          ],
          uncertaintyFlags: const [
            'Geopolitical escalation or de-escalation may cause price gaps'
          ],
          explanation:
              'Over a 30-day horizon, the primary macroeconomic drivers point towards further appreciation with higher highs as global real yields moderate.',
          majorEventsThisPeriod: const [
            'US Federal Reserve Interest Rate Decision',
            'India RBI Monetary Policy Review'
          ],
        ),
      ),
      silver: MetalPrediction(
        metal: 'silver',
        currentPriceInr: silverInr,
        currentPriceUsd: silverUsd,
        overallSentiment: 70,
        overallTheme:
            'High industrial consumption from solar photovoltaics and electronics combined with tight physical inventories.',
        nextDay: HorizonPrediction(
          horizon: 'day',
          predictedPriceInr: silverInr * 1.005,
          rangeLowInr: silverInr * 0.990,
          rangeHighInr: silverInr * 1.015,
          predictedPriceUsd: silverUsd * 1.005,
          direction: 'BULLISH',
          changePercent: 0.50,
          confidence: 71,
          riskLevel: 'MEDIUM',
          sentimentScore: 65,
          bullishFactors: const [
            PredictionFactor(
                key: 'industrial_demand',
                label: 'Renewed industrial supply contracts in green tech',
                strength: 8),
          ],
          bearishFactors: const [
            PredictionFactor(
                key: 'volatility',
                label: 'High intraday beta relative to gold',
                strength: 6),
          ],
          uncertaintyFlags: const ['High volatility expected on COMEX open'],
          explanation:
              'Silver prices are consolidating within a constructive ascending triangle pattern, supported by robust spot physical premiums.',
          majorEventsThisPeriod: const ['COMEX Options Expiry'],
        ),
        nextWeek: HorizonPrediction(
          horizon: 'week',
          predictedPriceInr: silverInr * 1.022,
          rangeLowInr: silverInr * 0.978,
          rangeHighInr: silverInr * 1.045,
          predictedPriceUsd: silverUsd * 1.022,
          direction: 'BULLISH',
          changePercent: 2.20,
          confidence: 77,
          riskLevel: 'HIGH',
          sentimentScore: 74,
          bullishFactors: const [
            PredictionFactor(
                key: 'solar_demand',
                label: 'Accelerating silver paste consumption in solar PV cells',
                strength: 9),
            PredictionFactor(
                key: 'gold_silver_ratio',
                label: 'Gold-to-Silver ratio compression potential',
                strength: 7),
          ],
          bearishFactors: const [
            PredictionFactor(
                key: 'base_metals',
                label: 'Mixed signals in broader base metal complexes (copper)',
                strength: 5),
          ],
          uncertaintyFlags: const [],
          explanation:
              'Industrial green-transition tailwinds and supply deficits in primary silver mining continue to tighten global inventories.',
          majorEventsThisPeriod: const [
            'Global Manufacturing PMI Reports',
            'LBMA vault inventory reports'
          ],
        ),
        nextMonth: HorizonPrediction(
          horizon: 'month',
          predictedPriceInr: silverInr * 1.048,
          rangeLowInr: silverInr * 0.950,
          rangeHighInr: silverInr * 1.085,
          predictedPriceUsd: silverUsd * 1.048,
          direction: 'BULLISH',
          changePercent: 4.80,
          confidence: 74,
          riskLevel: 'HIGH',
          sentimentScore: 78,
          bullishFactors: const [
            PredictionFactor(
                key: 'structural_deficit',
                label: 'Multi-year consecutive global physical supply deficit',
                strength: 9),
            PredictionFactor(
                key: 'indian_import',
                label: 'High festive and industrial import volumes into India',
                strength: 8),
          ],
          bearishFactors: const [
            PredictionFactor(
                key: 'cyclical_slowdown',
                label: 'Risks of global manufacturing momentum slowdown',
                strength: 5),
          ],
          uncertaintyFlags: const [
            'Mining supply updates from Mexico and Peru'
          ],
          explanation:
              'The 30-day projection anticipates silver outperforming gold on a percentage basis as institutional investors rebalance into undervalued white metals.',
          majorEventsThisPeriod: const [
            'World Silver Survey quarterly update',
            'Fed Interest Rate Announcement'
          ],
        ),
      ),
      marketCondition: 'BULL',
      keyTheme:
          'Central bank buying & festive demand support precious metals trend',
      generatedAt: DateTime.now(),
    );
  }
}
