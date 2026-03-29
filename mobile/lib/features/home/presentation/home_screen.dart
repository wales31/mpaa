import 'package:flutter/material.dart';
import 'package:mpaa_mobile/core/router/app_router.dart';
import 'package:mpaa_mobile/core/theme/design_tokens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = <String>[
      AppRoutePaths.auth,
      AppRoutePaths.dashboard,
      AppRoutePaths.reports,
      AppRoutePaths.settings,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('MPAA Mobile Foundation')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Week 1–2 architecture baseline', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            const Text('Feature modules and global patterns are defined in mobile/docs/.'),
            const SizedBox(height: AppSpacing.lg),
            Text('Module route contract', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ...modules.map((String module) => Card(
                  child: ListTile(
                    title: Text(module),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
