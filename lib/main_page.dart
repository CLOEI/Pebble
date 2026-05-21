import 'package:flutter/material.dart';
import 'tabs/home_tab.dart';
import 'tabs/todo_tab.dart';
import 'tabs/calories_tab.dart';
import 'tabs/report_tab.dart';
import 'tabs/profile_tab.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _tab = 0;

  static const _tabs = [HomeTab(), TodoTab(), CaloriesTab(), ReportTab(), ProfileTab()];

  static const _navItems = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.check_circle_outline_rounded, label: 'Todo'),
    (icon: Icons.local_fire_department_rounded, label: 'Calories'),
    (icon: Icons.bar_chart_rounded, label: 'Report'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (i) {
                final item = _navItems[i];
                final selected = i == _tab;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _tab = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 26,
                          color: selected
                              ? const Color(0xFFF5A623)
                              : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? const Color(0xFFF5A623)
                                : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
