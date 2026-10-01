import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _inr = NumberFormat('#,##,##0', 'en_IN');
  static final _inrDecimal = NumberFormat('#,##,##0.00', 'en_IN');
  static final _usd = NumberFormat('#,##0.00', 'en_US');
  static final _pct = NumberFormat('+0.00;-0.00', 'en_US');

  static String inr(double? value, {bool showSymbol = true}) {
    if (value == null || value <= 0) return '—';
    final formatted =
        value >= 100 ? _inr.format(value) : _inrDecimal.format(value);
    return showSymbol ? '₹$formatted' : formatted;
  }

  static String usd(double? value) {
    if (value == null || value <= 0) return '—';
    return '\$${_usd.format(value)}';
  }

  static String percent(double? value) {
    if (value == null) return '—';
    return '${_pct.format(value)}%';
  }

  static String compact(double? value) {
    if (value == null || value <= 0) return '—';
    if (value >= 1e7) return '₹${(value / 1e7).toStringAsFixed(2)}Cr';
    if (value >= 1e5) return '₹${(value / 1e5).toStringAsFixed(2)}L';
    return inr(value);
  }

  static String timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
