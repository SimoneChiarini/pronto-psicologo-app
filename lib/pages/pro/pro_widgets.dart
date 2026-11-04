import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

// ── Etichette ───────────────────────────────────────────────

const kAgeRanges = ['0-12', '13-17', '18-25', '26-40', '41-60', '61+'];

const kSettings = {
  'PRIVATE': 'Studio privato',
  'PUBLIC_SERVICE': 'Servizio pubblico',
  'ONLINE': 'Online',
  'OTHER': 'Altro',
};

const kRoleLabels = {
  'OWNER': 'Fondatore',
  'MODERATOR': 'Moderatore',
  'SUPERVISOR': 'Supervisore',
  'MEMBER': 'Membro',
};

const kSupervisionStatus = {
  'REQUESTED': 'In attesa di risposta',
  'ACCEPTED': 'In corso',
  'DECLINED': 'Rifiutata',
  'COMPLETED': 'Conclusa',
  'CANCELLED': 'Annullata',
};

String formatEur(int cents) {
  final euros = cents ~/ 100;
  final rest = (cents % 100).toString().padLeft(2, '0');
  return '€ $euros,$rest';
}

String formatDateTime(String? iso) {
  final d = DateTime.tryParse(iso ?? '')?.toLocal();
  if (d == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

String errorText(Object e) => e.toString().replaceFirst('Exception: ', '');

void showProError(BuildContext context, Object e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(errorText(e)), backgroundColor: AppColors.error),
  );
}

void showProInfo(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

Future<void> openExternal(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) showProError(context, 'Impossibile aprire il link');
  }
}

// ── Widget ──────────────────────────────────────────────────

class ColleagueAvatar extends StatelessWidget {
  final Map<String, dynamic>? colleague;
  final double radius;
  const ColleagueAvatar({super.key, this.colleague, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    final img = ApiService.resolveUrl(colleague?['profileImage'] as String?);
    final name = (colleague?['name'] as String?) ?? '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.borderFaint,
      backgroundImage: img != null ? NetworkImage(img) : null,
      child: img == null
          ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.w700, color: AppColors.textSecondary))
          : null,
    );
  }
}

class ProChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  const ProChip(this.label, {super.key, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: c), const SizedBox(width: 4)],
        Text(label, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class ProSectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const ProSectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(children: [
        Expanded(
          child: Text(text.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.textTertiary)),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// Promemoria deontologico mostrato dove si scrive di un caso.
class AnonymityReminder extends StatelessWidget {
  const AnonymityReminder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.shield_outlined, size: 18, color: AppColors.warning),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Condividi solo le informazioni strettamente necessarie e in forma anonima: '
            'niente nomi, luoghi, date precise, lavoro o dettagli che rendano riconoscibile il paziente.',
            style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textSecondary),
          ),
        ),
      ]),
    );
  }
}

/// Il server ha trovato possibili identificativi: chiede di rivedere o confermare.
/// Ritorna true se l'autore conferma che il testo è anonimo.
Future<bool> confirmDespiteWarnings(BuildContext context, List<String> warnings) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Controlla l\'anonimato'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Il testo sembra contenere:', style: TextStyle(fontSize: 13)),
        const SizedBox(height: 8),
        ...warnings.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                const SizedBox(width: 6),
                Expanded(child: Text(w, style: const TextStyle(fontSize: 13))),
              ]),
            )),
        const SizedBox(height: 10),
        const Text(
          'Se si tratta di dati che possono identificare il paziente, torna indietro e rimuovili. '
          'Il controllo è automatico e può sbagliare: se il testo è già anonimo puoi pubblicare.',
          style: TextStyle(fontSize: 12, color: AppColors.textTertiary, height: 1.4),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Modifica il testo')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('È anonimo, pubblica')),
      ],
    ),
  );
  return ok == true;
}

/// Patto di riservatezza richiesto per creare o entrare in un gruppo.
Future<bool> confirmConfidentiality(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Impegno alla riservatezza'),
      content: const Text(
        'Partecipando mi impegno a:\n\n'
        '• condividere casi solo in forma anonima e con le sole informazioni necessarie;\n'
        '• non diffondere fuori dal gruppo quanto letto o discusso;\n'
        '• mantenere un confronto rispettoso e non giudicante verso colleghi e pazienti.',
        style: TextStyle(fontSize: 13, height: 1.45),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Accetto')),
      ],
    ),
  );
  return ok == true;
}

/// Sheet per aggiungere un incontro: crea la stanza sul servizio scelto, incolla il link.
class AddMeetingSheet extends StatefulWidget {
  final Future<void> Function(String title, DateTime startsAt, String url) onSave;
  const AddMeetingSheet({super.key, required this.onSave});

  @override
  State<AddMeetingSheet> createState() => _AddMeetingSheetState();
}

class _AddMeetingSheetState extends State<AddMeetingSheet> {
  final _title = TextEditingController(text: 'Incontro di gruppo');
  final _url = TextEditingController();
  DateTime _startsAt = DateTime.now().add(const Duration(days: 1)).copyWith(minute: 0, second: 0);
  bool _saving = false;

  static const _creators = [
    ('Google Meet', 'https://meet.google.com/new', Icons.videocam_outlined),
    ('Teams', 'https://teams.microsoft.com/l/meeting/new', Icons.groups_outlined),
    ('Zoom', 'https://zoom.us/start/videomeeting', Icons.video_call_outlined),
  ];

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_startsAt));
    if (t == null) return;
    setState(() => _startsAt = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _save() async {
    if (_title.text.trim().length < 3 || _url.text.trim().isEmpty) {
      showProError(context, 'Inserisci titolo e link della stanza');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(_title.text.trim(), _startsAt, _url.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showProError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Nuovo incontro', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Crea la stanza sul servizio che preferisci, poi copia qui il link.',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in _creators)
              OutlinedButton.icon(
                onPressed: () => openExternal(context, c.$2),
                icon: Icon(c.$3, size: 16),
                label: Text('Crea su ${c.$1}', style: const TextStyle(fontSize: 12)),
              ),
          ]),
          const SizedBox(height: 14),
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Titolo')),
          const SizedBox(height: 10),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Link della stanza',
              hintText: 'https://meet.google.com/...',
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text(formatDateTime(_startsAt.toIso8601String())),
            subtitle: const Text('Data e ora'),
            trailing: const Icon(Icons.edit_calendar_outlined, size: 18),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Salva incontro'),
          ),
        ]),
      ),
    );
  }
}

/// Lista incontri con "Partecipa" (apre il link) ed eliminazione.
class MeetingsList extends StatelessWidget {
  final List<Map<String, dynamic>> meetings;
  final bool canAdd;
  final VoidCallback onAdd;
  final Future<void> Function(String meetingId) onDelete;

  const MeetingsList({
    super.key,
    required this.meetings,
    required this.canAdd,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(12), children: [
      if (canAdd)
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Nuovo incontro in videochiamata'),
        ),
      if (meetings.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(
            child: Text('Nessun incontro in programma', style: TextStyle(color: AppColors.textTertiary)),
          ),
        ),
      for (final m in meetings)
        Card(
          margin: const EdgeInsets.only(top: 10),
          child: ListTile(
            leading: const Icon(Icons.videocam_outlined),
            title: Text(m['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(formatDateTime(m['startsAt'] as String?)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              ElevatedButton(
                onPressed: () => openExternal(context, m['url'] as String),
                child: const Text('Partecipa'),
              ),
              if (m['canDelete'] == true)
                IconButton(
                  tooltip: 'Elimina',
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  onPressed: () => onDelete(m['id'] as String),
                ),
            ]),
          ),
        ),
    ]);
  }
}
