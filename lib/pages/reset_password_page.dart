import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

/// Aperta dal link nell'email: /#/reset-password?token=...
class ResetPasswordPage extends StatefulWidget {
  final String? token;
  const ResetPasswordPage({super.key, required this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _done = false;
  String? _error;

  bool get _hasToken => widget.token != null && widget.token!.isNotEmpty;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().resetPassword(widget.token!, _passwordController.text);
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToLogin() => Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (!_hasToken) {
      content = _message(
        icon: Icons.link_off_rounded,
        color: AppColors.error,
        text: 'Link non valido. Richiedi un nuovo link di reimpostazione dalla pagina di login.',
        button: 'Vai al login',
      );
    } else if (_done) {
      content = _message(
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.success,
        text: 'Password aggiornata. Ora puoi accedere con la nuova password.',
        button: 'Accedi',
      );
    } else {
      content = _buildForm();
    }

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: GlassCard(radius: 24, padding: const EdgeInsets.all(24), child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nuova password',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Scegli una nuova password di almeno 8 caratteri.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Nuova password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            obscureText: _obscure,
            textInputAction: TextInputAction.next,
            validator: (v) {
              final t = v ?? '';
              if (t.length < 8) return 'Almeno 8 caratteri';
              if (t.length > 72) return 'Massimo 72 caratteri';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmController,
            decoration: const InputDecoration(
              labelText: 'Conferma password',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            validator: (v) => v != _passwordController.text ? 'Le password non coincidono' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg))
                : const Text('Salva password'),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _goToLogin, child: const Text('Annulla')),
        ],
      ),
    );
  }

  Widget _message({required IconData icon, required Color color, required String text, required String button}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, size: 48, color: color),
        const SizedBox(height: 16),
        Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5)),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _goToLogin, child: Text(button)),
      ],
    );
  }
}
