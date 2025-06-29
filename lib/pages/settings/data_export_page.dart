import 'package:flutter/material.dart';
import '../../utils/export_sms.dart';

class DataExportPage extends StatelessWidget {
  const DataExportPage({super.key});

  Future<void> _exportAllSms(BuildContext context) async {
    await exportAllSms(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Data Export')),
      body: Center(
        child: ElevatedButton.icon(
          icon: Icon(Icons.sms),
          label: Text('Export All SMS'),
          onPressed: () => _exportAllSms(context),
        ),
      ),
    );
  }
}
