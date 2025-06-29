import 'package:flutter/material.dart';

void main() {
  runApp(const LanBeamApp());
}

class LanBeamApp extends StatelessWidget {
  const LanBeamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LAN Beam',
      home: Scaffold(
        appBar: AppBar(title: const Text('LAN Beam')),
        body: const Center(child: Text('Welcome to LAN Beam!')),
      ),
    );
  }
}
