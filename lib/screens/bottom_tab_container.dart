import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'customer_list_screen.dart';
import 'db_inspector_screen.dart';

class BottomTabContainer extends StatefulWidget {
  const BottomTabContainer({super.key});

  @override
  State<BottomTabContainer> createState() => _BottomTabContainerState();
}

class _BottomTabContainerState extends State<BottomTabContainer> {
  int _selectedIndex = 0;
  
  static const List<Widget> _screens = [
    HomeScreen(),
    CalendarScreen(),
    CustomerListScreen(),
    DbInspectorScreen(),
  ];
    
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storage_outlined),
            activeIcon: Icon(Icons.storage),
            label: 'DB Inspector',
          ),
        ],
      ),
    );
  }
}