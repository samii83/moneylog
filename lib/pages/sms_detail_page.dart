import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class SmsDetailPage extends StatefulWidget {
  final String body;
  final String sender;
  final String? receiver;
  final String? account;
  final double? amount;
  final String? category;
  final String? size;
  final DateTime? date;

  const SmsDetailPage({
    super.key,
    required this.body,
    required this.sender,
    this.receiver,
    this.account,
    this.amount,
    this.category,
    this.size,
    this.date,
  });

  @override
  State<SmsDetailPage> createState() => _SmsDetailPageState();
}

class _SmsDetailPageState extends State<SmsDetailPage> {
  List<String> tags = ['Banking', 'Delivery', 'Recharge', 'Promo', 'Personal'];
  String? selectedTag;
  DateTime? extractedFutureDate;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    extractedFutureDate = _extractFutureDate(widget.body);
    initNotifications();
  }

  DateTime? _extractFutureDate(String text) {
    final now = DateTime.now();

    // "in X days"
    final inDays = RegExp(r'in (\d+) days?').firstMatch(text);
    if (inDays != null) {
      final days = int.tryParse(inDays.group(1)!);
      if (days != null) return now.add(Duration(days: days));
    }

    // "tomorrow"
    if (text.toLowerCase().contains('tomorrow')) {
      return now.add(const Duration(days: 1));
    }

    // "on DD/MM/YYYY" or "on DD-MM-YYYY"
    final onDate = RegExp(r'on (\d{1,2})[\/-](\d{1,2})[\/-](\d{2,4})').firstMatch(text);
    if (onDate != null) {
      final d = int.parse(onDate.group(1)!);
      final m = int.parse(onDate.group(2)!);
      final y = int.parse(onDate.group(3)!);
      return DateTime(y < 100 ? 2000 + y : y, m, d);
    }

    // "on DD MMM" or "on DD Month"
    final onMonth = RegExp(r'on (\d{1,2}) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|January|February|March|April|May|June|July|August|September|October|November|December)', caseSensitive: false).firstMatch(text);
    if (onMonth != null) {
      final d = int.parse(onMonth.group(1)!);
      final m = DateFormat.MMM().parse(onMonth.group(2)!.substring(0, 3)).month;
      final year = now.month > m || (now.month == m && now.day > d) ? now.year + 1 : now.year;
      return DateTime(year, m, d);
    }

    // "next Tuesday", "next Friday", etc.
    final nextDay = RegExp(r'next (\w+)', caseSensitive: false).firstMatch(text);
    if (nextDay != null) {
      final weekdays = {
        'monday': DateTime.monday,
        'tuesday': DateTime.tuesday,
        'wednesday': DateTime.wednesday,
        'thursday': DateTime.thursday,
        'friday': DateTime.friday,
        'saturday': DateTime.saturday,
        'sunday': DateTime.sunday,
      };
      final day = nextDay.group(1)!.toLowerCase();
      if (weekdays.containsKey(day)) {
        int daysToAdd = (weekdays[day]! - now.weekday + 7) % 7;
        daysToAdd = daysToAdd == 0 ? 7 : daysToAdd; // always next week
        return now.add(Duration(days: daysToAdd));
      }
    }

    // "by Friday", "by Monday", etc.
    final byDay = RegExp(r'by (\w+)', caseSensitive: false).firstMatch(text);
    if (byDay != null) {
      final weekdays = {
        'monday': DateTime.monday,
        'tuesday': DateTime.tuesday,
        'wednesday': DateTime.wednesday,
        'thursday': DateTime.thursday,
        'friday': DateTime.friday,
        'saturday': DateTime.saturday,
        'sunday': DateTime.sunday,
      };
      final day = byDay.group(1)!.toLowerCase();
      if (weekdays.containsKey(day)) {
        int daysToAdd = (weekdays[day]! - now.weekday + 7) % 7;
        daysToAdd = daysToAdd == 0 ? 7 : daysToAdd;
        return now.add(Duration(days: daysToAdd));
      }
    }

    return null;
  }

  Future<void> initNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    tz.initializeTimeZones();
  }

  Future<void> scheduleReminder(DateTime date, String message) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Spendwise Reminder',
      message,
      tz.TZDateTime.from(date, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  // Improved regex for banking/debit messages
  bool isBankingOrDebitMessage(String body) {
    final debitRegex = RegExp(r'(debited|withdrawn|spent|purchase|sent|paid|deducted|transaction of|txn of|dr amount|dr\.|debited by|debited for|payment of|transfer to|to [A-Z0-9]{4,}|IMPS|NEFT|UPI|RTGS|ATM)', caseSensitive: false);
    final creditRegex = RegExp(r'(credited|received|deposited|cr amount|cr\.|credited by|credited for|payment received|transfer from|from [A-Z0-9]{4,}|IMPS|NEFT|UPI|RTGS)', caseSensitive: false);
    return debitRegex.hasMatch(body) || creditRegex.hasMatch(body);
  }

  // Save and load tagged messages using shared_preferences
  Future<void> saveTaggedMessage(String messageId, String tag) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tagged_$messageId', tag);
  }

  Future<String?> loadTaggedMessage(String messageId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('tagged_$messageId');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final infoRows = <Widget>[];
    if (widget.amount != null) {
      infoRows.add(_InfoRow(icon: Icons.currency_rupee, label: 'Amount', value: '₹${widget.amount!.toStringAsFixed(2)}'));
    }
    if (widget.account != null && widget.account!.isNotEmpty) {
      infoRows.add(_InfoRow(icon: Icons.account_balance_wallet, label: 'Account', value: widget.account!));
    }
    if (widget.receiver != null && widget.receiver!.isNotEmpty) {
      infoRows.add(_InfoRow(icon: Icons.person, label: 'Receiver', value: widget.receiver!));
    }
    if (widget.category != null && widget.category!.isNotEmpty) {
      infoRows.add(_InfoRow(icon: Icons.category, label: 'Category', value: widget.category!));
    }
    if (widget.size != null && widget.size!.isNotEmpty) {
      infoRows.add(_InfoRow(icon: Icons.sms, label: 'Message Size', value: widget.size!));
    }
    if (widget.date != null) {
      infoRows.add(_InfoRow(icon: Icons.access_time, label: 'Date & Time', value: DateFormat.yMMMd().add_jm().format(widget.date!)));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Message Details', style: theme.textTheme.titleLarge),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              color: theme.brightness == Brightness.dark
                  ? null
                  : theme.colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Container(
                decoration: theme.brightness == Brightness.dark
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.colorScheme.surfaceContainerHighest, theme.colorScheme.surface],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      )
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.account_circle, size: 36, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.sender, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            if (widget.date != null)
                              Text(DateFormat.yMMMd().add_jm().format(widget.date!), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (infoRows.isNotEmpty) ...[
              Text('Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                color: theme.colorScheme.surface,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    children: infoRows,
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
            Text('Message', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              color: theme.colorScheme.surfaceContainerHighest,
              elevation: 1,
              child: ExpansionTile(
                title: Text(
                  widget.body.length > 80 ? '${widget.body.substring(0, 80)}...' : widget.body,
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SelectableText(widget.body, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18)),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.body));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copied!')));
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('Tags', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: tags.map((tag) => ChoiceChip(
                label: Text(tag),
                selected: selectedTag == tag,
                onSelected: (_) => setState(() => selectedTag = tag),
                labelStyle: theme.textTheme.bodyMedium,
                selectedColor: theme.colorScheme.primaryContainer,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              )).toList(),
            ),
            const SizedBox(height: 18),
            if (extractedFutureDate != null)
              Card(
                color: theme.colorScheme.secondaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.event, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Text('Future date: ${DateFormat.yMMMd().format(extractedFutureDate!)}', style: theme.textTheme.bodyMedium),
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_alert),
                        label: const Text('Set Reminder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          if (extractedFutureDate != null) {
                            await scheduleReminder(extractedFutureDate!, widget.body);
                            final prefs = await SharedPreferences.getInstance();
                            final reminders = prefs.getStringList('user_reminders') ?? [];
                            reminders.add('${widget.sender}|${DateFormat('yyyy-MM-dd HH:mm').format(extractedFutureDate!)}|${widget.body}');
                            await prefs.setStringList('user_reminders', reminders);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Reminder set for ${DateFormat.yMMMd().add_jm().format(extractedFutureDate!)}')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Text('$label:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
