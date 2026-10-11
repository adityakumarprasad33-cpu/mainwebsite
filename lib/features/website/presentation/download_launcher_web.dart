import 'dart:async';
import 'dart:html' as html;

Future<bool> launchAndroidDownload(Uri uri, String fileName) async {
  try {
    final anchor = html.AnchorElement(href: uri.toString())
      ..download = fileName
      ..target = '_blank'
      ..rel = 'noopener noreferrer';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    return true;
  } catch (_) {
    return false;
  }
}
