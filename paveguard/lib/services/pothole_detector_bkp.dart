import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ------------------- CONFIG -------------------
const int windowSize = 50;                  // rolling window
const double thresholdUpdateFactor = 0.05;  // 10% change needed
const double detectionMultiplier = 3.0;     // mean + 3*std
const double debounceSeconds = 3.0;
const double duplicateDistanceM = 20.0;
const double gpsRefreshSeconds = 4.0;

final FirebaseFirestore db = FirebaseFirestore.instance;

// COMMENTED OUT NOTIFICATION PLUGIN
// final FlutterLocalNotificationsPlugin notifications =
//     FlutterLocalNotificationsPlugin();

// ------------------- STATE -------------------
List<double> accelWindow = [];
List<double> gyroWindow  = [];

double accelThreshold = 14.0;
double gyroThreshold  = 2.0;

double lastDetectionTime = 0;
Position? cachedPosition;
double lastGPSFetch = 0;

double? lastPotholeLat;
double? lastPotholeLon;
double? lastPotholeTime;

// ------------------- INIT -------------------
Future<void> initDetector() async {
  // COMMENTED OUT: Notifications disabled
  /*
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await notifications.initialize(
    const InitializationSettings(android: android),
  );
  */

  await _ensureGPSPermission();
}

// --------------------------------------------------
//   START DETECTION
// --------------------------------------------------
/*void startPotholeDetection() {
  double gx = 0, gy = 0, gz = 0;

  gyroscopeEventStream().listen((g) {
    gx = g.x;
    gy = g.y;
    gz = g.z;
  });

  accelerometerEventStream().listen((a) async {
    await _processIMU(
      ax: a.x, ay: a.y, az: a.z,
      gx: gx, gy: gy, gz: gz,
    );
  });
}*/

void startPotholeDetection() {
  double gx = 0, gy = 0, gz = 0;

  // GYROSCOPE (limit to 10 samples/second)
  gyroscopeEventStream()
      .throttleTime(const Duration(milliseconds: 100))
      .listen((g) {
        gx = g.x;
        gy = g.y;
        gz = g.z;
      });

  // ACCELEROMETER (limit to 10 samples/second)
  accelerometerEventStream()
      .throttleTime(const Duration(milliseconds: 100))
      .listen((a) async {
        await _processIMU(
          ax: a.x,
          ay: a.y,
          az: a.z,
          gx: gx,
          gy: gy,
          gz: gz,
        );
      });
}

// --------------------------------------------------
//     PROCESS ONE IMU READING
// --------------------------------------------------
Future<void> _processIMU({
  required double ax,
  required double ay,
  required double az,
  required double gx,
  required double gy,
  required double gz,
}) async {
  double accelMag = sqrt(ax*ax + ay*ay + az*az);
  double gyroMag  = sqrt(gx*gx + gy*gy + gz*gz);

  _pushToWindow(accelWindow, accelMag);
  _pushToWindow(gyroWindow, gyroMag);

  if (accelWindow.length < windowSize) return;

  double accelMean = _mean(accelWindow);
  double accelStd  = _std(accelWindow, accelMean);

  double gyroMean = _mean(gyroWindow);
  double gyroStd  = _std(gyroWindow, gyroMean);

  double newAccelThreshold = accelMean + detectionMultiplier * accelStd;
  double newGyroThreshold  = gyroMean  + detectionMultiplier * gyroStd;

  _maybeUploadThreshold("accelThreshold", accelThreshold, newAccelThreshold);
  _maybeUploadThreshold("gyroThreshold",  gyroThreshold,  newGyroThreshold);

  accelThreshold = newAccelThreshold;
  gyroThreshold  = newGyroThreshold;

  bool isPothole = accelMag > accelThreshold || gyroMag > gyroThreshold;
  if (!isPothole) return;

  double now = DateTime.now().millisecondsSinceEpoch / 1000;
  if ((now - lastDetectionTime) < debounceSeconds) return;
  lastDetectionTime = now;

  Position pos = await _getLazyPosition();

  if (_isDuplicate(pos)) return;

  await db.collection("detected_potholes_tst").add({
    "latitude": pos.latitude,
    "longitude": pos.longitude,
    "severity": accelMag,
    "timestamp": DateTime.now().toIso8601String(),
    "accel_threshold": accelThreshold,
    "gyro_threshold": gyroThreshold,
  });

  lastPotholeLat = pos.latitude;
  lastPotholeLon = pos.longitude;
  lastPotholeTime = now;

  // 🔕 Notification disabled
  /*
  notifications.show(
    0,
    "🚨 Pothole Detected",
    "At ${pos.latitude}, ${pos.longitude}",
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'pothole_channel',
        'Pothole Alerts',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
  */
}

// --------------------------------------------------
//      SUPPORT FUNCTIONS
// --------------------------------------------------

void _pushToWindow(List<double> window, double value) {
  window.add(value);
  if (window.length > windowSize) {
    window.removeAt(0);
  }
}

double _mean(List<double> list) {
  return list.reduce((a, b) => a + b) / list.length;
}

double _std(List<double> list, double mean) {
  double sum = 0;
  for (double x in list) {
    sum += pow(x - mean, 2);
  }
  return sqrt(sum / list.length);
}

void _maybeUploadThreshold(String field, double oldVal, double newVal) {
  double diff = (newVal - oldVal).abs() / (oldVal == 0 ? 1 : oldVal);
  if (diff > thresholdUpdateFactor) {
    db.collection("imu_thresholds").add({
      "field": field,
      "value": newVal,
      "timestamp": DateTime.now().toIso8601String(),
    });
  }
}

bool _isDuplicate(Position pos) {
  if (lastPotholeLat == null) return false;

  double d = _distanceMeters(
    lastPotholeLat!, lastPotholeLon!, pos.latitude, pos.longitude,
  );

  double timeDiff = (DateTime.now().millisecondsSinceEpoch / 1000) -
                    (lastPotholeTime ?? 0);

  return d < duplicateDistanceM && timeDiff < debounceSeconds;
}

double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371000;
  double dLat = (lat2 - lat1) * pi / 180;
  double dLon = (lon2 - lon1) * pi / 180;

  double a = sin(dLat/2)*sin(dLat/2) +
      cos(lat1*pi/180)*cos(lat2*pi/180) * sin(dLon/2)*sin(dLon/2);

  double c = 2 * atan2(sqrt(a), sqrt(1-a));
  return R * c;
}

Future<Position> _getLazyPosition() async {
  double now = DateTime.now().millisecondsSinceEpoch / 1000;

  if (cachedPosition == null || (now - lastGPSFetch) > gpsRefreshSeconds) {
    cachedPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    lastGPSFetch = now;
  }
  return cachedPosition!;
}

Future<void> _ensureGPSPermission() async {
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    await Geolocator.requestPermission();
  }
}
