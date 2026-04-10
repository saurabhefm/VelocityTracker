import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/log_service.dart';

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
