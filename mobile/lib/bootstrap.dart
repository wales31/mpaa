import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpaa_mobile/app.dart';
import 'package:mpaa_mobile/config/app_config.dart';
import 'package:mpaa_mobile/core/error/error_handler.dart';
import 'package:mpaa_mobile/core/logging/app_logger.dart';
import 'package:mpaa_mobile/core/network/dio_provider.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  const logger = AppLogger();
  final errorHandler = ErrorHandler(logger);
  errorHandler.installGlobalHandlers();

  logger.info('Bootstrapping MPAA mobile app');

  await Firebase.initializeApp();

  runApp(
    ProviderScope(
      overrides: <Override>[
        appConfigProvider.overrideWithValue(config),
      ],
      child: const App(),
    ),
  );
}
