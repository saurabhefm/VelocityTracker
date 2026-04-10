import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isMetric = true;
  bool isBackgroundEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Metric Units'),
            subtitle: const Text('Use km/h and meters instead of mph and miles.'),
            value: isMetric,
            activeColor: const Color(0xFF38BDF8),
            onChanged: (val) {
              setState(() {
                isMetric = val;
              });
            },
          ),
          const Divider(color: Colors.white10),
          SwitchListTile(
            title: const Text('Background Tracking'),
            subtitle: const Text('Allow VelocityLog to continue tracking while in the background.'),
            value: isBackgroundEnabled,
            activeColor: const Color(0xFF38BDF8),
            onChanged: (val) {
              setState(() {
                isBackgroundEnabled = val;
              });
            },
          ),
        ],
      ),
    );
  }
}
