import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/conversation_page.dart';
import 'pages/psychologist_profile_page.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Notifiche ricevute con l'app in primo piano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;
      _showForegroundNotificationOverlay(notification.title ?? '', notification.body ?? '');
    });
  } catch (_) {
    // Firebase non disponibile su questa piattaforma — l'app funziona normalmente,
    // solo le notifiche push saranno disabilitate
  }

  runApp(const MyApp());
}

// Chiave globale per mostrare SnackBar da fuori del widget tree
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void _showForegroundNotificationOverlay(String title, String body) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (body.isNotEmpty) Text(body),
        ],
      ),
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Pronto Psicologo',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/conversation') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => ConversationPage(
              conversationId: args['conversationId'] as String,
              psychologistId: args['psychologistId'] as String,
              psychologistLabel: args['psychologistLabel'] as String,
              userId: args['userId'] as String,
              role: args['role'] as String,
              questionTitle: args['questionTitle'] as String?,
              answerContent: args['answerContent'] as String?,
            ),
          );
        }
        if (settings.name == '/psychologist-profile') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => PsychologistProfilePage(
              psychologistId: args['psychologistId'] as String,
              role: args['role'] as String,
              isOwnProfile: args['isOwnProfile'] as bool? ?? false,
            ),
          );
        }
        return null;
      },
    );
  }
}
