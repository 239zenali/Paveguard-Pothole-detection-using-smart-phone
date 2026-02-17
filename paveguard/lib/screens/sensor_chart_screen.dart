import 'package:flutter/material.dart';
import '../services/sensor_service.dart';
import '../widgets/sensor_chart.dart';
import 'map_screen.dart';

class SensorChartScreen extends StatefulWidget {
  const SensorChartScreen({super.key});

  @override
  State<SensorChartScreen> createState() => _SensorChartScreenState();
}

class _SensorChartScreenState extends State<SensorChartScreen> {
  final SensorService _service = SensorService.instance();
  bool _isStarted = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _service.sensorStream.listen((event) {
      // if a pothole event arrived we can show snackbar or update UI
      if (event.containsKey('pothole')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pothole detected (map updated)')),
          );
        }
      }
      // If location update given, you could update UI as needed
    });
  }

  @override
  void dispose() {
    // don't dispose singleton here to allow map to keep using it
    super.dispose();
  }

  Future<void> _start() async {
    await _service.start();
    setState(() {
      _isStarted = true;
      _isPaused = false;
    });
  }

  void _pauseOrResume() {
    if (!_isStarted) return;
    if (_isPaused) {
      _service.resume();
      setState(() => _isPaused = false);
    } else {
      _service.pause();
      setState(() => _isPaused = true);
    }
  }

  void _stop() {
    if (!_isStarted) return;
    _service.stop();
    setState(() {
      _isStarted = false;
      _isPaused = false;
    });
  }


  void _openMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapScreen(sensorService: SensorService.instance()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensor Dashboard')),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _service.sensorStream,
        builder: (context, snapshot) {
          final accel = snapshot.data?['accelerometer'] ?? [0.0, 0.0, 0.0];
          final gyro = snapshot.data?['gyroscope'] ?? [0.0, 0.0, 0.0];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(
              children: [
                const Text('Accelerometer (X,Y,Z)',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SensorChart(data: accel, color: Colors.blue),
                const SizedBox(height: 20),
                const Text('Gyroscope (X,Y,Z)',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SensorChart(data: gyro, color: Colors.green),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start'),
                        onPressed: _isStarted ? null : _start,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(_isPaused ? Icons.play_circle : Icons.pause),
                        label: Text(_isPaused ? 'Resume' : 'Pause'),
                        onPressed: _isStarted ? _pauseOrResume : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop'),
                        onPressed: _isStarted ? _stop : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.map),
                  label: const Text('Open Map'),
                  onPressed: _openMap,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
