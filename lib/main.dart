import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'pages/home_page.dart';
import 'pages/lock_page.dart';
import 'providers/expense_provider.dart';
import '../providers/app_theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ExpenseProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppThemeProvider(),
      child: const MoneyLogApp(),
    );
  }
}

class MoneyLogApp extends StatefulWidget {
  const MoneyLogApp({super.key});

  @override
  State<MoneyLogApp> createState() => _MoneyLogAppState();
}

class _MoneyLogAppState extends State<MoneyLogApp> with WidgetsBindingObserver {
  bool appLockEnabled = false;
  bool isLocked = false;
  DateTime? lastActive;
  Color seedColor = Colors.deepPurple;
  Color accentColor = Colors.amber;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(Duration.zero, _checkLockOnStart);
  }

  void _checkLockOnStart() {
    if (appLockEnabled) {
      setState(() => isLocked = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = Provider.of<AppThemeProvider>(context);
    final darkStyle = appTheme.darkStyle;
    ColorScheme? customDarkScheme;
    if (darkStyle == 'Black') {
      customDarkScheme = ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
          background: Colors.black,
          surface: Colors.black);
    } else if (darkStyle == 'Dark Gray') {
      customDarkScheme = ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
          background: const Color(0xFF181A20),
          surface: const Color(0xFF23242A));
    }
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final colorSchemeSeed = seedColor;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'MoneyLog',
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: colorSchemeSeed,
            brightness: Brightness.light,
          ),
          darkTheme: customDarkScheme != null
              ? ThemeData(
                  useMaterial3: true,
                  colorScheme: customDarkScheme,
                  brightness: Brightness.dark,
                )
              : ThemeData(
                  useMaterial3: true,
                  colorSchemeSeed: colorSchemeSeed,
                  brightness: Brightness.dark,
                ),
          themeMode: appTheme.themeMode,
          home: isLocked && appLockEnabled
              ? LockPage(onUnlock: () => setState(() => isLocked = false))
              : HomePage(),
        );
      },
    );
  }
}

