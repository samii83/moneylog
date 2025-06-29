import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import 'sms_detail_page.dart';

class SmsTab extends StatefulWidget {
  const SmsTab({super.key});

  @override
  State<SmsTab> createState() => _SmsTabState();
}

class _SmsTabState extends State<SmsTab> {
  String sortBy = 'Newest';
  String groupBy = 'None';
  String tag = 'All';
  final List<String> sortOptions = ['Newest', 'Oldest'];
  final List<String> groupOptions = ['None', 'Date', 'Sender'];
  final List<String> tagOptions = ['All', 'Banking', 'Delivery', 'Recharge', 'Promo'];
  final List<String> dateFormats = [
    'dd/MM/yyyy',
    'MM/dd/yyyy',
    'yyyy-MM-dd',
    'MMM dd, yyyy'
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    // Show all SMSes, even if not parsed as transactions
    final allMessages = provider.allMessages;
    List<Expense> sortedMessages = List.from(allMessages);
    if (sortBy == 'Newest') {
      sortedMessages.sort((a, b) => b.date.compareTo(a.date));
    } else {
      sortedMessages.sort((a, b) => a.date.compareTo(b.date));
    }
    // Filtering by tag
    List<Expense> filteredMessages = List.from(allMessages);
    if (tag != 'All') {
      filteredMessages = filteredMessages.where((exp) {
        final desc = exp.description.toLowerCase();
        if (tag == 'Banking') return desc.contains('debit') || desc.contains('credit') || desc.contains('upi') || desc.contains('account');
        if (tag == 'Delivery') return desc.contains('delivery') || desc.contains('arriving') || desc.contains('order');
        if (tag == 'Recharge') return desc.contains('recharge') || desc.contains('validity') || desc.contains('pack');
        if (tag == 'Promo') return desc.contains('offer') || desc.contains('promo') || desc.contains('discount');
        return false;
      }).toList();
    }
    // Grouping
    Map<String, List<Expense>> grouped = {};
    if (groupBy == 'Date') {
      for (var exp in filteredMessages) {
        final key = _formatDate(exp.date, 'dd/MM/yyyy');
        grouped.putIfAbsent(key, () => []).add(exp);
      }
    } else if (groupBy == 'Sender') {
      for (var exp in filteredMessages) {
        final key = exp.sender;
        grouped.putIfAbsent(key, () => []).add(exp);
      }
    } else {
      grouped['All'] = filteredMessages;
    }
    List<String> groupKeys = grouped.keys.toList();
    if (sortBy == 'Newest') {
      groupKeys.sort((a, b) => grouped[b]![0].date.compareTo(grouped[a]![0].date));
    } else {
      groupKeys.sort((a, b) => grouped[a]![0].date.compareTo(grouped[b]![0].date));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Center(
            child: Icon(Icons.sms, size: 56, color: Theme.of(context).colorScheme.primary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: Row(
            children: [
              DropdownButton<String>(
                value: sortBy,
                items: sortOptions.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                onChanged: (v) => setState(() { if (v != null) sortBy = v; }),
                underline: Container(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: groupBy,
                items: groupOptions.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                onChanged: (v) => setState(() { if (v != null) groupBy = v; }),
                underline: Container(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: tag,
                items: tagOptions.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                onChanged: (v) => setState(() { if (v != null) tag = v; }),
                underline: Container(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: groupKeys.length,
            itemBuilder: (context, groupIdx) {
              final group = groupKeys[groupIdx];
              final messages = grouped[group]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (groupBy != 'None')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                      child: Text(group, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ...messages.map((exp) {
                    final sender = exp.sender;
                    final iconText = sender.length >= 2 ? sender.substring(0, 2).toUpperCase() : sender;
                    final firstLine = (exp.description).split('\n').first;
                    final dateStr = DateFormat.yMMMd().add_jm().format(exp.date);
                    final color = _uniqueColorFor(sender);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6),
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Theme.of(context).colorScheme.surface,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: color,
                            child: Text(iconText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(sender, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            firstLine.length > 30 ? '${firstLine.substring(0, 30)}...' : firstLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(dateStr, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.outline)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SmsDetailPage(
                                  body: exp.description,
                                  sender: exp.sender,
                                  receiver: null,
                                  account: exp.account,
                                  amount: exp.amount,
                                  category: null,
                                  size: null,
                                  date: exp.date,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ModernOvalButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;
  const _ModernOvalButton({required this.icon, required this.label, required this.options, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(32),
      child: PopupMenuButton<String>(
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 4),
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ],
        ),
        itemBuilder: (context) => options.map((o) => PopupMenuItem(value: o, child: Text(o))).toList(),
        onSelected: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

String _formatDate(DateTime date, String format) {
  switch (format) {
    case 'dd/MM/yyyy':
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    case 'MM/dd/yyyy':
      return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
    case 'yyyy-MM-dd':
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    case 'MMM dd, yyyy':
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month]} ${date.day}, ${date.year}';
    default:
      return date.toIso8601String();
  }
}

// Helper for unique color
Color _uniqueColorFor(String input) {
  final hash = input.codeUnits.fold(0, (prev, elem) => prev + elem);
  final colors = [
    Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.indigo, Colors.brown, Colors.pink, Colors.cyan
  ];
  return colors[hash % colors.length].withOpacity(0.85);
}
