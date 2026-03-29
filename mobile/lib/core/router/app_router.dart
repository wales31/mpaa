import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mpaa_mobile/features/home/presentation/home_screen.dart';

class AppRoutePaths {
  static const String home = '/';
}

final appRouter = GoRouter(
  initialLocation: AppRoutePaths.home,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutePaths.home,
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
  ],
);
