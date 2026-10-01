import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/api_keys.dart';
import '../../../core/services/dio_service.dart';
import '../../../core/services/hive_service.dart';

class FredService {
  final Dio _dio = DioService.fred;

  /// Fetch the latest value of a FRED series
  Future<Map<String, dynamic>?> fetchLatestObservation(String seriesId) async {
    final cacheKey = 'fred_$seriesId';
    final cached = HiveService.getIfFresh(HiveService.macroBox, cacheKey);
    if (cached != null) {
      return Map<String, dynamic>.from(jsonDecode(cached));
    }

    try {
      final response = await _dio.get(
        '/fred/series/observations',
        queryParameters: {
          'series_id': seriesId,
          'api_key': ApiKeys.fredApiKey,
          'file_type': 'json',
          'sort_order': 'desc',
          'limit': 1,
        },
      );
      final observations = response.data['observations'] as List;
      if (observations.isEmpty) return null;
      final latest = observations.first;
      final result = {
        'value': double.tryParse(latest['value'] ?? '') ?? 0.0,
        'date': latest['date'],
      };
      await HiveService.setWithTtl(
        HiveService.macroBox,
        cacheKey,
        jsonEncode(result),
        AppConfig.macroTtlMin,
      );
      return result;
    } catch (e) {
      return null;
    }
  }

  /// Fetch all configured macro indicators
  Future<Map<String, Map<String, dynamic>?>> fetchAllMacro() async {
    final results = <String, Map<String, dynamic>?>{};
    await Future.wait(
      AppConfig.fredSeries.entries.map((entry) async {
        results[entry.key] = await fetchLatestObservation(entry.value);
      }),
    );
    return results;
  }
}
