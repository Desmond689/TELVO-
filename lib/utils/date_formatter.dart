import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  static String formatDateTime(DateTime date) =>
      DateFormat('yyyy-MM-dd HH:mm:ss').format(date);

  static String formatTime(DateTime date) => DateFormat('HH:mm').format(date);

  static String formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'just now';
    }
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return 'Today, ${formatTime(date)}';
    } else if (dateDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${formatTime(date)}';
    } else if (dateDay.isAfter(today.subtract(const Duration(days: 7)))) {
      return '${DateFormat('EEEE').format(date)}, ${formatTime(date)}';
    } else {
      return formatDateTime(date);
    }
  }

  static String formatCurrency(double amount, {String currency = 'XAF'}) {
    final formatter = NumberFormat.currency(
      locale: 'en',
      symbol: currency == 'XAF' ? 'FCFA' : '',
      decimalDigits: 0,
    );
    return '${currency == 'XAF' ? 'XAF ' : ''}${formatter.format(amount)}';
  }

  static String formatPhoneNumber(String phone) {
    if (phone.length == 9) {
      return '${phone.substring(0, 2)} ${phone.substring(2, 4)} ${phone.substring(4, 6)} ${phone.substring(6, 8)} ${phone.substring(8)}';
    }
    return phone;
  }

  static DateTime parseDate(String dateString) =>
      DateFormat('yyyy-MM-dd').parse(dateString);

  static DateTime parseDateTime(String dateTimeString) =>
      DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateTimeString);

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours hours ${minutes > 0 ? '$minutes minutes' : ''}';
    } else if (minutes > 0) {
      return '$minutes minutes';
    } else {
      return 'less than a minute';
    }
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
}
