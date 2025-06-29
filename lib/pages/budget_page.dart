import 'package:flutter/material.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: UI for setting budgets and alerts
    return Scaffold(
      appBar: AppBar(title: Text('Budget & Alerts')),
      body: Center(child: Text('Set your monthly/weekly budget here.')),
    );
  }
}
