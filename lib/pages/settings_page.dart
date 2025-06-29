import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _resetApp(BuildContext context) {
    // TODO: Implement app reset logic (clear local data, etc.)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset App'),
        content: Text('Are you sure you want to reset the app? This will clear all local data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Clear local data here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('App reset!')),
              );
            },
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _resetApp(context),
          child: Text('Reset App'),
        ),
      ),
    );
  }
}
