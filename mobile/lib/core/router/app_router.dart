import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mpaa_mobile/features/home/presentation/home_screen.dart';

final appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
    ),
  ],
);
