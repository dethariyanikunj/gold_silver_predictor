import 'app_config.dart';

/// Store your API keys here or in .env file.
class ApiKeys {
  static String get fredApiKey =>
      AppConfig.fredApiKey.isNotEmpty ? AppConfig.fredApiKey : 'YOUR_FRED_API_KEY_HERE';

  static String get geminiApiKey =>
      AppConfig.geminiApiKey.isNotEmpty ? AppConfig.geminiApiKey : 'YOUR_GEMINI_API_KEY_HERE';

  static String get goldApiKey =>
      AppConfig.goldApiKey.isNotEmpty ? AppConfig.goldApiKey : 'YOUR_GOLD_API_KEY_HERE';
}
