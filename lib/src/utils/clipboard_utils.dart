import 'package:flutter/services.dart';

/// Copies [text] to the system clipboard and returns whether it worked.
///
/// The platform can refuse a clipboard write: on the web, for example, when
/// the page isn't focused or the browser denies clipboard permission. Then
/// `Clipboard.setData` throws a [PlatformException], which surfaced as an
/// uncaught error from every copy button. Callers use the result to show
/// "copied" feedback only when the copy really happened.
Future<bool> copyTextToClipboard(String text) async {
  try {
    await Clipboard.setData(ClipboardData(text: text));
    return true;
  } on PlatformException {
    return false;
  }
}
