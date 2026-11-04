import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Il controllo automatico ha trovato possibili dati identificativi: l'autore
/// deve rivederli e, se è tutto a posto, reinviare con acknowledgeWarnings.
class AnonymizationWarning implements Exception {
  final List<String> warnings;
  AnonymizationWarning(this.warnings);
}

/// Area riservata non disponibile (profilo non verificato o abbonamento non attivo).
class ProAreaLocked implements Exception {
  final String message;
  ProAreaLocked(this.message);
}

/// Client dell'area professionisti (/pro): intervisioni e supervisioni.
class ProApi {
  final AuthService _auth = AuthService();
  String get _base => '${AuthService.baseUrl}/pro';

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getToken();
    return {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'};
  }

  Future<dynamic> _send(String method, String path, {Object? body, Map<String, String>? query}) async {
    final uri = Uri.parse('$_base$path').replace(queryParameters: query?.isEmpty ?? true ? null : query);
    final headers = await _headers();
    final encoded = body == null ? null : jsonEncode(body);
    final http.Response r = switch (method) {
      'GET' => await http.get(uri, headers: headers),
      'POST' => await http.post(uri, headers: headers, body: encoded),
      'PUT' => await http.put(uri, headers: headers, body: encoded),
      'PATCH' => await http.patch(uri, headers: headers, body: encoded),
      'DELETE' => await http.delete(uri, headers: headers),
      _ => throw ArgumentError(method),
    };
    final data = r.bodyBytes.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode >= 200 && r.statusCode < 300) return data;

    final map = data is Map ? data : const {};
    if (r.statusCode == 422 && map['code'] == 'ANONYMIZATION_WARNINGS') {
      throw AnonymizationWarning((map['warnings'] as List).cast<String>());
    }
    if (r.statusCode == 403 && map['code'] == 'PRO_AREA_LOCKED') {
      throw ProAreaLocked(map['message'] as String? ?? 'Area non disponibile');
    }
    if (r.statusCode == 429) throw Exception('Troppe richieste. Riprova tra un minuto.');
    final msg = map['message'];
    throw Exception(msg is List ? msg.join('\n') : (msg as String? ?? 'Errore (${r.statusCode})'));
  }

  List<Map<String, dynamic>> _list(dynamic d) => (d as List).cast<Map<String, dynamic>>();

  // ── Accesso ───────────────────────────────────────────────
  Future<void> checkAccess() => _send('GET', '/access');

  // ── Gruppi ────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> myGroups() async => _list(await _send('GET', '/groups'));
  Future<List<Map<String, dynamic>>> discoverGroups([String q = '']) async =>
      _list(await _send('GET', '/groups', query: {'scope': 'discover', if (q.isNotEmpty) 'q': q}));
  Future<List<Map<String, dynamic>>> invitations() async => _list(await _send('GET', '/invitations'));
  Future<String> createGroup({
    required String name,
    String? description,
    required String visibility,
    List<String> topics = const [],
  }) async {
    final r = await _send('POST', '/groups', body: {
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      'visibility': visibility,
      'topics': topics,
      'confidentialityAccepted': true,
    });
    return r['id'] as String;
  }

  Future<Map<String, dynamic>> group(String id) async => (await _send('GET', '/groups/$id')) as Map<String, dynamic>;
  Future<void> updateGroup(String id, Map<String, dynamic> data) => _send('PATCH', '/groups/$id', body: data);
  Future<void> archiveGroup(String id) => _send('POST', '/groups/$id/archive');
  Future<String> joinGroup(String id) async =>
      (await _send('POST', '/groups/$id/join', body: {'confidentialityAccepted': true}))['status'] as String;
  Future<void> declineInvite(String id) => _send('POST', '/groups/$id/decline');
  Future<void> leaveGroup(String id) => _send('POST', '/groups/$id/leave');
  Future<void> invite(String groupId, String psychId) =>
      _send('POST', '/groups/$groupId/invite', body: {'psychologistId': psychId});
  Future<void> approveMember(String groupId, String psychId) => _send('POST', '/groups/$groupId/members/$psychId/approve');
  Future<void> setModerator(String groupId, String psychId, bool moderator) =>
      _send('POST', '/groups/$groupId/members/$psychId/moderator', body: {'moderator': moderator});
  Future<void> removeMember(String groupId, String psychId) => _send('DELETE', '/groups/$groupId/members/$psychId');
  Future<List<Map<String, dynamic>>> searchColleagues(String q, {String? groupId}) async =>
      _list(await _send('GET', '/colleagues', query: {'q': q, if (groupId != null) 'groupId': groupId}));

  // ── Casi ──────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> cases(String groupId) async => _list(await _send('GET', '/groups/$groupId/cases'));
  Future<String> createCase(String groupId, Map<String, dynamic> data, {bool acknowledgeWarnings = false}) async {
    final r = await _send('POST', '/groups/$groupId/cases', body: {
      ...data,
      'anonymizationConfirmed': true,
      if (acknowledgeWarnings) 'acknowledgeWarnings': true,
    });
    return r['id'] as String;
  }

  Future<Map<String, dynamic>> caseDetail(String caseId) async =>
      (await _send('GET', '/cases/$caseId')) as Map<String, dynamic>;
  Future<void> setCaseStatus(String caseId, String status) => _send('PATCH', '/cases/$caseId', body: {'status': status});
  Future<void> deleteCase(String caseId) => _send('DELETE', '/cases/$caseId');
  Future<void> postMessage(String caseId, String content, {bool acknowledgeWarnings = false}) =>
      _send('POST', '/cases/$caseId/messages', body: {
        'content': content,
        if (acknowledgeWarnings) 'acknowledgeWarnings': true,
      });
  Future<void> deleteMessage(String messageId) => _send('DELETE', '/messages/$messageId');
  Future<void> reportMessage(String messageId, String reason, String? details) =>
      _send('POST', '/messages/$messageId/report', body: {
        'reason': reason,
        if (details != null && details.isNotEmpty) 'details': details,
      });

  // ── Incontri ──────────────────────────────────────────────
  Future<void> createMeeting(String groupId, {required String title, required DateTime startsAt, required String url}) =>
      _send('POST', '/groups/$groupId/meetings', body: {
        'title': title,
        'startsAt': startsAt.toUtc().toIso8601String(),
        'url': url,
      });
  Future<void> deleteMeeting(String meetingId) => _send('DELETE', '/meetings/$meetingId');

  // ── Supervisione ──────────────────────────────────────────
  Future<Map<String, dynamic>?> mySupervisorProfile() async => (await _send('GET', '/supervisor-profile')) as Map<String, dynamic>?;
  Future<Map<String, dynamic>> saveSupervisorProfile(Map<String, dynamic> data) async =>
      (await _send('PUT', '/supervisor-profile', body: data)) as Map<String, dynamic>;
  Future<String> connectOnboardingUrl() async => (await _send('POST', '/supervisor-profile/connect'))['url'] as String;
  Future<String> connectDashboardUrl() async => (await _send('POST', '/supervisor-profile/dashboard'))['url'] as String;
  Future<List<Map<String, dynamic>>> supervisors([String q = '']) async =>
      _list(await _send('GET', '/supervisors', query: {if (q.isNotEmpty) 'q': q}));

  Future<String> requestSupervision({
    required String supervisorId,
    required String mode,
    required String title,
    required String caseSummary,
    List<String> colleagueIds = const [],
    bool acknowledgeWarnings = false,
  }) async {
    final r = await _send('POST', '/supervisions', body: {
      'supervisorId': supervisorId,
      'mode': mode,
      'title': title,
      'caseSummary': caseSummary,
      if (mode == 'GROUP') 'colleagueIds': colleagueIds,
      'anonymizationConfirmed': true,
      if (acknowledgeWarnings) 'acknowledgeWarnings': true,
    });
    return r['id'] as String;
  }

  Future<Map<String, dynamic>> supervisions() async => (await _send('GET', '/supervisions')) as Map<String, dynamic>;
  Future<Map<String, dynamic>> supervision(String id) async =>
      (await _send('GET', '/supervisions/$id')) as Map<String, dynamic>;
  Future<void> respondSupervision(String id, bool accept) => _send('POST', '/supervisions/$id/respond', body: {'accept': accept});
  Future<void> setParticipation(String id, bool accept) =>
      _send('POST', '/supervisions/$id/participation', body: {'accept': accept});
  Future<String> supervisionCheckoutUrl(String id) async =>
      (await _send('POST', '/supervisions/$id/checkout'))['url'] as String;
  Future<void> completeSupervision(String id) => _send('POST', '/supervisions/$id/complete');
  Future<void> cancelSupervision(String id) => _send('POST', '/supervisions/$id/cancel');
}
