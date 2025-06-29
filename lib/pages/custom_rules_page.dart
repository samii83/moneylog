import 'package:flutter/material.dart';

class CustomRulesPage extends StatelessWidget {
  const CustomRulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: UI for adding/editing custom regex rules
    return Scaffold(
      appBar: AppBar(title: Text('Custom Parsing Rules')),
      body: Center(child: Text('Add/Edit custom SMS parsing rules here.')),
    );
  }
}
