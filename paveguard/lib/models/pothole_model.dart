class PotholeModel {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double severity;

  PotholeModel({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.severity,
  });

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
        'severity': severity,
      };

  factory PotholeModel.fromMap(Map<String, dynamic> m) => PotholeModel(
        latitude: (m['latitude'] as num).toDouble(),
        longitude: (m['longitude'] as num).toDouble(),
        timestamp: DateTime.parse(m['timestamp']),
        severity: (m['severity'] as num).toDouble(),
      );
}
