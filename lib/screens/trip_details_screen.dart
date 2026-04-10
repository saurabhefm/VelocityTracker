import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_model.dart';
import '../utils/formatters.dart';
import '../providers/trip_provider.dart';

class TripDetailsScreen extends ConsumerWidget {
  final TripModel trip;

  const TripDetailsScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTrip = ref.watch(tripTrackingProvider).activeTrip;
    final currentTrip = (activeTrip?.id == trip.id) ? activeTrip! : trip;

    List<LatLng> points = currentTrip.routePoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    LatLng initialTarget = points.isNotEmpty 
        ? points.first 
        : const LatLng(0, 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF38BDF8)),
            onPressed: () {
              // Share functionality placeholder
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
              child: points.isEmpty 
                  ? Container(
                      color: const Color(0xFF1E293B),
                      child: const Center(
                        child: Text(
                          "No route data recorded for this trip.",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    )
                  : FlutterMap(
                options: MapOptions(
                  initialCenter: initialTarget,
                  initialZoom: 14.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.velocity_log_app',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: points,
                        color: const Color(0xFF38BDF8),
                        strokeWidth: 5.0,
                      )
                    ],
                  ),
                  if (points.isNotEmpty)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: points.last,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.formatDate(currentTrip.startTime),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatCard(title: 'Distance', value: Formatters.formatDistance(currentTrip.totalDistance), icon: Icons.straighten),
                        _StatCard(title: 'Max Speed', value: "${Formatters.formatSpeed(currentTrip.maxSpeed)} km/h", icon: Icons.speed),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatCard(
                          title: 'Duration', 
                          value: Formatters.formatDuration(currentTrip.startTime, currentTrip.endTime), 
                          icon: Icons.timer,
                          isFullWidth: true,
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isFullWidth;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isFullWidth ? double.infinity : (MediaQuery.of(context).size.width - 48 - 16) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF38BDF8)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
