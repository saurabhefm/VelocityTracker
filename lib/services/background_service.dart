import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'log_service.dart';

class BackgroundService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }

  static void start() {
    FlutterBackgroundService().startService();
  }

  static void stop() {
    FlutterBackgroundService().invoke('stopService');
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  try {
    await LogService.initialize(isBackground: true);
    LogService.info("[BG_SERVICE] Background Engine Started Successfully");
  } catch (e) {
    debugPrint("[BG_SERVICE] Failed to initialize logs: $e");
  }

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    LogService.info("[BG_SERVICE] Service Stopped manually");
    service.stopSelf();
  });

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "VelocityLog Tracking",
          content: "Active Trip Route",
        );
      }
    }
  });

  _startGeolocatorStream(service);
}

void _startGeolocatorStream(ServiceInstance service) {
  StreamSubscription<Position>? positionStream;

  void connect() {
    LogService.info("[BG_SERVICE] Initializing Geolocator Stream");
    positionStream?.cancel();
    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      service.invoke('update', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed,
        'accuracy': position.accuracy,
        'timestamp': position.timestamp.toIso8601String(),
      });
    }, onError: (error) {
      LogService.error("[BG_SERVICE] Stream Error: $error");
      positionStream?.cancel();
      Future.delayed(const Duration(seconds: 5), () {
        LogService.info("[BG_SERVICE] Attempting Stream Reconnection...");
        connect();
      });
    });
  }

  connect();
}
