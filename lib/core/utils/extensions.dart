import 'package:intl/intl.dart';

/// String extensions
extension StringExtensions on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Title case
  String toTitleCase() {
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Check if string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(this);
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }
}

/// DateTime extensions
extension DateTimeExtensions on DateTime {
  /// Format as date (e.g., "Jan 15, 2024")
  String toFormattedDate() {
    return DateFormat('MMM dd, yyyy').format(this);
  }

  /// Format as short date (e.g., "15 Jan")
  String toShortDate() {
    return DateFormat('dd MMM').format(this);
  }

  /// Format as time (e.g., "2:30 PM")
  String toFormattedTime() {
    return DateFormat('h:mm a').format(this);
  }

  /// Format as datetime (e.g., "Jan 15, 2024 at 2:30 PM")
  String toFormattedDateTime() {
    return DateFormat('MMM dd, yyyy \'at\' h:mm a').format(this);
  }

  /// Get relative time (e.g., "2 hours ago", "in 3 days")
  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.isNegative) {
      final futureDiff = this.difference(now);
      if (futureDiff.inDays > 365) {
        return 'in ${(futureDiff.inDays / 365).floor()} year${futureDiff.inDays >= 730 ? 's' : ''}';
      } else if (futureDiff.inDays > 30) {
        return 'in ${(futureDiff.inDays / 30).floor()} month${futureDiff.inDays >= 60 ? 's' : ''}';
      } else if (futureDiff.inDays > 0) {
        return 'in ${futureDiff.inDays} day${futureDiff.inDays > 1 ? 's' : ''}';
      } else if (futureDiff.inHours > 0) {
        return 'in ${futureDiff.inHours} hour${futureDiff.inHours > 1 ? 's' : ''}';
      } else if (futureDiff.inMinutes > 0) {
        return 'in ${futureDiff.inMinutes} minute${futureDiff.inMinutes > 1 ? 's' : ''}';
      } else {
        return 'in a few seconds';
      }
    }

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${difference.inDays >= 730 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${difference.inDays >= 60 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'just now';
    }
  }

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Check if date is in the past
  bool get isPast => isBefore(DateTime.now());

  /// Check if date is in the future
  bool get isFuture => isAfter(DateTime.now());
}

/// Double extensions for currency
extension DoubleExtensions on double {
  /// Format as currency (INR) - kept for backward compatibility
  @Deprecated('Use toCurrency(currencyCode) instead for dynamic currency support')
  String toINR() {
    return toCurrency('INR');
  }

  /// Format as currency with dynamic currency code
  String toCurrency(String currencyCode) {
    final currencyInfo = _getCurrencyInfo(currencyCode);
    final formatter = NumberFormat.currency(
      locale: currencyInfo.locale,
      symbol: currencyInfo.symbol,
      decimalDigits: currencyInfo.decimalDigits,
    );
    return formatter.format(this);
  }

  /// Format as currency without symbol
  String toFormattedAmount() {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: 2,
    );
    return formatter.format(this).trim();
  }

  /// Get currency info for formatting
  static _CurrencyInfo _getCurrencyInfo(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return _CurrencyInfo(symbol: '\$', locale: 'en_US', decimalDigits: 2);
      case 'EUR':
        return _CurrencyInfo(symbol: '€', locale: 'de_DE', decimalDigits: 2);
      case 'GBP':
        return _CurrencyInfo(symbol: '£', locale: 'en_GB', decimalDigits: 2);
      case 'JPY':
        return _CurrencyInfo(symbol: '¥', locale: 'ja_JP', decimalDigits: 0);
      case 'CNY':
        return _CurrencyInfo(symbol: '¥', locale: 'zh_CN', decimalDigits: 2);
      case 'AUD':
        return _CurrencyInfo(symbol: 'A\$', locale: 'en_AU', decimalDigits: 2);
      case 'CAD':
        return _CurrencyInfo(symbol: 'C\$', locale: 'en_CA', decimalDigits: 2);
      case 'CHF':
        return _CurrencyInfo(symbol: 'CHF', locale: 'de_CH', decimalDigits: 2);
      case 'SGD':
        return _CurrencyInfo(symbol: 'S\$', locale: 'en_SG', decimalDigits: 2);
      case 'AED':
        return _CurrencyInfo(symbol: 'د.إ', locale: 'ar_AE', decimalDigits: 2);
      case 'THB':
        return _CurrencyInfo(symbol: '฿', locale: 'th_TH', decimalDigits: 2);
      case 'MYR':
        return _CurrencyInfo(symbol: 'RM', locale: 'ms_MY', decimalDigits: 2);
      case 'INR':
      default:
        return _CurrencyInfo(symbol: '₹', locale: 'en_IN', decimalDigits: 2);
    }
  }
}

/// Helper class for currency formatting info
class _CurrencyInfo {
  final String symbol;
  final String locale;
  final int decimalDigits;

  const _CurrencyInfo({
    required this.symbol,
    required this.locale,
    required this.decimalDigits,
  });
}

/// List extensions
extension ListExtensions<T> on List<T> {
  /// Get first element or null
  T? get firstOrNull => isEmpty ? null : first;

  /// Get last element or null
  T? get lastOrNull => isEmpty ? null : last;

  /// Split list into chunks
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }
}
