import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_file_info/flutter_file_info.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  IconInfo? _iconInfo;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadIcon();
  }

  Future<void> _loadIcon() async {
    final bravePath = r'C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe';
    if (!File(bravePath).existsSync()) {
      setState(() => _error = 'Brave not found at $bravePath');
      return;
    }

    try {
      final info = await FileInfo.instance.getFileIconInfo(bravePath);
      setState(() {
        _iconInfo = info;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Icon Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_error.isNotEmpty) Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            if (_iconInfo != null) ...[
              Text('Icon loaded: ${_iconInfo!.width}x${_iconInfo!.height}, ${_iconInfo!.pixelData.length} bytes'),
              const SizedBox(height: 20),
              Image.memory(
                _iconInfo!.pixelData,
                width: 100,
                height: 100,
                errorBuilder: (context, error, stackTrace) => Text('Failed to render Image.memory: $error'),
              ),
            ] else if (_error.isEmpty) ...[
              const CircularProgressIndicator(),
            ]
          ],
        ),
      ),
    );
  }
}
