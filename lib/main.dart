import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/conversation_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        return null;
      },
    );
  }
}
