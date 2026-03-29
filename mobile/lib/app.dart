import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mpaa_mobile/core/router/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MPAA',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      routerConfig: appRouter,
    );
  }
}
