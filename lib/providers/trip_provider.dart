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
import 'package:permission_handler/permission_handler.dart';

class TripState {
  final TripStatus status;
  final TripModel? activeTrip;
  final double currentSpeed;
  final double latestLat;
  final double latestLon;

  TripState({
    required this.status,
    this.activeTrip,
    this.currentSpeed = 0.0,
    this.latestLat = 0.0,
    this.latestLon = 0.0,
  });

  TripState copyWith({
    TripStatus? status,
    TripModel? activeTrip,
    double? currentSpeed,
    double? latestLat,
    double? latestLon,
  }) {
    return TripState(
      status: status ?? this.status,
      activeTrip: activeTrip ?? this.activeTrip,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      latestLat: latestLat ?? this.latestLat,
      latestLon: latestLon ?? this.latestLon,
    );
  }
}

class TripTrackingNotifier extends Notifier<TripState> with WidgetsBindingObserver {
  StreamSubscription<Position>? _positionStream;
  bool _mounted = true;

  @override
  TripState build() {
    _mounted = true;
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      _mounted = false;
      WidgetsBinding.instance.removeObserver(this);
      _positionStream?.cancel();
    });
    
    // Attempt starting global stream immediately when initialized
    _startLocationStream(LocationAccuracy.medium);

    return TripState(status: TripStatus.idle);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (state.status == TripStatus.tracking) return; // Do not interrupt if a trip is active

    if (appState == AppLifecycleState.resumed) {
      _startLocationStream(LocationAccuracy.medium);
    } else if (appState == AppLifecycleState.paused || appState == AppLifecycleState.hidden) {
      _positionStream?.cancel();
      _positionStream = null;
      state = state.copyWith(currentSpeed: 0.0);
    }
  }



  void _startLocationStream(LocationAccuracy accuracy) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    
    var inUseStatus = await Permission.locationWhenInUse.status;
    if (!inUseStatus.isGranted) return; // Do not ask for permissions here, just silently fail global stream until user clicks start
    
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

    var inUseStatus = await Permission.locationWhenInUse.request();
    if (inUseStatus.isDenied || inUseStatus.isPermanentlyDenied) {
       return "Location permissions are denied.";
    }

    var alwaysStatus = await Permission.locationAlways.status;
    if (!alwaysStatus.isGranted) {
       await Permission.locationAlways.request();
    }

    BackgroundService.start();

    final newTrip = TripModel(
      id: const Uuid().v4(),
      startTime: DateTime.now(),
      tripTitle: tripTitle,
      carDetails: carDetails,
    );

    state = state.copyWith(status: TripStatus.tracking, activeTrip: newTrip);

    _startLocationStream(LocationAccuracy.bestForNavigation);

    return null; // success
  }

  void _processLocationUpdate(Position position) {
    final currentSpeed = position.speed * 3.6; // convert m/s to km/h

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
      debugPrint("Point Ignored (Accuracy too low): ${position.accuracy}");
      return;
    }
    
    debugPrint("Point Captured: ${position.latitude}, ${position.longitude}");

    final point = LocationPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
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

    // Force UI rebuild by explicitly establishing a fresh state copy
    state = TripState(
      status: state.status,
      activeTrip: trip,
      currentSpeed: currentSpeed,
      latestLat: position.latitude,
      latestLon: position.longitude,
    );
  }

  Future<void> pauseTrip() async {
    _positionStream?.pause();
    state = state.copyWith(status: TripStatus.paused, currentSpeed: 0.0);
  }

  Future<void> resumeTrip() async {
    _positionStream?.resume();
    state = state.copyWith(status: TripStatus.tracking);
  }

  Future<void> endTrip() async {
    _positionStream?.cancel();
    BackgroundService.stop();

    if (state.activeTrip != null) {
      final trip = state.activeTrip!;
      trip.endTime = DateTime.now();
      
      // Explicitly save the trip journey without checking distance limits
      await StorageService.saveTrip(trip);
      try {
        trip.save(); // Also call native HiveObject save explicitly
      } catch (_) {}
      
      // Refresh history by invalidating provider
      ref.invalidate(tripHistoryProvider);
    }
    state = TripState(status: TripStatus.idle);
    _startLocationStream(LocationAccuracy.medium);
  }
}

final tripTrackingProvider = NotifierProvider<TripTrackingNotifier, TripState>(() {
  return TripTrackingNotifier();
});

final tripHistoryProvider = Provider<List<TripModel>>((ref) {
  return StorageService.getAllTrips();
});
