import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Copies to clipboard and opens the native share sheet.
Future<void> shareCalculationMessage(String message) async {
  await Clipboard.setData(ClipboardData(text: message));
  await SharePlus.instance.share(ShareParams(text: message));
}
