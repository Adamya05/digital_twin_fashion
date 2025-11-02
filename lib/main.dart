import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

void main() {
  runApp(const DigitalTwinFashionApp());
}

class DigitalTwinFashionApp extends StatelessWidget {
  const DigitalTwinFashionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Twin Fashion App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Twin Fashion'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_bag,
              size: 100,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 24),
            const Text(
              'Digital Twin Fashion App',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDarkGray,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'A modern fashion marketplace with virtual try-on technology',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textDarkGray,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'App Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('✅ Dependencies installed'),
                    const Text('✅ Theme configured'),
                    const Text('✅ Basic app structure ready'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Welcome to Digital Twin Fashion!'),
                          ),
                        );
                      },
                      child: const Text('Test App'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}