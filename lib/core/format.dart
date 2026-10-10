import 'package:intl/intl.dart';

final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _compact = NumberFormat.compact(locale: 'en_IN');

/// Formats whole rupees in Indian grouping, e.g. 124999 -> ₹1,24,999.
String rupees(num amount) => _inr.format(amount);

/// 18420 -> "18K"
String compact(num n) => _compact.format(n);

/// "12 min ago", "3 h ago", "2 days ago".
String ageLabel(DateTime observedAt, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(observedAt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  return '${diff.inDays} days ago';
}
