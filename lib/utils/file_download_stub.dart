/// Piattaforme non web: download diretto non disponibile.
Future<bool> downloadTextFile(String filename, String content, {String mimeType = 'text/plain'}) async =>
    false;
