import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpaa_mobile/config/app_config.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('Override appConfigProvider in bootstrap.');
});

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  return Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
});
