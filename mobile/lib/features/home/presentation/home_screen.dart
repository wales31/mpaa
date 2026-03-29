import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mpaa_mobile/features/auth/data/repositories/auth_repository.dart';
import 'package:mpaa_mobile/features/auth/presentation/providers/auth_state_provider.dart';

enum PrimaryTab { dashboard, farmers, collections, payments, settings }

extension PrimaryTabX on PrimaryTab {
  String get label {
    switch (this) {
      case PrimaryTab.dashboard:
        return 'Dashboard';
      case PrimaryTab.farmers:
        return 'Farmers';
      case PrimaryTab.collections:
        return 'Collections';
      case PrimaryTab.payments:
        return 'Payments';
      case PrimaryTab.settings:
        return 'Settings';
    }
  }

  IconData get icon {
    switch (this) {
      case PrimaryTab.dashboard:
        return Icons.dashboard_outlined;
      case PrimaryTab.farmers:
        return Icons.people_outline;
      case PrimaryTab.collections:
        return Icons.local_drink_outlined;
      case PrimaryTab.payments:
        return Icons.payments_outlined;
      case PrimaryTab.settings:
        return Icons.settings_outlined;
    }
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  PrimaryTab _selectedTab = PrimaryTab.dashboard;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Loading your account...'),
            ],
          ),
        ),
      ),
      error: (Object error, StackTrace stackTrace) => Scaffold(
        body: Center(child: Text('Authentication failed: $error')),
      ),
      data: (User? user) {
        if (user == null) {
          return _LoggedOutView(
            onSignInPressed: () async {
              final repo = ref.read(authRepositoryProvider);
              try {
                await repo.signInForUxPreview();
              } catch (e) {
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sign-in failed: $e')),
                );
              }
            },
          );
        }

        final isAdmin = (user.email ?? '').toLowerCase().contains('admin');

        return Scaffold(
          appBar: AppBar(
            title: Text(_selectedTab.label),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(child: Text(user.email ?? user.uid)),
              ),
              IconButton(
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
                icon: const Icon(Icons.logout),
                tooltip: 'Sign out',
              ),
            ],
          ),
          body: Row(
            children: <Widget>[
              NavigationRail(
                selectedIndex: _selectedTab.index,
                onDestinationSelected: (int index) {
                  setState(() {
                    _selectedTab = PrimaryTab.values[index];
                  });
                },
                labelType: NavigationRailLabelType.all,
                destinations: PrimaryTab.values
                    .map(
                      (PrimaryTab tab) => NavigationRailDestination(
                        icon: Icon(tab.icon),
                        label: Text(tab.label),
                      ),
                    )
                    .toList(),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: _TabContent(tab: _selectedTab, isAdmin: isAdmin, user: user)),
            ],
          ),
        );
      },
    );
  }
}

class _LoggedOutView extends StatelessWidget {
  const _LoggedOutView({required this.onSignInPressed});

  final Future<void> Function() onSignInPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const FlutterLogo(size: 56),
                const SizedBox(height: 12),
                Text('MPAA', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text('Milk Producers Administration App'),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: onSignInPressed,
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({required this.tab, required this.isAdmin, required this.user});

  final PrimaryTab tab;
  final bool isAdmin;
  final User user;

  @override
  Widget build(BuildContext context) {
    switch (tab) {
      case PrimaryTab.dashboard:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const <Widget>[
                _KpiCard(label: 'Total farmers', value: '142'),
                _KpiCard(label: 'Total milk', value: '12,450 L'),
                _KpiCard(label: 'Paid payments total', value: '\$4,120'),
                _KpiCard(label: 'Pending payments total', value: '\$1,360'),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionCard(
              title: 'Recent collections',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('• Sarah N. — 35 L — Mar 28'),
                  Text('• James K. — 42 L — Mar 28'),
                  Text('• Amina O. — 28 L — Mar 27'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _SectionCard(
              title: 'Collection trend chart',
              child: SizedBox(
                height: 120,
                child: Center(child: Text('Chart placeholder (7-day trend)')),
              ),
            ),
          ],
        );
      case PrimaryTab.farmers:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const SearchBar(hintText: 'Search by name/phone/location'),
            const SizedBox(height: 12),
            _RoleBanner(isAdmin: isAdmin, adminAction: 'Create/Edit/Delete'),
            const SizedBox(height: 12),
            const _SectionCard(
              title: 'Farmers',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('• Sarah N. | +1 555-0101 | North Farm'),
                  Text('• James K. | +1 555-0102 | East Hill'),
                ],
              ),
            ),
          ],
        );
      case PrimaryTab.collections:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const SearchBar(hintText: 'Search by farmer name'),
            const SizedBox(height: 12),
            _RoleBanner(isAdmin: isAdmin, adminAction: 'Add Collection'),
            const SizedBox(height: 12),
            const _SectionCard(
              title: 'Collections',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('• Mar 28 | Sarah N. | 35 L'),
                  Text('• Mar 28 | James K. | 42 L'),
                ],
              ),
            ),
          ],
        );
      case PrimaryTab.payments:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _RoleBanner(isAdmin: isAdmin, adminAction: 'Generate + Mark Paid'),
            const SizedBox(height: 12),
            const _SectionCard(
              title: 'Payments',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('• Sarah N. | Mar 2026 | \$650 | Paid'),
                  Text('• James K. | Mar 2026 | \$720 | Pending'),
                ],
              ),
            ),
          ],
        );
      case PrimaryTab.settings:
        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _SectionCard(
              title: 'Profile',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Name: ${user.displayName ?? 'Not set'}'),
                  Text('Email: ${user.email ?? 'Not set'}'),
                  Text('UID: ${user.uid}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _SectionCard(
              title: 'Notifications',
              child: Column(
                children: <Widget>[
                  SwitchListTile(value: true, onChanged: null, title: Text('Daily summary')),
                  SwitchListTile(value: false, onChanged: null, title: Text('Payment reminders')),
                ],
              ),
            ),
          ],
        );
    }
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 6),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _RoleBanner extends StatelessWidget {
  const _RoleBanner({required this.isAdmin, required this.adminAction});

  final bool isAdmin;
  final String adminAction;

  @override
  Widget build(BuildContext context) {
    final text = isAdmin
        ? 'Admin access: $adminAction'
        : 'User access: view-only (admin required for $adminAction)';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isAdmin ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text),
    );
  }
}
