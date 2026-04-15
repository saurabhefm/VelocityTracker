import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'log_service.dart';
import 'settings_service.dart';

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
    await SettingsService.init();
    LogService.info("[BG_SERVICE] Background Engine Started Successfully");
  } catch (e) {
    debugPrint("[BG_SERVICE] Failed to initialize logs or settings: $e");
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

  double latestSpeed = 0.0;

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "VelocityLog Tracking",
          content: "Current Speed: ${latestSpeed.toStringAsFixed(1)} km/h",
        );
      }
    }
  });

  _startGeolocatorStream(service, (speed) {
    latestSpeed = speed * 3.6;
  });
}

void _startGeolocatorStream(ServiceInstance service, Function(double) onSpeedUpdate) {
  StreamSubscription<Position>? positionStream;

  void connect() {
    LogService.info("[BG_SERVICE] Initializing Geolocator Stream with BackgroundTracking=${SettingsService.trackInBackground}");
    positionStream?.cancel();

    LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "VelocityLog Tracking",
          notificationText: "Active Trip Route",
          notificationIcon: AndroidResource(name: 'ic_launcher'),
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: SettingsService.trackInBackground,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }

    positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      onSpeedUpdate(position.speed);
      service.invoke('update', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed,
        'heading': position.heading,
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
