import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../providers/trip_provider.dart';
import '../models/enums.dart';
import '../utils/formatters.dart';
import 'settings_screen.dart';
import 'trip_details_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Timer? _timer;
  bool isAnalogView = true;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final status = ref.read(tripTrackingProvider).status;
      if (status == TripStatus.tracking) {
        setState(() {}); 
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripTrackingProvider);
    final bool isIdle = tripState.status == TripStatus.idle;

    String durationText = "00:00:00";
    if (tripState.activeTrip != null) {
      durationText = Formatters.formatLiveDuration(tripState.activeTrip!.startTime);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('VelocityTracker', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF38BDF8)),
            onSelected: (value) {
              if (value == 'toggle_view') {
                setState(() {
                  isAnalogView = !isAnalogView;
                });
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'toggle_view',
                child: Text(isAnalogView ? 'Switch to Digital View' : 'Switch to Analog View'),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Text('Settings'),
              ),
            ],
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    isAnalogView = !isAnalogView;
                  });
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
                  },
                  child: isAnalogView 
                      ? _buildSpeedometer(tripState.currentSpeed)
                      : _buildDigitalSpeedometer(tripState.currentSpeed),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard("Distance", Formatters.formatDistance(tripState.activeTrip?.totalDistance ?? 0.0), Icons.straighten),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard("Duration", durationText, Icons.timer),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              IconButton(
                icon: const Icon(Icons.sync, color: Colors.grey),
                onPressed: () {
                  ref.read(tripTrackingProvider.notifier).syncCurrentLocation();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Syncing real-time constraints..."), duration: Duration(seconds: 1)));
                },
                tooltip: "Force Metric Sync",
              ),
              const SizedBox(height: 8),
              _buildControls(tripState.status),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: _buildLiveMap(context, isTracking: tripState.status == TripStatus.tracking),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveMap(BuildContext context, {required bool isTracking}) {
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialZoom: 16.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.velocity_log_app',
                ),
                CurrentLocationLayer(
                  alignPositionOnUpdate: isTracking ? AlignOnUpdate.always : AlignOnUpdate.never,
                  alignDirectionOnUpdate: isTracking ? AlignOnUpdate.always : AlignOnUpdate.never,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: FloatingActionButton.small(
              heroTag: 'locate_me_fab',
              backgroundColor: const Color(0xFF1E293B),
              onPressed: () {
                final lat = ref.read(tripTrackingProvider).latestLat;
                final lon = ref.read(tripTrackingProvider).latestLon;
                if (lat != 0.0 && lon != 0.0) {
                  _mapController.move(LatLng(lat, lon), 16.0);
                }
              },
              child: const Icon(Icons.my_location, color: Color(0xFF38BDF8)),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildSpeedometer(double speed) {
    bool isStopped = speed < 0.1;
    final displaySpeed = isStopped ? 0.0 : speed;

    return SizedBox(
      key: const ValueKey('analog'),
      height: 240,
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            minimum: 0,
            maximum: 200,
            ranges: <GaugeRange>[
              GaugeRange(startValue: 0, endValue: 60, color: const Color(0xFF38BDF8), startWidth: 10, endWidth: 10),
              GaugeRange(startValue: 60, endValue: 120, color: const Color(0xFF818CF8), startWidth: 10, endWidth: 10),
              GaugeRange(startValue: 120, endValue: 200, color: const Color(0xFFF43F5E), startWidth: 10, endWidth: 10)
            ],
            pointers: <GaugePointer>[
              NeedlePointer(
                value: displaySpeed, 
                enableAnimation: !isStopped, 
                animationDuration: isStopped ? 1 : 300,
                animationType: AnimationType.easeOutBack,  
                needleColor: Colors.white, 
                knobStyle: const KnobStyle(color: Color(0xFF38BDF8))
              )
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                widget: Text(
                  Formatters.formatSpeed(speed),
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                  semanticsLabel: "Current Speed: ${Formatters.formatSpeed(speed)} kilometers per hour",
                ),
                angle: 90,
                positionFactor: 0.45,
              ),
              const GaugeAnnotation(
                widget: Text('km/h', style: TextStyle(fontSize: 16, color: Colors.grey)),
                angle: 90,
                positionFactor: 0.7,
              )
            ],
            axisLineStyle: const AxisLineStyle(
              thickness: 15,
              cornerStyle: CornerStyle.bothCurve,
              color: Color(0xFF1E293B),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDigitalSpeedometer(double speed) {
    bool isStopped = speed < 0.1;
    final displaySpeed = isStopped ? 0.0 : speed;

    return Container(
      height: 240,
      key: const ValueKey('digital'),
      alignment: Alignment.center,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: displaySpeed),
        duration: Duration(milliseconds: isStopped ? 1 : 300),
        builder: (context, val, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                Formatters.formatSpeed(val),
                style: GoogleFonts.orbitron(
                  textStyle: const TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0, letterSpacing: -2.0)
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'km/h',
                style: TextStyle(fontSize: 24, color: Colors.grey, fontWeight: FontWeight.w600, letterSpacing: 2.0),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF38BDF8), size: 24),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1.1)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildControls(TripStatus status) {
    if (status == TripStatus.idle) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => _showStartTripSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 8,
              shadowColor: const Color(0xFF38BDF8).withOpacity(0.5)
            ),
            child: const Text('START JOURNEY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings, color: Color(0xFF38BDF8)),
              onPressed: () => _showStartTripSheet(context),
            ),
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton.extended(
            heroTag: "pause_btn",
            onPressed: status == TripStatus.tracking 
                ? () => ref.read(tripTrackingProvider.notifier).pauseTrip()
                : () => ref.read(tripTrackingProvider.notifier).resumeTrip(),
            backgroundColor: const Color(0xFF1E293B),
            icon: Icon(status == TripStatus.tracking ? Icons.pause : Icons.play_arrow, color: const Color(0xFF38BDF8)),
            label: Text(status == TripStatus.tracking ? "PAUSE" : "RESUME", style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 15),
          FloatingActionButton(
            heroTag: "map_preview_btn",
            onPressed: () {
              final activeTrip = ref.read(tripTrackingProvider).activeTrip;
              if (activeTrip != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TripDetailsScreen(trip: activeTrip)),
                );
              }
            },
            backgroundColor: const Color(0xFF38BDF8),
            child: const Icon(Icons.map, color: Colors.black),
          ),
          const SizedBox(width: 15),
          FloatingActionButton.extended(
            heroTag: "stop_btn",
            onPressed: () => ref.read(tripTrackingProvider.notifier).endTrip(),
            backgroundColor: const Color(0xFFF43F5E),
            icon: const Icon(Icons.stop, color: Colors.white),
            label: const Text("STOP", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      );
    }
  }
  void _showStartTripSheet(BuildContext context) {
    final defaultTitle = DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now());
    final titleController = TextEditingController(text: defaultTitle);
    final carController = TextEditingController(text: "Primary Vehicle");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          bottom: true,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Trip Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Trip Title',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF38BDF8))),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: carController,
                decoration: const InputDecoration(
                  labelText: 'Car Details',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF38BDF8))),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final error = await ref.read(tripTrackingProvider.notifier).startTrip(
                      tripTitle: titleController.text,
                      carDetails: carController.text,
                    );
                    if (error != null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Quick Start', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ));
      },
    );
  }
}
