import 'package:flutter/material.dart';
import 'package:sms_advanced/sms_advanced.dart';

class AnalysisCalendarDialog extends StatelessWidget {
  final DateTime date;
  final List<SmsMessage> messages;
  const AnalysisCalendarDialog({super.key, required this.date, required this.messages});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Transactions on ${date.toLocal().toString().split(' ')[0]}'),
      content: SizedBox(
        width: 350,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: messages.length,
          separatorBuilder: (_, __) => Divider(),
          itemBuilder: (context, i) {
            final sms = messages[i];
            return ListTile(
              leading: Icon(Icons.sms),
              title: Text(sms.body ?? ''),
              subtitle: Text(sms.address ?? ''),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }
}
