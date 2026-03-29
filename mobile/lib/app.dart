import 'package:flutter/material.dart';
import 'package:mpaa_mobile/core/router/app_router.dart';
import 'package:mpaa_mobile/core/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MPAA',
      theme: AppTheme.light(),
      routerConfig: appRouter,
    );
  }
}
