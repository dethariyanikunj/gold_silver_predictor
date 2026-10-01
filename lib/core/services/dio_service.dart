import 'package:dio/dio.dart';
import '../interceptors/retry_interceptor.dart';
import '../interceptors/logger_interceptor.dart';

class DioService {
  static Dio createDio({
    String? baseUrl,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 30),
    Map<String, dynamic>? headers,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: {
          'Accept': 'application/json',
          ...?headers,
        },
      ),
    );

    dio.interceptors.addAll([
      RetryInterceptor(dio: dio),
      AppLoggerInterceptor(),
    ]);

    return dio;
  }

  /// Pre-configured instances
  static final Dio yahoo = createDio(
    baseUrl: 'https://query1.finance.yahoo.com',
    connectTimeout: const Duration(seconds: 10),
  );

  static final Dio fred = createDio(
    baseUrl: 'https://api.stlouisfed.org',
  );

  static final Dio gemini = createDio(
    baseUrl: 'https://generativelanguage.googleapis.com',
    receiveTimeout: const Duration(seconds: 60),
  );

  static final Dio generic = createDio();
}
