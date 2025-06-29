import 'package:flutter/material.dart';

class PdfExportPage extends StatelessWidget {
  const PdfExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: UI for PDF export
    return Scaffold(
      appBar: AppBar(title: Text('Export as PDF')),
      body: Center(child: Text('Export your expense report as PDF here.')),
    );
  }
}
