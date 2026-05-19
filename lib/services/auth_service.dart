import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  // ↓ Cambia questo IP se cambi rete WiFi (ipconfig su Windows, ifconfig su Mac/Linux)
  // Usa 'http://10.0.2.2:3000' se stai usando l'emulatore Android invece del dispositivo fisico
  static const _backendUrl = 'http://192.168.1.184:3000';

  static String get baseUrl {
    if (kIsWeb) {
      // Usa lo stesso host da cui è servita la web app, porta 3000
      // Funziona sia da localhost (PC) che da IP locale (iPhone/altri dispositivi)
      return 'http://${Uri.base.host}:3000';
    }
    return _backendUrl; // dispositivo Android fisico
  }
  static const _tokenKey = 'access_token';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
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

    // Aggiorna il token anche quando Firebase lo rinnova
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      syncFcmToken().catchError((_) {});
    });
  }

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
