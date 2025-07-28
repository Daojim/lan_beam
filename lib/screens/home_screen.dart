import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/app_state.dart';
import '../models/transfer_session.dart';
import '../models/device.dart';
import '../models/file_info.dart';
import '../screens/incoming_request_screen.dart';
import '../screens/transfer_progress_screen.dart';
import '../services/tcp_file_sender.dart';

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

    return Column(
      children: [
        // Fixed top sections (non-scrollable)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device Info Section (fixed at top)
              _buildInfoCard(
                context,
                title: 'Device Information',
                children: [
                  Text('Device Name: ${appState.settings.localDeviceName}'),
                  const SizedBox(height: 8),
                  Text('Save Folder: ${appState.settings.defaultSaveFolder}'),
                ],
              ),

              const SizedBox(height: 24),

              // File Selection Section (fixed at top)
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
                          // Non-intrusive dialog instead of SnackBar
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('No File Selected'),
                              content: const Text(
                                'Please choose a file to continue.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
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
        ),

        // Scrollable device list section
        if (selectedFile != null) ...[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildInfoCard(
                context,
                title: 'Send to Device',
                children: [
                  if (_getFilteredDevices(appState).isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Searching for devices...\nMake sure other devices have LAN Beam open.',
                              style: TextStyle(color: Colors.orange.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Make device list scrollable with fixed height
                    SizedBox(
                      height: 300, // Fixed height for device list
                      child: ListView.builder(
                        itemCount: _getFilteredDevices(appState).length,
                        itemBuilder: (context, index) {
                          final device = _getFilteredDevices(appState)[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.devices,
                                color: device.status == DeviceStatus.available
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                              title: Text(device.name),
                              subtitle: Text(device.ipAddress),
                              trailing: ElevatedButton.icon(
                                onPressed: device.status == DeviceStatus.available
                                    ? () => _sendFileToDevice(
                                          context,
                                          appState,
                                          device,
                                        )
                                    : null,
                                icon: const Icon(Icons.send),
                                label: const Text('Send'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _sendFileToDevice(
    BuildContext context,
    AppState appState,
    Device device,
  ) async {
    if (appState.selectedFile == null) return;

    // Start transfer session visually first
    appState.setActiveTransfer(
      TransferSession(
        direction: TransferDirection.sending,
        file: appState.selectedFile!,
        progress: 0.0,
        status: TransferStatus.connecting,
        peerDevice: device,
      ),
    );

    // Navigate to progress screen
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const TransferProgressScreen()),
    );

    // Start sending file over TCP
    final sender = TcpFileSender(appState);
    await sender.sendFile(appState.selectedFile!, device);
  }

  // Filter out current device unless testing mode is enabled
  List<Device> _getFilteredDevices(AppState appState) {
    if (appState.settings.showMyDeviceForTesting) {
      // Show all devices including current device
      return appState.discoveredDevices;
    } else {
      // Filter out current device by name
      return appState.discoveredDevices
          .where((device) => device.name != appState.settings.localDeviceName)
          .toList();
    }
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
