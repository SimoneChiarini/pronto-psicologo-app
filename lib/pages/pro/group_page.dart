import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/pro_api.dart';
import '../../services/realtime_service.dart';
import '../../theme/app_theme.dart';
import 'case_page.dart';
import 'new_case_page.dart';
import 'pro_widgets.dart';

/// Stanza di intervisione o di supervisione: Casi · Incontri · Membri.
class GroupPage extends StatefulWidget {
  final String groupId;
  const GroupPage({super.key, required this.groupId});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  final _api = ProApi();
  Map<String, dynamic>? _group;
  List<Map<String, dynamic>> _cases = [];
  bool _loading = true;
  String? _error;

  StreamSubscription<Map<String, dynamic>>? _notifSub;

  @override
  void initState() {
    super.initState();
    _load();
    _notifSub = RealtimeService.instance.notifications
        .where((n) => n['groupId'] == widget.groupId)
        .listen((_) => _load());
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([_api.group(widget.groupId), _api.cases(widget.groupId)]);
      if (!mounted) return;
      setState(() {
        _group = results[0] as Map<String, dynamic>;
        _cases = results[1] as List<Map<String, dynamic>>;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() { _error = errorText(e); _loading = false; });
    }
  }

  bool get _isSupervision => _group?['type'] == 'SUPERVISION';
  bool get _archived => _group?['archived'] == true;
  bool get _canModerate => _group?['canModerate'] == true;

  Future<void> _run(Future<void> Function() action, {String? ok}) async {
    try {
      await action();
      await _load();
      if (ok != null && mounted) showProInfo(context, ok);
    } catch (e) {
      if (mounted) showProError(context, e);
    }
  }

  Future<void> _newCase() async {
    final id = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => NewCasePage(groupId: widget.groupId)),
    );
    await _load();
    if (id != null && mounted) _openCase(id);
  }

  Future<void> _openCase(String id) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CasePage(caseId: id)));
    _load();
  }

  void _addMeeting() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddMeetingSheet(
        onSave: (title, startsAt, url) async {
          await _api.createMeeting(widget.groupId, title: title, startsAt: startsAt, url: url);
          await _load();
        },
      ),
    );
  }

  Future<void> _invite() async {
    final picked = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ColleaguePickerDialog(groupId: widget.groupId),
    );
    if (picked == null) return;
    await _run(() => _api.invite(widget.groupId, picked['id'] as String), ok: 'Invito inviato a ${picked['name']}');
  }

  Future<void> _menu(String action) async {
    switch (action) {
      case 'edit':
        final changed = await showDialog<bool>(context: context, builder: (_) => _EditGroupDialog(group: _group!));
        if (changed == true) _load();
      case 'archive':
        final ok = await _confirm('Archiviare il gruppo?',
            'Il gruppo diventerà di sola lettura e non comparirà più nella ricerca.');
        if (ok) await _run(() => _api.archiveGroup(widget.groupId), ok: 'Gruppo archiviato');
      case 'leave':
        final ok = await _confirm('Lasciare il gruppo?', 'Non vedrai più casi e discussioni.');
        if (!ok) return;
        try {
          await _api.leaveGroup(widget.groupId);
          if (mounted) Navigator.pop(context, true);
        } catch (e) {
          if (mounted) showProError(context, e);
        }
    }
  }

  Future<bool> _confirm(String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Conferma')),
          ],
        ),
      ) ==
      true;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(_error!, style: const TextStyle(color: AppColors.error))));
    }
    final g = _group!;
    final myRole = g['myRole'] as String;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(g['name'] as String, overflow: TextOverflow.ellipsis),
            Text(
              _isSupervision ? 'Supervisione' : (g['visibility'] == 'PRIVATE' ? 'Intervisione · privato' : 'Intervisione · pubblico'),
              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
          ]),
          actions: [
            if (!_isSupervision)
              PopupMenuButton<String>(
                onSelected: _menu,
                itemBuilder: (_) => [
                  if (_canModerate && !_archived) const PopupMenuItem(value: 'edit', child: Text('Modifica gruppo')),
                  if (myRole == 'OWNER' && !_archived) const PopupMenuItem(value: 'archive', child: Text('Archivia gruppo')),
                  if (myRole != 'OWNER') const PopupMenuItem(value: 'leave', child: Text('Lascia il gruppo')),
                ],
              ),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'Casi'), Tab(text: 'Incontri'), Tab(text: 'Membri')]),
        ),
        floatingActionButton: _archived
            ? null
            : Builder(
                builder: (ctx) => FloatingActionButton.extended(
                  onPressed: _newCase,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Presenta un caso'),
                ),
              ),
        body: TabBarView(children: [
          _casesTab(g),
          MeetingsList(
            meetings: (g['meetings'] as List).cast<Map<String, dynamic>>(),
            canAdd: !_archived,
            onAdd: _addMeeting,
            onDelete: (id) => _run(() => _api.deleteMeeting(id)),
          ),
          _membersTab(g),
        ]),
      ),
    );
  }

  Widget _casesTab(Map<String, dynamic> g) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 90), children: [
        if (g['description'] != null && (g['description'] as String).isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(g['description'] as String, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
        if (_archived)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: ProChip('Archiviato · sola lettura', icon: Icons.inventory_2_outlined),
          ),
        if (_cases.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 60),
            child: Center(
              child: Text('Nessun caso ancora.\nPresentane uno per avviare il confronto.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.textTertiary)),
            ),
          ),
        for (final c in _cases)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              onTap: () => _openCase(c['id'] as String),
              leading: ColleagueAvatar(colleague: c['author'] as Map<String, dynamic>?),
              title: Text(c['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${(c['author'] as Map?)?['name'] ?? 'Collega'} · ${c['messageCount']} interventi · ${formatDateTime(c['lastActivityAt'] as String?)}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: c['status'] == 'CLOSED'
                  ? const ProChip('Risolto', color: AppColors.success)
                  : const Icon(Icons.chevron_right_rounded),
            ),
          ),
      ]),
    );
  }

  Widget _membersTab(Map<String, dynamic> g) {
    final members = (g['members'] as List).cast<Map<String, dynamic>>();
    final active = members.where((m) => m['status'] == 'ACTIVE').toList();
    final requested = members.where((m) => m['status'] == 'REQUESTED').toList();
    final invited = members.where((m) => m['status'] == 'INVITED').toList();
    final isOwner = g['myRole'] == 'OWNER';

    Widget tile(Map<String, dynamic> m, {List<Widget> actions = const []}) => ListTile(
          leading: ColleagueAvatar(colleague: m),
          title: Text(m['name'] as String),
          subtitle: Text([
            kRoleLabels[m['role']] ?? '',
            if (m['isPsychotherapist'] == true) 'Psicoterapeuta',
          ].where((s) => s.isNotEmpty).join(' · ')),
          trailing: actions.isEmpty ? null : Row(mainAxisSize: MainAxisSize.min, children: actions),
        );

    return ListView(padding: const EdgeInsets.all(12), children: [
      if (_canModerate && !_archived && !_isSupervision)
        OutlinedButton.icon(
          onPressed: _invite,
          icon: const Icon(Icons.person_add_alt_rounded, size: 18),
          label: const Text('Invita un collega'),
        ),
      if (requested.isNotEmpty) ...[
        const ProSectionTitle('Richieste di ingresso'),
        for (final m in requested)
          tile(m, actions: [
            IconButton(
              tooltip: 'Accetta',
              icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
              onPressed: () => _run(() => _api.approveMember(widget.groupId, m['id'] as String), ok: '${m['name']} è entrato nel gruppo'),
            ),
            IconButton(
              tooltip: 'Rifiuta',
              icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
              onPressed: () => _run(() => _api.removeMember(widget.groupId, m['id'] as String)),
            ),
          ]),
      ],
      if (invited.isNotEmpty) ...[
        const ProSectionTitle('Invitati'),
        for (final m in invited)
          tile(m, actions: [
            IconButton(
              tooltip: 'Ritira invito',
              icon: const Icon(Icons.close_rounded),
              onPressed: () => _run(() => _api.removeMember(widget.groupId, m['id'] as String)),
            ),
          ]),
      ],
      ProSectionTitle('Membri (${active.length})'),
      for (final m in active)
        tile(m, actions: [
          if (_canModerate && !_isSupervision && m['role'] != 'OWNER' && m['role'] != 'SUPERVISOR')
            PopupMenuButton<String>(
              onSelected: (a) {
                if (a == 'mod') _run(() => _api.setModerator(widget.groupId, m['id'] as String, m['role'] != 'MODERATOR'));
                if (a == 'remove') _run(() => _api.removeMember(widget.groupId, m['id'] as String));
              },
              itemBuilder: (_) => [
                if (isOwner)
                  PopupMenuItem(value: 'mod', child: Text(m['role'] == 'MODERATOR' ? 'Togli moderatore' : 'Rendi moderatore')),
                const PopupMenuItem(value: 'remove', child: Text('Rimuovi dal gruppo')),
              ],
            ),
        ]),
    ]);
  }
}

/// Ricerca di un collega verificato da invitare.
class ColleaguePickerDialog extends StatefulWidget {
  final String? groupId;
  final Set<String> exclude;
  const ColleaguePickerDialog({super.key, this.groupId, this.exclude = const {}});

  @override
  State<ColleaguePickerDialog> createState() => _ColleaguePickerDialogState();
}

class _ColleaguePickerDialogState extends State<ColleaguePickerDialog> {
  final _q = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(v));
  }

  Future<void> _search(String v) async {
    if (v.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final r = await ProApi().searchColleagues(v.trim(), groupId: widget.groupId);
      if (mounted) setState(() => _results = r.where((c) => !widget.exclude.contains(c['id'])).toList());
    } catch (e) {
      if (mounted) showProError(context, e);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cerca un collega'),
      content: SizedBox(
        width: 420,
        height: 360,
        child: Column(children: [
          TextField(
            controller: _q,
            autofocus: true,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: 'Nome o cognome',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searching
                  ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Compaiono solo psicologi verificati con abbonamento attivo.',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          Expanded(
            child: ListView(children: [
              for (final c in _results)
                ListTile(
                  leading: ColleagueAvatar(colleague: c),
                  title: Text(c['name'] as String),
                  subtitle: c['isPsychotherapist'] == true ? const Text('Psicoterapeuta') : null,
                  onTap: () => Navigator.pop(context, c),
                ),
            ]),
          ),
        ]),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Chiudi'))],
    );
  }
}

class _EditGroupDialog extends StatefulWidget {
  final Map<String, dynamic> group;
  const _EditGroupDialog({required this.group});

  @override
  State<_EditGroupDialog> createState() => _EditGroupDialogState();
}

class _EditGroupDialogState extends State<_EditGroupDialog> {
  late final _name = TextEditingController(text: widget.group['name'] as String);
  late final _desc = TextEditingController(text: widget.group['description'] as String? ?? '');
  late String _visibility = widget.group['visibility'] as String;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ProApi().updateGroup(widget.group['id'] as String, {
        'name': _name.text.trim(),
        'description': _desc.text.trim(),
        'visibility': _visibility,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        showProError(context, e);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifica gruppo'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nome')),
          const SizedBox(height: 10),
          TextField(controller: _desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Descrizione')),
          const SizedBox(height: 10),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'PUBLIC', label: Text('Pubblico'), icon: Icon(Icons.public_rounded)),
              ButtonSegment(value: 'PRIVATE', label: Text('Privato'), icon: Icon(Icons.lock_outline_rounded)),
            ],
            selected: {_visibility},
            onSelectionChanged: (s) => setState(() => _visibility = s.first),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
        ElevatedButton(onPressed: _saving ? null : _save, child: const Text('Salva')),
      ],
    );
  }
}
