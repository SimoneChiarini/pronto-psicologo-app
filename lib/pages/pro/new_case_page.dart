import 'package:flutter/material.dart';
import '../../services/pro_api.dart';
import '../../theme/app_theme.dart';
import 'pro_widgets.dart';

/// Scheda guidata per presentare un caso: campi pensati per non contenere dati identificativi.
class NewCasePage extends StatefulWidget {
  final String groupId;
  const NewCasePage({super.key, required this.groupId});

  @override
  State<NewCasePage> createState() => _NewCasePageState();
}

class _NewCasePageState extends State<NewCasePage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _problem = TextEditingController();
  final _question = TextEditingController();
  String? _ageRange;
  String? _setting;
  bool _anonymized = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _problem.dispose();
    _question.dispose();
    super.dispose();
  }

  Future<void> _submit({bool acknowledge = false}) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_anonymized) {
      showProError(context, 'Conferma di aver reso anonimo il caso');
      return;
    }
    setState(() => _saving = true);
    try {
      final id = await ProApi().createCase(widget.groupId, {
        'title': _title.text.trim(),
        if (_ageRange != null) 'ageRange': _ageRange,
        if (_setting != null) 'setting': _setting,
        'presentingProblem': _problem.text.trim(),
        'question': _question.text.trim(),
      }, acknowledgeWarnings: acknowledge);
      if (mounted) Navigator.pop(context, id);
    } on AnonymizationWarning catch (w) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (await confirmDespiteWarnings(context, w.warnings)) return _submit(acknowledge: true);
    } catch (e) {
      if (mounted) showProError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presenta un caso')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const AnonymityReminder(),
          const SizedBox(height: 16),
          TextFormField(
            controller: _title,
            maxLength: 160,
            decoration: const InputDecoration(
              labelText: 'Titolo',
              hintText: 'Es. "Resistenze al cambiamento in un percorso con un adolescente"',
            ),
            validator: (v) => (v?.trim().length ?? 0) < 3 ? 'Almeno 3 caratteri' : null,
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _ageRange,
                decoration: const InputDecoration(labelText: 'Fascia d\'età'),
                items: [for (final a in kAgeRanges) DropdownMenuItem(value: a, child: Text(a))],
                onChanged: (v) => setState(() => _ageRange = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _setting,
                decoration: const InputDecoration(labelText: 'Contesto'),
                items: [for (final e in kSettings.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
                onChanged: (v) => setState(() => _setting = v),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          TextFormField(
            controller: _problem,
            minLines: 5,
            maxLines: 12,
            maxLength: 5000,
            decoration: const InputDecoration(
              labelText: 'Situazione clinica',
              hintText: 'Problema portato, andamento del percorso, ipotesi di lavoro…',
              alignLabelWithHint: true,
            ),
            validator: (v) => (v?.trim().length ?? 0) < 10 ? 'Descrivi la situazione (almeno 10 caratteri)' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _question,
            minLines: 2,
            maxLines: 5,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'Cosa chiedi al gruppo?',
              hintText: 'La domanda precisa su cui vuoi un confronto',
              alignLabelWithHint: true,
            ),
            validator: (v) => (v?.trim().length ?? 0) < 5 ? 'Scrivi la tua domanda' : null,
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _anonymized,
            onChanged: (v) => setState(() => _anonymized = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Confermo di aver rimosso nomi, luoghi, date e ogni dettaglio che possa rendere riconoscibile il paziente',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _saving ? null : () => _submit(),
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textInverse))
                : const Text('Pubblica nel gruppo'),
          ),
        ]),
      ),
    );
  }
}
