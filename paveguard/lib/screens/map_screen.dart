import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/pothole_model.dart';
import '../services/sensor_service.dart';

class MapScreen extends StatefulWidget {
  final SensorService sensorService;
  const MapScreen({super.key, required this.sensorService});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<PotholeModel> _localPotholes = [];
  List<PotholeModel> _firebasePotholes = [];

  LatLng? _center;
  bool _loadingLocation = true;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();

    _initLocation();
    _listenToLocalSensorPotholes();
    _listenToFirestorePotholes();
  }

  // -------------------- 1️⃣ GET USER LOCATION --------------------
  Future<void> _initLocation() async {
    final hasPermission = await _handlePermission();
    if (!hasPermission) {
      setState(() => _loadingLocation = false);
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _center = LatLng(pos.latitude, pos.longitude);
        _loadingLocation = false;
      });
    } catch (e) {
      setState(() => _loadingLocation = false);
    }
  }

  Future<bool> _handlePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  // -------------------- 2️⃣ LOCAL POTHOLES FROM SENSOR SERVICE --------------------
  void _listenToLocalSensorPotholes() {
    // initial potholes
    _localPotholes = widget.sensorService.getPotholePoints();

    // stream updates from detection service
    widget.sensorService.sensorStream.listen((event) {
      if (event.containsKey('pothole')) {
        setState(() {
          _localPotholes = widget.sensorService.getPotholePoints();
        });
      }

      if (event.containsKey('location')) {
        final loc = event['location'];
        if (loc is List && loc.length >= 2) {
          setState(() {
            _center = LatLng(
              (loc[0] as num).toDouble(),
              (loc[1] as num).toDouble(),
            );
          });
        }
      }
    });
  }

  // -------------------- 3️⃣ FIRESTORE REAL-TIME POTHOLES --------------------
void _listenToFirestorePotholes() {
  FirebaseFirestore.instance
      .collection("detected_potholes_tst") // ← CHANGE IF YOUR COLLECTION NAME DIFFERS
      .snapshots()
      .listen((snapshot) {

    //print("🔥 Firestore count = ${snapshot.docs.length}");

    List<PotholeModel> result = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();

      //print("📍 DOC DATA: $data");

      result.add(PotholeModel(
        latitude: (data["latitude"] as num?)?.toDouble() ?? 0.0,
        longitude: (data["longitude"] as num?)?.toDouble() ?? 0.0,
        severity: (data["severity"] as num?)?.toDouble() ?? 0.0,
        timestamp: DateTime.tryParse(data["timestamp"] ?? "") ?? DateTime.now(),
      ));
    }

    //print("🔥 Parsed markers = ${result.length}");

    setState(() => _firebasePotholes = result);
  });
}


  // -------------------- RECENTER BUTTON --------------------
  void _recenterMap() {
    if (_center != null) _mapController.move(_center!, 16);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingLocation || _center == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ---- Combine LOCAL + FIRESTORE potholes ----
    final allPotholeMarkers = <Marker>[
      ..._firebasePotholes.map((p) => Marker(
            point: LatLng(p.latitude, p.longitude),
            width: 36,
            height: 36,
            child: Image.asset(
              'assets/icons/Red.png',
              width: 20,
              height: 20,
            ),
          )),
      ..._localPotholes.map((p) => Marker(
            point: LatLng(p.latitude, p.longitude),
            width: 36,
            height: 36,
            child: Image.asset(
              'assets/icons/Yellow.png',
              width: 40,
              height: 40,
            ),
          )),
    ];

    final markers = <Marker>[
      // User location marker
      Marker(
        point: _center!,
        width: 40,
        height: 40,
        child:
            const Icon(Icons.my_location, size: 28, color: Colors.blueAccent),
      ),
      ...allPotholeMarkers,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Pothole Map")),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center!,
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.example.paveguard",
              ),
              MarkerLayer(markers: markers),
            ],
          ),

          // Recenter Floating Button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.blue,
              onPressed: _recenterMap,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
