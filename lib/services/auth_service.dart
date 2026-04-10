import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const String _pinKey = 'user_secure_pin';
  
  static bool _hasPin = false;

  static Future<void> init() async {
    final pin = await _storage.read(key: _pinKey);
    _hasPin = pin != null && pin.isNotEmpty;
  }

  static bool get hasPin => _hasPin;

  static Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
    _hasPin = true;
  }

  static Future<bool> verifyPin(String pin) async {
    final storedPin = await _storage.read(key: _pinKey);
    return storedPin == pin;
  }
}
