import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Pulsante "Elimina account" con dialog di conferma (password + spunta).
/// Dopo la cancellazione riporta al login.
class DeleteAccountButton extends StatelessWidget {
  final bool isPsychologist;
  const DeleteAccountButton({super.key, this.isPsychologist = false});

  Future<void> _open(BuildContext context) async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteAccountDialog(isPsychologist: isPsychologist),
    );
    if (deleted != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (_) => false);
    messenger.showSnackBar(
      const SnackBar(content: Text('Account eliminato. Ci dispiace vederti andare via.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _open(context),
      icon: const Icon(Icons.delete_forever_outlined, size: 18, color: AppColors.textTertiary),
      label: const Text('Elimina account',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  final bool isPsychologist;
  const _DeleteAccountDialog({required this.isPsychologist});

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _confirmed = false;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Inserisci la password');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().deleteAccount(_passwordController.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final consequences = [
      if (widget.isPsychologist) ...[
        'Il tuo profilo verrà rimosso e non sarà più visibile ai pazienti',
        'L\'abbonamento verrà disdetto subito, senza altri addebiti',
        'Post, risposte e agenda verranno eliminati',
      ] else ...[
        'Domande, recensioni e appuntamenti verranno eliminati',
      ],
      'Tutte le conversazioni e i messaggi verranno eliminati',
      'L\'operazione è definitiva e non può essere annullata',
    ];

    return AlertDialog(
      title: const Text('Eliminare l\'account?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...consequences.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.remove_circle_outline, size: 14, color: AppColors.error),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(c, style: const TextStyle(fontSize: 13, height: 1.35))),
                  ]),
                )),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              enabled: !_loading,
              decoration: InputDecoration(
                labelText: 'Password per confermare',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _confirmed,
              onChanged: _loading ? null : (v) => setState(() => _confirmed = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              title: const Text('Ho capito che la cancellazione è definitiva',
                  style: TextStyle(fontSize: 13)),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
          onPressed: (_confirmed && !_loading) ? _delete : null,
          child: _loading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
              : const Text('Elimina definitivamente'),
        ),
      ],
    );
  }
}
