import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';

class DayDetailPage extends StatelessWidget {
  final DateTime day;
  const DayDetailPage({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final allExpenses = provider.expenses;
    final dayExpenses = allExpenses.where((e) => e.date.year == day.year && e.date.month == day.month && e.date.day == day.day).toList();
    final dayMessages = dayExpenses.map((e) => e.description).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Details for ${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Transactions', style: Theme.of(context).textTheme.titleLarge),
          ...dayExpenses.map((e) => Card(
                child: ListTile(
                  leading: Icon(e.type == 'debit' || e.type == 'upi_sent' ? Icons.arrow_upward : Icons.arrow_downward, color: e.type == 'debit' || e.type == 'upi_sent' ? Colors.red : Colors.green),
                  title: Text('₹${e.amount.toStringAsFixed(2)}'),
                  subtitle: Text(e.account.isNotEmpty ? e.account : e.sender),
                  trailing: Text(DateFormat('hh:mm a').format(e.date)),
                ),
              )),
          const SizedBox(height: 24),
          ExpansionTile(
            title: Text('All Messages'),
            children: dayMessages.isEmpty
                ? [ListTile(title: Text('No messages for this day'))]
                : dayMessages.map((msg) => ListTile(title: Text(msg))).toList(),
          ),
        ],
      ),
    );
  }
}
