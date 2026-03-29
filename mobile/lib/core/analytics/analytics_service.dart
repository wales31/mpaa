import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpaa_mobile/core/logging/app_logger.dart';

abstract class AnalyticsService {
  Future<void> logEvent(
    String eventName, {
    Map<String, Object?> parameters = const <String, Object?>{},
  });

  Future<void> identifyUser(String userId, {String? role});
}

class DebugAnalyticsService implements AnalyticsService {
  const DebugAnalyticsService(this._logger);

  final AppLogger _logger;

  @override
  Future<void> identifyUser(String userId, {String? role}) async {
    _logger.info('analytics.identify_user', error: {'userId': userId, 'role': role});
  }

  @override
  Future<void> logEvent(
    String eventName, {
    Map<String, Object?> parameters = const <String, Object?>{},
  }) async {
    _logger.info('analytics.event.$eventName', error: parameters);
  }
}

final appLoggerProvider = Provider<AppLogger>((ref) {
  return const AppLogger();
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final logger = ref.watch(appLoggerProvider);
  return DebugAnalyticsService(logger);
});
