import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/file_info.dart';
import 'package:file_picker/file_picker.dart';

class FilePickerScreen extends StatelessWidget {
  const FilePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final file = appState.selectedFile;

    return Scaffold(
      appBar: AppBar(title: const Text('File Picker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (file == null)
              const Text('No file selected.')
            else ...[
              Text('File Name: ${file.fileName}'),
              Text('File Size: ${file.formattedSize}'),
              Text('File Type: ${file.fileType}'),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
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
                  // User canceled picking
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No file selected')),
                  );
                }
              },
              child: const Text('Pick File'),
            ),

            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                appState.setSelectedFile(null);
              },
              child: const Text('Clear Selected File'),
            ),
          ],
        ),
      ),
    );
  }
}
