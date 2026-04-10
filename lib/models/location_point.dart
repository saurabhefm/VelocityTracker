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

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}
