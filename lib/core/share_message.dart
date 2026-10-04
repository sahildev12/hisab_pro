import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

ShareParams _shareParams(String message) => ShareParams(
      text: message,
      // Web: never open mailto: — it navigates the page and fails on many browsers.
      mailToFallbackEnabled: !kIsWeb,
      downloadFallbackEnabled: !kIsWeb,
    );

/// Copies to clipboard and opens the native share sheet.
///
/// Returns `true` when share was unavailable on web and the message was left
/// on the clipboard (already copied before share was attempted).
Future<bool> shareCalculationMessage(String message) async {
  await Clipboard.setData(ClipboardData(text: message));
  return _shareWithWebFallback(message, alreadyCopied: true);
}

Future<void> copyCalculationMessage(String message) async {
  await Clipboard.setData(ClipboardData(text: message));
}

/// Opens the native share sheet.
///
/// Returns `true` when share was unavailable on web and the message was copied
/// to the clipboard instead.
Future<bool> shareOnlyCalculationMessage(String message) async {
  return _shareWithWebFallback(message);
}

Future<bool> _shareWithWebFallback(
  String message, {
  bool alreadyCopied = false,
}) async {
  try {
    await SharePlus.instance.share(_shareParams(message));
    return false;
  } catch (_) {
    if (!kIsWeb) rethrow;
    if (!alreadyCopied) {
      await Clipboard.setData(ClipboardData(text: message));
    }
    return true;
  }
}
