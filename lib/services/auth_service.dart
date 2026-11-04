import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'realtime_service.dart';

class AuthService {
  static const _productionUrl = 'https://pronto-psicologo-backend-production.up.railway.app';
  // localhost:3000 per Chrome/Windows desktop
  // 192.168.1.184:3000 per dispositivo fisico sulla stessa rete WiFi
  // 10.0.2.2:3000 per emulatore Android
  static const _localUrl = 'http://localhost:3000';

  // ⬇ Cambia qui per passare da locale a produzione
  static String get baseUrl => _productionUrl;
  static const _tokenKey = 'access_token';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    // Chiude il canale in tempo reale della sessione (logout o account eliminato)
    RealtimeService.instance.disconnect();
  }

  Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Credenziali non valide');
    }

    final body = jsonDecode(response.body);
    final token = body['access_token'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);

    // Invia il token FCM al backend (fire-and-forget)
    syncFcmToken().catchError((_) {});
  }

  // Legge il token FCM del dispositivo e lo registra sul backend.
  // Chiamato automaticamente al login e può essere richiamato manualmente
  // per aggiornare il token in caso di refresh.
  Future<void> syncFcmToken() async {
    final jwtToken = await getToken();
    if (jwtToken == null) return;

    String? fcmToken;
    try {
      if (kIsWeb) {
        // Su web il VAPID key è richiesto — sostituisci con il tuo
        // Firebase Console > Impostazioni progetto > Cloud Messaging > Certificati push web
        const vapidKey = 'BHFXJ5t1GXb7OoKU-NwsN1ffYS8l4lN7--J1jk_rQPl-WDKGATmZ76A4Ai0CrRu6Mdj2FxfYFwgWWl76YiKbBWw';
        await FirebaseMessaging.instance.requestPermission();
        fcmToken = await FirebaseMessaging.instance.getToken(vapidKey: vapidKey);
      } else {
        await FirebaseMessaging.instance.requestPermission();
        fcmToken = await FirebaseMessaging.instance.getToken();
      }
    } catch (_) {
      return;
    }

    if (fcmToken == null) return;

    await http.patch(
      Uri.parse('$baseUrl/auth/fcm-token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode({'fcmToken': fcmToken}),
    );

    // Aggiorna il token anche quando Firebase lo rinnova (un solo listener per sessione app)
    if (!_tokenRefreshListening) {
      _tokenRefreshListening = true;
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        syncFcmToken().catchError((_) {});
      });
    }
  }

  static bool _tokenRefreshListening = false;

  Future<void> register(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Registrazione fallita');
    }

    final body = jsonDecode(response.body);
    final token = body['access_token'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    syncFcmToken().catchError((_) {});
  }

  // ── Recupero password ─────────────────────────────────────

  /// Il backend risponde sempre con lo stesso messaggio (non rivela se l'email esiste).
  Future<String> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 429) {
      throw Exception('Troppe richieste. Riprova tra un minuto.');
    }
    if (response.statusCode != 200) throw Exception(_errorMessage(response, 'Richiesta non riuscita'));
    return (jsonDecode(response.body) as Map<String, dynamic>)['message'] as String;
  }

  Future<void> resetPassword(String token, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'password': password}),
    );
    if (response.statusCode == 429) {
      throw Exception('Troppi tentativi. Riprova tra un minuto.');
    }
    if (response.statusCode != 200) throw Exception(_errorMessage(response, 'Reset non riuscito'));
  }

  /// Cancellazione definitiva dell'account (richiede la password). In caso di
  /// successo rimuove anche il token locale.
  Future<void> deleteAccount(String password) async {
    final token = await getToken();
    if (token == null) throw Exception('Non autenticato');
    final response = await http.post(
      Uri.parse('$baseUrl/account/delete'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'password': password}),
    );
    if (response.statusCode == 429) {
      throw Exception('Troppi tentativi. Riprova tra un minuto.');
    }
    if (response.statusCode != 200) throw Exception(_errorMessage(response, 'Cancellazione non riuscita'));
    await logout();
  }

  /// Export dei dati personali (GDPR). Ritorna il JSON già formattato.
  Future<String> exportMyData(String password) async {
    final token = await getToken();
    if (token == null) throw Exception('Non autenticato');
    final response = await http.post(
      Uri.parse('$baseUrl/account/export'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'password': password}),
    );
    if (response.statusCode == 429) {
      throw Exception('Troppe richieste. Riprova tra un minuto.');
    }
    if (response.statusCode != 200) throw Exception(_errorMessage(response, 'Export non riuscito'));
    // utf8.decode: response.body userebbe latin1 se manca il charset
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Nest restituisce `message` come stringa o come lista (errori di validazione).
  static String _errorMessage(http.Response response, String fallback) {
    try {
      final msg = (jsonDecode(response.body) as Map<String, dynamic>)['message'];
      if (msg is List) return msg.join('\n');
      if (msg is String) return msg;
    } catch (_) {}
    return fallback;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();
    if (token == null) throw Exception('Non autenticato');

    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401) {
      await logout();
      throw Exception('Sessione scaduta, effettua di nuovo il login');
    }
    if (response.statusCode != 200) {
      throw Exception('Impossibile caricare il profilo');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
