import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'auth_service.dart';

class ApiService {
  static const baseUrl = AuthService.baseUrl;

  final AuthService _auth = AuthService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _auth.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── DOMANDE ──────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getQuestions() async {
    final response = await http.get(Uri.parse('$baseUrl/questions'));
    if (response.statusCode != 200) throw Exception('Errore nel caricamento delle domande');
    final list = jsonDecode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> createQuestion({
    required String title,
    required String content,
    bool isAnonymous = false,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/questions'),
      headers: headers,
      body: jsonEncode({
        'title': title,
        'content': content,
        'isAnonymous': isAnonymous,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Errore nell\'invio della domanda');
    }
  }

  // ── PSICOLOGI ─────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getPsychologists() async {
    final response = await http.get(Uri.parse('$baseUrl/psychologists'));
    if (response.statusCode != 200) throw Exception('Errore nel caricamento degli psicologi');
    final list = jsonDecode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> getPsychologistByUserId(String userId) async {
    final list = await getPsychologists();
    try {
      return list.firstWhere((p) => p['userId'] == userId);
    } catch (_) {
      return null;
    }
  }

  Future<void> updatePsychologist(String id, Map<String, dynamic> data) async {
    final headers = await _authHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/psychologists/$id'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Errore nell\'aggiornamento del profilo');
    }
  }

  // ── UPLOAD IMMAGINE ───────────────────────────────────────

  /// Carica un'immagine sul server e restituisce l'URL completo.
  Future<String> uploadImage(XFile imageFile) async {
    final uri = Uri.parse('$baseUrl/upload/image');
    final request = http.MultipartRequest('POST', uri);

    final ext = imageFile.name.split('.').last.toLowerCase();
    String mimeType;
    if (ext == 'png') {
      mimeType = 'image/png';
    } else if (ext == 'gif') {
      mimeType = 'image/gif';
    } else if (ext == 'webp') {
      mimeType = 'image/webp';
    } else {
      mimeType = 'image/jpeg';
    }

    final bytes = await imageFile.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: imageFile.name,
      contentType: MediaType.parse(mimeType),
    ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Upload fallito [${response.statusCode}]: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final relativePath = body['url'] as String;
    return '$baseUrl$relativePath';
  }

  // ── RISPOSTE ──────────────────────────────────────────────

  Future<void> createAnswer({
    required String questionId,
    required String content,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/answers'),
      headers: headers,
      body: jsonEncode({
        'questionId': questionId,
        'content': content,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Errore nell\'invio della risposta');
    }
  }

  Future<List<Map<String, dynamic>>> getAnswersByQuestion(String questionId) async {
    final response = await http.get(Uri.parse('$baseUrl/answers'));
    if (response.statusCode != 200) throw Exception('Errore nel caricamento delle risposte');
    final list = jsonDecode(response.body) as List;
    return list
        .cast<Map<String, dynamic>>()
        .where((a) => a['questionId'] == questionId)
        .toList();
  }

  Future<void> updateMyLocation(double latitude, double longitude) async {
    final headers = await _authHeaders();
    await http.patch(
      Uri.parse('$baseUrl/auth/location'),
      headers: headers,
      body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
    );
  }

  Future<List<Map<String, dynamic>>> getMyConversations() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/conversations'),
      headers: headers,
    );
    if (response.statusCode != 200) throw Exception('Errore nel caricamento delle conversazioni');
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getQuestionsForPsych() async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/questions/for-psych'),
      headers: headers,
    );
    if (response.statusCode != 200) throw Exception('Errore nel caricamento delle domande');
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  /// Ritorna tutte le risposte alle domande dell'utente corrente,
  /// ordinate per distanza se lat/lng sono forniti.
  Future<List<Map<String, dynamic>>> getAnswersForMyQuestions({double? lat, double? lng}) async {
    final headers = await _authHeaders();
    final queryParams = <String, String>{};
    if (lat != null) queryParams['lat'] = lat.toString();
    if (lng != null) queryParams['lng'] = lng.toString();
    final uri = Uri.parse('$baseUrl/answers/my-questions')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) throw Exception('Errore nel caricamento delle risposte');
    final list = jsonDecode(response.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createConversation({
    required String psychologistId,
    required String firstQuestionId,
    required String firstAnswerId,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/conversations'),
      headers: headers,
      body: jsonEncode({
        'psychologistId': psychologistId,
        'firstQuestionId': firstQuestionId,
        'firstAnswerId': firstAnswerId,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Errore nella creazione della conversazione');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ── MESSAGGI ──────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/messages/conversation/$conversationId'),
      headers: headers,
    );
    if (response.statusCode != 200) throw Exception('Errore nel caricamento dei messaggi');
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<void> sendMessage(String conversationId, String content) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: headers,
      body: jsonEncode({'conversationId': conversationId, 'content': content}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Errore nell\'invio del messaggio');
    }
  }

  // ── RECENSIONI ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getReviewsByPsychologist(String psychologistId) async {
    final response = await http.get(Uri.parse('$baseUrl/reviews/psychologist/$psychologistId'));
    if (response.statusCode != 200) throw Exception('Errore nel caricamento delle recensioni');
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<void> createReview({
    required String psychologistId,
    required int rating,
    String? comment,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/reviews'),
      headers: headers,
      body: jsonEncode({
        'psychologistId': psychologistId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Errore nell\'invio della recensione');
    }
  }

  // ── ADMIN ─────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAdminSettings() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$baseUrl/admin/settings'), headers: headers);
    if (response.statusCode != 200) throw Exception('Errore nel caricamento impostazioni');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> updateAdminSettings({double? radiusKm, int? expandMinutes, int? maxAnswers}) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{};
    if (radiusKm != null) body['radiusKm'] = radiusKm;
    if (expandMinutes != null) body['expandMinutes'] = expandMinutes;
    if (maxAnswers != null) body['maxAnswers'] = maxAnswers;
    await http.patch(Uri.parse('$baseUrl/admin/settings'), headers: headers, body: jsonEncode(body));
  }

  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$baseUrl/admin/users'), headers: headers);
    if (response.statusCode != 200) throw Exception('Errore');
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getAdminPsychologists() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$baseUrl/admin/psychologists'), headers: headers);
    if (response.statusCode != 200) throw Exception('Errore');
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getAdminQuestions() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$baseUrl/admin/questions'), headers: headers);
    if (response.statusCode != 200) throw Exception('Errore');
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getAdminConversations() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$baseUrl/admin/conversations'), headers: headers);
    if (response.statusCode != 200) throw Exception('Errore');
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getAdminConversationMessages(String conversationId) async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$baseUrl/admin/conversations/$conversationId/messages'), headers: headers);
    if (response.statusCode != 200) throw Exception('Errore');
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getAdminAnswers() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$baseUrl/admin/answers'), headers: headers);
    if (response.statusCode != 200) throw Exception('Errore');
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }
}
