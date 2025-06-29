import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmsLimitSettingsPage extends StatefulWidget {
  const SmsLimitSettingsPage({super.key});

  @override
  State<SmsLimitSettingsPage> createState() => _SmsLimitSettingsPageState();
}

class _SmsLimitSettingsPageState extends State<SmsLimitSettingsPage> {
  String _selected = 'all';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selected = prefs.getString('sms_limit') ?? 'all';
    });
  }

  Future<void> _savePrefs(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sms_limit', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SMS Limit Settings')),
      body: ListView(
        children: [
          ListTile(title: Text('Restrict SMS analysis to:')),
          RadioListTile<String>(
            title: Text('Last 30 days'),
            value: '30',
            groupValue: _selected,
            onChanged: (v) async {
              setState(() => _selected = v!);
              await _savePrefs(v!);
            },
          ),
          RadioListTile<String>(
            title: Text('Last 90 days'),
            value: '90',
            groupValue: _selected,
            onChanged: (v) async {
              setState(() => _selected = v!);
              await _savePrefs(v!);
            },
          ),
          RadioListTile<String>(
            title: Text('All time'),
            value: 'all',
            groupValue: _selected,
            onChanged: (v) async {
              setState(() => _selected = v!);
              await _savePrefs(v!);
            },
          ),
        ],
      ),
    );
  }
}
