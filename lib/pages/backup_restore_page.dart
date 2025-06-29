import 'package:flutter/material.dart';

class BackupRestorePage extends StatelessWidget {
  const BackupRestorePage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: UI for backup and restore
    return Scaffold(
      appBar: AppBar(title: Text('Backup & Restore')),
      body: Center(child: Text('Backup or restore your data here.')),
    );
  }
}
