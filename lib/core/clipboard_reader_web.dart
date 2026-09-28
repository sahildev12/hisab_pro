import 'dart:js_interop';

import 'package:web/web.dart';

Future<String?> readClipboardText() async {
  try {
    final text = await window.navigator.clipboard.readText().toDart;
    return text.toDart;
  } catch (_) {
    return null;
  }
}
