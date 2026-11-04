import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/file_download.dart';

/// Pulsante "Scarica i miei dati" (export GDPR): chiede la password e scarica
/// un file JSON. Dove il download non è disponibile copia il JSON negli appunti.
class ExportDataButton extends StatelessWidget {
  const ExportDataButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => showDialog(context: context, builder: (_) => const _ExportDialog()),
      icon: const Icon(Icons.download_outlined, size: 18, color: AppColors.textTertiary),
      label: const Text('Scarica i miei dati',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
    );
  }
}

class _ExportDialog extends StatefulWidget {
  const _ExportDialog();

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Inserisci la password');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final json = await AuthService().exportMyData(_passwordController.text);
      final now = DateTime.now();
      final date = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final downloaded = await downloadTextFile('luminia-care-dati-$date.json', json, mimeType: 'application/json');
      if (!downloaded) await Clipboard.setData(ClipboardData(text: json));
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
        content: Text(downloaded
            ? 'Download avviato: trovi il file nella cartella Download.'
            : 'I tuoi dati sono stati copiati negli appunti.'),
      ));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scarica i tuoi dati'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riceverai un file con i dati del tuo account: profilo, domande e risposte, '
              'conversazioni con i messaggi, recensioni, appuntamenti e segnalazioni inviate.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 8),
            const Text(
              'Il file contiene informazioni personali e riservate: conservalo con cura.',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              enabled: !_loading,
              onSubmitted: (_) => _export(),
              decoration: InputDecoration(
                labelText: 'Password per confermare',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
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
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _export,
          child: _loading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.textInverse))
              : const Text('Scarica'),
        ),
      ],
    );
  }
}
