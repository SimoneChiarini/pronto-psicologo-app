import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Web: crea un Blob e simula il click su un link di download.
Future<bool> downloadTextFile(String filename, String content, {String mimeType = 'text/plain'}) async {
  final blob = web.Blob(
    [content.toJS].toJS,
    web.BlobPropertyBag(type: '$mimeType;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  // Revoca dopo un attimo: alcuni browser leggono l'URL in modo asincrono
  Future.delayed(const Duration(seconds: 2), () => web.URL.revokeObjectURL(url));
  return true;
}
