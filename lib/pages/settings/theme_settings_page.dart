import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeSettingsPage extends StatefulWidget {
  final Color seedColor;
  final ValueChanged<Color> onSeedColorChanged;
  const ThemeSettingsPage({super.key, required this.seedColor, required this.onSeedColorChanged, required MaterialColor color, required Null Function(dynamic c) onThemeColorChanged});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  late Color _seedColor;

  @override
  void initState() {
    super.initState();
    _seedColor = widget.seedColor;
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('seed_color');
    if (colorValue != null) {
      setState(() => _seedColor = Color(colorValue));
    }
  }

  Future<void> _savePrefs(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('seed_color', color.value);
    widget.onSeedColorChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Theme')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Seed Color'),
            trailing: CircleAvatar(backgroundColor: _seedColor),
            onTap: () async {
              Color? picked = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Pick a color'),
                  content: SingleChildScrollView(
                    child: BlockPicker(
                      pickerColor: _seedColor,
                      onColorChanged: (c) => Navigator.pop(context, c),
                    ),
                  ),
                ),
              );
              if (picked != null) {
                setState(() => _seedColor = picked);
                await _savePrefs(picked);
              }
            },
          ),
        ],
      ),
    );
  }
}
