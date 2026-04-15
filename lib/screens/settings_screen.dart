import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/log_service.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _speedController = TextEditingController(
    text: SettingsService.speedLimit.toStringAsFixed(0)
  );

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
            value: true, // Simplified for now since logic wasn't fully implemented
            activeColor: const Color(0xFF38BDF8),
            onChanged: (val) {},
          ),
          const Divider(color: Colors.white10),
          SwitchListTile(
            title: const Text('Keep Screen Awake'),
            subtitle: const Text('Prevent display from dimming during a journey.'),
            value: SettingsService.keepScreenAwake,
            activeColor: const Color(0xFF38BDF8),
            onChanged: (val) {
              setState(() {
                SettingsService.keepScreenAwake = val;
              });
            },
          ),
          const Divider(color: Colors.white10),
          SwitchListTile(
            title: const Text('Track in Background'),
            subtitle: const Text('Allows the app to record data while locked or in background.'),
            value: SettingsService.trackInBackground,
            activeColor: const Color(0xFF38BDF8),
            onChanged: (val) {
              setState(() {
                SettingsService.trackInBackground = val;
              });
            },
          ),
          const Divider(color: Colors.white10),
          ListTile(
            title: const Text('Speed Limit Alert'),
            subtitle: const Text('Threshold (km/h) for safety notifications.'),
            trailing: SizedBox(
              width: 60,
              child: TextField(
                controller: _speedController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF38BDF8))),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                onSubmitted: (val) {
                  final limit = double.tryParse(val);
                  if (limit != null && limit > 0) {
                    SettingsService.speedLimit = limit;
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Developer Options', style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Export Debug Logs'),
            subtitle: const Text('Share local logs for troubleshooting.'),
            leading: const Icon(Icons.bug_report, color: Colors.grey),
            trailing: const Icon(Icons.ios_share, size: 20),
            onTap: () async {
              final paths = await LogService.getExportPaths();
              if (paths.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No logs found.')));
                }
                return;
              }
              final xFiles = paths.map((path) => XFile(path)).toList();
              await Share.shareXFiles(xFiles, text: 'VelocityTracker Debug Logs');
            },
          ),
        ],
      ),
    );
  }
}
