import 'package:intl/intl.dart';

class MarketCalendarHelper {
  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final _shortDateFormat = DateFormat('E, dd MMM');

  /// Returns the next valid trading day (skipping Saturday & Sunday).
  /// If [baseDate] + [daysOffset] falls on a weekend, it moves forward to Monday.
  static DateTime getNextTradingDay(DateTime baseDate, int daysOffset) {
    DateTime target = baseDate.add(Duration(days: daysOffset));
    if (target.weekday == DateTime.saturday) {
      target = target.add(const Duration(days: 2)); // Shift to Monday
    } else if (target.weekday == DateTime.sunday) {
      target = target.add(const Duration(days: 1)); // Shift to Monday
    }
    return target;
  }

  /// Formats date time for current live pricing: e.g. "22 Aug 2026, 07:46 PM"
  static String formatCurrentDateTime(DateTime? dt) {
    final date = dt ?? DateTime.now();
    return _dateTimeFormat.format(date);
  }

  /// Formats date for trading target: e.g. "Mon, 24 Aug 2026 · 09:00 AM IST"
  static String formatTargetDateTime(DateTime targetDate, {String marketTime = '09:00 AM IST'}) {
    return '${_dateFormat.format(targetDate)} · $marketTime';
  }

  /// Formats short trading target for chips/summary: e.g. "Mon, 24 Aug"
  static String formatShortTargetDate(DateTime baseDate, int daysOffset) {
    final target = getNextTradingDay(baseDate, daysOffset);
    return _shortDateFormat.format(target);
  }

  /// Returns whether a given date falls on a weekend market holiday
  static bool isWeekend(DateTime dt) {
    return dt.weekday == DateTime.saturday || dt.weekday == DateTime.sunday;
  }

  /// Market status string: e.g. "Weekend Closed (Next Open: Mon 09:00 AM)" or "Market Live"
  static String getMarketStatusDescription(DateTime? now) {
    final dt = now ?? DateTime.now();
    if (isWeekend(dt)) {
      final nextMon = getNextTradingDay(dt, dt.weekday == DateTime.saturday ? 2 : 1);
      return 'Market Closed (Weekend) · Next Session: ${_shortDateFormat.format(nextMon)}, 09:00 AM IST';
    }
    return 'Active Session · Live Spot';
  }
}
