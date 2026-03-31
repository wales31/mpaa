import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

class FarmerRecord {
  const FarmerRecord({
    required this.id,
    required this.name,
    required this.phone,
    required this.location,
  });

  final String id;
  final String name;
  final String phone;
  final String location;
}

class MilkCollectionRecord {
  const MilkCollectionRecord({
    required this.id,
    required this.farmerId,
    required this.litres,
    required this.recordedAt,
  });

  final String id;
  final String farmerId;
  final double litres;
  final DateTime recordedAt;
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.farmerId,
    required this.amount,
    required this.recordedAt,
  });

  final String id;
  final String farmerId;
  final double amount;
  final DateTime recordedAt;
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const double _ratePerLitre = 0.42;

  PrimaryTab _selectedTab = PrimaryTab.dashboard;

  List<FarmerRecord> _farmers = <FarmerRecord>[
    const FarmerRecord(
      id: 'farmer-sarah',
      name: 'Sarah N.',
      phone: '+1 555-0101',
      location: 'North Farm',
    ),
    const FarmerRecord(
      id: 'farmer-james',
      name: 'James K.',
      phone: '+1 555-0102',
      location: 'East Hill',
    ),
    const FarmerRecord(
      id: 'farmer-amina',
      name: 'Amina O.',
      phone: '+1 555-0103',
      location: 'Valley Coop',
    ),
  ];

  List<MilkCollectionRecord> _collections = <MilkCollectionRecord>[
    MilkCollectionRecord(
      id: 'c1',
      farmerId: 'farmer-sarah',
      litres: 35,
      recordedAt: DateTime(2026, 3, 31),
    ),
    MilkCollectionRecord(
      id: 'c2',
      farmerId: 'farmer-james',
      litres: 42,
      recordedAt: DateTime(2026, 3, 31),
    ),
    MilkCollectionRecord(
      id: 'c3',
      farmerId: 'farmer-amina',
      litres: 28,
      recordedAt: DateTime(2026, 3, 30),
    ),
    MilkCollectionRecord(
      id: 'c4',
      farmerId: 'farmer-sarah',
      litres: 31,
      recordedAt: DateTime(2026, 3, 1),
    ),
  ];

  List<PaymentRecord> _payments = <PaymentRecord>[
    PaymentRecord(
      id: 'p1',
      farmerId: 'farmer-sarah',
      amount: 20,
      recordedAt: DateTime(2026, 3, 15),
    ),
    PaymentRecord(
      id: 'p2',
      farmerId: 'farmer-james',
      amount: 12,
      recordedAt: DateTime(2026, 3, 12),
    ),
    PaymentRecord(
      id: 'p3',
      farmerId: 'farmer-amina',
      amount: 8,
      recordedAt: DateTime(2026, 3, 18),
    ),
  ];

  Map<String, double> _paidByFarmer() {
    final Map<String, double> totals = <String, double>{};
    for (final PaymentRecord payment in _payments) {
      totals.update(
        payment.farmerId,
        (double current) => current + payment.amount,
        ifAbsent: () => payment.amount,
      );
    }
    return totals;
  }

  Map<String, double> _collectedLitresByFarmer({DateTime? month}) {
    final Map<String, double> totals = <String, double>{};
    for (final MilkCollectionRecord collection in _collections) {
      if (month != null &&
          (collection.recordedAt.year != month.year ||
              collection.recordedAt.month != month.month)) {
        continue;
      }
      totals.update(
        collection.farmerId,
        (double current) => current + collection.litres,
        ifAbsent: () => collection.litres,
      );
    }
    return totals;
  }

  Future<void> _showAddFarmerDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final locationCtrl = TextEditingController();

    final FarmerRecord? farmer = await showDialog<FarmerRecord>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add farmer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) {
                  return;
                }
                Navigator.of(dialogContext).pop(
                  FarmerRecord(
                    id: 'farmer-${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    location: locationCtrl.text.trim(),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameCtrl.dispose();
    phoneCtrl.dispose();
    locationCtrl.dispose();

    if (farmer == null) {
      return;
    }
    setState(() {
      _farmers = <FarmerRecord>[..._farmers, farmer];
    });
  }

  void _dropFarmer(FarmerRecord farmer) {
    setState(() {
      _farmers = _farmers.where((FarmerRecord f) => f.id != farmer.id).toList();
      _collections = _collections
          .where((MilkCollectionRecord c) => c.farmerId != farmer.id)
          .toList();
      _payments =
          _payments.where((PaymentRecord p) => p.farmerId != farmer.id).toList();
    });
  }

  FarmerRecord _resolveFarmerForUser(User user) {
    final String email = (user.email ?? '').toLowerCase();
    if (email.contains('sarah')) {
      return _farmers.firstWhere((FarmerRecord f) => f.id == 'farmer-sarah');
    }
    if (email.contains('james')) {
      return _farmers.firstWhere((FarmerRecord f) => f.id == 'farmer-james');
    }
    return _farmers.first;
  }

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
        final FarmerRecord farmer = _resolveFarmerForUser(user);
        final collectedByFarmer = _collectedLitresByFarmer();
        final paidByFarmer = _paidByFarmer();

        return Scaffold(
          appBar: AppBar(
            title: Text(_selectedTab.label),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Text(isAdmin ? 'Admin • ${user.email}' : 'Farmer • ${farmer.name}'),
                ),
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
              Expanded(
                child: _TabContent(
                  tab: _selectedTab,
                  isAdmin: isAdmin,
                  user: user,
                  farmers: _farmers,
                  collections: _collections,
                  payments: _payments,
                  farmer: farmer,
                  ratePerLitre: _ratePerLitre,
                  litresByFarmer: collectedByFarmer,
                  paidByFarmer: paidByFarmer,
                  onAddFarmer: _showAddFarmerDialog,
                  onDropFarmer: _dropFarmer,
                ),
              ),
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
  const _TabContent({
    required this.tab,
    required this.isAdmin,
    required this.user,
    required this.farmers,
    required this.collections,
    required this.payments,
    required this.farmer,
    required this.ratePerLitre,
    required this.litresByFarmer,
    required this.paidByFarmer,
    required this.onAddFarmer,
    required this.onDropFarmer,
  });

  final PrimaryTab tab;
  final bool isAdmin;
  final User user;
  final List<FarmerRecord> farmers;
  final List<MilkCollectionRecord> collections;
  final List<PaymentRecord> payments;
  final FarmerRecord farmer;
  final double ratePerLitre;
  final Map<String, double> litresByFarmer;
  final Map<String, double> paidByFarmer;
  final Future<void> Function() onAddFarmer;
  final void Function(FarmerRecord farmer) onDropFarmer;

  double _owedAmount(String farmerId) {
    final totalLitres = litresByFarmer[farmerId] ?? 0;
    final paid = paidByFarmer[farmerId] ?? 0;
    return (totalLitres * ratePerLitre) - paid;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime(2026, 3, 31);
    final monthName = DateFormat('MMMM y').format(today);

    switch (tab) {
      case PrimaryTab.dashboard:
        if (isAdmin) {
          final totalOwed = farmers.fold<double>(
            0,
            (double acc, FarmerRecord farmer) => acc + _owedAmount(farmer.id),
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _KpiCard(label: 'Total farmers', value: '${farmers.length}'),
                  _KpiCard(
                    label: 'Collected litres (month)',
                    value: '${litresByFarmer.values.fold<double>(0, (a, b) => a + b).toStringAsFixed(0)} L',
                  ),
                  _KpiCard(label: 'Total owed', value: '\$${totalOwed.toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Amount owed by farmer',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: farmers
                      .map(
                        (FarmerRecord farmer) => Text(
                          '• ${farmer.name}: \$${_owedAmount(farmer.id).toStringAsFixed(2)}',
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );
        }

        final farmerCollections = collections
            .where((MilkCollectionRecord c) => c.farmerId == farmer.id)
            .toList();
        final totalLitres = farmerCollections.fold<double>(
          0,
          (double sum, MilkCollectionRecord c) => sum + c.litres,
        );
        final totalPaid = paidByFarmer[farmer.id] ?? 0;
        final totalOwed = (totalLitres * ratePerLitre) - totalPaid;
        final smsBody =
            'MPAA report for ${farmer.name}: ${farmerCollections.length} collections recorded. Amount received per collection is calculated at \$${ratePerLitre.toStringAsFixed(2)} per litre.';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _KpiCard(label: 'Milk collected', value: '${totalLitres.toStringAsFixed(1)} L'),
                _KpiCard(label: 'Amount owed', value: '\$${totalOwed.toStringAsFixed(2)}'),
                _KpiCard(label: 'Amount paid', value: '\$${totalPaid.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Reports (SMS)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(smsBody),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('SMS report queued for delivery.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.sms_outlined),
                    label: const Text('Send report to phone'),
                  ),
                ],
              ),
            ),
          ],
        );
      case PrimaryTab.farmers:
        if (!isAdmin) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _SectionCard(
                title: 'Farmer profile',
                child: Text('${farmer.name} • ${farmer.phone} • ${farmer.location}'),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(child: SearchBar(hintText: 'Search by name/phone/location')),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onAddFarmer,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add farmer'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _RoleBanner(isAdmin: true, adminAction: 'Add or drop farmer accounts'),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Farmers in system',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: farmers
                    .map(
                      (FarmerRecord farmer) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${farmer.name} (${farmer.location})'),
                        subtitle: Text(farmer.phone),
                        trailing: IconButton(
                          onPressed: () => onDropFarmer(farmer),
                          icon: const Icon(Icons.person_remove),
                          tooltip: 'Drop farmer',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      case PrimaryTab.collections:
        if (!isAdmin) {
          final farmerCollections = collections
              .where((MilkCollectionRecord c) => c.farmerId == farmer.id)
              .toList()
            ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _SectionCard(
                title: 'Your milk collections',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: farmerCollections
                      .map(
                        (MilkCollectionRecord c) => Text(
                          '• ${DateFormat('MMM d, y').format(c.recordedAt)} — ${c.litres.toStringAsFixed(1)} L',
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );
        }

        final dailyTotals = <String, double>{};
        final monthlyTotals = <String, double>{};
        for (final record in collections) {
          final dayKey = '${record.farmerId}-${DateFormat('yyyy-MM-dd').format(record.recordedAt)}';
          final monthKey = '${record.farmerId}-${record.recordedAt.year}-${record.recordedAt.month}';
          dailyTotals.update(dayKey, (double v) => v + record.litres, ifAbsent: () => record.litres);
          monthlyTotals.update(monthKey, (double v) => v + record.litres, ifAbsent: () => record.litres);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _SectionCard(
              title: 'Daily and monthly collection per farmer ($monthName)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: farmers.map((FarmerRecord farmer) {
                  final dayKey = '${farmer.id}-${DateFormat('yyyy-MM-dd').format(today)}';
                  final monthKey = '${farmer.id}-${today.year}-${today.month}';
                  return Text(
                    '• ${farmer.name}: Today ${dailyTotals[dayKey]?.toStringAsFixed(1) ?? '0.0'} L, Month ${monthlyTotals[monthKey]?.toStringAsFixed(1) ?? '0.0'} L',
                  );
                }).toList(),
              ),
            ),
          ],
        );
      case PrimaryTab.payments:
        if (!isAdmin) {
          final farmerPayments = payments
              .where((PaymentRecord p) => p.farmerId == farmer.id)
              .toList()
            ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _SectionCard(
                title: 'Your payments received',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: farmerPayments
                      .map(
                        (PaymentRecord p) => Text(
                          '• ${DateFormat('MMM d, y').format(p.recordedAt)} — \$${p.amount.toStringAsFixed(2)}',
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            const _RoleBanner(isAdmin: true, adminAction: 'Review outstanding balances'),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Owed amount (global and per farmer)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Total owed: \$${farmers.fold<double>(0, (double total, FarmerRecord farmer) => total + _owedAmount(farmer.id)).toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 8),
                  ...farmers.map(
                    (FarmerRecord farmer) => Text(
                      '• ${farmer.name}: \$${_owedAmount(farmer.id).toStringAsFixed(2)}',
                    ),
                  ),
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
