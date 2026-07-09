import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/image_picker_field.dart';
import '../widgets/specialization_picker.dart';

// Prezzi abbonamento professionista (scaffolding: nessun addebito reale ancora)
const String _priceMonthly = '9,99';
const String _priceAnnual  = '59,99';
// Risparmio annuale vs 12 mensilità (12×9,99=119,88 → ~50%)
const int    _annualSavingPercent = 50;

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
  final _phoneController      = TextEditingController();

  String  _role = 'USER';
  XFile?  _selectedImage;
  bool    _loading = false;
  bool    _obscure = true;
  String? _error;

  bool? _isMale;
  bool  _isOnlineOnly      = false;
  bool  _isPsychotherapist = false;
  bool  _privacyAccepted   = false;
  bool  _contractAccepted  = false;
  String _plan = 'ANNUAL'; // 'MONTHLY' | 'ANNUAL'
  final List<_AddressFields> _addresses = [_AddressFields()];
  Set<String> _tagCodes = {};

  @override
  void dispose() {
    for (final c in [_firstNameController, _lastNameController, _emailController,
      _passwordController, _alboController, _bioController, _phoneController]) {
      c.dispose();
    }
    for (final a in _addresses) a.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == 'PSYCHOLOGIST' && !_isOnlineOnly) {
      if (_addresses.isEmpty || _addresses.first.viaCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Inserisci almeno un indirizzo studio');
        return;
      }
    }
    if (!_privacyAccepted) {
      setState(() => _error = 'Devi accettare la Privacy Policy per continuare.');
      return;
    }
    if (_role == 'PSYCHOLOGIST' && !_contractAccepted) {
      setState(() => _error = 'Devi accettare il contratto di abbonamento per continuare.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await ApiService().uploadImage(_selectedImage!);
      }
      final addresses = (_role == 'PSYCHOLOGIST' && !_isOnlineOnly)
          ? _addresses.map((a) => a.fullAddress).where((s) => s.trim().length > 5).toList()
          : <String>[];
      await AuthService().register({
        'firstName': _firstNameController.text.trim(),
        'lastName':  _lastNameController.text.trim(),
        'email':     _emailController.text.trim(),
        'password':  _passwordController.text,
        'role':      _role,
        if (_role == 'PSYCHOLOGIST') 'alboCode': _alboController.text.trim(),
        if (_role == 'PSYCHOLOGIST' && _bioController.text.isNotEmpty) 'bio': _bioController.text.trim(),
        if (_role == 'PSYCHOLOGIST') 'isOnlineOnly': _isOnlineOnly,
        if (_role == 'PSYCHOLOGIST') 'isPsychotherapist': _isPsychotherapist,
        if (_role == 'PSYCHOLOGIST') 'addresses': addresses,
        if (_phoneController.text.trim().isNotEmpty) 'phone': _phoneController.text.trim(),
        if (_role == 'PSYCHOLOGIST' && _isMale != null) 'isMale': _isMale,
        if (_role == 'PSYCHOLOGIST' && _tagCodes.isNotEmpty) 'tagCodes': _tagCodes.toList(),
        if (_role == 'PSYCHOLOGIST') 'subscriptionPlan': _plan,
        if (_role == 'PSYCHOLOGIST') 'contractAccepted': _contractAccepted,
        if (imageUrl != null) 'profileImage': imageUrl,
      });
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/email-pending', arguments: {
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
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
                  // Logo completo (come login)
                  Center(
                    child: Image.asset(
                      'assets/logo.png',
                      height: 200,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary),
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      ),
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
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Numero di telefono',
                          hintText: 'Es. +39 333 1234567',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (_role == 'PSYCHOLOGIST' && (v == null || v.isEmpty)) {
                            return 'Obbligatorio per psicologi';
                          }
                          return null;
                        },
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

                        // Sesso
                        _SectionLabel(label: 'Sesso', icon: Icons.person_outline_rounded),
                        const SizedBox(height: 12),
                        Row(children: [
                          _GenderChip(
                            label: 'Uomo',
                            icon: Icons.male_rounded,
                            selected: _isMale == true,
                            onTap: () => setState(() => _isMale = true),
                          ),
                          const SizedBox(width: 10),
                          _GenderChip(
                            label: 'Donna',
                            icon: Icons.female_rounded,
                            selected: _isMale == false,
                            onTap: () => setState(() => _isMale = false),
                          ),
                        ]),
                        const SizedBox(height: 24),

                        // Qualifica
                        _SectionLabel(label: 'Qualifica', icon: Icons.workspace_premium_outlined),
                        const SizedBox(height: 12),
                        Row(children: [
                          Switch(
                            value: _isPsychotherapist,
                            onChanged: (v) => setState(() => _isPsychotherapist = v),
                          ),
                          const SizedBox(width: 8),
                          const Text('Psicoterapeuta', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ]),
                        const SizedBox(height: 24),

                        // Modalità lavoro
                        _SectionLabel(label: 'Modalità', icon: Icons.laptop_outlined),
                        const SizedBox(height: 12),
                        Row(children: [
                          Switch(
                            value: _isOnlineOnly,
                            onChanged: (v) => setState(() => _isOnlineOnly = v),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            _isOnlineOnly ? 'Solo online' : 'In presenza (+ eventualmente online)',
                            style: const TextStyle(fontSize: 13),
                          )),
                        ]),
                        const SizedBox(height: 20),

                        // Indirizzi studio (visibili solo se non online)
                        if (!_isOnlineOnly) ...[
                          _SectionLabel(label: 'Indirizzi studio', icon: Icons.location_on_outlined),
                          const SizedBox(height: 4),
                          Text(
                            'Puoi aggiungere più sedi',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
                          ),
                          const SizedBox(height: 14),
                          for (int i = 0; i < _addresses.length; i++) ...[
                            if (_addresses.length > 1) Row(children: [
                              Text(
                                'Studio ${i + 1}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                              const Spacer(),
                              if (i > 0) TextButton(
                                onPressed: () => setState(() {
                                  _addresses[i].dispose();
                                  _addresses.removeAt(i);
                                }),
                                style: TextButton.styleFrom(foregroundColor: AppColors.error, padding: EdgeInsets.zero),
                                child: const Text('Rimuovi', style: TextStyle(fontSize: 12)),
                              ),
                            ]),
                            if (_addresses.length > 1) const SizedBox(height: 6),
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Expanded(flex: 3, child: TextField(
                                controller: _addresses[i].viaCtrl,
                                decoration: const InputDecoration(labelText: 'Via / Piazza', hintText: 'Es. Via Roma'),
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                              )),
                              const SizedBox(width: 10),
                              Expanded(flex: 1, child: TextField(
                                controller: _addresses[i].civCtrl,
                                decoration: const InputDecoration(labelText: 'N°', hintText: '1'),
                                textInputAction: TextInputAction.next,
                              )),
                            ]),
                            const SizedBox(height: 10),
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Expanded(flex: 2, child: TextField(
                                controller: _addresses[i].capCtrl,
                                decoration: const InputDecoration(labelText: 'CAP', hintText: '59100'),
                                keyboardType: TextInputType.number,
                                maxLength: 5,
                                textInputAction: TextInputAction.next,
                              )),
                              const SizedBox(width: 10),
                              Expanded(flex: 3, child: TextField(
                                controller: _addresses[i].provCtrl,
                                decoration: const InputDecoration(labelText: 'Città / Provincia', hintText: 'Es. Prato'),
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                              )),
                            ]),
                            if (i < _addresses.length - 1) const SizedBox(height: 16),
                          ],
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => setState(() => _addresses.add(_AddressFields())),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Aggiungi studio', style: TextStyle(fontSize: 13)),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

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

                    // Aree di specializzazione (gerarchiche)
                    const SizedBox(height: 16),
                    GlassCard(
                      radius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _SectionLabel(label: 'Aree di specializzazione', icon: Icons.psychology_outlined),
                        const SizedBox(height: 6),
                        Text(
                          'Scegli categoria → sottocategoria → disturbi/aree (puoi aggiungerne più di una)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
                        ),
                        const SizedBox(height: 16),
                        SpecializationPicker(
                          selectedCodes: _tagCodes,
                          onChanged: (codes) => setState(() => _tagCodes = codes),
                        ),
                      ]),
                    ),

                    // ── Abbonamento professionista ─────────────────────────
                    const SizedBox(height: 16),
                    GlassCard(
                      radius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _SectionLabel(label: 'Abbonamento', icon: Icons.workspace_premium_rounded),
                        const SizedBox(height: 6),
                        Text(
                          'Scegli il piano. Nessun addebito ora: pagherai solo dopo la verifica del tuo albo, per pubblicare il profilo.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
                        ),
                        const SizedBox(height: 16),
                        _PlanCard(
                          title: 'Annuale',
                          price: '€$_priceAnnual',
                          period: '/anno',
                          highlight: 'Risparmi il $_annualSavingPercent%',
                          selected: _plan == 'ANNUAL',
                          onTap: () => setState(() => _plan = 'ANNUAL'),
                        ),
                        const SizedBox(height: 10),
                        _PlanCard(
                          title: 'Mensile',
                          price: '€$_priceMonthly',
                          period: '/mese',
                          selected: _plan == 'MONTHLY',
                          onTap: () => setState(() => _plan = 'MONTHLY'),
                        ),
                        const SizedBox(height: 16),
                        // Checkbox contratto (obbligatorio per psicologi)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: _contractAccepted,
                              onChanged: (v) => setState(() => _contractAccepted = v ?? false),
                              activeColor: AppColors.bgInverse,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text(
                                    'Ho letto e accetto il ',
                                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                  GestureDetector(
                                    onTap: () => showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => const _ContractSheet(),
                                    ),
                                    child: const Text(
                                      'Contratto di abbonamento',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textStrong,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Privacy Policy ─────────────────────────────────────
                  GlassCard(
                    radius: 14,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _privacyAccepted,
                          onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
                          activeColor: AppColors.bgInverse,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Ho letto e accetto la ',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                              GestureDetector(
                                onTap: () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => _PrivacySheet(
                                    isPsychologist: _role == 'PSYCHOLOGIST',
                                  ),
                                ),
                                child: Text(
                                  _role == 'PSYCHOLOGIST'
                                      ? 'Privacy Policy per Professionisti'
                                      : 'Privacy Policy',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textStrong,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
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

// ─────────────────────────────────────────────────────────────────────────────
// PRIVACY SHEET
// ─────────────────────────────────────────────────────────────────────────────

const String _privacyUser = '''
INFORMATIVA SUL TRATTAMENTO DEI DATI PERSONALI
(ai sensi degli artt. 13-14 del Regolamento UE 2016/679 – GDPR)

⚠ TESTO DI PROVA – sarà sostituito dal testo definitivo redatto dall'avvocato.

1. TITOLARE DEL TRATTAMENTO
Luminia Care S.r.l. (in fase di costituzione), con sede legale in [indirizzo da definire].
Contatto: privacy@luminiacare.it

2. DATI RACCOLTI
Il Titolare raccoglie: nome, cognome, indirizzo e-mail, numero di telefono (opzionale), posizione geografica (opzionale), immagine profilo (opzionale), token dispositivo per notifiche push.

3. FINALITÀ E BASE GIURIDICA
• Erogazione del servizio di abbinamento con professionisti della salute mentale — base: esecuzione del contratto (art. 6 par. 1 lett. b GDPR).
• Invio di notifiche push per appuntamenti e messaggi — base: consenso (art. 6 par. 1 lett. a GDPR).
• Verifica dell'identità tramite e-mail e/o SMS — base: esecuzione del contratto.

4. CONSERVAZIONE
I dati sono conservati per tutta la durata del rapporto contrattuale e per i 10 anni successivi alla sua cessazione, salvo diversi obblighi di legge.

5. COMUNICAZIONE A TERZI
I dati non vengono ceduti a terzi, salvo fornitori tecnici (Firebase, Railway e simili) che operano come responsabili del trattamento ai sensi dell'art. 28 GDPR.

6. DIRITTI DELL'INTERESSATO
Hai il diritto di accedere, rettificare, cancellare, limitare e opporti al trattamento, nonché alla portabilità dei dati. Per esercitarli scrivi a privacy@luminiacare.it.

7. DIRITTO DI RECLAMO
Hai il diritto di proporre reclamo al Garante per la protezione dei dati personali (www.garanteprivacy.it).
''';

const String _privacyPsychologist = '''
INFORMATIVA SUL TRATTAMENTO DEI DATI PERSONALI – PROFESSIONISTI
(ai sensi degli artt. 13-14 del Regolamento UE 2016/679 – GDPR)

⚠ TESTO DI PROVA – sarà sostituito dal testo definitivo redatto dall'avvocato.

1. TITOLARE DEL TRATTAMENTO
Luminia Care S.r.l. (in fase di costituzione), con sede legale in [indirizzo da definire].
Contatto: privacy@luminiacare.it

2. DATI RACCOLTI
Oltre ai dati raccolti per gli utenti standard, per i professionisti vengono trattati: numero di iscrizione all'Albo, qualifica professionale, aree di specializzazione, indirizzo/i dello studio, biografia professionale, disponibilità e calendario degli appuntamenti.

3. FINALITÀ E BASE GIURIDICA
• Pubblicazione del profilo professionale sulla piattaforma — base: esecuzione del contratto (art. 6 par. 1 lett. b GDPR).
• Gestione degli appuntamenti con i clienti — base: esecuzione del contratto.
• Verifica dell'iscrizione all'Albo — base: legittimo interesse del Titolare (art. 6 par. 1 lett. f GDPR).

4. TRATTAMENTO DI DATI SANITARI
In qualità di professionista iscritto all'Albo, sei titolare autonomo del trattamento dei dati sanitari dei tuoi pazienti/clienti. Luminia Care agisce come responsabile del trattamento (art. 28 GDPR) esclusivamente per i dati necessari all'erogazione del servizio di piattaforma.

5. VISIBILITÀ DEI DATI
Il profilo professionale (nome, cognome, albo, specializzazioni, indirizzo studio, foto) è visibile agli utenti registrati della piattaforma.

6. CONSERVAZIONE
I dati sono conservati per tutta la durata del rapporto e per i 10 anni successivi.

7. DIRITTI DELL'INTERESSATO
Hai il diritto di accedere, rettificare, cancellare, limitare e opporti al trattamento, nonché alla portabilità dei dati. Scrivi a privacy@luminiacare.it.

8. DIRITTO DI RECLAMO
Hai il diritto di proporre reclamo al Garante per la protezione dei dati personali (www.garanteprivacy.it).
''';

class _PrivacySheet extends StatelessWidget {
  final bool isPsychologist;
  const _PrivacySheet({required this.isPsychologist});

  @override
  Widget build(BuildContext context) {
    final text = isPsychologist ? _privacyPsychologist : _privacyUser;
    final title = isPsychologist
        ? 'Privacy Policy — Professionisti'
        : 'Privacy Policy — Utenti';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.7,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Ho capito'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _GenderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.bgInverse : AppColors.bg,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: selected ? AppColors.bgInverse : AppColors.glassBorder,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: selected ? AppColors.textInverse : AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? AppColors.textInverse : AppColors.textSecondary,
            ),
          ),
        ]),
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

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final String? highlight;
  final bool selected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.selected,
    required this.onTap,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.bgInverse : AppColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.bgInverse : AppColors.glassBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Icon(
            selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
            size: 20,
            color: selected ? AppColors.textInverse : AppColors.textTertiary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.textInverse : AppColors.textPrimary,
                ),
              ),
              if (highlight != null) ...[
                const SizedBox(height: 2),
                Text(
                  highlight!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.textInverse : AppColors.primary,
                  ),
                ),
              ],
            ]),
          ),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(
              price,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: selected ? AppColors.textInverse : AppColors.textPrimary,
              ),
            ),
            Text(
              period,
              style: TextStyle(
                fontSize: 12,
                color: selected ? AppColors.textInverse : AppColors.textTertiary,
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTRATTO DI ABBONAMENTO
// ─────────────────────────────────────────────────────────────────────────────

const String _contractText = '''
CONTRATTO DI ABBONAMENTO – PROFESSIONISTI

⚠ TESTO DI PROVA – sarà sostituito dal testo definitivo redatto dall'avvocato.

1. OGGETTO
Il presente contratto disciplina l'abbonamento al servizio Luminia Care che consente al professionista iscritto all'Albo di pubblicare il proprio profilo, gestire appuntamenti e ricevere richieste dagli utenti della piattaforma.

2. PIANI E CORRISPETTIVI
• Piano mensile: € 9,99 al mese (IVA inclusa), rinnovo automatico ogni mese.
• Piano annuale: € 59,99 all'anno (IVA inclusa), rinnovo automatico ogni 12 mesi.
Il piano selezionato in fase di registrazione potrà essere modificato dalle impostazioni dell'account.

3. ATTIVAZIONE E PAGAMENTO
Nessun importo è dovuto al momento della registrazione. L'abbonamento diventa esigibile ed efficace soltanto dopo la verifica dell'iscrizione all'Albo da parte di Luminia Care. Solo a seguito dell'esito positivo della verifica il professionista sarà invitato a perfezionare il pagamento per la pubblicazione del profilo.

4. RINNOVO E DISDETTA
L'abbonamento si rinnova automaticamente alla scadenza al medesimo prezzo, salvo disdetta comunicata prima del rinnovo tramite le impostazioni dell'account o scrivendo a supporto@luminiacare.it.

5. DIRITTO DI RECESSO
Il professionista può recedere secondo i termini di legge. Il recesso comporta la cessazione della pubblicazione del profilo al termine del periodo già pagato.

6. OBBLIGHI DEL PROFESSIONISTA
Il professionista garantisce la veridicità dei dati forniti, la validità dell'iscrizione all'Albo e il rispetto del codice deontologico. Luminia Care si riserva di sospendere l'account in caso di dati non veritieri.

7. LIMITAZIONE DI RESPONSABILITÀ
Luminia Care fornisce esclusivamente il servizio tecnologico di piattaforma e non è parte del rapporto professionale tra il professionista e i suoi clienti/pazienti.

8. FORO COMPETENTE
Per ogni controversia è competente il foro di [città da definire].
''';

class _ContractSheet extends StatelessWidget {
  const _ContractSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Contratto di abbonamento',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: const Text(
                  _contractText,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.7,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Ho capito'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressFields {
  final viaCtrl  = TextEditingController();
  final civCtrl  = TextEditingController();
  final capCtrl  = TextEditingController();
  final provCtrl = TextEditingController();

  String get fullAddress =>
      '${viaCtrl.text.trim()} ${civCtrl.text.trim()}, '
      '${capCtrl.text.trim()} ${provCtrl.text.trim()}';

  void dispose() {
    viaCtrl.dispose(); civCtrl.dispose();
    capCtrl.dispose(); provCtrl.dispose();
  }
}
