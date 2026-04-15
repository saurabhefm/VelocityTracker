import 'dart:async';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../models/trip_model.dart';
import '../models/enums.dart';
import '../models/location_point.dart';
import '../services/storage_service.dart';
import '../services/background_service.dart';
import '../services/log_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:vibration/vibration.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';

class TripState {
  final TripStatus status;
  final TripModel? activeTrip;
  final double currentSpeed;
  final double latestLat;
  final double latestLon;
  final double latestHeading;
  final bool isOverSpeedLimit;

  TripState({
    required this.status,
    this.activeTrip,
    this.currentSpeed = 0.0,
    this.latestLat = 0.0,
    this.latestLon = 0.0,
    this.latestHeading = 0.0,
    this.isOverSpeedLimit = false,
  });

  TripState copyWith({
    TripStatus? status,
    TripModel? activeTrip,
    double? currentSpeed,
    double? latestLat,
    double? latestLon,
    double? latestHeading,
    bool? isOverSpeedLimit,
  }) {
    return TripState(
      status: status ?? this.status,
      activeTrip: activeTrip ?? this.activeTrip,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      latestLat: latestLat ?? this.latestLat,
      latestLon: latestLon ?? this.latestLon,
      latestHeading: latestHeading ?? this.latestHeading,
      isOverSpeedLimit: isOverSpeedLimit ?? this.isOverSpeedLimit,
    );
  }
}

class TripTrackingNotifier extends Notifier<TripState> with WidgetsBindingObserver {
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<Map<String, dynamic>?>? _bgStreamSubscription;
  bool _mounted = true;
  bool _hasAlertedCurrentSession = false;

  @override
  TripState build() {
    _mounted = true;
    WidgetsBinding.instance.addObserver(this);

    _bgStreamSubscription = FlutterBackgroundService().on('update').listen((event) {
      if (_mounted && event != null) {
        _processBgLocationUpdate(event);
      }
    });

    ref.onDispose(() {
      _mounted = false;
      WidgetsBinding.instance.removeObserver(this);
      _positionStream?.cancel();
      _bgStreamSubscription?.cancel();
    });
    
    // Attempt starting global stream immediately when initialized
    _startLocationStream(LocationAccuracy.high);

    return TripState(status: TripStatus.idle);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    LogService.info('App Lifecycle State changed: $appState');
    if (state.status == TripStatus.tracking) return; // Do not interrupt if a trip is active

    if (appState == AppLifecycleState.resumed) {
      _startLocationStream(LocationAccuracy.high);
    } else if (appState == AppLifecycleState.paused || appState == AppLifecycleState.hidden) {
      _positionStream?.cancel();
      _positionStream = null;
      state = state.copyWith(currentSpeed: 0.0);
    }
  }



  void _startLocationStream(LocationAccuracy accuracy) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return; // Silently fail global stream until user clicks start
    
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      if (_mounted) {
        _processLocationUpdate(position);
      }
    });
  }

  Future<String?> startTrip({String? tripTitle, String? carDetails}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return "Location services are disabled. Please enable them.";

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return "Location permissions are denied.";
    }

    if (SettingsService.keepScreenAwake) {
      WakelockPlus.enable();
    }

    BackgroundService.start();

    // Calibration: Fetch exact absolute coordinate instantly before tracker loop buffers.
    late Position initialPosition;
    try {
      initialPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (_) {
      initialPosition = await Geolocator.getLastKnownPosition() ?? Position(longitude: 0, latitude: 0, timestamp: DateTime.now(), accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0);
    }
    
    final currentSpeed = initialPosition.speed * 3.6;

    final newTrip = TripModel(
      id: const Uuid().v4(),
      startTime: DateTime.now(),
      tripTitle: tripTitle,
      carDetails: carDetails,
      totalDistance: 0.0,
      maxSpeed: currentSpeed,
      routePoints: initialPosition.latitude != 0 
        ? [LocationPoint(latitude: initialPosition.latitude, longitude: initialPosition.longitude, timestamp: initialPosition.timestamp)]
        : [],
    );

    state = state.copyWith(
      status: TripStatus.tracking, 
      activeTrip: newTrip,
      currentSpeed: currentSpeed,
      latestLat: initialPosition.latitude,
      latestLon: initialPosition.longitude,
    );

    LogService.info("Starting trip with title: ${tripTitle != null ? '[TRIP_TITLE_SET]' : 'UNSET'}, car: ${carDetails != null ? '[CAR_NAME_SET]' : 'UNSET'}");
    _positionStream?.cancel(); // Kill local stream since BackgroundEngine tracks now
    
    _hasAlertedCurrentSession = false;

    return null; // success
  }

  Future<void> syncCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      double speed = pos.speed * 3.6;
      
      // Floor filter
      if (speed < 0.8) speed = 0.0;

      // Force completely new state block for rigorous UI flushing
      state = TripState(
        status: state.status,
        activeTrip: state.activeTrip,
        currentSpeed: speed,
        latestLat: pos.latitude,
        latestLon: pos.longitude,
      );
    } catch (e) {
      LogService.error("Failed to sync location manually: $e");
    }
  }

  void _processBgLocationUpdate(Map<String, dynamic> data) {
    if (state.status != TripStatus.tracking) return;

    final lat = data['latitude'] as double;
    final lon = data['longitude'] as double;
    final speed = data['speed'] as double;
    final accuracy = data['accuracy'] as double;
    final heading = (data['heading'] ?? 0.0) as double;
    final timestampStr = data['timestamp'] as String;
    
    double currentSpeed = speed * 3.6; // convert m/s to km/h
    
    // Noise Filter: Deadzone for tiny drifts while idling
    if (currentSpeed < 0.8) {
      currentSpeed = 0.0;
    }

    if (accuracy > 30.0) {
      LogService.warn("Point Ignored (Accuracy too low): $accuracy");
      return;
    }

    final point = LocationPoint(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime.parse(timestampStr),
      speed: currentSpeed,
    );
    
    final trip = state.activeTrip!; 
    
    // Distance / Spike Integrity
    if (trip.routePoints.isNotEmpty) {
      final lastPoint = trip.routePoints.last;
      final timeDiffMs = point.timestamp.difference(lastPoint.timestamp).inMilliseconds;
      if (timeDiffMs <= 1500 && state.currentSpeed < 1.0 && currentSpeed > 100.0) {
        LogService.warn("GPS Jitter Guard: Impossible >100km/h spike from 0 bypassed. Ignored.");
        return; 
      }
    }
    
    double addedDistance = 0.0;
    if (trip.routePoints.isNotEmpty) {
      final lastPoint = trip.routePoints.last;
      addedDistance = Geolocator.distanceBetween(
        lastPoint.latitude, lastPoint.longitude,
        point.latitude, point.longitude,
      );
    }

    trip.routePoints = List.from(trip.routePoints)..add(point);
    trip.totalDistance += addedDistance;
    
    if (currentSpeed > trip.maxSpeed) {
      trip.maxSpeed = currentSpeed;
    }

    _handleSpeedAlert(currentSpeed);

    state = TripState(
      status: state.status,
      activeTrip: trip,
      currentSpeed: currentSpeed,
      latestLat: lat,
      latestLon: lon,
      latestHeading: heading,
      isOverSpeedLimit: currentSpeed > SettingsService.speedLimit,
    );
  }

  void _handleSpeedAlert(double currentSpeed) {
    final limit = SettingsService.speedLimit;
    
    // Trigger
    if (currentSpeed > limit && !_hasAlertedCurrentSession) {
      _hasAlertedCurrentSession = true;
      NotificationService.showSpeedAlert(currentSpeed, limit);
      Vibration.vibrate(duration: 500, amplitude: 255); // Heavy pulse
      LogService.info("Speed alert triggered: $currentSpeed km/h (Limit: $limit)");
    } 
    // Hysteresis reset (drop 5km/h below limit)
    else if (_hasAlertedCurrentSession && currentSpeed < (limit - 5.0)) {
      _hasAlertedCurrentSession = false;
      LogService.info("Speed alert reset (hysteresis): $currentSpeed km/h dropped 5km/h below limit");
    }
  }

  void _processLocationUpdate(Position position) {
    double currentSpeed = position.speed * 3.6; // convert m/s to km/h
    final double heading = position.heading;
    
    if (currentSpeed < 0.8) {
      currentSpeed = 0.0;
    }

    if (state.activeTrip == null || state.status != TripStatus.tracking) {
      state = state.copyWith(
        currentSpeed: currentSpeed,
        latestLat: position.latitude,
        latestLon: position.longitude,
      );
      return;
    }
    
    // Ignore updates with low accuracy (> 30 meters)
    if (position.accuracy > 30.0) {
      LogService.warn("Point Ignored (Accuracy too low): ${position.accuracy}");
      return;
    }
    


    final point = LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
      speed: currentSpeed,
    );
    
    final trip = state.activeTrip!; // Riverpod notifies listeners if state is changed via copyWith, 
                                    // but we also mutate the object because of Hive reference.
    
    double addedDistance = 0.0;
    if (trip.routePoints.isNotEmpty) {
      final lastPoint = trip.routePoints.last;
      addedDistance = Geolocator.distanceBetween(
        lastPoint.latitude, lastPoint.longitude,
        point.latitude, point.longitude,
      );
    }
    
    // Stability filter: Ignore GPS drifts less than 2 meters purely for path/distance adding
    final isJitter = trip.routePoints.isNotEmpty && (addedDistance < 2.0);

    if (!isJitter) {
      trip.routePoints = List.from(trip.routePoints)..add(point);
      trip.totalDistance += addedDistance;
    }
    
    if (currentSpeed > trip.maxSpeed) {
      trip.maxSpeed = currentSpeed;
    }

    _handleSpeedAlert(currentSpeed);

    // Force UI rebuild by explicitly establishing a fresh state copy
    state = TripState(
      status: state.status,
      activeTrip: trip,
      currentSpeed: currentSpeed,
      latestLat: position.latitude,
      latestLon: position.longitude,
      latestHeading: heading,
      isOverSpeedLimit: currentSpeed > SettingsService.speedLimit,
    );
  }

  Future<void> pauseTrip() async {
    LogService.info("Trip paused manually");
    _positionStream?.pause();
    state = state.copyWith(status: TripStatus.paused, currentSpeed: 0.0);
  }

  Future<void> resumeTrip() async {
    LogService.info("Trip resumed manually");
    _positionStream?.resume();
    state = state.copyWith(status: TripStatus.tracking);
  }

  Future<void> endTrip() async {
    BackgroundService.stop();
    WakelockPlus.disable();

    if (state.activeTrip != null) {
      final trip = state.activeTrip!;
      trip.endTime = DateTime.now();
      
      // Explicitly save the trip journey without checking distance limits
      await StorageService.saveTrip(trip);
      try {
        trip.save(); // Also call native HiveObject save explicitly
        LogService.info('Hive save successful for trip: ${trip.id}');
      } catch (e, stack) {
        LogService.error('Hive save failed for trip: ${trip.id}', e, stack);
      }
      
      // Refresh history by invalidating provider
      ref.invalidate(tripHistoryProvider);
    }
    state = TripState(status: TripStatus.idle);
    _startLocationStream(LocationAccuracy.high);
  }
}

final tripTrackingProvider = NotifierProvider<TripTrackingNotifier, TripState>(() {
  return TripTrackingNotifier();
});

final tripHistoryProvider = Provider<List<TripModel>>((ref) {
  return StorageService.getAllTrips();
});
