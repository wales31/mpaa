import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:mpaa_mobile/core/logging/app_logger.dart';

class ErrorHandler {
  const ErrorHandler(this._logger);

  final AppLogger _logger;

  void capture(Object error, StackTrace stackTrace, {String context = 'unhandled'}) {
    _logger.error('error.$context', error: error, stackTrace: stackTrace);
  }

  void installGlobalHandlers() {
    FlutterError.onError = (FlutterErrorDetails details) {
      capture(details.exception, details.stack ?? StackTrace.current, context: 'flutter_error');
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
      capture(error, stackTrace, context: 'platform_dispatcher');
      return true;
    };
  }
}
