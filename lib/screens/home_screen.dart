import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/app_state.dart';
import '../models/transfer_session.dart';
import '../models/device.dart';
import '../models/file_info.dart';
import '../screens/incoming_request_screen.dart';
import '../main.dart'; // gives access to `tcpFileReceiver`

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transfer = appState.activeTransfer;
      if (transfer != null &&
          transfer.direction == TransferDirection.receiving &&
          transfer.status == TransferStatus.idle) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const IncomingRequestScreen(),
          ),
        );
      }
    });

    final selectedFile = appState.selectedFile;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device Info Section
          _buildInfoCard(
            context,
            title: 'Device Information',
            children: [
              Text('Device Name: ${appState.settings.localDeviceName}'),
              const SizedBox(height: 8),
              Text('Save Folder: ${appState.settings.defaultSaveFolder}'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Status: ${appState.isListening ? "Listening" : "Stopped"}',
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    appState.isListening
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: appState.isListening ? Colors.green : Colors.grey,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Control Buttons
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  if (appState.isListening) {
                    tcpFileReceiver.stopListening();
                  } else {
                    tcpFileReceiver.startListening();
                  }
                  appState.toggleListening();
                },
                icon: Icon(
                  appState.isListening ? Icons.stop : Icons.play_arrow,
                ),
                label: Text(
                  appState.isListening ? 'Stop Listening' : 'Start Listening',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appState.isListening
                      ? Colors.red
                      : Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  if (appState.selectedFile == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please pick a file first.'),
                      ),
                    );
                    return;
                  }

                  // Create a fake sending TransferSession to simulate an incoming request
                  appState.setActiveTransfer(
                    TransferSession(
                      direction: TransferDirection.sending,
                      file: appState.selectedFile!,
                      progress: 0.0,
                      status: TransferStatus.idle,
                      peerDevice: Device(
                        name: 'TestSender-PC',
                        ipAddress: '192.168.1.99',
                        status: DeviceStatus.available,
                      ),
                    ),
                  );

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const IncomingRequestScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.bug_report),
                label: const Text('Test Mode'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // File Selection Section
          _buildInfoCard(
            context,
            title: 'File Selection',
            children: [
              if (selectedFile == null) ...[
                const Text(
                  'No file selected.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedFile.fileName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${selectedFile.formattedSize} • ${selectedFile.fileType}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => appState.setSelectedFile(null),
                        icon: const Icon(Icons.close, color: Colors.red),
                        tooltip: 'Remove file',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // File picker buttons
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result = await FilePicker.platform
                          .pickFiles();

                      if (result != null && result.files.isNotEmpty) {
                        final pickedFile = result.files.first;

                        appState.setSelectedFile(
                          FileInfo(
                            fileName: pickedFile.name,
                            fileSizeBytes: pickedFile.size,
                            fileType: pickedFile.extension != null
                                ? '.${pickedFile.extension}'
                                : '',
                            filePath: pickedFile.path ?? '',
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No file selected')),
                        );
                      }
                    },
                    icon: const Icon(Icons.folder_open),
                    label: Text(
                      selectedFile == null ? 'Choose File' : 'Change File',
                    ),
                  ),
                  if (selectedFile != null) ...[
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => appState.setSelectedFile(null),
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
