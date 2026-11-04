// Salvataggio di un file di testo generato dall'app.
// Web: avvia il download dal browser. Altre piattaforme: non supportato
// (ritorna false e il chiamante offre un'alternativa, es. copia negli appunti).
export 'file_download_stub.dart' if (dart.library.js_interop) 'file_download_web.dart';
