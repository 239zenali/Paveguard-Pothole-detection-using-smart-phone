import 'package:flutter/material.dart';
import 'sensor_chart_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PaveGuard - Pothole Detector')),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.sensors),
            label: const Text('Open Sensor Dashboard'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SensorChartScreen()),
              );
            },
          ),
        ]),
      ),
    );
  }
}
