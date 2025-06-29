import 'package:sms_advanced/sms_advanced.dart';
import '../utils/generate_tags.dart';

class TransactionTimelineEntry {
  final DateTime timestamp;
  final SmsMessage message;
  final String type; // incoming, outgoing, balance_update, neutral_money, neutral
  final double? amount;
  final String account;
  final String service;
  final double? balanceSnapshot;
  final List<String> tags;

  TransactionTimelineEntry({
    required this.timestamp,
    required this.message,
    required this.type,
    this.amount,
    required this.account,
    required this.service,
    this.balanceSnapshot,
    required this.tags,
  });
}

class TransactionTimeline {
  final List<TransactionTimelineEntry> _timeline = [];
  final Map<String, List<TransactionTimelineEntry>> _accountMap = {};
  final Map<String, double> _currentBalances = {};

  // Helper to check if an account or message is ATM-related
  bool _isAtmAccountOrMessage(SmsMessage msg, String account) {
    final body = msg.body?.toLowerCase() ?? '';
    return account.toLowerCase().contains('atm') || body.contains('atm');
  }

  void addTransaction(SmsMessage message) {
    final tags = generateTagsForMessage(message);
    final body = message.body?.toLowerCase() ?? '';
    // Type detection
    String type = 'neutral';
    if (tags.contains('credit')) {
      type = 'incoming';
    } else if (tags.contains('debit')) type = 'outgoing';
    else if (tags.contains('balance_update')) type = 'balance_update';
    else if (tags.contains('otp')) type = 'otp';
    else if (tags.contains('upi_mandate')) type = 'upi_mandate';
    else if (tags.contains('recharge')) type = 'recharge';
    else if (tags.contains('delivery')) type = 'delivery';
    else if (tags.contains('warning')) type = 'warning';
    else if (tags.contains('ecommerce')) type = 'ecommerce';
    // Amount extraction
    double? amount;
    String service = '';
    final amtMatch = RegExp(r'(?:inr|rs\.?|₹)\s?([\d,]+(?:\.\d{1,2})?)').firstMatch(body);
    if (amtMatch != null) {
      amount = double.tryParse(amtMatch.group(1)!.replaceAll(',', ''));
    }
    // Account extraction (masked account or UPI handle)
    String account = '';
    final accMatch = RegExp(r'(?:a/c(?:\s*(?:no\.?|number|ending))?\s*[:\-]?\s*[x*]{2,}[\d]{2,})').firstMatch(body);
    if (accMatch != null) {
      account = accMatch.group(0) ?? '';
    } else {
      final upiMatch = RegExp(r'\b[\w.-]+@[\w.-]+\b').firstMatch(body);
      if (upiMatch != null) account = upiMatch.group(0)!;
    }
    // SBI-style debit: 'A/C X7821 debited by 52.0 ... trf to Mr KISHORE KUMAR ...'
    final sbiDebitMatch = RegExp(r'A/C?\s*([Xx\d*]+)\s*debited by ([\d.]+).*trf to ([A-Za-z0-9 .&-]+)', caseSensitive: false).firstMatch(body);
    if (sbiDebitMatch != null) {
      account = sbiDebitMatch.group(1) ?? '';
      amount = double.tryParse(sbiDebitMatch.group(2)!);
      final payee = sbiDebitMatch.group(3)?.trim() ?? '';
      service = payee;
    }
    // Filter out ATM-related accounts/messages
    if (_isAtmAccountOrMessage(message, account)) return;
    // Service detection (UPI, bank, Amazon, etc.)
    if (tags.contains('upi')) {
      service = 'UPI';
    } else if (tags.contains('ecommerce')) service = 'Ecommerce';
    else if (tags.any((t) => ['sbi','hdfc','icici','axis','kotak','bob','pnb','yesbank','idfc','federal'].contains(t))) {
      service = tags.firstWhere((t) => ['sbi','hdfc','icici','axis','kotak','bob','pnb','yesbank','idfc','federal'].contains(t), orElse: ()=>'');
    }
    // Balance snapshot
    double? balanceSnapshot;
    if (type == 'balance_update') {
      final balMatch = RegExp(r'(?:bal(?:ance)?(?:\s*[:\-])?\s*)(inr|rs\.?|₹)?\s*([\d,]+(?:\.\d{1,2})?)').firstMatch(body);
      if (balMatch != null) {
        balanceSnapshot = double.tryParse(balMatch.group(2)!.replaceAll(',', ''));
        if (account.isNotEmpty && balanceSnapshot != null) {
          _currentBalances[account] = balanceSnapshot;
        }
      }
    }
    final entry = TransactionTimelineEntry(
      timestamp: message.date ?? DateTime.now(),
      message: message,
      type: type,
      amount: amount,
      account: account,
      service: service,
      balanceSnapshot: balanceSnapshot,
      tags: tags,
    );
    _timeline.add(entry);
    _timeline.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (account.isNotEmpty) {
      _accountMap.putIfAbsent(account, () => []).add(entry);
    }
  }

  List<TransactionTimelineEntry> getAll() => List.unmodifiable(_timeline);

  double getSpendingInRange(DateTime start, DateTime end) {
    return _timeline.where((e) =>
      e.timestamp.isAfter(start) &&
      e.timestamp.isBefore(end) &&
      (e.type == 'outgoing' || e.type == 'balance_update') &&
      (e.amount ?? 0) > 0
    ).fold(0.0, (sum, e) => sum + (e.amount ?? 0));
  }

  double? getBalanceAt(DateTime date) {
    final entries = _timeline.where((e) => e.timestamp.isBefore(date) && e.balanceSnapshot != null).toList();
    if (entries.isEmpty) return null;
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries.first.balanceSnapshot;
  }

  Map<String, int> getCategoryCounts() {
    final Map<String, int> counts = {};
    for (final entry in _timeline) {
      for (final tag in entry.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    return counts;
  }

  // Assigns a normalized account identifier to the message and merges similar accounts
  String assignAccountForMessage(SmsMessage msg) {
    final body = msg.body?.toLowerCase() ?? '';
    // Extract masked account or UPI handle
    String? extracted;
    final accMatch = RegExp(r'(?:a/c(?:\s*(?:no\.?|number|ending))?\s*[:\-]?\s*[x*]{0,}[\d]{2,})').firstMatch(body);
    if (accMatch != null) {
      extracted = accMatch.group(0)?.replaceAll(RegExp(r'[^\dx*]'), '');
    } else {
      final upiMatch = RegExp(r'\b[\w.-]+@[\w.-]+\b').firstMatch(body);
      if (upiMatch != null) extracted = upiMatch.group(0);
    }
    if (extracted == null || extracted.isEmpty) return '';
    // Normalize: keep only last 4 digits for masked accounts
    String normalized = extracted;
    final digits = RegExp(r'(\d{4,})').firstMatch(extracted);
    if (digits != null) {
      normalized = 'A${digits.group(1)!}'; // e.g., A7821
    }
    // Merge with similar existing account if found
    String mergedKey = normalized;
    for (final key in _accountMap.keys) {
      if (key.endsWith(normalized.substring(1))) {
        mergedKey = key;
        break;
      }
    }
    // Optionally, update registry (no entry yet)
    _accountMap.putIfAbsent(mergedKey, () => []);
    return mergedKey;
  }

  // Summarizes timeline entries for analytics and charting
  Map<String, dynamic> summarize() {
    final Map<String, Map<DateTime, List<TransactionTimelineEntry>>> byDay = {};
    final Map<String, Map<int, List<TransactionTimelineEntry>>> byWeek = {};
    final Map<String, Map<String, List<TransactionTimelineEntry>>> byMonth = {};
    final Map<String, int> typeCounts = {};
    double totalSpent = 0;
    double totalReceived = 0;
    final Map<String, double> servicePie = {};
    final Map<String, double> categoryPie = {};
    for (final entry in _timeline) {
      // Group by type
      typeCounts[entry.type] = (typeCounts[entry.type] ?? 0) + 1;
      // Totals
      if (entry.type == 'outgoing' && entry.amount != null) totalSpent += entry.amount!;
      if (entry.type == 'incoming' && entry.amount != null) totalReceived += entry.amount!;
      // Pie chart: service
      if (entry.service.isNotEmpty && entry.amount != null) {
        servicePie[entry.service] = (servicePie[entry.service] ?? 0) + entry.amount!;
      }
      // Pie chart: category/tag
      for (final tag in entry.tags) {
        if (entry.amount != null && entry.type != 'balance_update') {
          categoryPie[tag] = (categoryPie[tag] ?? 0) + entry.amount!;
        }
      }
      // Group by day
      final day = DateTime(entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
      byDay.putIfAbsent(entry.type, () => {});
      byDay[entry.type]!.putIfAbsent(day, () => []).add(entry);
      // Group by week (ISO week)
      final week = int.parse('${entry.timestamp.year}${((_dayOfYear(entry.timestamp) - entry.timestamp.weekday + 10) / 7).floor()}');
      byWeek.putIfAbsent(entry.type, () => {});
      byWeek[entry.type]!.putIfAbsent(week, () => []).add(entry);
      // Group by month
      final month = '${entry.timestamp.year}-${entry.timestamp.month.toString().padLeft(2, '0')}' ;
      byMonth.putIfAbsent(entry.type, () => {});
      byMonth[entry.type]!.putIfAbsent(month, () => []).add(entry);
    }
    return {
      'byDay': byDay,
      'byWeek': byWeek,
      'byMonth': byMonth,
      'typeCounts': typeCounts,
      'totalSpent': totalSpent,
      'totalReceived': totalReceived,
      'servicePie': servicePie,
      'categoryPie': categoryPie,
    };
  }

  // Expose current balances for syncing
  Map<String, double> get currentBalances => Map.unmodifiable(_currentBalances);

  // Helper to get day of year from DateTime
  int _dayOfYear(DateTime date) {
    return int.parse(DateTime(date.year, date.month, date.day)
        .difference(DateTime(date.year, 1, 1))
        .inDays.toString()) + 1;
  }
}

// Reminder object for extracted reminders
class Reminder {
  final DateTime reminderDate;
  final String label;
  final SmsMessage message;
  final TransactionTimelineEntry? sourceEntry;

  Reminder({
    required this.reminderDate,
    required this.label,
    required this.message,
    this.sourceEntry,
  });
}

// Extracts a reminder from an SMS message if a due/expiry date is found
Reminder? extractReminderFromMessage(SmsMessage msg, {TransactionTimelineEntry? entry}) {
  final body = msg.body?.toLowerCase() ?? '';
  final now = DateTime.now();
  // Patterns for absolute dates
  final patterns = [
    RegExp(r'due on (\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})'),
    RegExp(r'expires? on (\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})'),
    RegExp(r'recharge before (\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})'),
  ];
  for (final pat in patterns) {
    final m = pat.firstMatch(body);
    if (m != null) {
      final dateStr = m.group(1)!;
      final parts = dateStr.split(RegExp(r'[\/\-]'));
      int day = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int year = parts.length > 2 ? int.parse(parts[2]) : now.year;
      if (year < 100) year += 2000;
      final dt = DateTime(year, month, day);
      return Reminder(
        reminderDate: dt,
        label: pat.pattern.split(' ')[0],
        message: msg,
        sourceEntry: entry,
      );
    }
  }
  // Relative dates
  if (body.contains('tomorrow')) {
    return Reminder(
      reminderDate: now.add(Duration(days: 1)),
      label: 'tomorrow',
      message: msg,
      sourceEntry: entry,
    );
  }
  final relMatch = RegExp(r'in (\d+) days').firstMatch(body);
  if (relMatch != null) {
    final days = int.parse(relMatch.group(1)!);
    return Reminder(
      reminderDate: now.add(Duration(days: days)),
      label: 'in $days days',
      message: msg,
      sourceEntry: entry,
    );
  }
  if (body.contains('ends tomorrow')) {
    return Reminder(
      reminderDate: now.add(Duration(days: 1)),
      label: 'ends tomorrow',
      message: msg,
      sourceEntry: entry,
    );
  }
  return null;
}
