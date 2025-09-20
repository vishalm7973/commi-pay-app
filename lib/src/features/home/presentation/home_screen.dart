import 'package:commipay_app/src/features/committees/presentation/committees_screen.dart';
import 'package:commipay_app/src/features/home/presentation/tabs/home_tab.dart';
import 'package:commipay_app/src/features/home/presentation/tabs/settings_tab.dart';
import 'package:commipay_app/src/features/members/presentation/member_screen.dart';
import 'package:commipay_app/utils/app_colors.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeTab(),
      CommitteesScreen(),
      MembersScreen(),
      SettingsTab(),
    ];
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<BottomNavigationBarItem> tabs = const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.group_work), label: 'Committee'),
    BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Members'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: tabs,
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        selectedItemColor: Color(0xFF093030),
        unselectedItemColor: AppColors.honeydew,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.caribbeanGreen,
      ),
    );
  }
}
