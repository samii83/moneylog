import 'package:flutter/material.dart';

class ManualEntryPage extends StatelessWidget {
  const ManualEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: UI for manual transaction entry
    return Scaffold(
      appBar: AppBar(title: Text('Manual Transaction Entry')),
      body: Center(child: Text('Add a manual transaction here.')),
    );
  }
}
