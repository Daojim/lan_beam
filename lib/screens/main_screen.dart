import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'discovery_screen.dart';
import 'settings_screen.dart';
import 'transfer_progress_screen.dart';
import 'file_picker_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    DiscoveryScreen(),
    SettingsScreen(),
    TransferProgressScreen(),
    FilePickerScreen(),
  ];

  final List<String> _titles = [
    'Home',
    'Discovery',
    'Settings',
    'Transfer Progress',
    'File Picker',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Permanent Sidebar
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                right: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Sidebar Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: Colors.blue),
                  child: const Text(
                    'LAN Beam',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Sidebar Menu Items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildSidebarItem(
                        icon: Icons.home,
                        title: 'Home',
                        index: 0,
                      ),
                      _buildSidebarItem(
                        icon: Icons.devices,
                        title: 'Discovery',
                        index: 1,
                      ),
                      _buildSidebarItem(
                        icon: Icons.settings,
                        title: 'Settings',
                        index: 2,
                      ),
                      _buildSidebarItem(
                        icon: Icons.swap_horiz,
                        title: 'Transfer Progress',
                        index: 3,
                      ),
                      _buildSidebarItem(
                        icon: Icons.insert_drive_file,
                        title: 'File Picker',
                        index: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _titles[_selectedIndex],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                // Screen Content
                Expanded(child: _screens[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: Colors.blue.withOpacity(0.3), width: 1)
            : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey[600]),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () => _onItemTapped(index),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
