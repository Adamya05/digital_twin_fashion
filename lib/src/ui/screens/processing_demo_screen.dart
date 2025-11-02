/// Demo Processing Screen
/// 
/// A demo screen that directly shows the processing screen with mock API polling.
/// This is for testing the processing flow without going through the full scan wizard.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ui/screens/processing_screen.dart';

class ProcessingDemoScreen extends ConsumerStatefulWidget {
  const ProcessingDemoScreen({super.key});

  @override
  ConsumerState<ProcessingDemoScreen> createState() => _ProcessingDemoScreenState();
}

class _ProcessingDemoScreenState extends ConsumerState<ProcessingDemoScreen> {
  String _scanId = '';

  @override
  void initState() {
    super.initState();
    // Generate a mock scan ID
    _scanId = 'demo_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Processing Demo'),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.bug_report,
                color: Colors.orange,
                size: 80,
              ),
              const SizedBox(height: 32),
              const Text(
                'Processing Demo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'This will demonstrate the processing screen with mock API polling.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Scan ID: $_scanId',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => ProcessingScreen(scanId: _scanId),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Processing Demo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.grey),
                label: const Text('Back', style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo Features:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Mock API polling every 1-2 seconds',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      '• Realistic processing delays (5-10 seconds)',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      '• Progress animations and status messages',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      '• Error handling and retry options',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      '• 30-second timeout protection',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      '• Automatic navigation to avatar preview',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
