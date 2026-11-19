import 'package:intl/intl.dart';

class DateTimeFormatter {
  DateTimeFormatter._();

  static String formatFullHeader(DateTime dt) {
    return DateFormat('EEE, dd MMM yyyy • HH:mm:ss').format(dt);
  }

  static String formatTimeWithSeconds(DateTime? dt) {
    if (dt == null) return 'Never synchronized';
    return DateFormat('HH:mm:ss').format(dt);
  }

  static String formatAlertTimestamp(DateTime dt) {
    return DateFormat('dd MMM • HH:mm:ss').format(dt);
  }

  static String formatRelativeAge(DateTime? dt, DateTime now) {
    if (dt == null) return 'No telemetry';
    final diff = now.difference(dt);
    if (diff.inSeconds < 3) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
