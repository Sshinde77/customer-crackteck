import 'package:customer_cracktreck/screens/product_list.dart';
import 'package:customer_cracktreck/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'hometab.dart';
import 'amc_plans_screen.dart';
import '../widgets/custom_bottom_nav.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // The screens for each tab
  final List<Widget> _pages = [
    const HomeScreen(), // Home Tab
    const AmcPlansScreen(), // AMC Tab
    const ProductScreen(), // Product Tab
    const ProfileScreen(), // Profile Tab
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps the state of each page alive
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
