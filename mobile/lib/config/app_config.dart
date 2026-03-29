import 'package:mpaa_mobile/config/flavor.dart';

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.apiBaseUrl,
    required this.firebaseProjectId,
  });

  final Flavor flavor;
  final String apiBaseUrl;
  final String firebaseProjectId;

  static const String _flavorEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static const String _apiBaseUrlEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.dev.example.com',
  );

  static const String _firebaseProjectIdEnv = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'mpaa-dev',
  );

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      flavor: FlavorX.fromString(_flavorEnv),
      apiBaseUrl: _apiBaseUrlEnv,
      firebaseProjectId: _firebaseProjectIdEnv,
    );
  }
}
