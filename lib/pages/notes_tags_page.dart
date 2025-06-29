import 'package:flutter/material.dart';

class NotesTagsPage extends StatelessWidget {
  const NotesTagsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: UI for notes and tags
    return Scaffold(
      appBar: AppBar(title: Text('Notes & Tags')),
      body: Center(child: Text('Add notes or tags to transactions here.')),
    );
  }
}
