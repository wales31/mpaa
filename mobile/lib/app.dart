import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mpaa_mobile/core/router/app_router.dart';
import 'package:mpaa_mobile/core/theme/app_theme.dart';
import 'package:mpaa_mobile/core/widgets/error_view.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late Future<void> _firebaseInitFuture;

  @override
  void initState() {
    super.initState();
    _firebaseInitFuture = _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw TimeoutException(
        'Firebase initialization timed out. Check your Firebase config files.',
      ),
    );
  }

  void _retryInitialization() {
    setState(() {
      _firebaseInitFuture = _initializeFirebase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _firebaseInitFuture,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            title: 'MPAA',
            theme: AppTheme.light(),
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            title: 'MPAA',
            theme: AppTheme.light(),
            home: Scaffold(
              body: ErrorView(
                message:
                    'Startup failed: ${snapshot.error}\n\nRun flutterfire configure and verify google-services files are present.',
                onRetry: _retryInitialization,
              ),
            ),
          );
        }

        return MaterialApp.router(
          title: 'MPAA',
          theme: AppTheme.light(),
          routerConfig: appRouter,
        );
      },
    );
  }
}
