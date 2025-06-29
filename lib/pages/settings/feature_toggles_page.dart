import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeatureTogglesPage extends StatefulWidget {
  const FeatureTogglesPage({super.key});

  @override
  State<FeatureTogglesPage> createState() => _FeatureTogglesPageState();
}

class _FeatureTogglesPageState extends State<FeatureTogglesPage> {
  bool reminders = true;
  bool ecommerce = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      reminders = prefs.getBool('feature_reminders') ?? true;
      ecommerce = prefs.getBool('feature_ecommerce') ?? true;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('feature_reminders', reminders);
    await prefs.setBool('feature_ecommerce', ecommerce);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Feature Toggles')),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('Reminders'),
            value: reminders,
            onChanged: (v) async {
              setState(() => reminders = v);
              await _savePrefs();
            },
          ),
          SwitchListTile(
            title: Text('E-commerce Detection'),
            value: ecommerce,
            onChanged: (v) async {
              setState(() => ecommerce = v);
              await _savePrefs();
            },
          ),
        ],
      ),
    );
  }
}
