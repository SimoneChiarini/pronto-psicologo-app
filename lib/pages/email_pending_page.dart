import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class EmailPendingPage extends StatelessWidget {
  final String email;
  final String phone;

  const EmailPendingPage({
    super.key,
    required this.email,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhone = phone.isNotEmpty;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Image.asset('assets/logo.jpg', height: 100, fit: BoxFit.contain),
                const SizedBox(height: 20),
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 56,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Controlla la tua email',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Abbiamo inviato un link di conferma a:\n$email\n\nClicca il link per attivare il tuo account.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary, height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                if (hasPhone) ...[
                  GlassCard(
                    radius: 16,
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      const Icon(Icons.phone_iphone_rounded,
                          size: 32, color: AppColors.primary),
                      const SizedBox(height: 10),
                      const Text(
                        'Verifica anche il numero di telefono',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Riceverai un codice SMS su $phone',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/phone-verify',
                            arguments: {'phone': phone},
                          ),
                          child: const Text('Verifica telefono'),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],
                OutlinedButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/home'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.textTertiary),
                  ),
                  child: Text(
                    hasPhone ? 'Salta per ora' : 'Continua',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
