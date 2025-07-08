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
    Navigator.pop(context); // close the drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'LAN Beam Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('Discovery'),
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => _onItemTapped(2),
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Transfer Progress'),
              onTap: () => _onItemTapped(3),
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('File Picker'),
              onTap: () => _onItemTapped(4),
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}
