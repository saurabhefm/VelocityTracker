import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyKeepScreenAwake = 'keep_screen_awake';
  static const String _keyTrackInBackground = 'track_in_background';
  static const String _keyRotateWithCompass = 'rotate_with_compass';
  static const String _keySpeedLimit = 'speed_limit';

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get keepScreenAwake => _prefs.getBool(_keyKeepScreenAwake) ?? true;
  static set keepScreenAwake(bool value) => _prefs.setBool(_keyKeepScreenAwake, value);

  static bool get trackInBackground => _prefs.getBool(_keyTrackInBackground) ?? true;
  static set trackInBackground(bool value) => _prefs.setBool(_keyTrackInBackground, value);

  static bool get rotateWithCompass => _prefs.getBool(_keyRotateWithCompass) ?? false;
  static set rotateWithCompass(bool value) => _prefs.setBool(_keyRotateWithCompass, value);

  static double get speedLimit => _prefs.getDouble(_keySpeedLimit) ?? 80.0;
  static set speedLimit(double value) => _prefs.setDouble(_keySpeedLimit, value);
}
