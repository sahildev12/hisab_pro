import 'package:flutter/services.dart';

Future<String?> readClipboardText() async {
  final data = await Clipboard.getData('text/plain');
  return data?.text;
}
