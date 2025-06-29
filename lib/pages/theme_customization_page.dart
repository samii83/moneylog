import 'package:flutter/material.dart';

class ThemeCustomizationPage extends StatefulWidget {
  final Function(Color, Color) onThemeChanged;
  const ThemeCustomizationPage({super.key, required this.onThemeChanged});

  @override
  State<ThemeCustomizationPage> createState() => _ThemeCustomizationPageState();
}

class _ThemeCustomizationPageState extends State<ThemeCustomizationPage> {
  Color selectedPrimary = Colors.deepPurple;
  Color selectedAccent = Colors.amber;
  final List<Color> palette = [
    Colors.deepPurple, Colors.blue, Colors.green, Colors.red, Colors.orange, Colors.pink, Colors.teal, Colors.brown, Colors.cyan, Colors.indigo
  ];
  final List<Color> accentPalette = [
    Colors.amber, Colors.yellow, Colors.lime, Colors.deepOrange, Colors.purpleAccent, Colors.lightBlueAccent, Colors.greenAccent, Colors.redAccent
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Theme Customization')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Primary Color:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: palette.map((c) => GestureDetector(
                onTap: () {
                  setState(() => selectedPrimary = c);
                  widget.onThemeChanged(selectedPrimary, selectedAccent);
                },
                child: CircleAvatar(
                  backgroundColor: c,
                  child: selectedPrimary == c ? Icon(Icons.check, color: Colors.white) : null,
                ),
              )).toList(),
            ),
            SizedBox(height: 24),
            Text('Select Accent Color:', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: accentPalette.map((c) => GestureDetector(
                onTap: () {
                  setState(() => selectedAccent = c);
                  widget.onThemeChanged(selectedPrimary, selectedAccent);
                },
                child: CircleAvatar(
                  backgroundColor: c,
                  child: selectedAccent == c ? Icon(Icons.check, color: Colors.white) : null,
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
