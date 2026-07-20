import 'package:flutter/material.dart';
import 'package:nara/features/assistant/presentation/pages/assistant_coming_soon_page.dart';
import 'package:nara/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:nara/features/finance/presentation/pages/finance_page.dart';
import 'package:nara/features/productivity/presentation/pages/schedule_page.dart';
import 'package:nara/features/productivity/presentation/pages/task_page.dart';
import 'package:nara/features/settings/presentation/pages/settings_page.dart';
import 'package:nara/features/smart_scan/presentation/pages/smart_scan_page.dart';
import 'package:nara/shared/widgets/nara_logo.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _selectedIndex = 0;

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
          bottomNavigationBar: _NaraBottomBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _selectPage,
          ),
        );
      },
    );
  }
}

class _NaraBottomBar extends StatelessWidget {
  const _NaraBottomBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final colors = Theme.of(context).colorScheme;

    return Container(
      key: const ValueKey('nara-bottom-bar'),
      padding: EdgeInsets.fromLTRB(18, 10, 18, 12 + bottom),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow.withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.7)),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF001B3D).withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, -14),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavIcon(
            key: const ValueKey('nav-home'),
            icon: Icons.grid_view_rounded,
            label: 'Beranda',
            selected: selectedIndex == 0,
            onTap: () => onDestinationSelected(0),
          ),
          _NavIcon(
            key: const ValueKey('nav-finance'),
            icon: Icons.account_balance_wallet_outlined,
            label: 'Keuangan',
            selected: selectedIndex == 1,
            onTap: () => onDestinationSelected(1),
          ),
          _AssistantOrb(
            key: const ValueKey('nav-assistant'),
            selected: selectedIndex == 4,
            onTap: () => onDestinationSelected(4),
          ),
          _NavIcon(
            key: const ValueKey('nav-schedule'),
            icon: Icons.calendar_month_outlined,
            label: 'Jadwal',
            selected: selectedIndex == 2,
            onTap: () => onDestinationSelected(2),
          ),
          _NavIcon(
            key: const ValueKey('nav-task'),
            icon: Icons.format_list_bulleted_rounded,
            label: 'Task',
            selected: selectedIndex == 3,
            onTap: () => onDestinationSelected(3),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = selected ? colors.secondary : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: SizedBox(
          width: 54,
          height: 54,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 5 : 3,
                height: selected ? 5 : 3,
                decoration: BoxDecoration(
                  color: selected ? colors.secondary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantOrb extends StatelessWidget {
  const _AssistantOrb({required this.selected, required this.onTap, super.key});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Asisten',
      child: InkResponse(
        onTap: onTap,
        radius: 40,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF001B3D), Color(0xFF007B89)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF00DDF2,
                ).withValues(alpha: selected ? 0.38 : 0.2),
                blurRadius: selected ? 28 : 20,
                spreadRadius: selected ? 3 : 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Center(
            child: NaraLogo(
              size: 44,
              padding: 4,
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
