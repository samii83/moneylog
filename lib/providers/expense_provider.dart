import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_advanced/sms_advanced.dart';
import '../utils/sms_parser.dart';
import '../utils/first_where_or_null.dart';

class AccountBalanceInfo {
  final String account;
  double? startingBalance;
  DateTime? startingDate;
  bool isSpeculative;
  AccountBalanceInfo({required this.account, this.startingBalance, this.startingDate, this.isSpeculative = false});

  Map<String, dynamic> toJson() => {
    'account': account,
    'startingBalance': startingBalance,
    'startingDate': startingDate?.toIso8601String(),
    'isSpeculative': isSpeculative,
  };
  static AccountBalanceInfo fromJson(Map<String, dynamic> json) => AccountBalanceInfo(
    account: json['account'],
    startingBalance: (json['startingBalance'] as num?)?.toDouble(),
    startingDate: json['startingDate'] != null ? DateTime.parse(json['startingDate']) : null,
    isSpeculative: json['isSpeculative'] ?? false,
  );
}

// Expense model for compatibility with the app
class Expense {
  final String account;
  final String sender;
  final double amount;
  final String description;
  final DateTime date;
  final String type; // Add type for filtering (e.g., upi_mandate, otp, etc.)
  final String toAccount; // For UPI, recharge, etc.

  Expense({
    required this.account,
    required this.sender,
    required this.amount,
    required this.description,
    required this.date,
    required this.type,
    required this.toAccount,
  });

  factory Expense.fromParsedTransaction(ParsedTransaction tx) {
    return Expense(
      account: tx.fromAccount,
      sender: tx.sender,
      amount: tx.amount,
      description: tx.originalMessage,
      date: tx.date,
      type: tx.type,
      toAccount: tx.toAccount,
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      account: json['account'] ?? '',
      sender: json['sender'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      date: DateTime.parse(json['date']),
      type: json['type'] ?? '',
      toAccount: json['toAccount'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'account': account,
    'sender': sender,
    'amount': amount,
    'description': description,
    'date': date.toIso8601String(),
    'type': type,
    'toAccount': toAccount,
  };
}

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  double _totalSpent = 0.0;
  DateTime? _lastUpdated;
  bool _loading = false;
  Map<String, AccountBalanceInfo> _accountBalances = {};
  double? _manualBalance;

  List<Expense> get expenses => _expenses;
  double get totalSpent => _totalSpent;
  DateTime? get lastUpdated => _lastUpdated;
  bool get loading => _loading;
  Map<String, AccountBalanceInfo> get accountBalances => _accountBalances;
  // Add this to ExpenseProvider to expose all SMSes (parsed and unparsed)
  List<Expense> get allMessages => _expenses;

  ExpenseProvider() {
    loadCachedExpenses();
  }

  void setManualBalance(double value) async {
    _manualBalance = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('manual_balance', value);
    notifyListeners();
  }

  Future<void> loadCachedExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('sms_expenses');
    final totalSpent = prefs.getDouble('total_spent') ?? 0.0;
    final lastUpdatedStr = prefs.getString('last_updated');
    final balancesString = prefs.getString('account_balances');
    _manualBalance = prefs.getDouble('manual_balance');
    if (jsonString != null) {
      final List<dynamic> decoded = json.decode(jsonString);
      _expenses = decoded.map((e) => Expense.fromJson(e)).toList();
      _totalSpent = totalSpent;
      _lastUpdated = lastUpdatedStr != null ? DateTime.parse(lastUpdatedStr) : null;
      if (balancesString != null) {
        final Map<String, dynamic> balancesDecoded = json.decode(balancesString);
        _accountBalances = balancesDecoded.map((k, v) => MapEntry(k, AccountBalanceInfo.fromJson(v)));
      }
      notifyListeners();
    }
  }

  Future<void> refreshExpenses(BuildContext context) async {
    _loading = true;
    notifyListeners();
    final smsQuery = SmsQuery();
    final messages = await smsQuery.getAllSms;
    final expenses = parseSmsMessages(messages);
    final total = expenses.fold(0.0, (sum, e) => sum + e.amount);
    _expenses = expenses;
    _totalSpent = total;
    _lastUpdated = DateTime.now();
    _loading = false;
    await _speculateBalancesAndPrompt(context);
    await _saveToPrefs();
    notifyListeners();
  }

  Future<void> _speculateBalancesAndPrompt(BuildContext context) async {
    // 1. Find all accounts, only valid ones
    final Set<String> accounts = _expenses.map((e) => e.account)
      .where((acc) => SmsParser.isValidAccount(acc)).toSet();
    for (final acc in accounts) {
      // 2. Check if any SMS has a balance for this account
      final balanceExpense = firstWhereOrNull(
        _expenses,
        (e) => e.description.toLowerCase().contains('balance') && e.account == acc,
      );
      if (balanceExpense != null) {
        _accountBalances[acc] = AccountBalanceInfo(
          account: acc,
          startingBalance: balanceExpense.amount,
          startingDate: balanceExpense.date,
          isSpeculative: false,
        );
      } else {
        // 3. Speculate: sum all transactions for this account
        final accExpenses = _expenses.where((e) => e.account == acc).toList();
        accExpenses.sort((a, b) => a.date.compareTo(b.date));
        final earliest = accExpenses.isNotEmpty ? accExpenses.first.date : null;
        double speculativeBalance = 0.0;
        for (final e in accExpenses) {
          final body = e.description;
          final isDebit = RegExp(r'(debited|spent|paid|purchase|withdrawn)', caseSensitive: false).hasMatch(body);
          final isCredit = RegExp(r'(credited|received|deposit|income|salary|refund)', caseSensitive: false).hasMatch(body);
          if (isDebit) {
            speculativeBalance -= e.amount;
          } else if (isCredit) {
            speculativeBalance += e.amount;
          }
        }
        _accountBalances[acc] = AccountBalanceInfo(
          account: acc,
          startingBalance: speculativeBalance,
          startingDate: earliest,
          isSpeculative: true,
        );
      }
    }
  }

  double? getCurrentBalance(String account) {
    final info = _accountBalances[account];
    if (info == null || info.startingBalance == null) return null;
    // Calculate current balance from starting point
    final afterStart = _expenses.where((e) => e.account == account && (info.startingDate == null || e.date.isAfter(info.startingDate!)));
    double balance = info.startingBalance!;
    for (final e in afterStart) {
      final body = e.description;
      final isDebit = RegExp(r'(debited|spent|paid|purchase|withdrawn)', caseSensitive: false).hasMatch(body);
      final isCredit = RegExp(r'(credited|received|deposit|income|salary|refund)', caseSensitive: false).hasMatch(body);
      if (isDebit) {
        balance -= e.amount;
      } else if (isCredit) {
        balance += e.amount;
      }
    }
    return balance;
  }

  bool isBalanceSpeculative(String account) {
    final info = _accountBalances[account];
    return info?.isSpeculative ?? true;
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(_expenses.map((e) => e.toJson()).toList());
    await prefs.setString('sms_expenses', jsonString);
    await prefs.setDouble('total_spent', _totalSpent);
    await prefs.setString('last_updated', _lastUpdated?.toIso8601String() ?? '');
    await prefs.setString('account_balances', json.encode(_accountBalances.map((k, v) => MapEntry(k, v.toJson()))));
  }

  // Sync balances from TransactionTimeline (call after timeline is built)
  void syncBalancesFromTimeline(Map<String, double> timelineBalances) {
    for (final entry in timelineBalances.entries) {
      final acc = entry.key;
      final bal = entry.value;
      if (_accountBalances.containsKey(acc)) {
        _accountBalances[acc] = AccountBalanceInfo(
          account: acc,
          startingBalance: bal,
          startingDate: DateTime.now(),
          isSpeculative: false,
        );
      } else {
        _accountBalances[acc] = AccountBalanceInfo(
          account: acc,
          startingBalance: bal,
          startingDate: DateTime.now(),
          isSpeculative: false,
        );
      }
    }
    notifyListeners();
  }

  /// Returns the total savings (total received - total spent) from all expenses.
  double getTotalSavings() {
    if (_manualBalance != null) return _manualBalance!;
    double totalReceived = _expenses.where((e) => e.type == 'credit' || e.type == 'upi_received').fold(0.0, (a, b) => a + b.amount);
    double totalSpent = _expenses.where((e) => e.type == 'debit' || e.type == 'upi_sent').fold(0.0, (a, b) => a + b.amount);
    return totalReceived - totalSpent;
  }
}
