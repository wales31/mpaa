import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  const AppLogger();

  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, error: error, stackTrace: stackTrace);
  }

  void info(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, error: error, stackTrace: stackTrace);
  }

  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, error: error, stackTrace: stackTrace);
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }

  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final levelName = level.name.toUpperCase();
    final composed = '[$levelName] $message';

    if (kDebugMode) {
      developer.log(
        composed,
        error: error,
        stackTrace: stackTrace,
        name: 'mpaa_mobile',
      );
      return;
    }

    developer.log(
      composed,
      error: error,
      stackTrace: stackTrace,
      name: 'mpaa_mobile',
    );
  }
}
