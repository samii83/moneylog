// sms_parser.dart

import 'package:sms_advanced/sms_advanced.dart';
import '../providers/expense_provider.dart';

class ParsedTransaction {
  final String fromAccount;
  final String toAccount;
  final double amount;
  final String type; // debit, credit, upi_sent, upi_received, recharge, delivery
  final String service; // like GPay, Paytm, Amazon, Flipkart, Airtel
  final String sender;
  final DateTime date;
  final String originalMessage;

  ParsedTransaction({
    required this.fromAccount,
    required this.toAccount,
    required this.amount,
    required this.type,
    required this.service,
    required this.sender,
    required this.date,
    required this.originalMessage,
  });
}

class SmsParser {
  static final RegExp _amountRegex =
      RegExp(r'(?:INR|Rs\.?|₹)\s?([\d,]+(?:\.\d{1,2})?)', caseSensitive: false);

  // Stricter: Only match masked account numbers with clear banking context
  static final RegExp _accountRegex = RegExp(
    r'(A/c(?:\s*(?:No\.?|number|ending))?\s*[:\-]?\s*[Xx*]{2,}[\d]{2,})',
    caseSensitive: false,
  );

  static final RegExp _upiSenderRegex =
      RegExp(r'to\s+([\w@.]+)', caseSensitive: false);
  static final RegExp _upiReceiverRegex =
      RegExp(r'from\s+([\w@.]+)', caseSensitive: false);

  static final RegExp _rechargeRegex = RegExp(
    r'(data pack|recharge|plan)\s+(ends|expires|due).*?(\d{1,2}\s+\w+|\d{2,4}-\d{2}-\d{2})',
    caseSensitive: false,
  );

  static final RegExp _deliveryRegex = RegExp(
    r'(delivering|arriving|arrives|delivery).*?(on\s)?(\d{1,2}\s+\w+|\d{2,4}-\d{2}-\d{2})',
    caseSensitive: false,
  );

  static final RegExp _orderPlacedRegex = RegExp(
    r'order (placed|confirmed|success).*?(order id[:\s]*([\w\d-]+))?.*?(amount[:\s]*[\w\d.,]+)?',
    caseSensitive: false,
  );
  static final RegExp _orderAmountRegex = RegExp(r'amount[:\s]*[\w\d.,]+', caseSensitive: false);
  static final RegExp _orderIdRegex = RegExp(r'order id[:\s]*([\w\d-]+)', caseSensitive: false);
  static final RegExp _deliveryDateRegex = RegExp(r'delivery (by|on) ([\d]{1,2} [A-Za-z]{3,9} [\d]{4})', caseSensitive: false);

  static final RegExp _upiMandateRegex = RegExp(r'upi-mandate.*?rs\.?\s*([\d,.]+).*?towards ([\w .&-]+).*?a/c.*?(x+\d+)', caseSensitive: false);
  static final RegExp _upiRegistrationRegex = RegExp(r'upi id (registered|created|linked).*?([\w.-]+@[\w.-]+)', caseSensitive: false);
  static final RegExp _rechargeExpiryRegex = RegExp(r'(pack|plan|validity).*?(ends|till|expires|expiry|valid upto|valid till|due|tomorrow).*?(\d{1,2}[/-][A-Za-z]{3,9}[/-]\d{2,4}|\d{1,2}\s+[A-Za-z]{3,9}\s*\d{2,4}|tomorrow)', caseSensitive: false);
  static final RegExp _upiRequestRegex = RegExp(r'has requested money.*?rs\.?\s*([\d,.]+).*?from.*?account', caseSensitive: false);
  static final RegExp _lowBalanceRegex = RegExp(r'(avg balance|balance).*?(below|low|less).*?(required|reqd|minimum|min)', caseSensitive: false);
  static final RegExp _avlBalanceRegex = RegExp(r'avl bal(?:ance)?\s*(inr|rs|:)?\s*([\d,.]+)', caseSensitive: false);
  static final RegExp _govAdviceRegex = RegExp(r'(digital arrest|rbi|government|cybercrime|1930|helpline|fraud|scam|advice)', caseSensitive: false);
  static final RegExp _otpRegex = RegExp(r'\b(otp|one time password|verification code|security code|code)\b.*?(\d{4,8})', caseSensitive: false);

  static final RegExp _sbiUpiDebit = RegExp(r'A/C?\s*([Xx\d]+)\s*debited by ([\d.]+).*trf to ([A-Za-z0-9 .&-]+) Refno', caseSensitive: false);
  static final RegExp _upiMandate = RegExp(r'UPI-Mandate for Rs\.([\d.]+) is successfully created towards ([\w .&-]+) from A/c No:?\s*([Xx\d]+)', caseSensitive: false);
  static final RegExp _upiRegistration = RegExp(r'UPI ID (registered|created|linked).*?([\w.-]+@[\w.-]+)', caseSensitive: false);
  static final RegExp _rechargeEnds = RegExp(r'(pack|plan|validity).*?(ends|till|expires|expiry|valid upto|valid till|due|tomorrow)', caseSensitive: false);
  static final RegExp _upiRequest = RegExp(r'has requested money.*?Rs([\d.]+)', caseSensitive: false);
  static final RegExp _lowBalance = RegExp(r'Avg Balance in yr A/C ([Xx\d]+) is below the Monthly Avg Balance reqd', caseSensitive: false);
  static final RegExp _creditWithAvl = RegExp(r'A/C ([Xx\d]+) has credit.*?of Rs ([\d,.]+).*?Avl Bal Rs ([\d,.]+)', caseSensitive: false);
  static final RegExp _creditByTransfer = RegExp(r'A/C ([Xx\d]+) Credited INR ([\d,.]+).*?Deposit by transfer from ([A-Za-z .]+)', caseSensitive: false);
  static final RegExp _otpCode = RegExp(r'(otp|one time password|verification code|security code|code).*?(\d{4,8})', caseSensitive: false);
  static final RegExp _govAdvice = RegExp(r'(Digital Arrest|1930|RBI|cybercrime|helpline|fraud|scam|advice)', caseSensitive: false);

  static List<ParsedTransaction> parseMessages(List<SmsMessage> messages) {
    List<ParsedTransaction> transactions = [];

    for (var msg in messages) {
      if (msg.body == null) continue;
      final body = msg.body!;
      final sender = msg.address ?? 'Unknown';
      final date = msg.date ?? DateTime.now();
      final amount = _extractAmount(body);
      final service = _extractService(body);
      final accounts = _extractAccounts(body);

      // SBI and similar credit/transfer detection
      final sbiCreditMatch = RegExp(r'A/c\s*([Xx\d]+)[^\d]+credited by Rs\.?([\d,.]+).*transfer from ([A-Za-z .]+) Ref', caseSensitive: false).firstMatch(body);
      if (sbiCreditMatch != null) {
        final acc = sbiCreditMatch.group(1) ?? accounts.item1;
        final amt = double.tryParse(sbiCreditMatch.group(2)!.replaceAll(',', '')) ?? amount ?? 0.0;
        final from = sbiCreditMatch.group(3)?.trim() ?? 'Unknown';
        transactions.add(ParsedTransaction(
          fromAccount: from,
          toAccount: acc,
          amount: amt,
          type: 'credit',
          service: service,
          sender: sender,
          date: date,
          originalMessage: body,
        ));
        continue;
      }

      // SBI-style debit: 'A/C X7821 debited by 52.0 ... trf to Mr KISHORE KUMAR ...'
      final sbiDebitMatch = RegExp(r'A/C?\s*([Xx\d*]+)\s*debited by ([\d.]+).*trf to ([A-Za-z0-9 .&-]+)', caseSensitive: false).firstMatch(body);
      if (sbiDebitMatch != null) {
        final acc = sbiDebitMatch.group(1) ?? accounts.item1;
        final amt = double.tryParse(sbiDebitMatch.group(2)!) ?? amount ?? 0.0;
        final to = sbiDebitMatch.group(3)?.trim() ?? 'Unknown';
        transactions.add(ParsedTransaction(
          fromAccount: acc,
          toAccount: to,
          amount: amt,
          type: 'debit',
          service: service,
          sender: sender,
          date: date,
          originalMessage: body,
        ));
        continue;
      }

      // Debit/Spent/Withdrawal
      if (RegExp(r'(debited|spent|paid|purchase|withdrawn)', caseSensitive: false).hasMatch(body)) {
        transactions.add(ParsedTransaction(
          fromAccount: accounts.item1,
          toAccount: service,
          amount: amount ?? 0.0,
          type: 'debit',
          service: service,
          sender: sender,
          date: date,
          originalMessage: body,
        ));
        continue;
      }

      // Credit/Received/Deposit
      if (RegExp(r'(credited|received|deposit|income|salary|refund)', caseSensitive: false).hasMatch(body)) {
        transactions.add(ParsedTransaction(
          fromAccount: service,
          toAccount: accounts.item1,
          amount: amount ?? 0.0,
          type: 'credit',
          service: service,
          sender: sender,
          date: date,
          originalMessage: body,
        ));
        continue;
      }

      // UPI Sent
      if (body.toLowerCase().contains('sent') && body.toLowerCase().contains('upi')) {
        final toUpi = _upiSenderRegex.firstMatch(body)?.group(1) ?? 'Unknown';
        transactions.add(ParsedTransaction(
          fromAccount: accounts.item1,
          toAccount: toUpi,
          amount: amount ?? 0.0,
          type: 'upi_sent',
          service: 'UPI',
          sender: sender,
          date: date,
          originalMessage: body,
        ));
        continue;
      }

      // UPI Received
      if (body.toLowerCase().contains('received') && body.toLowerCase().contains('upi')) {
        final fromUpi = _upiReceiverRegex.firstMatch(body)?.group(1) ?? 'Unknown';
        transactions.add(ParsedTransaction(
          fromAccount: fromUpi,
          toAccount: accounts.item1,
          amount: amount ?? 0.0,
          type: 'upi_received',
          service: 'UPI',
          sender: sender,
          date: date,
          originalMessage: body,
        ));
        continue;
      }

      // Recharge
      if (_rechargeRegex.hasMatch(body)) {
        transactions.add(ParsedTransaction(
          fromAccount: 'wallet',
          toAccount: 'mobile',
          amount: 0.0,
          type: 'recharge',
          service: 'Mobile Recharge',
          sender: sender,
          date: date,
          originalMessage: body,
        ));
        continue;
      }

      // Delivery
      if (_deliveryRegex.hasMatch(body)) {
        transactions.add(ParsedTransaction(
          fromAccount: 'seller',
          toAccount: 'user',
          amount: 0.0,
          type: 'delivery',
          service: 'E-commerce',
          sender: sender,
          date: date,
          originalMessage: body,
        ));
        continue;
      }

      // E-commerce Order Placed/Confirmed
      if (_orderPlacedRegex.hasMatch(body) || body.toLowerCase().contains('order placed') || body.toLowerCase().contains('order confirmed')) {
        final orderId = _orderIdRegex.firstMatch(body)?.group(1) ?? '';
        final amtMatch = _amountRegex.firstMatch(body);
        final orderAmount = amtMatch != null ? double.tryParse(amtMatch.group(1)!.replaceAll(',', '')) : amount;
        final deliveryDateMatch = _deliveryDateRegex.firstMatch(body);
        final deliveryDate = deliveryDateMatch?.group(2);
        transactions.add(ParsedTransaction(
          fromAccount: sender,
          toAccount: 'Lenskart',
          amount: orderAmount ?? 0.0,
          type: 'order_placed',
          service: 'Lenskart',
          sender: sender,
          date: date,
          originalMessage: body,
        ));
        continue;
      }

      // OTP detection
      if (_otpRegex.hasMatch(body)) {
        final otpMatch = _otpRegex.firstMatch(body);
        final otpCode = otpMatch?.group(2) ?? '';
        transactions.add(ParsedTransaction(
          fromAccount: sender,
          toAccount: '',
          amount: 0.0,
          type: 'otp',
          service: 'OTP',
          sender: sender,
          date: date,
          originalMessage: body,
        ));
        continue;
      }

      // UPI/Debit with merchant and ref
      if ((body.toLowerCase().contains('debited') || body.toLowerCase().contains('trf to')) && body.toLowerCase().contains('upi')) {
        final merchantMatch = RegExp(r'trf to ([A-Z0-9 .&-]+)', caseSensitive: false).firstMatch(body);
        final merchant = merchantMatch?.group(1)?.trim() ?? 'Unknown';
        transactions.add(ParsedTransaction(
          fromAccount: accounts.item1,
          toAccount: merchant,
          amount: amount ?? 0.0,
          type: 'upi_sent',
          service: merchant,
          sender: sender,
          date: date,
          originalMessage: body,
        ));
        continue;
      }

      // UPI Mandate/Recurring Autopay
      if (_upiMandateRegex.hasMatch(body)) {
        final match = _upiMandateRegex.firstMatch(body)!;
        final amt = double.tryParse(match.group(1)!.replaceAll(',', '')) ?? 0.0;
        final merchant = match.group(2) ?? 'Unknown';
        final account = match.group(3) ?? 'Unknown';
        transactions.add(ParsedTransaction(
          fromAccount: account,
          toAccount: merchant,
          amount: amt,
          type: 'upi_mandate',
          service: merchant,
          sender: sender,
          date: date,
          originalMessage: body,
        ));
        continue;
      }
      // UPI Registration
      if (_upiRegistrationRegex.hasMatch(body)) {
        final match = _upiRegistrationRegex.firstMatch(body)!;
        final upiId = match.group(2) ?? 'Unknown';
        transactions.add(ParsedTransaction(
          fromAccount: sender,
          toAccount: upiId,
          amount: 0.0,
          type: 'upi_registration',
          service: 'UPI',
          sender: sender,
          date: date,
          originalMessage: body,
        ));
        continue;
      }
      // Recharge/Prepaid Validity
      if (_rechargeExpiryRegex.hasMatch(body)) {
        final match = _rechargeExpiryRegex.firstMatch(body)!;
        final expiry = match.group(3) ?? 'Unknown';
        transactions.add(ParsedTransaction(
          fromAccount: sender,
          toAccount: 'Mobile',
          amount: 0.0,
          type: 'recharge_expiry',
          service: 'Mobile Recharge',
          sender: sender,
          date: date,
          originalMessage: '$body\nExpiry: $expiry',
        ));
        continue;
      }
      // UPI Request
      if (_upiRequestRegex.hasMatch(body)) {
        final match = _upiRequestRegex.firstMatch(body)!;
        final amount = double.tryParse(match.group(1)!.replaceAll(',', '')) ?? 0.0;
        transactions.add(ParsedTransaction(
          fromAccount: sender,
          toAccount: 'UPI Request',
          amount: amount,
          type: 'upi_request',
          service: 'UPI',
          sender: sender,
          date: date,
          originalMessage: body,
        ));
        continue;
      }
      // Low Balance Warning
      if (_lowBalanceRegex.hasMatch(body)) {
        transactions.add(ParsedTransaction(
          fromAccount: accounts.item1,
          toAccount: '',
          amount: 0.0,
          type: 'low_balance',
          service: 'Bank',
          sender: sender,
          date: date,
          originalMessage: body,
        ));
        continue;
      }
      // Avl Balance
      if (_avlBalanceRegex.hasMatch(body)) {
        final match = _avlBalanceRegex.firstMatch(body)!;
        final avlBal = double.tryParse(match.group(2)!.replaceAll(',', '')) ?? 0.0;
        transactions.add(ParsedTransaction(
          fromAccount: accounts.item1,
          toAccount: '',
          amount: avlBal,
          type: 'avl_balance',
          service: 'Bank',
          sender: sender,
          date: date,
          originalMessage: body,
        ));
        continue;
      }
      // Government Advice
      if (_govAdviceRegex.hasMatch(body)) {
        transactions.add(ParsedTransaction(
          fromAccount: sender,
          toAccount: '',
          amount: 0.0,
          type: 'gov_advice',
          service: 'Govt',
          sender: sender,
          date: date,
          originalMessage: body,
        ));
        continue;
      }
    }

    return transactions;
  }

  static double? _extractAmount(String body) {
    final match = _amountRegex.firstMatch(body);
    if (match != null) {
      final amtStr = match.group(1)?.replaceAll(',', '');
      return double.tryParse(amtStr ?? '');
    }
    return null;
  }

  // Only allow accounts like [xx][numbers], e.g. XX1234, and exclude 'atm', 'cash', etc.
  static bool isValidAccount(String? acc) {
    if (acc == null) return false;
    final lower = acc.toLowerCase();
    if (lower.contains('atm') || lower.contains('cash') || lower.contains('card') || lower.contains('credit') || lower.contains('debit')) return false;
    // Accept only accounts like XX1234, X123456, etc.
    return RegExp(r'^[xX*]{2,}\d{2,}$').hasMatch(acc);
  }

  static Tuple2<String, String> _extractAccounts(String body) {
    final match = _accountRegex.firstMatch(body);
    if (match != null) {
      final acc = match.group(0)?.replaceAll(RegExp(r'[^\dxX*]'), '').trim() ?? 'Unknown';
      // Only accept if it contains at least 2 X/x/* and at least 2 digits, and is preceded by A/c or similar
      final maskCount = RegExp(r'[Xx*]').allMatches(acc).length;
      final digitCount = RegExp(r'\d').allMatches(acc).length;
      if (maskCount >= 2 && digitCount >= 2 && isValidAccount(acc)) {
        return Tuple2(acc, acc);
      }
    }
    return const Tuple2('Unknown', 'Unknown');
  }

  static String _extractService(String body) {
    if (body.toLowerCase().contains('amazon')) return 'Amazon';
    if (body.toLowerCase().contains('flipkart')) return 'Flipkart';
    if (body.toLowerCase().contains('paytm')) return 'Paytm';
    if (body.toLowerCase().contains('gpay')) return 'GPay';
    if (body.toLowerCase().contains('phonepe')) return 'PhonePe';
    if (body.toLowerCase().contains('airtel')) return 'Airtel';
    if (body.toLowerCase().contains('vi') || body.toLowerCase().contains('vodafone')) return 'Vi';
    if (body.toLowerCase().contains('jio')) return 'Jio';
    return 'Unknown';
  }
}

class Tuple2<T1, T2> {
  final T1 item1;
  final T2 item2;
  const Tuple2(this.item1, this.item2);
}

List<Expense> parseSmsMessages(List<SmsMessage> messages) {
  final parsed = SmsParser.parseMessages(messages);
  return parsed.map((tx) => Expense.fromParsedTransaction(tx)).toList();
}
