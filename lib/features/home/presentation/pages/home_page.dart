import 'package:flutter/material.dart';
import 'package:nara/features/assistant/presentation/pages/assistant_coming_soon_page.dart';
import 'package:nara/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:nara/features/finance/presentation/pages/finance_page.dart';
import 'package:nara/features/productivity/presentation/pages/schedule_page.dart';
import 'package:nara/features/productivity/presentation/pages/task_page.dart';
import 'package:nara/features/settings/presentation/pages/settings_page.dart';
import 'package:nara/features/smart_scan/presentation/pages/smart_scan_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _selectedIndex = 0;

  static const _destinations = [
    NavigationDestination(
      key: ValueKey('nav-home'),
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Beranda',
    ),
    NavigationDestination(
      key: ValueKey('nav-finance'),
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet),
      label: 'Keuangan',
    ),
    NavigationDestination(
      key: ValueKey('nav-schedule'),
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month),
      label: 'Jadwal',
    ),
    NavigationDestination(
      key: ValueKey('nav-task'),
      icon: Icon(Icons.task_alt_outlined),
      selectedIcon: Icon(Icons.task_alt),
      label: 'Task',
    ),
    NavigationDestination(
      key: ValueKey('nav-assistant'),
      icon: Icon(Icons.auto_awesome_outlined),
      selectedIcon: Icon(Icons.auto_awesome),
      label: 'Asisten',
    ),
  ];

  static const _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined, key: ValueKey('nav-home')),
      selectedIcon: Icon(Icons.home, key: ValueKey('nav-home')),
      label: Text('Beranda'),
    ),
    NavigationRailDestination(
      icon: Icon(
        Icons.account_balance_wallet_outlined,
        key: ValueKey('nav-finance'),
      ),
      selectedIcon: Icon(
        Icons.account_balance_wallet,
        key: ValueKey('nav-finance'),
      ),
      label: Text('Keuangan'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.calendar_month_outlined, key: ValueKey('nav-schedule')),
      selectedIcon: Icon(Icons.calendar_month, key: ValueKey('nav-schedule')),
      label: Text('Jadwal'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.task_alt_outlined, key: ValueKey('nav-task')),
      selectedIcon: Icon(Icons.task_alt, key: ValueKey('nav-task')),
      label: Text('Task'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.auto_awesome_outlined, key: ValueKey('nav-assistant')),
      selectedIcon: Icon(Icons.auto_awesome, key: ValueKey('nav-assistant')),
      label: Text('Asisten'),
    ),
  ];

  void _selectPage(int index) {
    setState(() => _selectedIndex = index);
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => const SettingsPage()));
  }

  void _openSmartScan() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const SmartScanPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        onOpenFinance: () => _selectPage(1),
        onOpenSchedule: () => _selectPage(2),
        onOpenTasks: () => _selectPage(3),
        onOpenSmartScan: _openSmartScan,
        onOpenSettings: _openSettings,
      ),
      const FinancePage(),
      const SchedulePage(),
      const TaskPage(),
      const AssistantPage(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 800;
        if (useRail) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    labelType: constraints.maxWidth >= 1100
                        ? NavigationRailLabelType.all
                        : NavigationRailLabelType.selected,
                    destinations: _railDestinations,
                    onDestinationSelected: _selectPage,
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: IndexedStack(index: _selectedIndex, children: pages),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: IndexedStack(index: _selectedIndex, children: pages),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            destinations: _destinations,
            onDestinationSelected: _selectPage,
          ),
        );
      },
    );
  }
}
