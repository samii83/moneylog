import 'package:flutter/material.dart';
import 'sms_tab.dart';
import 'analysis_tab.dart';
import 'about_tab.dart' show UserInfoTab;
import 'about_app.dart';
import 'settings_tab.dart' show SettingsTab;
import 'sms_search_delegate.dart'; // Fix import for SmsSearchDelegate
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import 'sms_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  static ThemeData customMaterial3Theme(Color primaryColor, Color accentColor, {bool dark = false}) {
    final colorScheme = ColorScheme.fromSeed(seedColor: primaryColor, brightness: dark ? Brightness.dark : Brightness.light);
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 22),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        shadowColor: colorScheme.shadow,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: accentColor.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.all(TextStyle(fontWeight: FontWeight.w600)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: accentColor.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withOpacity(0.2),
        thickness: 1,
      ),
      shadowColor: colorScheme.shadow,
    );
  }

  final ValueChanged<bool>? onDarkModeChanged;
  final bool? isDarkMode;
  const HomePage({super.key, this.onDarkModeChanged, this.isDarkMode});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedTab = 0;
  bool darkMode = false;
  bool absoluteDark = false;
  Color primaryColor = Colors.deepPurple;
  Color accentColor = Colors.amber;
  String sentPieRange = 'This Month';
  String receivedPieRange = 'This Month';
  final List<String> pieRanges = [
    '30 Days', 'This Month', 'All History'
  ];

  // Add toggles for top/last transactions
  bool showTopSent = true;
  bool showTopReceived = true;

  String? username;

  @override
  void initState() {
    super.initState();
    // Load and parse SMSes on startup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        username = prefs.getString('username') ?? 'User';
      });
      Provider.of<ExpenseProvider>(context, listen: false).refreshExpenses(context);
    });
  }

  Future<void> _refreshAll(BuildContext context) async {
    HapticFeedback.mediumImpact();
    await Provider.of<ExpenseProvider>(context, listen: false).refreshExpenses(context);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Use widget.isDarkMode if provided
    final isDark = darkMode;
    return MaterialApp(
      theme: HomePage.customMaterial3Theme(primaryColor, accentColor, dark: false),
      darkTheme: HomePage.customMaterial3Theme(primaryColor, accentColor, dark: true),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: AnimatedSwitcher(
        duration: Duration(milliseconds: 350),
        child: Scaffold(
          key: ValueKey(selectedTab),
          appBar: AppBar(
            title: Text(_getAppBarTitle()),
            actions: [
              IconButton(
                icon: Icon(Icons.search),
                tooltip: 'Search SMS',
                onPressed: () async {
                  showSearch(
                    context: context,
                    delegate: SmsSearchDelegate(),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: () async {
                  await _refreshAll(context);
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'darkmode') {
                    setState(() => darkMode = !darkMode);
                  }
                  if (value == 'settings') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsTab()),
                    );
                  } else if (value == 'about') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AboutAppPage()),
                    );
                  } else if (value == 'refresh') {
                    await _refreshAll(context);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'darkmode',
                    child: Row(
                      children: [
                        Icon(isDark ? Icons.dark_mode : Icons.light_mode, size: 20),
                        SizedBox(width: 8),
                        Text(isDark ? 'Light Mode' : 'Dark Mode'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [Icon(Icons.settings, size: 20), SizedBox(width: 8), Text('Settings')],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'about',
                    child: Row(
                      children: [Icon(Icons.info_outline, size: 20), SizedBox(width: 8), Text('About App')],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [Icon(Icons.refresh, size: 20), SizedBox(width: 8), Text('Refresh')],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await _refreshAll(context);
            },
            child: _getTabBody(),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedTab,
            onDestinationSelected: (i) => setState(() => selectedTab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.sms), label: 'Messages'),
              NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Analysis'),
              NavigationDestination(icon: Icon(Icons.person), label: 'User Info'),
            ],
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (selectedTab) {
      case 0: return 'Home';
      case 1: return 'All SMS';
      case 2: return 'Analysis';
      case 3: return 'User Info';
      default: return '';
    }
  }

  Widget _buildTransactionListCard(BuildContext context, bool sent) {
    final provider = Provider.of<ExpenseProvider>(context);
    // Use all history
    final filtered = provider.expenses.where((exp) {
      final isSent = exp.type == 'debit' || exp.type == 'upi_sent';
      final isReceived = exp.type == 'credit' || exp.type == 'upi_received';
      // Hide zero-value transactions
      if (exp.amount == 0) return false;
      return sent ? isSent : isReceived;
    }).toList();
    List<Expense> displayList;
    String label;
    if ((sent ? showTopSent : showTopReceived)) {
      filtered.sort((a, b) => b.amount.compareTo(a.amount));
      displayList = filtered.take(5).toList();
      label = sent ? 'Top 5 Sent Transactions' : 'Top 5 Received Transactions';
    } else {
      filtered.sort((a, b) => b.date.compareTo(a.date));
      displayList = filtered.take(5).toList();
      label = sent ? 'Last 5 Sent Transactions' : 'Last 5 Received Transactions';
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 2,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label, style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Switch(
                  value: sent ? showTopSent : showTopReceived,
                  onChanged: (v) {
                    setState(() {
                      if (sent) {
                        showTopSent = v;
                      } else {
                        showTopReceived = v;
                      }
                    });
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveThumbColor: Theme.of(context).colorScheme.secondary,
                ),
                Text((sent ? showTopSent : showTopReceived) ? 'Top' : 'Last'),
              ],
            ),
            const SizedBox(height: 12),
            if (displayList.isEmpty)
              Text('Nil', style: Theme.of(context).textTheme.bodyLarge),
            ...displayList.map((exp) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: sent ? Colors.red[100] : Colors.green[100],
                      child: Icon(sent ? Icons.arrow_upward : Icons.arrow_downward, color: sent ? Colors.red : Colors.green),
                    ),
                    title: Text('₹${exp.amount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    subtitle: Row(
                      children: [
                        if (exp.sender != 'Unknown' && exp.sender.trim().isNotEmpty)
                          Text(exp.sender, style: TextStyle(fontWeight: FontWeight.w500)),
                        if (exp.sender == 'Unknown' || exp.sender.trim().isEmpty)
                          Text(exp.type.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.primary)),
                        const SizedBox(width: 8),
                        Icon(Icons.calendar_today, size: 14, color: Theme.of(context).colorScheme.outline),
                        const SizedBox(width: 2),
                        Text(_formatDate(exp.date, 'dd MMM yy'), style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.sms, color: Theme.of(context).colorScheme.primary),
                      tooltip: 'View Details',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SmsDetailPage(
                              body: exp.description,
                              sender: exp.sender,
                              account: exp.account,
                              amount: exp.amount,
                              date: exp.date,
                            ),
                          ),
                        );
                      },
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    tileColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date, String pattern) {
    // Simple implementation for 'dd MMM yy' pattern
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String day = twoDigits(date.day);
    String month = months[date.month - 1];
    String year = date.year.toString().substring(2);
    if (pattern == 'dd MMM yy') {
      return '$day $month $year';
    }
    // Fallback to default format
    return date.toString();
  }

  Widget _buildHomeTab() {
    final provider = Provider.of<ExpenseProvider>(context);
    final accountBalances = provider.accountBalances;
    final usableAccounts = accountBalances.entries
        .where((e) => e.value.startingBalance != null && !e.value.isSpeculative)
        .map((e) => e.key)
        .where((acc) => !acc.toLowerCase().contains('atm'))
        .toList();
    String selectedAccount = usableAccounts.isNotEmpty ? usableAccounts[0] : '';
    // Use savings logic for balance if all balances are null
    // (no longer needed for display)
    final allDates = provider.expenses.map((e) => e.date).toList();
    allDates.sort();
    final earliest = allDates.isNotEmpty ? allDates.first : null;
    final latest = allDates.isNotEmpty ? allDates.last : null;
    String historyText = '';
    if (earliest != null && latest != null) {
      final months = ((latest.year - earliest.year) * 12 + (latest.month - earliest.month)).abs();
      historyText = 'History: ${_formatDate(earliest, 'dd MMM yy')} to ${_formatDate(latest, 'dd MMM yy')}';
      if (months > 0) {
        historyText += '  (${months + 1} months)';
      } else {
        historyText += '  (same month)';
      }
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 36, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Hello, ${username ?? 'User'}!', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              if (historyText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(historyText, style: Theme.of(context).textTheme.bodyMedium),
                ),
              // Show unified balance (savings) as in analysis and user info tabs
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.account_balance_wallet, size: 36, color: Theme.of(context).colorScheme.primary),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Balance', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text('₹${provider.getTotalSavings().toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildTransactionListCard(context, true),
              const SizedBox(height: 24),
              _buildTransactionListCard(context, false),
            ],
          ),
        );
      },
    );
  }

  Widget _getTabBody() {
    switch (selectedTab) {
      case 0:
        return _buildHomeTab();
      case 1:
        return SmsTab();
      case 2:
        return AnalysisTab();
      case 3:
        return UserInfoTab();
      default:
        return Container();
    }
  }
}
