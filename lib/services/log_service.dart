import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class LogService {
  static late File _logFile;
  static bool _initialized = false;
  static String _tag = '[MAIN]';

  // Constants
  static const int _maxFileSize = 2 * 1024 * 1024; // 2MB

  static Future<void> initialize({bool isBackground = false}) async {
    _tag = isBackground ? '[BG_SERVICE]' : '[MAIN]';
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      _logFile = File('${dir.path}/velocity_tracker.log');
      
      if (_logFile.existsSync() && _logFile.lengthSync() > _maxFileSize) {
        final oldFile = File('${dir.path}/velocity_tracker.log.old');
        if (oldFile.existsSync()) {
          oldFile.deleteSync();
        }
        _logFile.renameSync(oldFile.path);
      }
      
      _initialized = true;
      _writeLog('INFO', 'LogService initialized');
    } catch (e) {
      debugPrint('$_tag Failed to initialize LogService: $e');
    }
  }

  static void info(String message) => _writeLog('INFO', message);
  static void warn(String message) => _writeLog('WARN', message);
  static void error(String message, [Object? error, StackTrace? stack]) {
    _writeLog('ERROR', '$message ${error != null ? '\nError: $error' : ''} ${stack != null ? '\nStack: $stack' : ''}');
  }

  static void _writeLog(String level, String message) {
    if (!_initialized) {
      debugPrint('$_tag [$level] $message (Uninitialized Logger)');
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final logLine = '$timestamp $_tag [$level] $message\n';

    try {
      if (_logFile.existsSync() && _logFile.lengthSync() > _maxFileSize) {
        final oldFile = File('${_logFile.path}.old');
        if (oldFile.existsSync()) oldFile.deleteSync();
        _logFile.renameSync(oldFile.path);
      }

      final sink = _logFile.openWrite(mode: FileMode.append);
      sink.write(logLine);
      sink.close(); 
    } catch (e) {
      // Fallback
      debugPrint('$_tag [$level] $message (Fallback, Log Write Failed: $e)');
    }
  }

  static Future<List<String>> getExportPaths() async {
    final dir = await getApplicationDocumentsDirectory();
    final active = '${dir.path}/velocity_tracker.log';
    final old = '${dir.path}/velocity_tracker.log.old';
    
    List<String> paths = [];
    if (File(active).existsSync()) paths.add(active);
    if (File(old).existsSync()) paths.add(old);
    
    return paths;
  }
}
