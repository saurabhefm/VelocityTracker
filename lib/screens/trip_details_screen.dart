import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
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
        leading: BackButton(color: Colors.white),
        title: const Text('Trip Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF38BDF8)),
            onPressed: () {
              final distance = Formatters.formatDistance(currentTrip.totalDistance);
              final maxSpeed = Formatters.formatSpeed(currentTrip.maxSpeed);
              Share.share('Check out my trip on VelocityTracker! Distance: $distance, Top Speed: $maxSpeed km/h.');
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Card(
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.white10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flag, color: Color(0xFF38BDF8), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentTrip.tripTitle?.isNotEmpty == true 
                                ? currentTrip.tripTitle! 
                                : Formatters.formatDate(currentTrip.startTime),
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.directions_car, color: Color(0xFF818CF8), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          currentTrip.carDetails?.isNotEmpty == true 
                              ? currentTrip.carDetails! 
                              : "Primary Vehicle",
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _InfoItem(icon: Icons.straighten, label: Formatters.formatDistance(currentTrip.totalDistance))),
                        Expanded(child: _InfoItem(icon: Icons.speed, label: "${Formatters.formatSpeed(currentTrip.maxSpeed)} km/h")),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
