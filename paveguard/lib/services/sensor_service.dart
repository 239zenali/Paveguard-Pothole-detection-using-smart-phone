import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/pothole_model.dart';
import 'location_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

class SensorService {
  // Singleton
  SensorService._internal();
  static final SensorService _instance = SensorService._internal();
  factory SensorService.instance() => _instance;

  // Stream for UI
  final StreamController<Map<String, dynamic>> _sensorController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get sensorStream => _sensorController.stream;

  // Subscriptions
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<Position>? _positionSub;

  // Last sensor values
  double _ax = 0, _ay = 0, _az = 0;
  double _gx = 0, _gy = 0, _gz = 0;

  // Last known GPS position
  Position? _lastPosition;

  // Flags
  bool _isListening = false;
  bool _isPaused = false;

  // Pothole list (optional visualization)
  final List<PotholeModel> _potholes = [];

  // Firebase setup
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _firebaseInitialized = false;

  bool get isListening => _isListening;
  bool get isPaused => _isPaused;
  List<PotholeModel> getPotholePoints() => List.unmodifiable(_potholes);

  /// ✅ Initialize Firebase (once)
  Future<void> _initFirebase() async {
    if (!_firebaseInitialized) {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _firebaseInitialized = true;
      if (kDebugMode) debugPrint("✅ Firebase initialized in SensorService");
    }
  }

  /// ✅ Upload a single sensor reading to Firestore
  Future<void> _uploadSensorData(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('sensor_readings').add(data);
      if (kDebugMode) {
        debugPrint("📤 Uploaded sensor data: ${data['timestamp']}");
      }
    } catch (e) {
      if (kDebugMode) debugPrint("❌ Firestore upload failed: $e");
    }
  }

  /// ✅ Start collecting sensor + location data
  Future<void> start() async {
    await _initFirebase();

    if (_isListening) {
      if (_isPaused) resume();
      return;
    }

    final locOk = await LocationService.ensurePermission();
    if (!locOk) {
      if (kDebugMode) debugPrint('⚠️ Location permission denied — no GPS data');
    }

    _isListening = true;
    _isPaused = false;

    // ✅ Get one-time initial GPS fix
    try {
      final pos = await LocationService.getCurrentPositionSafe();
      if (pos != null) {
        _lastPosition = pos;
        if (kDebugMode) {
          debugPrint('📍 Initial GPS fix: ${pos.latitude}, ${pos.longitude}');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error getting initial location: $e');
    }

    // ✅ Continuous location updates
    try {
      _positionSub = LocationService.positionStream().listen((pos) {
        _lastPosition = pos;
        if (!_sensorController.isClosed) {
          _sensorController.add({
            'location': [pos.latitude, pos.longitude]
          });
        }
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error starting location stream: $e');
    }

    // ✅ Accelerometer stream
    _accelSub = accelerometerEventStream().listen((event) async {
      _ax = event.x;
      _ay = event.y;
      _az = event.z;

      if (_isPaused) return;

      final lat = _lastPosition?.latitude ?? 0.0;
      final lon = _lastPosition?.longitude ?? 0.0;

      final data = {
        "timestamp": DateTime.now().toIso8601String(),
        "ax": _ax,
        "ay": _ay,
        "az": _az,
        "gx": _gx,
        "gy": _gy,
        "gz": _gz,
        "latitude": lat,
        "longitude": lon
      };

      _uploadSensorData(data);

      if (!_sensorController.isClosed) {
        _sensorController.add({
          'accelerometer': [_ax, _ay, _az],
          'gyroscope': [_gx, _gy, _gz],
          'location': [lat, lon],
        });
      }
    });

    // ✅ Gyroscope stream
    _gyroSub = gyroscopeEventStream().listen((g) async {
      _gx = g.x;
      _gy = g.y;
      _gz = g.z;

      if (_isPaused) return;

      final lat = _lastPosition?.latitude ?? 0.0;
      final lon = _lastPosition?.longitude ?? 0.0;

      final data = {
        "timestamp": DateTime.now().toIso8601String(),
        "ax": _ax,
        "ay": _ay,
        "az": _az,
        "gx": _gx,
        "gy": _gy,
        "gz": _gz,
        "latitude": lat,
        "longitude": lon,
      };

      _uploadSensorData(data);

      if (!_sensorController.isClosed) {
        _sensorController.add({
          'accelerometer': [_ax, _ay, _az],
          'gyroscope': [_gx, _gy, _gz],
          'location': [lat, lon],
        });
      }
    });
  }

  void pause() {
    if (!_isListening || _isPaused) return;
    _isPaused = true;
    try {
      _accelSub?.pause();
      _gyroSub?.pause();
      _positionSub?.pause();
    } catch (_) {}
  }

  void resume() {
    if (!_isListening || !_isPaused) return;
    _isPaused = false;
    try {
      _accelSub?.resume();
      _gyroSub?.resume();
      _positionSub?.resume();
    } catch (_) {}
  }

  void stop() {
    if (!_isListening) return;
    _isListening = false;
    _isPaused = false;

    _accelSub?.cancel();
    _gyroSub?.cancel();
    _positionSub?.cancel();

    _accelSub = null;
    _gyroSub = null;
    _positionSub = null;
  }

  void clearRecordedData() {
    _potholes.clear();
  }

  void dispose() {
    stop();
    try {
      _sensorController.close();
    } catch (_) {}
  }
}
