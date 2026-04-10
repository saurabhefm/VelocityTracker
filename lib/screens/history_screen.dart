import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/trip_provider.dart';
import '../models/trip_model.dart';
import '../utils/formatters.dart';
import 'trip_details_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: trips.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Ready for your first journey?', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return _buildTripCard(context, trip);
              },
            ),
    );
  }

  Widget _buildTripCard(BuildContext context, TripModel trip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF2E3B4E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TripDetailsScreen(trip: trip)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trip.tripTitle?.isNotEmpty == true ? trip.tripTitle! : Formatters.formatDate(trip.startTime),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (trip.tripTitle?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            Formatters.formatDate(trip.startTime),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
              const SizedBox(height: 16),
              FittedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoItem(icon: Icons.straighten, label: Formatters.formatDistance(trip.totalDistance)),
                    const SizedBox(width: 12),
                    _InfoItem(icon: Icons.timer, label: Formatters.formatDuration(trip.startTime, trip.endTime)),
                    const SizedBox(width: 12),
                    _InfoItem(icon: Icons.speed, label: "${Formatters.formatSpeed(trip.maxSpeed)} km/h"),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }
}
