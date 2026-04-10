import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/storage_service.dart';
import 'services/background_service.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'services/auth_service.dart';
import 'screens/pin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await BackgroundService.initialize();
  await AuthService.init();
  runApp(const ProviderScope(child: VelocityLogApp()));
}

class VelocityLogApp extends StatelessWidget {
  const VelocityLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VelocityLog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFF818CF8),
          surface: Color(0xFF1E293B),
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const PinScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const DashboardScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1E293B),
        indicatorColor: const Color(0xFF38BDF8).withOpacity(0.2),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.speed_outlined),
            selectedIcon: Icon(Icons.speed, color: Color(0xFF38BDF8)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Color(0xFF38BDF8)),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
