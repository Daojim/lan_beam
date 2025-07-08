import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../models/file_info.dart';

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
              Text('File Size: ${file.fileSizeBytes} bytes'),
              Text('File Type: ${file.fileType}'),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // For now: simulate picking a file
                appState.setSelectedFile(
                  FileInfo(
                    fileName: 'example_document.pdf',
                    fileSizeBytes: 234567,
                    fileType: '.pdf',
                    filePath: '/fake/path/example_document.pdf',
                  ),
                );
              },
              child: const Text('Pick File (Simulated)'),
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
