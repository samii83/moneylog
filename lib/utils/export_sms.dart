import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sms_advanced/sms_advanced.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

Future<void> exportAllSms(BuildContext context) async {
  // Request storage permission
  if (!await Permission.storage.request().isGranted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Storage permission denied.')));
    return;
  }
  // Pick file location
  String? outputPath = await FilePicker.platform.saveFile(
    dialogTitle: 'Export All SMS',
    fileName: 'all_sms.json',
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (outputPath == null) return;
  // Fetch all SMS
  SmsQuery query = SmsQuery();
  List<SmsMessage> messages = await query.getAllSms;
  // Convert to JSON
  final jsonList = messages.map((sms) => {
    'address': sms.address,
    'body': sms.body,
    'date': sms.date?.toIso8601String(),
    'kind': sms.kind.toString(),
    'status': sms.status.toString(),
  }).toList();
  final jsonString = json.encode(jsonList);
  // Write to file
  final file = File(outputPath);
  await file.writeAsString(jsonString);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported all SMS to $outputPath')));
}

extension on SmsMessage {
  Null get status => null;
}
