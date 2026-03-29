import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpaa_mobile/app.dart';
import 'package:mpaa_mobile/config/app_config.dart';
import 'package:mpaa_mobile/core/network/dio_provider.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();

  await Firebase.initializeApp();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
      ],
      child: const App(),
    ),
  );
}
