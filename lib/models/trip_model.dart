import 'package:hive/hive.dart';
import 'location_point.dart';

part 'trip_model.g.dart';

@HiveType(typeId: 0)
class TripModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime startTime;

  @HiveField(2)
  DateTime? endTime;

  @HiveField(3)
  double totalDistance;

  @HiveField(4)
  double maxSpeed;

  @HiveField(5)
  List<LocationPoint> routePoints;

  TripModel({
    required this.id,
    required this.startTime,
    this.endTime,
    this.totalDistance = 0.0,
    this.maxSpeed = 0.0,
    this.routePoints = const [],
  });
}
