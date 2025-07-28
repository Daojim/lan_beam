import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _deviceNameController;
  late TextEditingController _saveFolderController;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _deviceNameController = TextEditingController(
      text: appState.settings.localDeviceName,
    );
    _saveFolderController = TextEditingController(
      text: appState.settings.defaultSaveFolder,
    );
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _saveFolderController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final appState = context.read<AppState>();
    final newSettings = AppSettings(
      localDeviceName: _deviceNameController.text,
      defaultSaveFolder: _saveFolderController.text,
      showMyDeviceForTesting: appState.settings.showMyDeviceForTesting,
    );
    appState.updateSettings(newSettings);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _deviceNameController,
              decoration: const InputDecoration(labelText: 'Device Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _saveFolderController,
              decoration: const InputDecoration(
                labelText: 'Default Save Folder',
              ),
            ),
            const SizedBox(height: 32),

            // Testing Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Testing Options',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Show my device in transfer list'),
                      subtitle: const Text(
                        'Enable to test file transfers to yourself',
                      ),
                      value: appState.settings.showMyDeviceForTesting,
                      onChanged: (bool value) {
                        final newSettings = AppSettings(
                          localDeviceName: appState.settings.localDeviceName,
                          defaultSaveFolder:
                              appState.settings.defaultSaveFolder,
                          showMyDeviceForTesting: value,
                        );
                        appState.updateSettings(newSettings);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
