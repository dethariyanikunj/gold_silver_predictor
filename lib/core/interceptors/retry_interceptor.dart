import 'dart:async';
import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int retries;
  final Duration delay;

  RetryInterceptor({
    required this.dio,
    this.retries = 3,
    this.delay = const Duration(seconds: 2),
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = extra['retryCount'] as int? ?? 0;

    if (retryCount < retries && _isRetryable(err)) {
      final options = err.requestOptions;
      options.extra['retryCount'] = retryCount + 1;
      await Future.delayed(delay * (retryCount + 1));
      try {
        final response = await dio.fetch(options);
        return handler.resolve(response);
      } catch (e) {
        // continue to next handler
      }
    }
    handler.next(err);
  }

  bool _isRetryable(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null &&
            err.response!.statusCode! >= 500);
  }
}
