import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpaa_mobile/config/app_config.dart';
import 'package:mpaa_mobile/core/analytics/analytics_service.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('Override appConfigProvider in bootstrap.');
});

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final logger = ref.watch(appLoggerProvider);
  final analytics = ref.watch(analyticsServiceProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        logger.debug('HTTP ${options.method} ${options.path}');
        handler.next(options);
      },
      onError: (error, handler) {
        logger.error(
          'HTTP ${error.requestOptions.method} ${error.requestOptions.path} failed',
          error: error,
          stackTrace: error.stackTrace,
        );
        analytics.logEvent(
          'api_request_failed',
          parameters: <String, Object?>{
            'path': error.requestOptions.path,
            'method': error.requestOptions.method,
            'statusCode': error.response?.statusCode,
          },
        );
        handler.next(error);
      },
    ),
  );

  return dio;
});
