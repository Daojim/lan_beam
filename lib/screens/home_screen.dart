import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lan_beam/models/app_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Lan Beam Home')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Local Device Name:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(appState.settings.localDeviceName),

            const SizedBox(height: 16),

            Text(
              'Default Save Folder:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(appState.settings.defaultSaveFolder),

            const SizedBox(height: 16),

            Text(
              'Listening for incoming requests:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(appState.isListening ? 'Yes' : 'No'),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                appState.setListening(!appState.isListening);
              },
              child: Text(
                appState.isListening ? 'Stop Listening' : 'Start Listening',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
