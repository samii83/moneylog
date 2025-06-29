import 'package:flutter/material.dart';

class MultiAccountPage extends StatelessWidget {
  const MultiAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: UI for multi-account support
    return Scaffold(
      appBar: AppBar(title: Text('Accounts')),
      body: Center(child: Text('Manage multiple bank accounts or cards here.')),
    );
  }
}
