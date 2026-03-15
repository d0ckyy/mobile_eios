import 'package:flutter/material.dart';
import 'package:eios/presentation/screens/attendance_code/attendance_code_screen.dart';
import 'package:eios/core/theme/app_theme.dart';
import 'package:eios/presentation/screens/discipline/discipline_screen.dart';
import 'package:eios/presentation/screens/timetable/timetable_screen.dart';
import 'profile/profile_screen.dart';

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  int _currentIndex = 0;
  static const int _scannerTabIndex = 3;
  static const List<_TabItemData> _tabs = [
    _TabItemData(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: 'Расписание',
    ),
    _TabItemData(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Профиль',
    ),
    _TabItemData(
      icon: Icons.auto_stories_outlined,
      selectedIcon: Icons.auto_stories_rounded,
      label: 'Успеваемость',
    ),
    _TabItemData(
      icon: Icons.qr_code_scanner_outlined,
      selectedIcon: Icons.qr_code_scanner_rounded,
      label: 'Посещаемость',
    ),
  ];

  final Map<int, Widget> _loadedPages = {};

  @override
  void initState() {
    super.initState();
    _loadPage(0);
  }

  void _loadPage(int index) {
    if (index == _scannerTabIndex) return;

    if (!_loadedPages.containsKey(index)) {
      switch (index) {
        case 0:
          _loadedPages[0] = const TimeTableScreen();
          break;
        case 1:
          _loadedPages[1] = const ProfileScreen();
          break;
        case 2:
          _loadedPages[2] = const DisciplineListScreen();
          break;
      }
    }
  }

  Widget _pageForIndex(int index) {
    if (index == _scannerTabIndex) {
      return AttendanceCodeScreen(isActive: _currentIndex == _scannerTabIndex);
    }

    return _loadedPages[index] ??
        const Center(child: CircularProgressIndicator());
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _loadPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(4, _pageForIndex),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: appPanelDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (index) {
                final item = _tabs[index];

                return _CompactTabButton(
                  icon: item.icon,
                  selectedIcon: item.selectedIcon,
                  label: item.label,
                  isSelected: _currentIndex == index,
                  onTap: () => _onTabTapped(index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactTabButton extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CompactTabButton({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.deepBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isSelected ? selectedIcon : icon,
              size: 22,
              color: isSelected ? AppColors.white : AppColors.mutedText,
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _TabItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
