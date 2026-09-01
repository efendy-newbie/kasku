import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../utils/formatters.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/goal_sheet.dart';
import '../widgets/transfer_sheet.dart';
import 'dashboard_screen.dart';
import 'goals_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class RootShell extends ConsumerStatefulWidget {
  const RootShell({super.key});

  @override
  ConsumerState<RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<RootShell> {
  final _screens = const [
    DashboardScreen(),
    HistoryScreen(),
    GoalsScreen(),
    StatsScreen(),
  ];

  void _openFabMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).dividerColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Text('Buat Baru', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Tambah Pemasukan'),
                onTap: () {
                  Navigator.pop(ctx);
                  showAddTransactionSheet(context, initialIsIncome: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle_outline),
                title: const Text('Tambah Pengeluaran'),
                onTap: () {
                  Navigator.pop(ctx);
                  showAddTransactionSheet(context, initialIsIncome: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Transfer Antar Akun'),
                onTap: () {
                  Navigator.pop(ctx);
                  showTransferSheet(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Target Tabungan Baru'),
                onTap: () {
                  Navigator.pop(ctx);
                  showGoalSheet(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final tabIndex = ref.watch(currentTabProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              topBarDateLabel(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              greetingForNow(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(appState.themeMode == ThemeMode.dark
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined),
            onPressed: () {
              final order = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];
              final cur = order.indexOf(appState.themeMode);
              appState.setThemeMode(order[(cur + 1) % order.length]);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => showSettingsSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _screens[tabIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _openFabMenu,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (i) => ref.read(currentTabProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Riwayat'),
          NavigationDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag), label: 'Target'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Statistik'),
        ],
      ),
    );
  }
}
