import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_picker_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController  = TextEditingController();
  final _lastNameController   = TextEditingController();
  final _emailController      = TextEditingController();
  final _passwordController   = TextEditingController();
  final _alboController       = TextEditingController();
  final _bioController        = TextEditingController();
  final _viaController        = TextEditingController();
  final _civController        = TextEditingController();
  final _capController        = TextEditingController();
  final _provinciaController  = TextEditingController();
  final _phoneController      = TextEditingController();

  String  _role = 'USER';
  XFile?  _selectedImage;
  bool    _loading = false;
  bool    _obscure = true;
  String? _error;

  @override
  void dispose() {
    for (final c in [_firstNameController, _lastNameController, _emailController,
      _passwordController, _alboController, _bioController, _viaController,
      _civController, _capController, _provinciaController, _phoneController]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _fullAddress =>
      '${_viaController.text.trim()} ${_civController.text.trim()}, '
      '${_capController.text.trim()} ${_provinciaController.text.trim()}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await ApiService().uploadImage(_selectedImage!);
      }
      await AuthService().register({
        'firstName': _firstNameController.text.trim(),
        'lastName':  _lastNameController.text.trim(),
        'email':     _emailController.text.trim(),
        'password':  _passwordController.text,
        'role':      _role,
        if (_role == 'PSYCHOLOGIST') 'alboCode': _alboController.text.trim(),
        if (_role == 'PSYCHOLOGIST' && _bioController.text.isNotEmpty) 'bio': _bioController.text.trim(),
        if (_role == 'PSYCHOLOGIST') 'address': _fullAddress,
        if (_role == 'PSYCHOLOGIST') 'phone': _phoneController.text.trim(),
        if (imageUrl != null) 'profileImage': imageUrl,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrazione completata! Accedi con le tue credenziali.')),
      );
      Navigator.pushReplacementNamed(context, '/login');
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Crea account',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Dati base
                  GlassCard(
                    radius: 20,
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      Row(children: [
                        Expanded(child: TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(labelText: 'Nome'),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.isEmpty) ? 'Obbligatorio' : null,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(labelText: 'Cognome'),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.isEmpty) ? 'Obbligatorio' : null,
                        )),
                      ]),
                      const SizedBox(height: 14),
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
                      const SizedBox(height: 14),
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
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.length < 6) ? 'Minimo 6 caratteri' : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _role,
                        dropdownColor: AppColors.surface,
                        decoration: const InputDecoration(labelText: 'Tipo di account'),
                        items: const [
                          DropdownMenuItem(value: 'USER', child: Text('Utente')),
                          DropdownMenuItem(value: 'PSYCHOLOGIST', child: Text('Psicologo')),
                        ],
                        onChanged: (v) { if (v != null) setState(() => _role = v); },
                      ),
                    ]),
                  ),

                  // Dati psicologo
                  if (_role == 'PSYCHOLOGIST') ...[
                    const SizedBox(height: 16),
                    GlassCard(
                      radius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _SectionLabel(label: 'Dati professionali', icon: Icons.badge_outlined),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _alboController,
                          decoration: const InputDecoration(
                            labelText: 'Codice Albo',
                            hintText: 'Es. OPL-12345',
                            prefixIcon: Icon(Icons.numbers_rounded),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.isEmpty) ? 'Inserisci il codice albo' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _bioController,
                          decoration: const InputDecoration(
                            labelText: 'Bio (facoltativo)',
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel(label: 'Indirizzo studio', icon: Icons.location_on_outlined),
                        const SizedBox(height: 4),
                        Text('Dove intendi effettuare le sedute', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary)),
                        const SizedBox(height: 14),
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(flex: 3, child: TextFormField(
                            controller: _viaController,
                            decoration: const InputDecoration(labelText: 'Via / Piazza', hintText: 'Es. Via Roma'),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null || v.isEmpty) ? 'Obbligatorio' : null,
                          )),
                          const SizedBox(width: 10),
                          Expanded(flex: 1, child: TextFormField(
                            controller: _civController,
                            decoration: const InputDecoration(labelText: 'N°', hintText: '1'),
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null || v.isEmpty) ? 'N/A' : null,
                          )),
                        ]),
                        const SizedBox(height: 12),
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(flex: 2, child: TextFormField(
                            controller: _capController,
                            decoration: const InputDecoration(labelText: 'CAP', hintText: '59100'),
                            keyboardType: TextInputType.number,
                            maxLength: 5,
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null || v.length != 5) ? 'CAP non valido' : null,
                          )),
                          const SizedBox(width: 10),
                          Expanded(flex: 3, child: TextFormField(
                            controller: _provinciaController,
                            decoration: const InputDecoration(labelText: 'Città / Provincia', hintText: 'Es. Prato'),
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null || v.isEmpty) ? 'Obbligatorio' : null,
                          )),
                        ]),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Numero di telefono',
                            hintText: 'Es. +39 055 1234567',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.isEmpty) ? 'Inserisci il numero' : null,
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: ImagePickerField(
                            label: 'Foto profilo (facoltativo)',
                            selectedImage: _selectedImage,
                            onImageSelected: (f) => setState(() => _selectedImage = f),
                          ),
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                  ],
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg))
                        : const Text('Registrati'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text('Hai già un account? Accedi'),
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

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
    ]);
  }
}
