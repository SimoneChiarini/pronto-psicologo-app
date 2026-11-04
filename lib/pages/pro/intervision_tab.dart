import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/specialization_data.dart';
import '../../services/pro_api.dart';
import '../../services/realtime_service.dart';
import '../../theme/app_theme.dart';
import 'group_page.dart';
import 'pro_widgets.dart';

/// Intervisioni: i miei gruppi, inviti ricevuti, gruppi pubblici da scoprire.
class IntervisionTab extends StatefulWidget {
  const IntervisionTab({super.key});

  @override
  State<IntervisionTab> createState() => _IntervisionTabState();
}

class _IntervisionTabState extends State<IntervisionTab> with AutomaticKeepAliveClientMixin {
  final _api = ProApi();
  final _search = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _mine = [];
  List<Map<String, dynamic>> _invites = [];
  List<Map<String, dynamic>> _discover = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  StreamSubscription<Map<String, dynamic>>? _notifSub;

  @override
  void initState() {
    super.initState();
    _load();
    const types = {'group_invite', 'group_approved', 'group_request', 'case_new', 'case_message'};
    _notifSub = RealtimeService.instance.notifications.where((n) => types.contains(n['type'])).listen((_) => _load());
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await Future.wait([_api.myGroups(), _api.invitations(), _api.discoverGroups(_search.text.trim())]);
      if (!mounted) return;
      setState(() { _mine = r[0]; _invites = r[1]; _discover = r[2]; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showProError(context, e);
      }
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final d = await _api.discoverGroups(_search.text.trim());
        if (mounted) setState(() => _discover = d);
      } catch (_) {}
    });
  }

  Future<void> _open(String id) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => GroupPage(groupId: id)));
    _load();
  }

  Future<void> _join(Map<String, dynamic> g, {required bool invited}) async {
    if (!await confirmConfidentiality(context)) return;
    try {
      final status = await _api.joinGroup(g['id'] as String);
      await _load();
      if (!mounted) return;
      if (status == 'ACTIVE') {
        _open(g['id'] as String);
      } else {
        showProInfo(context, 'Richiesta inviata: ti avviseremo quando verrà accettata');
      }
    } catch (e) {
      if (mounted) showProError(context, e);
    }
  }

  Future<void> _create() async {
    final id = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const CreateGroupPage()));
    await _load();
    if (id != null && mounted) _open(id);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-group',
        onPressed: _create,
        icon: const Icon(Icons.group_add_rounded),
        label: const Text('Nuovo gruppo'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(12, 4, 12, 90), children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              'Confronto tra pari su casi clinici, in forma anonima e senza giudizio.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
          if (_invites.isNotEmpty) ...[
            const ProSectionTitle('Inviti ricevuti'),
            for (final g in _invites)
              _GroupCard(
                g: g,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  TextButton(
                    onPressed: () async {
                      try {
                        await _api.declineInvite(g['id'] as String);
                        _load();
                      } catch (e) {
                        if (context.mounted) showProError(context, e);
                      }
                    },
                    child: const Text('Rifiuta'),
                  ),
                  ElevatedButton(onPressed: () => _join(g, invited: true), child: const Text('Entra')),
                ]),
              ),
          ],
          ProSectionTitle('I miei gruppi (${_mine.length})'),
          if (_mine.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Non fai ancora parte di nessun gruppo. Creane uno o unisciti a un gruppo pubblico.',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
            ),
          for (final g in _mine) _GroupCard(g: g, onTap: () => _open(g['id'] as String)),
          const ProSectionTitle('Scopri gruppi pubblici'),
          TextField(
            controller: _search,
            onChanged: _onSearch,
            decoration: const InputDecoration(
              hintText: 'Cerca per nome o argomento',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          if (_discover.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Nessun gruppo pubblico trovato.', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
            ),
          for (final g in _discover)
            _GroupCard(
              g: g,
              trailing: g['myStatus'] == 'REQUESTED'
                  ? const ProChip('Richiesta inviata', icon: Icons.schedule_rounded)
                  : g['myStatus'] == 'INVITED'
                      ? ElevatedButton(onPressed: () => _join(g, invited: true), child: const Text('Entra'))
                      : OutlinedButton(onPressed: () => _join(g, invited: false), child: const Text('Chiedi di entrare')),
            ),
        ]),
      ),
    );
  }
}

String topicLabel(String code) {
  for (final m in kTaxonomy) {
    if (m.code == code) return m.label;
  }
  return code;
}

class _GroupCard extends StatelessWidget {
  final Map<String, dynamic> g;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _GroupCard({required this.g, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final topics = (g['topics'] as List? ?? []).cast<String>();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(g['visibility'] == 'PRIVATE' ? Icons.lock_outline_rounded : Icons.public_rounded,
                  size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(g['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              ),
              if (g['myRole'] == 'OWNER') const ProChip('Fondatore'),
              if (g['myRole'] == 'MODERATOR') const ProChip('Moderatore'),
            ]),
            if (g['description'] != null && (g['description'] as String).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(g['description'] as String,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            ],
            if (topics.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: [for (final t in topics.take(4)) ProChip(topicLabel(t))]),
            ],
            const SizedBox(height: 8),
            Row(children: [
              Text('${g['memberCount']} membri · ${g['openCases']} casi aperti',
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              const Spacer(),
              if (trailing != null) trailing!,
            ]),
          ]),
        ),
      ),
    );
  }
}

/// Creazione di un gruppo di intervisione.
class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _name = TextEditingController();
  final _desc = TextEditingController();
  String _visibility = 'PUBLIC';
  final Set<String> _topics = {};
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 3) {
      showProError(context, 'Il nome deve avere almeno 3 caratteri');
      return;
    }
    if (!await confirmConfidentiality(context)) return;
    setState(() => _saving = true);
    try {
      final id = await ProApi().createGroup(
        name: _name.text.trim(),
        description: _desc.text.trim(),
        visibility: _visibility,
        topics: _topics.toList(),
      );
      if (mounted) Navigator.pop(context, id);
    } catch (e) {
      if (mounted) {
        showProError(context, e);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo gruppo di intervisione')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(
          controller: _name,
          maxLength: 120,
          decoration: const InputDecoration(labelText: 'Nome del gruppo', hintText: 'Es. "Intervisione età evolutiva"'),
        ),
        TextField(
          controller: _desc,
          maxLines: 3,
          maxLength: 2000,
          decoration: const InputDecoration(
            labelText: 'Descrizione',
            hintText: 'Di cosa vi occupate, orientamenti benvenuti, ritmo degli incontri…',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        const Text('Visibilità', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'PUBLIC', label: Text('Pubblico'), icon: Icon(Icons.public_rounded)),
            ButtonSegment(value: 'PRIVATE', label: Text('Privato'), icon: Icon(Icons.lock_outline_rounded)),
          ],
          selected: {_visibility},
          onSelectionChanged: (s) => setState(() => _visibility = s.first),
        ),
        const SizedBox(height: 4),
        Text(
          _visibility == 'PUBLIC'
              ? 'Compare nella ricerca: i colleghi chiedono di entrare e tu approvi.'
              : 'Non compare nella ricerca: si entra solo su tuo invito.',
          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 16),
        const Text('Argomenti (facoltativo)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final m in kTaxonomy)
            FilterChip(
              label: Text(m.label, style: const TextStyle(fontSize: 12)),
              selected: _topics.contains(m.code),
              onSelected: (on) => setState(() {
                if (on && _topics.length < 10) {
                  _topics.add(m.code);
                } else {
                  _topics.remove(m.code);
                }
              }),
            ),
        ]),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Crea gruppo'),
        ),
      ]),
    );
  }
}
