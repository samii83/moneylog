import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../utils/sms_parser.dart';

class UserInfoTab extends StatefulWidget {
  const UserInfoTab({super.key});

  @override
  State<UserInfoTab> createState() => _UserInfoTabState();
}

class _UserInfoTabState extends State<UserInfoTab> {
  String? phoneNumber;
  String? username;
  String? profilePicPath;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPrefs();
  }

  void _loadUserPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? username;
      profilePicPath = prefs.getString('profilePicPath') ?? profilePicPath;
      phoneNumber = prefs.getString('phoneNumber') ?? phoneNumber;
    });
  }

  // Validate phone number input
  void _promptPhoneNumber() async {
    final controller = TextEditingController(text: phoneNumber);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Phone Number'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Your phone number'),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = controller.text.trim();
              if (!RegExp(r'^\d{10,15}\$').hasMatch(value)) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a valid phone number.')));
                return;
              }
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('phoneNumber', value);
              HapticFeedback.mediumImpact();
              Navigator.pop(context, value);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => phoneNumber = result);
    }
  }

  void _promptUsername() async {
    final controller = TextEditingController(text: username);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter Username'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Your username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('username', controller.text);
              HapticFeedback.mediumImpact();
              Navigator.pop(context, controller.text);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => username = result);
    }
  }

  void _pickProfilePic() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => profilePicPath = picked.path);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profilePicPath', picked.path);
      HapticFeedback.mediumImpact();
    }
  }

  // Add a reset profile button
  void _resetProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('profilePicPath');
    await prefs.remove('phoneNumber');
    setState(() {
      username = null;
      profilePicPath = null;
      phoneNumber = null;
    });
    HapticFeedback.mediumImpact();
  }

  // Add info icon for Estimated
  Widget _balanceRow(String acc, double? bal, bool isSpec) {
    return Row(
      children: [
        Text('Balance: ₹${bal?.toStringAsFixed(2) ?? '--'}'),
        if (isSpec)
          Tooltip(
            message: 'Estimated: No balance SMS found, calculated from transactions.',
            child: Icon(Icons.info_outline, color: Colors.orange, size: 18),
          ),
      ],
    );
  }

  void _promptBalance() async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final controller = TextEditingController(text: provider.getTotalSavings().toStringAsFixed(2));
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Balance'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: 'Enter your current balance'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null) {
                provider.setManualBalance(value);
                Navigator.pop(context, value);
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final accountBalances = provider.accountBalances;
    final accountNumbers = accountBalances.entries
        .where((e) => e.value.startingBalance != null && !e.value.isSpeculative)
        .map((e) => e.key)
        .where((acc) => SmsParser.isValidAccount(acc))
        .toList();
    final allExpenses = provider.expenses;
    final allDates = allExpenses.map((e) => e.date).toList();
    allDates.sort();
    final earliest = allDates.isNotEmpty ? allDates.first : null;
    final latest = allDates.isNotEmpty ? allDates.last : null;
    final months = (earliest != null && latest != null)
        ? ((latest.year - earliest.year) * 12 + (latest.month - earliest.month)).abs() + 1
        : 0;
    double savings = provider.getTotalSavings();
    return RefreshIndicator(
      onRefresh: () async {
        _loadUserPrefs();
      },
      child: Scaffold(
        appBar: AppBar(
          // Remove the username/profile/phone number title
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickProfilePic,
                        child: CircleAvatar(
                          radius: 36,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          backgroundImage: profilePicPath != null ? FileImage(File(profilePicPath!)) : null,
                          child: profilePicPath == null
                              ? Icon(Icons.person, size: 40, color: Theme.of(context).colorScheme.onPrimary)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    username ?? 'Tap to add your username',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                                  onPressed: _promptUsername,
                                  tooltip: 'Add/Edit Username',
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: _promptPhoneNumber,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Phone Number', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
                                  Text(phoneNumber ?? 'Tap to add your phone number', style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('Total Balance: ₹${savings.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: Icon(Icons.edit, size: 18, color: Theme.of(context).colorScheme.primary),
                                  tooltip: 'Edit Balance',
                                  onPressed: _promptBalance,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCard(icon: Icons.account_balance, label: 'Accounts', value: accountNumbers.length.toString()),
                  GestureDetector(
                    onTap: () async {
                      final controller = TextEditingController(text: provider.getTotalSavings().toStringAsFixed(2));
                      final result = await showDialog<double>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Set Current Balance'),
                          content: TextField(
                            controller: controller,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(hintText: 'Enter your current balance'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final value = double.tryParse(controller.text);
                                if (value != null) {
                                  provider.setManualBalance(value);
                                  Navigator.pop(context, value);
                                }
                              },
                              child: Text('Save'),
                            ),
                          ],
                        ),
                      );
                      if (result != null) setState(() {});
                    },
                    child: _StatCard(icon: Icons.savings, label: 'Savings', value: '₹${savings.toStringAsFixed(2)}'),
                  ),
                  _StatCard(icon: Icons.sms, label: 'SMSes', value: allExpenses.length.toString()),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 1,
                child: ExpansionTile(
                  leading: Icon(Icons.account_balance, color: Theme.of(context).colorScheme.primary),
                  title: Text('Bank Accounts', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  children: accountNumbers.isEmpty
                      ? [ListTile(title: Text('No accounts detected'))]
                      : accountNumbers.map((acc) {
                          // Show unified savings for all accounts
                          final savings = provider.getTotalSavings();
                          return ListTile(
                            leading: Icon(Icons.credit_card, color: Theme.of(context).colorScheme.secondary),
                            title: Text(acc, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                            subtitle: Text('Balance: ₹${savings.toStringAsFixed(2)}'),
                            trailing: Chip(
                              label: Text('₹${savings.toStringAsFixed(0)}'),
                              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                            ),
                          );
                        }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('App Usage', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text('Last updated: ${provider.lastUpdated != null ? DateFormat('dd MMM yyyy, hh:mm a').format(provider.lastUpdated!) : '--'}'),
                      if (earliest != null && latest != null)
                        Text('History: ${earliest.year}-${earliest.month.toString().padLeft(2, '0')}-${earliest.day.toString().padLeft(2, '0')} to ${latest.year}-${latest.month.toString().padLeft(2, '0')}-${latest.day.toString().padLeft(2, '0')}'),
                      if (months > 0)
                        Text('Months of history: $months'),
                      if (allExpenses.isNotEmpty)
                        Text('First SMS: ${earliest != null ? earliest.toLocal().toString().split(" ")[0] : '-'}'),
                      if (allExpenses.isNotEmpty)
                        Text('Last SMS: ${latest != null ? latest.toLocal().toString().split(" ")[0] : '-'}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _resetProfile,
                icon: Icon(Icons.refresh),
                label: Text('Reset Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: theme.colorScheme.secondaryContainer,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(height: 6),
            Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
