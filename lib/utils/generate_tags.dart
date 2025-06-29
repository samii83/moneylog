import 'package:sms_advanced/sms_advanced.dart';

List<String> generateTagsForMessage(SmsMessage message) {
  final body = message.body?.toLowerCase() ?? '';
  final tags = <String>[];

  // Transaction types
  if (body.contains('upi')) tags.add('upi');
  if (RegExp(r'credited|received|deposit|income|salary|refund').hasMatch(body)) tags.add('credit');
  if (RegExp(r'debited|spent|paid|purchase|withdrawn').hasMatch(body)) tags.add('debit');
  if (RegExp(r'upi mandate|autopay').hasMatch(body)) tags.add('upi_mandate');

  // Balance update
  if (RegExp(r'balance[:\s]|available balance|current balance|bal is|bal:|bal\s').hasMatch(body)) tags.add('balance_update');

  // E-commerce
  if (RegExp(r'amazon|flipkart|myntra|snapdeal|meesho|bigbasket|swiggy|zomato').hasMatch(body)) tags.add('ecommerce');

  // Delivery
  if (RegExp(r'deliver|arriving|arrives|delivery scheduled|out for delivery').hasMatch(body)) tags.add('delivery');

  // Recharge/plan
  if (RegExp(r'recharge|plan|validity|data pack|expires|expiring').hasMatch(body)) tags.add('recharge');

  // Warning/alert
  if (RegExp(r'low balance|fraud|alert|blocked|suspicious').hasMatch(body)) tags.add('warning');

  // OTP/security
  if (RegExp(r'otp|one time password|verification code|security code|use code').hasMatch(body)) tags.add('otp');

  // Neutral
  if (RegExp(r'money|rs|inr|amount|transaction').hasMatch(body) && tags.isEmpty) tags.add('neutral');

  // Bank/service detection (simple)
  if (RegExp(r'sbi|hdfc|icici|axis|kotak|bob|pnb|yes bank|idfc|federal').hasMatch(body)) {
    final bankMatch = RegExp(r'sbi|hdfc|icici|axis|kotak|bob|pnb|yes bank|idfc|federal').firstMatch(body);
    if (bankMatch != null) tags.add(bankMatch.group(0)!.replaceAll(' ', ''));
  }

  // Add sender as tag if not generic
  final sender = message.sender ?? '';
  if (sender.isNotEmpty && !RegExp(r'otp|info|alert|notice|service').hasMatch(sender.toLowerCase())) {
    tags.add(sender);
  }

  return tags.toSet().toList();
}

// Helper: Detects and extracts OTP codes from a message
bool isOtpMessage(SmsMessage msg, {List<String>? tagsOut}) {
  final body = msg.body?.toLowerCase() ?? '';
  final otpRegex = RegExp(r'\b(otp|one time password|verification code|security code|code)\b.*?(\d{4,8})');
  final match = otpRegex.firstMatch(body);
  if (match != null) {
    tagsOut?.add('otp');
    return true;
  }
  return false;
}

// Helper: Detects if a message is a government alert (RBI, government, etc.)
bool isGovAlert(SmsMessage msg, {List<String>? tagsOut}) {
  final body = msg.body?.toLowerCase() ?? '';
  final sender = msg.sender?.toLowerCase() ?? '';
  if (body.contains('rbi') || body.contains('government of india') || body.contains('govt of india') ||
      sender.contains('rbi') || sender.contains('govt') || sender.contains('sebi') || sender.contains('income tax')) {
    tagsOut?.add('gov_alert');
    return true;
  }
  return false;
}

// Helper: Detects if a message is a fraud warning (e.g., Digital Arrest, scam, etc.)
bool isFraudWarning(SmsMessage msg, {List<String>? tagsOut}) {
  final body = msg.body?.toLowerCase() ?? '';
  if (body.contains('digital arrest') || body.contains('fraud') || body.contains('scam') ||
      body.contains('your account will be blocked') || body.contains('suspicious activity')) {
    tagsOut?.add('fraud_warning');
    return true;
  }
  return false;
}
