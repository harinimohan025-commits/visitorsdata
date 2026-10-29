import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../providers/visitor_provider.dart';
import '../utils/helpers.dart';
import 'dashboard_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';
import 'visitors_screens.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  final titles = const ['Dashboard', 'Visitors', 'Scan QR', 'Settings'];

  void _go(int i) => setState(() => selectedIndex = i);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VisitorProvider>();
    final waiting = provider.registeredCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[selectedIndex]),
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => context
                .read<ThemeProvider>()
                .setMode(isDark ? ThemeMode.light : ThemeMode.dark),
          ),
          if (selectedIndex <= 1)
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: provider.isLoading ? null : provider.load,
            ),
          if (selectedIndex == 1)
            IconButton(
              tooltip: 'Register visitor',
              icon: const Icon(Icons.person_add_alt_1_outlined),
              onPressed: () => openForm(context),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          DashboardScreen(onViewAll: () => _go(1), onScan: () => _go(2)),
          const VisitorsScreen(),
          // camera only exists while the Scan tab is visible
          selectedIndex == 2 ? const ScanScreen() : const SizedBox.shrink(),
          const SettingsScreen(),
        ],
      ),
      floatingActionButton: selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Register'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _go,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: waiting > 0,
              label: Text('$waiting'),
              child: const Icon(Icons.people_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: waiting > 0,
              label: Text('$waiting'),
              child: const Icon(Icons.people),
            ),
            label: 'Visitors',
          ),
          const NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}