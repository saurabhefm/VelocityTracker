import 'package:hive_flutter/hive_flutter.dart';
import '../models/trip_model.dart';
import '../models/location_point.dart';
import '../models/enums.dart';

class StorageService {
  static const String tripBoxName = 'trips_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    Hive.registerAdapter(TripModelAdapter());
    Hive.registerAdapter(LocationPointAdapter());
    Hive.registerAdapter(TripStatusAdapter());

    await Hive.openBox<TripModel>(tripBoxName);
  }

  static Box<TripModel> get tripsBox {
    if (!Hive.isBoxOpen(tripBoxName)) {
      throw HiveError('StorageService must be initialized before access. Call await StorageService.init() in main().');
    }
    return Hive.box<TripModel>(tripBoxName);
  }

  static Future<void> saveTrip(TripModel trip) async {
    await tripsBox.put(trip.id, trip);
  }

  static List<TripModel> getAllTrips() {
    return tripsBox.values.toList()..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  static Future<void> deleteTrip(String id) async {
    await tripsBox.delete(id);
  }
}
