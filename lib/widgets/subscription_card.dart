import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

/// Card di gestione abbonamento per il professionista.
/// Auto-carica lo stato (verified / subscriptionActive / piano) e mostra:
/// - in attesa di verifica albo → messaggio informativo
/// - verificato ma non pagante → pulsante "Attiva abbonamento" (Stripe Checkout)
/// - abbonamento attivo → conferma
class SubscriptionCard extends StatefulWidget {
  const SubscriptionCard({super.key});

  @override
  State<SubscriptionCard> createState() => _SubscriptionCardState();
}

class _SubscriptionCardState extends State<SubscriptionCard> {
  final _api = ApiService();

  Map<String, dynamic>? _status;
  bool _loading = true;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await _api.getBillingStatus();
      if (!mounted) return;
      setState(() { _status = s; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _planLabel(String? plan) {
    switch (plan) {
      case 'ANNUAL':
        return 'Annuale — € 59,99/anno';
      case 'MONTHLY':
        return 'Mensile — € 9,99/mese';
      default:
        return 'Nessun piano selezionato';
    }
  }

  Future<void> _startCheckout() async {
    setState(() => _starting = true);
    try {
      final url = await _api.createCheckout();
      final uri = Uri.parse(url);
      // Su web navighiamo nella stessa scheda così il success_url riporta all'app.
      final ok = await launchUrl(
        uri,
        mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
        webOnlyWindowName: kIsWeb ? '_self' : null,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Impossibile aprire la pagina di pagamento'),
          backgroundColor: AppColors.error,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    final s = _status;
    if (s == null) return const SizedBox.shrink();

    final verified = s['verified'] == true;
    final active = s['subscriptionActive'] == true;
    final plan = s['subscriptionPlan'] as String?;

    // Abbonamento attivo → conferma, nessuna azione.
    if (active) {
      return _wrap(
        icon: Icons.check_circle_rounded,
        iconColor: AppColors.success,
        title: 'Abbonamento attivo',
        subtitle: _planLabel(plan),
      );
    }

    // Non ancora verificato → non può pagare.
    if (!verified) {
      return _wrap(
        icon: Icons.hourglass_top_rounded,
        iconColor: AppColors.star,
        title: 'In attesa di verifica',
        subtitle: 'Il tuo albo è in fase di verifica. Potrai attivare l\'abbonamento e pubblicare il profilo non appena sarà approvato.',
      );
    }

    // Verificato ma non pagante → pulsante di attivazione.
    return _wrap(
      icon: Icons.workspace_premium_rounded,
      iconColor: AppColors.primary,
      title: 'Attiva il tuo abbonamento',
      subtitle: 'Albo verificato ✓ — completa il pagamento (${_planLabel(plan)}) per pubblicare il tuo profilo e ricevere richieste.',
      action: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _starting ? null : _startCheckout,
          icon: _starting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.lock_rounded, size: 18),
          label: Text(_starting ? 'Apertura pagamento...' : 'Attiva abbonamento'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
      ),
    );
  }

  Widget _wrap({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: GlassCard(
        radius: 16,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
              ]),
            ),
          ]),
          if (action != null) ...[
            const SizedBox(height: 14),
            action,
          ],
        ]),
      ),
    );
  }
}
