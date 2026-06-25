import 'package:intl/intl.dart';

class DateFormatter {
  static String formatShort(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (msgDate == today) {
      return DateFormat.jm().format(dateTime); // e.g. 10:30 AM
    } else if (msgDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(msgDate).inDays < 7) {
      return DateFormat.E().format(dateTime); // e.g. Mon, Tue
    } else {
      return DateFormat.yMd().format(dateTime); // e.g. 6/8/2026
    }
  }

  static String formatCallTimer(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    if (duration.inHours > 0) {
      final hours = duration.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$secs';
    }
    return '$minutes:$secs';
  }

  static String formatDurationReadable(int seconds) {
    if (seconds == 0) return '0s';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    List<String> parts = [];
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    if (secs > 0) parts.add('${secs}s');

    return parts.join(' ');
  }
}
