import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// Sezione riutilizzabile per verificare email e telefono dell'account.
/// Self-contained: carica il profilo, mostra lo stato e gestisce le azioni.
/// Usata sia nel tab Profilo dell'utente sia nel profilo dello psicologo.
class AccountVerificationCard extends StatefulWidget {
  const AccountVerificationCard({super.key});

  @override
  State<AccountVerificationCard> createState() => _AccountVerificationCardState();
}

class _AccountVerificationCardState extends State<AccountVerificationCard> {
  final _auth = AuthService();
  final _api = ApiService();

  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _sendingEmail = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _auth.getProfile();
      if (!mounted) return;
      setState(() { _profile = p; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _sendingEmail = true);
    try {
      final msg = await _api.resendVerificationEmail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _sendingEmail = false);
    }
  }

  Future<void> _verifyPhone() async {
    final phone = (_profile?['phone'] as String?) ?? '';
    await Navigator.pushNamed(context, '/phone-verify', arguments: {'phone': phone});
    _load(); // al ritorno ricarico lo stato aggiornato
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    final p = _profile;
    if (p == null) return const SizedBox.shrink();

    final email = (p['email'] as String?) ?? '';
    final phone = (p['phone'] as String?) ?? '';
    final emailVerified = p['emailVerified'] == true;
    final phoneVerified = p['phoneVerified'] == true;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Verifica account',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      const Text(
        'Verifica i tuoi contatti per aumentare la fiducia e la sicurezza del tuo account.',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 16),
      _VerifyRow(
        icon: Icons.mail_outline_rounded,
        title: 'Email',
        subtitle: email,
        verified: emailVerified,
        actionLabel: 'Reinvia email',
        busy: _sendingEmail,
        onAction: _resendEmail,
      ),
      const SizedBox(height: 12),
      _VerifyRow(
        icon: Icons.phone_iphone_rounded,
        title: 'Telefono',
        subtitle: phone.isEmpty ? 'Nessun numero inserito' : phone,
        verified: phoneVerified,
        actionLabel: 'Verifica ora',
        busy: false,
        onAction: _verifyPhone,
      ),
    ]);
  }
}

class _VerifyRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool verified;
  final String actionLabel;
  final bool busy;
  final VoidCallback onAction;

  const _VerifyRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.verified,
    required this.actionLabel,
    required this.busy,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = verified ? AppColors.success : AppColors.star;
    return GlassCard(
      radius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Icon(icon, size: 24, color: AppColors.textSecondary),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(verified ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                      size: 13, color: badgeColor),
                  const SizedBox(width: 4),
                  Text(verified ? 'Verificato' : 'Da verificare',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: badgeColor)),
                ]),
              ),
            ]),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        if (!verified) ...[
          const SizedBox(width: 8),
          busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ]),
    );
  }
}
