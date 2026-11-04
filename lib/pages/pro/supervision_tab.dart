import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/pro_api.dart';
import '../../services/realtime_service.dart';
import '../../theme/app_theme.dart';
import 'group_page.dart';
import 'pro_widgets.dart';

/// Supervisioni: richieste fatte, richieste ricevute (se supervisore), profilo supervisore.
class SupervisionTab extends StatefulWidget {
  const SupervisionTab({super.key});

  @override
  State<SupervisionTab> createState() => _SupervisionTabState();
}

class _SupervisionTabState extends State<SupervisionTab> with AutomaticKeepAliveClientMixin {
  final _api = ProApi();
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _asSupervisor = [];
  List<Map<String, dynamic>> _asParticipant = [];
  bool _loading = true;

  StreamSubscription<Map<String, dynamic>>? _notifSub;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
    _notifSub = RealtimeService.instance.notifications.where((n) => n['type'] == 'supervision').listen((_) => _load());
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await Future.wait([_api.mySupervisorProfile(), _api.supervisions()]);
      if (!mounted) return;
      final s = r[1] as Map<String, dynamic>;
      setState(() {
        _profile = r[0] as Map<String, dynamic>?;
        _asSupervisor = (s['asSupervisor'] as List).cast<Map<String, dynamic>>();
        _asParticipant = (s['asParticipant'] as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showProError(context, e);
      }
    }
  }

  Future<void> _openDetail(String id) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => SupervisionDetailPage(supervisionId: id)));
    _load();
  }

  Future<void> _findSupervisor() async {
    final id = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const FindSupervisorPage()));
    await _load();
    if (id != null && mounted) _openDetail(id);
  }

  Future<void> _editProfile() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => SupervisorProfilePage(initial: _profile)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    final pendingForMe = _asSupervisor.where((s) => s['status'] == 'REQUESTED').length;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'find-supervisor',
        onPressed: _findSupervisor,
        icon: const Icon(Icons.support_agent_rounded),
        label: const Text('Chiedi una supervisione'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(12, 4, 12, 90), children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              'Chiedi aiuto su un caso a un collega più esperto, da solo o insieme ad altri colleghi.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
          _SupervisorProfileCard(profile: _profile, pendingRequests: pendingForMe, onEdit: _editProfile, onRefresh: _load),
          if (_asSupervisor.isNotEmpty) ...[
            const ProSectionTitle('Come supervisore'),
            for (final s in _asSupervisor) _SupervisionCard(s: s, onTap: () => _openDetail(s['id'] as String)),
          ],
          ProSectionTitle('Le mie richieste (${_asParticipant.length})'),
          if (_asParticipant.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Non hai ancora richiesto supervisioni.', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
            ),
          for (final s in _asParticipant) _SupervisionCard(s: s, onTap: () => _openDetail(s['id'] as String)),
        ]),
      ),
    );
  }
}

class _SupervisorProfileCard extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final int pendingRequests;
  final VoidCallback onEdit;
  final VoidCallback onRefresh;
  const _SupervisorProfileCard({required this.profile, required this.pendingRequests, required this.onEdit, required this.onRefresh});

  Future<void> _connect(BuildContext context) async {
    try {
      final url = await ProApi().connectOnboardingUrl();
      if (context.mounted) await openExternal(context, url);
    } catch (e) {
      if (context.mounted) showProError(context, e);
    }
  }

  Future<void> _dashboard(BuildContext context) async {
    try {
      final url = await ProApi().connectDashboardUrl();
      if (context.mounted) await openExternal(context, url);
    } catch (e) {
      if (context.mounted) showProError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = profile;
    if (p == null) {
      return Card(
        margin: const EdgeInsets.only(top: 12),
        child: ListTile(
          leading: const Icon(Icons.school_outlined),
          title: const Text('Offri supervisione', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Rendi disponibile la tua esperienza ai colleghi e imposta le tue tariffe.'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: onEdit,
        ),
      );
    }
    final active = p['active'] == true;
    final payouts = p['payoutsEnabled'] == true;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.school_outlined, size: 18),
            const SizedBox(width: 8),
            const Expanded(child: Text('Il tuo profilo da supervisore', style: TextStyle(fontWeight: FontWeight.w700))),
            TextButton(onPressed: onEdit, child: const Text('Modifica')),
          ]),
          Wrap(spacing: 6, runSpacing: 6, children: [
            ProChip(active ? 'Visibile ai colleghi' : 'Non attivo', color: active ? AppColors.success : AppColors.textTertiary),
            ProChip('Individuale ${formatEur(p['priceIndividualCents'] as int)}'),
            ProChip('Gruppo ${formatEur(p['pricePerParticipantCents'] as int)} a persona'),
            if (pendingRequests > 0) ProChip('$pendingRequests richieste da valutare', color: AppColors.warning),
          ]),
          const SizedBox(height: 10),
          if (!payouts) ...[
            Text(
              p['paymentsSetUp'] == true
                  ? 'Completa la configurazione degli incassi su Stripe per comparire nella ricerca.'
                  : 'Per ricevere i pagamenti configura il tuo conto incassi (Stripe). La piattaforma trattiene il ${p['feePercent']}%.',
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(children: [
              ElevatedButton.icon(
                onPressed: () => _connect(context),
                icon: const Icon(Icons.account_balance_outlined, size: 18),
                label: Text(p['paymentsSetUp'] == true ? 'Completa configurazione' : 'Configura incassi'),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: onRefresh, child: const Text('Ho finito, aggiorna')),
            ]),
          ] else
            TextButton.icon(
              onPressed: () => _dashboard(context),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Incassi e bonifici (Stripe)'),
            ),
        ]),
      ),
    );
  }
}

class _SupervisionCard extends StatelessWidget {
  final Map<String, dynamic> s;
  final VoidCallback onTap;
  const _SupervisionCard({required this.s, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = s['status'] as String;
    final color = switch (status) {
      'REQUESTED' => AppColors.warning,
      'ACCEPTED' => AppColors.success,
      'DECLINED' || 'CANCELLED' => AppColors.textTertiary,
      _ => AppColors.textSecondary,
    };
    final needsPayment = status == 'ACCEPTED' && s['isSupervisor'] != true &&
        s['myStatus'] == 'CONFIRMED' && s['myPaymentStatus'] != 'PAID';
    final needsConfirm = s['myStatus'] == 'INVITED' && (status == 'REQUESTED' || status == 'ACCEPTED');
    final other = s['isSupervisor'] == true ? s['createdBy'] : s['supervisor'];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: ColleagueAvatar(colleague: other as Map<String, dynamic>?),
        title: Text(s['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(spacing: 6, runSpacing: 4, children: [
            ProChip(kSupervisionStatus[status] ?? status, color: color),
            ProChip(s['mode'] == 'GROUP' ? 'Di gruppo' : 'Individuale'),
            if (needsPayment) const ProChip('Da pagare', color: AppColors.error, icon: Icons.payments_outlined),
            if (needsConfirm) const ProChip('Sei stato invitato', color: AppColors.warning),
          ]),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

// ── Dettaglio supervisione ──────────────────────────────────

class SupervisionDetailPage extends StatefulWidget {
  final String supervisionId;
  const SupervisionDetailPage({super.key, required this.supervisionId});

  @override
  State<SupervisionDetailPage> createState() => _SupervisionDetailPageState();
}

class _SupervisionDetailPageState extends State<SupervisionDetailPage> {
  final _api = ProApi();
  Map<String, dynamic>? _s;
  bool _loading = true;
  bool _busy = false;
  StreamSubscription<Map<String, dynamic>>? _notifSub;

  @override
  void initState() {
    super.initState();
    _load();
    // Es. pagamento confermato dal webhook mentre si è su questa pagina
    _notifSub = RealtimeService.instance.notifications
        .where((n) => n['supervisionId'] == widget.supervisionId)
        .listen((_) => _load());
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final s = await _api.supervision(widget.supervisionId);
      if (mounted) setState(() { _s = s; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showProError(context, e);
      }
    }
  }

  Future<void> _do(Future<void> Function() action, {String? ok}) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
      if (ok != null && mounted) showProInfo(context, ok);
    } catch (e) {
      if (mounted) showProError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pay() async {
    setState(() => _busy = true);
    try {
      final url = await _api.supervisionCheckoutUrl(widget.supervisionId);
      if (mounted) await openExternal(context, url);
    } catch (e) {
      if (mounted) showProError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _enterRoom() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => GroupPage(groupId: _s!['groupId'] as String)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final s = _s;
    if (s == null) return Scaffold(appBar: AppBar());
    final status = s['status'] as String;
    final isSup = s['isSupervisor'] == true;
    final participants = (s['participants'] as List).cast<Map<String, dynamic>>();

    final actions = <Widget>[
      if (isSup && status == 'REQUESTED') ...[
        ElevatedButton.icon(
          onPressed: _busy ? null : () => _do(() => _api.respondSupervision(widget.supervisionId, true), ok: 'Supervisione accettata: la stanza è pronta'),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Accetta'),
        ),
        OutlinedButton(
          onPressed: _busy ? null : () => _do(() => _api.respondSupervision(widget.supervisionId, false)),
          child: const Text('Rifiuta'),
        ),
      ],
      if (!isSup && s['myStatus'] == 'INVITED' && (status == 'REQUESTED' || status == 'ACCEPTED')) ...[
        ElevatedButton(
          onPressed: _busy ? null : () => _do(() => _api.setParticipation(widget.supervisionId, true)),
          child: const Text('Partecipo'),
        ),
        OutlinedButton(
          onPressed: _busy ? null : () => _do(() => _api.setParticipation(widget.supervisionId, false)),
          child: const Text('Non partecipo'),
        ),
      ],
      if (!isSup && status == 'ACCEPTED' && s['myStatus'] == 'CONFIRMED' && s['myPaymentStatus'] != 'PAID')
        ElevatedButton.icon(
          onPressed: _busy ? null : _pay,
          icon: const Icon(Icons.payments_outlined),
          label: Text('Paga ${formatEur(s['priceCents'] as int)} ed entra'),
        ),
      if (s['canEnterRoom'] == true)
        ElevatedButton.icon(
          onPressed: _enterRoom,
          icon: const Icon(Icons.meeting_room_outlined),
          label: const Text('Entra nella stanza'),
        ),
      if (isSup && status == 'ACCEPTED')
        OutlinedButton(
          onPressed: _busy ? null : () => _do(() => _api.completeSupervision(widget.supervisionId), ok: 'Supervisione conclusa'),
          child: const Text('Concludi supervisione'),
        ),
      if (s['isCreator'] == true && (status == 'REQUESTED' || status == 'ACCEPTED'))
        TextButton(
          onPressed: _busy ? null : () => _do(() => _api.cancelSupervision(widget.supervisionId), ok: 'Richiesta annullata'),
          child: const Text('Annulla richiesta'),
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(s['title'] as String, overflow: TextOverflow.ellipsis)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Wrap(spacing: 6, runSpacing: 6, children: [
            ProChip(kSupervisionStatus[status] ?? status),
            ProChip(s['mode'] == 'GROUP' ? 'Di gruppo' : 'Individuale'),
            ProChip(isSup
                ? 'Ricevi ${formatEur(s['netPerParticipantCents'] as int)} a partecipante (commissione ${s['feePercent']}%)'
                : '${formatEur(s['priceCents'] as int)} a partecipante'),
            if (s['myPaymentStatus'] == 'PAID') const ProChip('Pagato', color: AppColors.success, icon: Icons.check_rounded),
            if (s['myPaymentStatus'] == 'PENDING') const ProChip('Pagamento in corso', color: AppColors.warning),
          ]),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ColleagueAvatar(colleague: s['supervisor'] as Map<String, dynamic>?),
            title: Text((s['supervisor'] as Map?)?['name'] as String? ?? 'Supervisore'),
            subtitle: const Text('Supervisore'),
          ),
          const Text('Sintesi del caso', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
          const SizedBox(height: 4),
          Text(s['caseSummary'] as String? ?? '', style: const TextStyle(fontSize: 13.5, height: 1.45)),
          const SizedBox(height: 16),
          if (actions.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: actions),
          if (s['myPaymentStatus'] == 'PENDING')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Ho pagato, aggiorna'),
              ),
            ),
          ProSectionTitle('Partecipanti (${participants.length})'),
          for (final p in participants)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ColleagueAvatar(colleague: p),
              title: Text(p['name'] as String),
              subtitle: Text([
                p['status'] == 'INVITED' ? 'Invitato' : 'Confermato',
                if (p['paymentStatus'] == 'PAID') 'pagato',
                if (p['paymentStatus'] != null && p['paymentStatus'] != 'PAID') 'non ancora pagato',
              ].join(' · ')),
            ),
          if (status == 'REQUESTED')
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Il pagamento si attiva quando il supervisore accetta. Fino ad allora la richiesta si può annullare.',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ),
        ]),
      ),
    );
  }
}

// ── Ricerca supervisore e richiesta ─────────────────────────

class FindSupervisorPage extends StatefulWidget {
  const FindSupervisorPage({super.key});

  @override
  State<FindSupervisorPage> createState() => _FindSupervisorPageState();
}

class _FindSupervisorPageState extends State<FindSupervisorPage> {
  final _q = TextEditingController();
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final l = await ProApi().supervisors(_q.text.trim());
      if (mounted) setState(() { _list = l; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showProError(context, e);
      }
    }
  }

  Future<void> _request(Map<String, dynamic> sup) async {
    final id = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => RequestSupervisionPage(supervisor: sup)),
    );
    if (id != null && mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scegli un supervisore')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _q,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              hintText: 'Cerca per nome',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward_rounded), onPressed: _load),
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _list.isEmpty
                  ? const Center(child: Text('Nessun supervisore disponibile', style: TextStyle(color: AppColors.textTertiary)))
                  : ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [
                      for (final s in _list)
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                ColleagueAvatar(colleague: s, radius: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(s['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text([
                                      if (s['isPsychotherapist'] == true) 'Psicoterapeuta',
                                      if (s['orientation'] != null) s['orientation'] as String,
                                      if (s['yearsExperience'] != null) '${s['yearsExperience']} anni di esperienza',
                                    ].join(' · '), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ]),
                                ),
                              ]),
                              if (s['supervisorBio'] != null) ...[
                                const SizedBox(height: 8),
                                Text(s['supervisorBio'] as String, maxLines: 4, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12.5, height: 1.4)),
                              ],
                              const SizedBox(height: 8),
                              Row(children: [
                                ProChip('Individuale ${formatEur(s['priceIndividualCents'] as int)}'),
                                const SizedBox(width: 6),
                                ProChip('Gruppo ${formatEur(s['pricePerParticipantCents'] as int)}/persona'),
                                const Spacer(),
                                ElevatedButton(onPressed: () => _request(s), child: const Text('Richiedi')),
                              ]),
                            ]),
                          ),
                        ),
                    ]),
        ),
      ]),
    );
  }
}

class RequestSupervisionPage extends StatefulWidget {
  final Map<String, dynamic> supervisor;
  const RequestSupervisionPage({super.key, required this.supervisor});

  @override
  State<RequestSupervisionPage> createState() => _RequestSupervisionPageState();
}

class _RequestSupervisionPageState extends State<RequestSupervisionPage> {
  final _title = TextEditingController();
  final _summary = TextEditingController();
  String _mode = 'INDIVIDUAL';
  final List<Map<String, dynamic>> _colleagues = [];
  bool _anonymized = false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    super.dispose();
  }

  int get _price => (_mode == 'INDIVIDUAL'
      ? widget.supervisor['priceIndividualCents']
      : widget.supervisor['pricePerParticipantCents']) as int;

  Future<void> _addColleague() async {
    final c = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ColleaguePickerDialog(
        exclude: {widget.supervisor['id'] as String, ..._colleagues.map((c) => c['id'] as String)},
      ),
    );
    if (c != null) setState(() => _colleagues.add(c));
  }

  Future<void> _submit({bool acknowledge = false}) async {
    if (_title.text.trim().length < 3 || _summary.text.trim().length < 20) {
      showProError(context, 'Inserisci un titolo e una sintesi del caso (almeno 20 caratteri)');
      return;
    }
    if (!_anonymized) {
      showProError(context, 'Conferma di aver reso anonimo il caso');
      return;
    }
    setState(() => _saving = true);
    try {
      final id = await ProApi().requestSupervision(
        supervisorId: widget.supervisor['id'] as String,
        mode: _mode,
        title: _title.text.trim(),
        caseSummary: _summary.text.trim(),
        colleagueIds: _colleagues.map((c) => c['id'] as String).toList(),
        acknowledgeWarnings: acknowledge,
      );
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
      appBar: AppBar(title: Text('Supervisione con ${widget.supervisor['name']}')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'INDIVIDUAL', label: Text('Individuale'), icon: Icon(Icons.person_outline_rounded)),
            ButtonSegment(value: 'GROUP', label: Text('Con colleghi'), icon: Icon(Icons.groups_outlined)),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
        ),
        const SizedBox(height: 8),
        Text(
          _mode == 'INDIVIDUAL'
              ? 'Costo: ${formatEur(_price)}. Pagherai dopo che il supervisore avrà accettato.'
              : 'Costo: ${formatEur(_price)} a partecipante. Ogni collega conferma e paga la propria quota.',
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        if (_mode == 'GROUP') ...[
          const ProSectionTitle('Colleghi da coinvolgere'),
          for (final c in _colleagues)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ColleagueAvatar(colleague: c),
              title: Text(c['name'] as String),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(() => _colleagues.remove(c)),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _addColleague,
            icon: const Icon(Icons.person_add_alt_rounded, size: 18),
            label: const Text('Aggiungi collega'),
          ),
        ],
        const SizedBox(height: 16),
        const AnonymityReminder(),
        const SizedBox(height: 12),
        TextField(controller: _title, maxLength: 160, decoration: const InputDecoration(labelText: 'Titolo')),
        TextField(
          controller: _summary,
          minLines: 5,
          maxLines: 12,
          maxLength: 5000,
          decoration: const InputDecoration(
            labelText: 'Sintesi anonima del caso e cosa chiedi',
            alignLabelWithHint: true,
          ),
        ),
        CheckboxListTile(
          value: _anonymized,
          onChanged: (v) => setState(() => _anonymized = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: const Text('Confermo che il caso è descritto in forma anonima', style: TextStyle(fontSize: 13)),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _saving ? null : () => _submit(),
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Invia richiesta'),
        ),
      ]),
    );
  }
}

// ── Profilo supervisore ─────────────────────────────────────

class SupervisorProfilePage extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const SupervisorProfilePage({super.key, this.initial});

  @override
  State<SupervisorProfilePage> createState() => _SupervisorProfilePageState();
}

class _SupervisorProfilePageState extends State<SupervisorProfilePage> {
  late bool _active = widget.initial?['active'] as bool? ?? true;
  late final _bio = TextEditingController(text: widget.initial?['bio'] as String? ?? '');
  late final _orientation = TextEditingController(text: widget.initial?['orientation'] as String? ?? '');
  late final _years = TextEditingController(text: widget.initial?['yearsExperience']?.toString() ?? '');
  late final _priceInd = TextEditingController(text: _eur(widget.initial?['priceIndividualCents'] as int? ?? 8000));
  late final _priceGroup = TextEditingController(text: _eur(widget.initial?['pricePerParticipantCents'] as int? ?? 4000));
  bool _saving = false;

  static String _eur(int cents) => (cents / 100).toStringAsFixed(cents % 100 == 0 ? 0 : 2);
  static int? _cents(String v) {
    final d = double.tryParse(v.trim().replaceAll(',', '.'));
    return d == null ? null : (d * 100).round();
  }

  @override
  void dispose() {
    for (final c in [_bio, _orientation, _years, _priceInd, _priceGroup]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final ind = _cents(_priceInd.text);
    final grp = _cents(_priceGroup.text);
    if (ind == null || grp == null || ind < 500 || grp < 500) {
      showProError(context, 'Le tariffe devono essere di almeno 5 €');
      return;
    }
    setState(() => _saving = true);
    try {
      await ProApi().saveSupervisorProfile({
        'active': _active,
        'bio': _bio.text.trim(),
        'orientation': _orientation.text.trim(),
        if (int.tryParse(_years.text.trim()) != null) 'yearsExperience': int.parse(_years.text.trim()),
        'priceIndividualCents': ind,
        'pricePerParticipantCents': grp,
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
    final ind = _cents(_priceInd.text) ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Profilo da supervisore')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SwitchListTile(
          value: _active,
          onChanged: (v) => setState(() => _active = v),
          contentPadding: EdgeInsets.zero,
          title: const Text('Disponibile per supervisioni'),
          subtitle: const Text('Se disattivi, non ricevi nuove richieste'),
        ),
        TextField(
          controller: _orientation,
          maxLength: 120,
          decoration: const InputDecoration(labelText: 'Orientamento', hintText: 'Es. cognitivo-comportamentale, sistemico…'),
        ),
        TextField(
          controller: _years,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Anni di esperienza clinica'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bio,
          maxLines: 4,
          maxLength: 2000,
          decoration: const InputDecoration(
            labelText: 'Presentazione come supervisore',
            hintText: 'Ambiti in cui supervisioni, approccio, formazione…',
            alignLabelWithHint: true,
          ),
        ),
        const ProSectionTitle('Tariffe'),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _priceInd,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Individuale (€)'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _priceGroup,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Gruppo, a persona (€)'),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Text(
          'La piattaforma trattiene il 10%: su ${formatEur(ind)} ricevi ${formatEur(ind - (ind * 10 / 100).round())}.',
          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Salva'),
        ),
      ]),
    );
  }
}
