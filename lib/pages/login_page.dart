import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().login(_emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  const _Logo(),
                  const SizedBox(height: 48),

                  // Form card
                  GlassCard(
                    radius: 24,
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Accedi',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Bentornato. Inserisci le tue credenziali.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null || v.isEmpty) ? 'Inserisci la tua email' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (v) => (v == null || v.isEmpty) ? 'Inserisci la password' : null,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: const TextStyle(color: AppColors.error, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 28),
                          ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg))
                                : const Text('Accedi'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                    child: const Text('Non hai un account? Registrati'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.glassBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: const Icon(Icons.psychology_rounded, color: AppColors.textPrimary, size: 26),
            ),
            const SizedBox(width: 14),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Pronto',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Psicologo',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 26,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Supporto psicologico sempre vicino a te.',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
        ),
      ],
    );
  }
}
