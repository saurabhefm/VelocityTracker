import 'package:hive/hive.dart';

part 'enums.g.dart';

@HiveType(typeId: 1)
enum TripStatus {
  @HiveField(0)
  idle,
  @HiveField(1)
  tracking,
  @HiveField(2)
  paused
}
