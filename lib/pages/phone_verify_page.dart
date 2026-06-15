import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../services/api_service.dart';

class PhoneVerifyPage extends StatefulWidget {
  final String initialPhone;

  const PhoneVerifyPage({super.key, required this.initialPhone});

  @override
  State<PhoneVerifyPage> createState() => _PhoneVerifyPageState();
}

class _PhoneVerifyPageState extends State<PhoneVerifyPage> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _codeSent = false;
  bool _loading = false;
  String? _error;
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.text = widget.initialPhone;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneCtrl.text.trim(),
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          await _verifyCredential(credential);
        },
        verificationFailed: (e) {
          if (mounted) setState(() { _error = e.message ?? 'Errore invio SMS'; _loading = false; });
        },
        codeSent: (verificationId, _) {
          if (mounted) setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _loading = false;
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _verifyCode() async {
    if (_verificationId == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpCtrl.text.trim(),
      );
      await _verifyCredential(credential);
    } catch (_) {
      if (mounted) setState(() { _error = 'Codice non valido. Riprova.'; _loading = false; });
    }
  }

  Future<void> _verifyCredential(PhoneAuthCredential credential) async {
    try {
      final result = await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseToken = await result.user?.getIdToken();
      if (firebaseToken == null) throw Exception('Token non ottenuto');
      await ApiService().verifyPhone(firebaseToken);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Verifica telefono',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ]),
                const SizedBox(height: 32),
                GlassCard(
                  radius: 20,
                  padding: const EdgeInsets.all(24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Icon(Icons.sms_outlined, size: 40, color: AppColors.primary),
                    const SizedBox(height: 16),
                    if (!_codeSent) ...[
                      Text(
                        'Inserisci il numero in formato internazionale per ricevere il codice SMS.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Numero di telefono',
                          hintText: '+39 333 1234567',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loading ? null : _sendCode,
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.bg))
                            : const Text('Invia codice SMS'),
                      ),
                    ] else ...[
                      Text(
                        'Inserisci il codice a 6 cifre che hai ricevuto su ${_phoneCtrl.text.trim()}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _otpCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Codice OTP',
                          hintText: '123456',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loading ? null : _verifyCode,
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.bg))
                            : const Text('Verifica'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => setState(() { _codeSent = false; _otpCtrl.clear(); }),
                        child: const Text('Cambia numero',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ]),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                  child: const Text(
                    'Salta per ora',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
