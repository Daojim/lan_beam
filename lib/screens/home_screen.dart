import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/app_state.dart';
import '../models/transfer_session.dart';
import '../models/device.dart';
import '../models/transfer_item.dart';
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

    final selectedItem = appState.selectedItem;

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
                title: 'File & Folder Selection',
                children: [
                  if (selectedItem == null) ...[
                    const Text(
                      'No file or folder selected.',
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
                          Icon(
                            selectedItem.type == TransferItemType.file
                                ? Icons.insert_drive_file
                                : Icons.folder,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedItem.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${selectedItem.formattedSize} • ${selectedItem.type == TransferItemType.file ? 'File' : 'Folder'}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => appState.setSelectedItem(null),
                            icon: const Icon(Icons.close, color: Colors.red),
                            tooltip: 'Clear selection',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // File and folder picker buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickFile(context, appState),
                          icon: const Icon(Icons.insert_drive_file),
                          label: const Text('Choose File'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _pickFolder(context, appState),
                          icon: const Icon(Icons.folder),
                          label: const Text('Choose Folder'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        // Scrollable device list section
        if (selectedItem != null) ...[
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
                                onPressed:
                                    device.status == DeviceStatus.available &&
                                        selectedItem.type ==
                                            TransferItemType.file
                                    ? () => _sendFileToDevice(
                                        context,
                                        appState,
                                        device,
                                      )
                                    : null,
                                icon: Icon(
                                  selectedItem.type == TransferItemType.folder
                                      ? Icons.folder_off
                                      : Icons.send,
                                ),
                                label: Text(
                                  selectedItem.type == TransferItemType.folder
                                      ? 'Coming Soon'
                                      : 'Send',
                                ),
                                style:
                                    selectedItem.type == TransferItemType.folder
                                    ? ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange.shade100,
                                        foregroundColor: Colors.orange.shade700,
                                      )
                                    : null,
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
    if (appState.selectedItem == null) return;

    // Check if trying to send a folder
    if (appState.selectedItem!.type == TransferItemType.folder) {
      _showErrorDialog(
        context,
        'Folder Transfer Not Yet Supported',
        'Folder transfers are coming soon! For now, please select individual files.',
      );
      return;
    }

    // Start transfer session visually first
    appState.setActiveTransfer(
      TransferSession(
        direction: TransferDirection.sending,
        file: appState
            .selectedFile!, // This will use the backward compatibility getter
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
    await sender.sendFile(
      appState.selectedFile!,
      device,
    ); // This will use the backward compatibility getter
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

  // File picker method
  Future<void> _pickFile(BuildContext context, AppState appState) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      final pickedFile = result.files.first;
      if (pickedFile.path != null) {
        final itemResult = TransferItem.createFile(filePath: pickedFile.path!);
        if (itemResult.isSuccess) {
          appState.setSelectedItem(itemResult.value);
        } else {
          _showErrorDialog(context, 'Invalid File', itemResult.error!);
        }
      }
    } else {
      _showErrorDialog(
        context,
        'No File Selected',
        'Please choose a file to continue.',
      );
    }
  }

  // Folder picker method
  Future<void> _pickFolder(BuildContext context, AppState appState) async {
    String? directoryPath = await FilePicker.platform.getDirectoryPath();

    if (directoryPath != null) {
      final itemResult = await TransferItem.createFolder(
        folderPath: directoryPath,
      );
      if (itemResult.isSuccess) {
        appState.setSelectedItem(itemResult.value);
      } else {
        _showErrorDialog(context, 'Invalid Folder', itemResult.error!);
      }
    } else {
      _showErrorDialog(
        context,
        'No Folder Selected',
        'Please choose a folder to continue.',
      );
    }
  }

  // Error dialog helper
  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
