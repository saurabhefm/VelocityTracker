import 'package:intl/intl.dart';

class Formatters {
  static String formatSpeed(double speed) {
    return speed.toStringAsFixed(2);
  }

  static String formatDistance(double meters) {
    if (meters < 1000) {
      return "${meters.toStringAsFixed(2)} m";
    }
    return "${(meters / 1000).toStringAsFixed(2)} km";
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy - HH:mm').format(date);
  }

  static String formatDuration(DateTime start, DateTime? end) {
    if (end == null) return "Ongoing";
    final diff = end.difference(start);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(diff.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(diff.inSeconds.remainder(60));
    return "${twoDigits(diff.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
  
  static String formatLiveDuration(DateTime start) {
    final diff = DateTime.now().difference(start);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(diff.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(diff.inSeconds.remainder(60));
    return "${twoDigits(diff.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
