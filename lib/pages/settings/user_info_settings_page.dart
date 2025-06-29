import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserInfoSettingsPage extends StatelessWidget {
  const UserInfoSettingsPage({super.key});

  Future<void> _deleteUserData(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('All user data deleted.')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Info Settings')),
      body: ListView(
        children: [
          ListTile(
            title: Text('What info does the app know?'),
            subtitle: Text('Phone number, detected accounts, balances, etc.'),
          ),
          ListTile(
            title: Text('Delete all user data'),
            leading: Icon(Icons.delete, color: Colors.red),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete all user data?'),
                  content: Text('This will remove all your app data and cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) {
                await _deleteUserData(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
