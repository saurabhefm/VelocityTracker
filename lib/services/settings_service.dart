import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyKeepScreenAwake = 'keep_screen_awake';
  static const String _keyTrackInBackground = 'track_in_background';
  static const String _keyRotateWithCompass = 'rotate_with_compass';
  static const String _keySpeedLimit = 'speed_limit';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _safePrefs {
    if (_prefs == null) {
      throw StateError('SettingsService must be initialized before access. Call await SettingsService.init() in main().');
    }
    return _prefs!;
  }

  static bool get keepScreenAwake => _safePrefs.getBool(_keyKeepScreenAwake) ?? true;
  static set keepScreenAwake(bool value) => _safePrefs.setBool(_keyKeepScreenAwake, value);

  static bool get trackInBackground => _safePrefs.getBool(_keyTrackInBackground) ?? true;
  static set trackInBackground(bool value) => _safePrefs.setBool(_keyTrackInBackground, value);

  static bool get rotateWithCompass => _safePrefs.getBool(_keyRotateWithCompass) ?? false;
  static set rotateWithCompass(bool value) => _safePrefs.setBool(_keyRotateWithCompass, value);

  static double get speedLimit => _safePrefs.getDouble(_keySpeedLimit) ?? 80.0;
  static set speedLimit(double value) => _safePrefs.setDouble(_keySpeedLimit, value);
}
