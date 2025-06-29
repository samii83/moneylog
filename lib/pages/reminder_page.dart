import 'package:flutter/material.dart';

class ReminderPage extends StatelessWidget {
  const ReminderPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: UI for local notification reminders
    return Scaffold(
      appBar: AppBar(title: Text('Reminders')),
      body: Center(child: Text('Set reminders to review expenses here.')),
    );
  }
}
