import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_theme_provider.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  late String themeMode;
  late String darkStyle;
  late String initialThemeMode;
  late String initialDarkStyle;

  @override
  void initState() {
    super.initState();
    final appTheme = Provider.of<AppThemeProvider>(context, listen: false);
    themeMode = appTheme.themeMode == ThemeMode.system
        ? 'system'
        : appTheme.themeMode == ThemeMode.dark
            ? 'dark'
            : 'light';
    darkStyle = appTheme.darkStyle;
    initialThemeMode = themeMode;
    initialDarkStyle = darkStyle;
  }

  void _saveChanges() async {
    final appTheme = Provider.of<AppThemeProvider>(context, listen: false);
    await appTheme.setThemeMode(
      themeMode == 'system'
          ? ThemeMode.system
          : themeMode == 'dark'
              ? ThemeMode.dark
              : ThemeMode.light,
    );
    await appTheme.setDarkStyle(darkStyle);
    setState(() {
      initialThemeMode = themeMode;
      initialDarkStyle = darkStyle;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appearance settings saved.')));
  }

  @override
  Widget build(BuildContext context) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Theme Mode'),
            subtitle: const Text('Follow system, Dark, or Light'),
            trailing: DropdownButton<String>(
              value: themeMode,
              items: const [
                DropdownMenuItem(value: 'system', child: Text('Follow system')),
                DropdownMenuItem(value: 'dark', child: Text('Dark mode')),
                DropdownMenuItem(value: 'light', child: Text('Light mode')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => themeMode = v);
              },
            ),
          ),
          if (themeMode == 'dark' || (themeMode == 'system' && systemBrightness == Brightness.dark))
            ListTile(
              title: const Text('Dark Mode Style'),
              trailing: DropdownButton<String>(
                value: darkStyle,
                items: const [
                  DropdownMenuItem(value: 'Black', child: Text('Black')),
                  DropdownMenuItem(value: 'Dark Gray', child: Text('Dark Gray')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => darkStyle = v);
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: (themeMode != initialThemeMode || darkStyle != initialDarkStyle) ? _saveChanges : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
