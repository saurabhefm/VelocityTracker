import 'package:hive/hive.dart';

part 'location_point.g.dart';

@HiveType(typeId: 2)
class LocationPoint {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final double speed;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed = 0.0,
  });
}
