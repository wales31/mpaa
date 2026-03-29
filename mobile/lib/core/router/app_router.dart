import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mpaa_mobile/features/home/presentation/home_screen.dart';

class AppRoutePaths {
  static const String auth = '/auth';
  static const String dashboard = '/dashboard';
  static const String reports = '/reports';
  static const String settings = '/settings';
}

final appRouter = GoRouter(
  initialLocation: AppRoutePaths.dashboard,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutePaths.dashboard,
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
  ],
);
