import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../providers/expense_provider.dart';
import 'day_detail_page.dart'; // Import the DayDetailPage

class AnalysisTab extends StatefulWidget {
  const AnalysisTab({super.key});

  @override
  State<AnalysisTab> createState() => _AnalysisTabState();
}

class _AnalysisTabState extends State<AnalysisTab> {
  double bigAmountThreshold = 10000.0;
  int daysRange = 7; // Only 7-day option
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  List<Map<String, dynamic>> reminders = [];

  CalendarFormat _weekCalendarFormat = CalendarFormat.week;
  CalendarFormat _monthCalendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    tz.initializeTimeZones();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  DateTime? _extractFutureDate(String text) {
    final now = DateTime.now();
    final inDays = RegExp(r'in (\d+) days?').firstMatch(text);
    if (inDays != null) {
      final days = int.tryParse(inDays.group(1)!);
      if (days != null) return now.add(Duration(days: days));
    }
    final byDate = RegExp(r'by (\d{1,2}) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|January|February|March|April|May|June|July|August|September|October|November|December)', caseSensitive: false).firstMatch(text);
    if (byDate != null) {
      final d = int.parse(byDate.group(1)!);
      final m = DateFormat.MMM().parse(byDate.group(2)!.substring(0, 3)).month;
      final year = now.month > m || (now.month == m && now.day > d) ? now.year + 1 : now.year;
      return DateTime(year, m, d);
    }
    return null;
  }

  Future<void> _scheduleReminder(String title, String body, DateTime date) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      date.millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      tz.TZDateTime.from(date, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails('reminders', 'Reminders', importance: Importance.max, priority: Priority.high),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  void _onRemindMe(String message, String title) async {
    final date = _extractFutureDate(message);
    if (date != null) {
      await _scheduleReminder('Reminder: $title', message, date);
      setState(() {
        reminders.add({
          'title': title,
          'type': 'Bill',
          'due': date,
          'on': true,
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminder set for ${DateFormat.yMMMd().format(date)}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not extract date from message.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final expenses = provider.expenses;
    // Use all history for stats
    Map<DateTime, double> dailySpend = {};
    for (var exp in expenses) {
      final date = exp.date;
      final day = DateTime(date.year, date.month, date.day);
      dailySpend[day] = (dailySpend[day] ?? 0) + (exp.type == 'debit' || exp.type == 'upi_sent' ? exp.amount : 0);
    }
    // Prepare chart data for all history

    // Modern stat cards
    double totalSpent = expenses.where((e) => e.type == 'debit' || e.type == 'upi_sent').fold(0.0, (a, b) => a + b.amount);
    double totalReceived = expenses.where((e) => e.type == 'credit' || e.type == 'upi_received').fold(0.0, (a, b) => a + b.amount);
    double savings = provider.getTotalSavings();
    // Find earliest/latest
    final allDates = expenses.map((e) => e.date).toList();
    allDates.sort();
    final earliest = allDates.isNotEmpty ? allDates.first : null;
    final latest = allDates.isNotEmpty ? allDates.last : null;
    String historyText = '';
    if (earliest != null && latest != null) {
      final months = ((latest.year - earliest.year) * 12 + (latest.month - earliest.month)).abs();
      historyText = 'History: ${DateFormat('dd MMM yy').format(earliest)} to ${DateFormat('dd MMM yy').format(latest)}';
      if (months > 0) {
        historyText += '  (${months + 1} months)';
      } else {
        historyText += '  (same month)';
      }
    }

    // Remove expansion mode and show each transaction/message as a dot on the calendar
    // Prepare events for calendar: show a dot for each transaction/message on a day
    Map<DateTime, List<String>> calendarEvents = {};
    for (var exp in expenses) {
      final day = DateTime(exp.date.year, exp.date.month, exp.date.day);
      if (!calendarEvents.containsKey(day)) calendarEvents[day] = [];
      calendarEvents[day]!.add('dot');
    }

    // Clamp focusedDay for weekly calendar
    final weekFirstDay = DateTime.now().subtract(Duration(days: 30));
    final weekLastDay = DateTime.now();
    DateTime weekFocusedDay = _focusedDay.isBefore(weekFirstDay)
        ? weekFirstDay
        : (_focusedDay.isAfter(weekLastDay) ? weekLastDay : _focusedDay);

    return Scaffold(
      appBar: AppBar(
        // Remove the 'Analysis' heading
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Remove the 2nd heading before history and replace with an icon
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Center(
                child: Icon(Icons.history, size: 44, color: Theme.of(context).colorScheme.primary),
              ),
            ),
            if (historyText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(historyText, style: Theme.of(context).textTheme.bodyMedium),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _modernStatCard(context, "Total Spent", totalSpent, Colors.red, Icons.arrow_upward),
                _modernStatCard(context, "Total Received", totalReceived, Colors.green, Icons.arrow_downward),
                _modernStatCard(context, "Savings", savings, Colors.blue, Icons.savings),
              ],
            ),
            const SizedBox(height: 32),
            // Remove expansion mode: do not show IconButton or Dialog for expanding chart
            Row(
              children: [
                Icon(Icons.bar_chart, size: 32, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text("Daily Spend (weekly)", style: Theme.of(context).textTheme.titleLarge),
                Spacer(),
                // Expansion IconButton removed
              ],
            ),
            const SizedBox(height: 16),
            // Replace daily spend bar chart with a weekly calendar-like view
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TableCalendar(
                firstDay: weekFirstDay,
                lastDay: weekLastDay,
                focusedDay: weekFocusedDay,
                calendarFormat: _weekCalendarFormat,
                onFormatChanged: (format) {
                  setState(() {
                    _weekCalendarFormat = format;
                  });
                },
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) {
                  final d = DateTime(day.year, day.month, day.day);
                  final amt = dailySpend[d] ?? 0;
                  return amt > 0 ? [amt] : [];
                },
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 1,
                  markerSizeScale: 1.2,
                ),
                headerVisible: false,
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      final amt = events.first as double;
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('₹${amt.toStringAsFixed(0)}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSecondaryContainer)),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Move variable declarations outside the widget tree
            Builder(
              builder: (context) {
                DateTime monthFirstDay = earliest ?? DateTime.now().subtract(Duration(days: 365));
                DateTime monthLastDay = latest ?? DateTime.now();
                DateTime monthFocusedDay = _focusedDay.isBefore(monthFirstDay)
                    ? monthFirstDay
                    : (_focusedDay.isAfter(monthLastDay) ? monthLastDay : _focusedDay);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Calendar View", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(24),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            // Add a toggle for weekly/monthly calendar view
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 28, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 12),
                                Text("Calendar", style: Theme.of(context).textTheme.titleLarge),
                                Spacer(),
                              ],
                            ),
                            TableCalendar(
                              firstDay: monthFirstDay,
                              lastDay: monthLastDay,
                              focusedDay: monthFocusedDay,
                              calendarFormat: _monthCalendarFormat,
                              onFormatChanged: (format) {
                                setState(() {
                                  _monthCalendarFormat = format;
                                });
                              },
                              eventLoader: (day) => calendarEvents[DateTime(day.year, day.month, day.day)] ?? [],
                              calendarStyle: CalendarStyle(
                                markerDecoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                markersMaxCount: 5,
                              ),
                              onDaySelected: (selected, focused) {
                                setState(() {
                                  _selectedDay = selected;
                                  _focusedDay = focused;
                                });
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DayDetailPage(day: selected),
                                  ),
                                );
                              },
                              calendarBuilders: CalendarBuilders(
                                markerBuilder: (context, day, events) {
                                  if (events.isEmpty) return null;
                                  // Color-code by transaction type
                                  final expList = expenses.where((e) => e.date.year == day.year && e.date.month == day.month && e.date.day == day.day).toList();
                                  Color markerColor = Theme.of(context).colorScheme.primary;
                                  if (expList.any((e) => e.type == 'debit' || e.type == 'upi_sent')) {
                                    markerColor = Colors.red;
                                  } else if (expList.any((e) => e.type == 'credit' || e.type == 'upi_received')) {
                                    markerColor = Colors.green;
                                  }
                                  return Positioned(
                                    bottom: 1,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: markerColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            // Collapsible smart features
            _collapsibleSection(context, "Smart Reminders", _buildSmartReminders(context), showIfEmpty: true, emptyMessage: "No smart reminders detected."),
            _collapsibleSection(context, "Deadlines", _buildDeadlines(context), showIfEmpty: true, emptyMessage: "No deadlines detected."),
            _collapsibleSection(context, "Upcoming Deliveries", _buildUpcomingDeliveries(context), showIfEmpty: true, emptyMessage: "No upcoming deliveries detected."),
            _collapsibleSection(context, "UPI Mandates & AutoPay", _buildUpiMandates(context, expenses), showIfEmpty: true, emptyMessage: "No UPI mandates or AutoPay detected."),
            _collapsibleSection(context, "Registered UPI IDs", _buildUpiRegistrations(context, expenses), showIfEmpty: true, emptyMessage: "No UPI IDs registered."),
            _collapsibleSection(context, "Recharge/Prepaid Validity", _buildRechargeValidity(context, expenses), showIfEmpty: true, emptyMessage: "No recharge/prepaid validity detected."),
            _collapsibleSection(context, "UPI Requests", _buildUpiRequests(context, expenses), showIfEmpty: true, emptyMessage: "No UPI requests detected."),
            _collapsibleSection(context, "Low Balance Warnings", _buildLowBalance(context, expenses), showIfEmpty: true, emptyMessage: "No low balance warnings detected."),
            _collapsibleSection(context, "Available Balances", _buildAvlBalances(context, expenses), showIfEmpty: true, emptyMessage: "No available balances detected."),
            _collapsibleSection(context, "Government Advice & Warnings", _buildGovAdvice(context, expenses), showIfEmpty: true, emptyMessage: "No government advice or warnings detected."),
            _collapsibleSection(context, "OTP & Security Codes", _buildOtpCodes(context, expenses), showIfEmpty: true, emptyMessage: "No OTP or security codes detected."),
            // At the very bottom:
            _buildBalanceHistory(),
          ],
        ),
      ),
    );
  }

  Widget _modernStatCard(BuildContext context, String label, double value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: color.withOpacity(0.08),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('₹${value.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _collapsibleSection(BuildContext context, String title, Widget child, {bool showIfEmpty = false, String? emptyMessage}) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(title, style: Theme.of(context).textTheme.titleLarge),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
          initiallyExpanded: false,
          children: [
            if (showIfEmpty && emptyMessage != null) child else child,
          ],
        ),
      ),
    );
  }

  // The following methods return the widgets for each smart feature section
  Widget _buildSmartReminders(BuildContext context) {
    if (reminders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text("No smart reminders detected.", style: Theme.of(context).textTheme.bodyMedium),
      );
    }
    return Column(
      children: reminders.map((r) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).colorScheme.surface,
        elevation: 1,
        child: ListTile(
          leading: Icon(r["type"] == "Bill" ? Icons.bolt : Icons.local_shipping, color: Theme.of(context).colorScheme.primary),
          title: Text(r["title"]),
          subtitle: Text("Due: ${r["due"].toString().split(' ')[0]}"),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: r["on"],
                onChanged: (v) {}, // TODO: Implement toggle
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {}, // TODO: Implement edit
              ),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {}, // TODO: Implement delete
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildDeadlines(BuildContext context) {
    if (reminders.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text("No deadlines detected.", style: Theme.of(context).textTheme.bodyMedium),
      );
    }
    return Column(
      children: reminders.map((d) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).colorScheme.surface,
        elevation: 1,
        child: ListTile(
          leading: Icon(Icons.date_range, color: Theme.of(context).colorScheme.primary),
          title: Text(d["title"]),
          subtitle: Text("Due: ${d["due"].toString().split(' ')[0]}"),
          trailing: ElevatedButton.icon(
            icon: const Icon(Icons.add_alert),
            label: const Text("Remind Me"),
            onPressed: () {
              _onRemindMe(d["title"] ?? '', d["title"] ?? '');
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 2,
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildUpcomingDeliveries(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final expenses = provider.expenses;
    final upcomingDeliveries = expenses.where((exp) {
      final desc = exp.description.toLowerCase();
      final hasDelivery = desc.contains('delivery') || desc.contains('arriving') || desc.contains('order placed') || desc.contains('order confirmed');
      final dateMatch = RegExp(r'(\d{1,2} [A-Za-z]{3,9} \d{4})').firstMatch(desc);
      if (hasDelivery && dateMatch != null) {
        final deliveryDate = DateFormat('d MMMM yyyy').tryParse(dateMatch.group(0)!) ?? DateFormat('d MMM yyyy').tryParse(dateMatch.group(0)!);
        return deliveryDate != null && deliveryDate.isAfter(DateTime.now());
      }
      return false;
    }).toList();
    if (upcomingDeliveries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text("No upcoming deliveries detected.", style: Theme.of(context).textTheme.bodyMedium),
      );
    }
    return Column(
      children: [
        ...upcomingDeliveries.map((exp) {
          final desc = exp.description;
          final dateMatch = RegExp(r'(\d{1,2} [A-Za-z]{3,9} \d{4})').firstMatch(desc);
          final deliveryDate = dateMatch != null ? dateMatch.group(0) : "Unknown";
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Theme.of(context).colorScheme.surface,
            elevation: 1,
            child: ListTile(
              leading: Icon(Icons.local_shipping, color: Theme.of(context).colorScheme.primary),
              title: Text(desc.split("\n").first),
              subtitle: Text("Delivery by: $deliveryDate"),
              trailing: ElevatedButton.icon(
                icon: const Icon(Icons.add_alert),
                label: const Text("Remind Me"),
                onPressed: () => _onRemindMe(desc, desc.split("\n").first),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 2,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildUpiMandates(BuildContext context, List expenses) {
    return Column(
      children: expenses.where((e) => e.description.toLowerCase().contains('upi-mandate') || e.type == 'upi_mandate').map((exp) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        elevation: 1,
        child: ListTile(
          leading: Icon(Icons.repeat, color: Theme.of(context).colorScheme.primary),
          title: Text(exp.description.split("\n").first),
          subtitle: Text("AutoPay/Mandate: ${exp.amount > 0 ? '₹${exp.amount}' : ''}"),
          trailing: ElevatedButton.icon(
            icon: const Icon(Icons.add_alert),
            label: const Text("Remind Me"),
            onPressed: () => _onRemindMe(exp.description, exp.description.split("\n").first),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 2,
            ),
          ),
        ),
      )).toList(),
    );
  }
  Widget _buildUpiRegistrations(BuildContext context, List expenses) {
    return Column(
      children: expenses.where((e) => e.type == 'upi_registration').map((exp) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        elevation: 1,
        child: ListTile(
          leading: Icon(Icons.account_balance_wallet, color: Theme.of(context).colorScheme.primary),
          title: Text("UPI ID: ${exp.toAccount}"),
          subtitle: Text(exp.description.split("\n").first),
        ),
      )).toList(),
    );
  }
  Widget _buildRechargeValidity(BuildContext context, List expenses) {
    return Column(
      children: expenses.where((e) => e.type == 'recharge_expiry').map((exp) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        elevation: 1,
        child: ListTile(
          leading: Icon(Icons.sim_card, color: Theme.of(context).colorScheme.primary),
          title: Text(exp.description.split("\n").first),
          subtitle: Text(exp.description),
          trailing: ElevatedButton.icon(
            icon: const Icon(Icons.add_alert),
            label: const Text("Remind Me"),
            onPressed: () => _onRemindMe(exp.description, exp.description.split("\n").first),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 2,
            ),
          ),
        ),
      )).toList(),
    );
  }
  Widget _buildUpiRequests(BuildContext context, List expenses) {
    return Column(
      children: expenses.where((e) => e.type == 'upi_request').map((exp) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        elevation: 1,
        child: ListTile(
          leading: Icon(Icons.request_page, color: Theme.of(context).colorScheme.primary),
          title: Text(exp.description.split("\n").first),
          subtitle: Text("Amount: ₹${exp.amount}"),
          trailing: ElevatedButton.icon(
            icon: const Icon(Icons.add_alert),
            label: const Text("Remind Me"),
            onPressed: () => _onRemindMe(exp.description, exp.description.split("\n").first),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 2,
            ),
          ),
        ),
      )).toList(),
    );
  }
  Widget _buildLowBalance(BuildContext context, List expenses) {
    return Column(
      children: expenses.where((e) => e.type == 'low_balance').map((exp) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.red[100],
        elevation: 1,
        child: ListTile(
          leading: Icon(Icons.warning, color: Colors.red),
          title: Text("Low Balance Alert"),
          subtitle: Text(exp.description),
        ),
      )).toList(),
    );
  }
  Widget _buildAvlBalances(BuildContext context, List expenses) {
    return Column(
      children: expenses.where((e) => e.type == 'avl_balance').map((exp) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        elevation: 1,
        child: ListTile(
          leading: Icon(Icons.account_balance, color: Theme.of(context).colorScheme.primary),
          title: Text("Available Balance: ₹${exp.amount}"),
          subtitle: Text(exp.description),
        ),
      )).toList(),
    );
  }
  Widget _buildGovAdvice(BuildContext context, List expenses) {
    final provider = Provider.of<ExpenseProvider>(context);
    final expenses = provider.expenses;
    return Column(
      children: expenses.where((e) => e.type == 'gov_advice').map((exp) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.yellow[100],
        elevation: 1,
        child: ListTile(
          leading: Icon(Icons.info, color: Colors.orange),
          title: Text("Govt. Advice/Warning"),
          subtitle: Text(exp.description),
        ),
      )).toList(),
    );
  }
  Widget _buildOtpCodes(BuildContext context, List expenses) {
    return Column(
      children: expenses.where((e) => e.type == 'otp').map((exp) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        elevation: 1,
        child: ListTile(
          leading: Icon(Icons.password, color: Theme.of(context).colorScheme.primary),
          title: Text("OTP/Code Detected"),
          subtitle: Text(exp.description),
        ),
      )).toList(),
    );
  }

  Widget _buildBalanceHistory() {
    final provider = Provider.of<ExpenseProvider>(context);
    // Use all expenses for the running calculation
    final expenses = provider.expenses.toList();
    expenses.sort((a, b) => a.date.compareTo(b.date));
    double running = 0.0;
    List<Widget> rows = [];
    for (final e in expenses) {
      final isDebit = RegExp(r'(debited|spent|paid|purchase|withdrawn)', caseSensitive: false).hasMatch(e.description);
      final isCredit = RegExp(r'(credited|received|deposit|income|salary|refund)', caseSensitive: false).hasMatch(e.description);
      if (isDebit) running -= e.amount;
      if (isCredit) running += e.amount;
      rows.add(Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.95),
              Theme.of(context).colorScheme.surface.withOpacity(0.85),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('dd MMM yy').format(e.date), style: Theme.of(context).textTheme.bodySmall),
            Text('${isDebit ? '-' : '+'}₹${e.amount.toStringAsFixed(2)}', style: TextStyle(color: isDebit ? Colors.red : Colors.green)),
            Text('₹${running.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ));
    }
    return Card(
      margin: const EdgeInsets.only(top: 24, bottom: 12),
      color: Colors.transparent,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Balance Calculation History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      ),
    );
  }
}
