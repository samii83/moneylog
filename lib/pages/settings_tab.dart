import 'package:flutter/material.dart';
import 'settings/appearance_settings_page.dart';
import 'settings/theme_settings_page.dart';
import 'settings/data_export_page.dart';
import 'settings/user_info_settings_page.dart';
import 'settings/sms_limit_settings_page.dart';
import 'settings/feature_toggles_page.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text('Personalization', style: Theme.of(context).textTheme.titleMedium),
          ),
          ListTile(
            leading: Icon(Icons.dark_mode),
            title: Text('Appearance'),
            subtitle: Text('Dark mode and type of dark mode'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AppearanceSettingsPage()),
            ),
          ),
          ListTile(
            leading: Icon(Icons.palette),
            title: Text('Theme'),
            subtitle: Text('Accent color'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ThemeSettingsPage(
                color: Colors.deepPurple, // TODO: Make dynamic
                onThemeColorChanged: (c) {}, seedColor: Colors.deepPurple, onSeedColorChanged: (Color value) {  },
              )),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text('Data', style: Theme.of(context).textTheme.titleMedium),
          ),
          ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text('Data Export'),
            subtitle: Text('Export as PDF or other formats'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DataExportPage()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text('Advanced', style: Theme.of(context).textTheme.titleMedium),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: Text('User Info Settings'),
            subtitle: Text('View/delete user info'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserInfoSettingsPage()),
            ),
          ),
          ListTile(
            leading: Icon(Icons.sms),
            title: Text('SMS Limit Settings'),
            subtitle: Text('Restrict SMS analysis period'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SmsLimitSettingsPage()),
            ),
          ),
          ListTile(
            leading: Icon(Icons.toggle_on),
            title: Text('Feature Toggles'),
            subtitle: Text('Enable/disable features'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FeatureTogglesPage()),
            ),
          ),
        ],
      ),
    );
  }
}
