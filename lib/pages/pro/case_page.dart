import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/report_reasons.dart';
import '../../services/pro_api.dart';
import '../../services/realtime_service.dart';
import '../../theme/app_theme.dart';
import 'pro_widgets.dart';

/// Un caso presentato al gruppo e la sua discussione.
class CasePage extends StatefulWidget {
  final String caseId;
  const CasePage({super.key, required this.caseId});

  @override
  State<CasePage> createState() => _CasePageState();
}

class _CasePageState extends State<CasePage> {
  final _api = ProApi();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Map<String, dynamic>? _case;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  StreamSubscription<RealtimeEvent>? _liveSub;

  @override
  void initState() {
    super.initState();
    _load();
    RealtimeService.instance.subscribe('case', widget.caseId);
    _liveSub = RealtimeService.instance.listenRoom('case', widget.caseId, _load);
  }

  @override
  void dispose() {
    _liveSub?.cancel();
    RealtimeService.instance.unsubscribe('case', widget.caseId);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final c = await _api.caseDetail(widget.caseId);
      if (!mounted) return;
      final grew = (c['messages'] as List).length > ((_case?['messages'] as List?)?.length ?? 0);
      setState(() { _case = c; _loading = false; _error = null; });
      // Nuovo intervento arrivato in tempo reale: porta in fondo alla discussione
      if (grew && _case != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = errorText(e); _loading = false; });
    }
  }

  Future<void> _send({bool acknowledge = false}) async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _api.postMessage(widget.caseId, text, acknowledgeWarnings: acknowledge);
      _input.clear();
      await _load();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    } on AnonymizationWarning catch (w) {
      if (!mounted) return;
      setState(() => _sending = false);
      if (await confirmDespiteWarnings(context, w.warnings)) return _send(acknowledge: true);
    } catch (e) {
      if (mounted) showProError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleStatus() async {
    final closed = _case!['status'] == 'CLOSED';
    try {
      await _api.setCaseStatus(widget.caseId, closed ? 'OPEN' : 'CLOSED');
      await _load();
    } catch (e) {
      if (mounted) showProError(context, e);
    }
  }

  Future<void> _deleteCase() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare il caso?'),
        content: const Text('Il caso e tutta la discussione verranno eliminati per tutti i membri.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.deleteCase(widget.caseId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showProError(context, e);
    }
  }

  Future<void> _messageActions(Map<String, dynamic> m) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (m['isMine'] == true)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Elimina il mio messaggio'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            )
          else
            ListTile(
              leading: const Icon(Icons.outlined_flag_rounded),
              title: const Text('Segnala messaggio'),
              subtitle: const Text('Solo questo messaggio sarà visibile allo staff'),
              onTap: () => Navigator.pop(ctx, 'report'),
            ),
        ]),
      ),
    );
    if (!mounted || action == null) return;
    try {
      if (action == 'delete') {
        await _api.deleteMessage(m['id'] as String);
        await _load();
      } else {
        final sent = await showDialog<bool>(context: context, builder: (_) => _ReportMessageDialog(messageId: m['id'] as String));
        if (sent == true && mounted) showProInfo(context, 'Segnalazione inviata');
      }
    } catch (e) {
      if (mounted) showProError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _case;
    return Scaffold(
      appBar: AppBar(
        title: Text(c?['title'] as String? ?? 'Caso', overflow: TextOverflow.ellipsis),
        actions: [
          if (c != null && c['canClose'] == true && c['archived'] != true)
            IconButton(
              tooltip: c['status'] == 'CLOSED' ? 'Riapri il caso' : 'Segna come risolto',
              icon: Icon(c['status'] == 'CLOSED' ? Icons.lock_open_rounded : Icons.task_alt_rounded),
              onPressed: _toggleStatus,
            ),
          if (c != null && c['isMine'] == true)
            IconButton(tooltip: 'Elimina caso', icon: const Icon(Icons.delete_outline_rounded), onPressed: _deleteCase),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
              : Column(children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(controller: _scroll, padding: const EdgeInsets.all(12), children: [
                        _CaseHeader(c: c!),
                        const SizedBox(height: 12),
                        if ((c['messages'] as List).isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text('Nessun intervento ancora. Condividi il tuo punto di vista.',
                                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.textTertiary)),
                            ),
                          ),
                        for (final m in (c['messages'] as List).cast<Map<String, dynamic>>())
                          _MessageTile(m: m, onLongPress: m['deleted'] == true ? null : () => _messageActions(m)),
                      ]),
                    ),
                  ),
                  if (c['status'] == 'CLOSED' || c['archived'] == true)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      color: AppColors.bgPanel,
                      child: Text(
                        c['archived'] == true ? 'Il gruppo è archiviato: la discussione è in sola lettura.' : 'Il caso è chiuso.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                      ),
                    )
                  else
                    _Composer(controller: _input, sending: _sending, onSend: () => _send()),
                ]),
    );
  }
}

class _CaseHeader extends StatelessWidget {
  final Map<String, dynamic> c;
  const _CaseHeader({required this.c});

  @override
  Widget build(BuildContext context) {
    final author = c['author'] as Map<String, dynamic>?;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ColleagueAvatar(colleague: author),
            const SizedBox(width: 8),
            Expanded(
              child: Text(author?['name'] as String? ?? 'Collega',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            if (c['status'] == 'CLOSED') const ProChip('Risolto', color: AppColors.success, icon: Icons.task_alt_rounded),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            if (c['ageRange'] != null) ProChip('Età ${c['ageRange']}'),
            if (c['setting'] != null) ProChip(kSettings[c['setting']] ?? c['setting'] as String),
          ]),
          const SizedBox(height: 10),
          const Text('Situazione', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
          const SizedBox(height: 2),
          Text(c['presentingProblem'] as String, style: const TextStyle(fontSize: 13, height: 1.45)),
          const SizedBox(height: 10),
          const Text('Domanda al gruppo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
          const SizedBox(height: 2),
          Text(c['question'] as String, style: const TextStyle(fontSize: 13, height: 1.45, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  final Map<String, dynamic> m;
  final VoidCallback? onLongPress;
  const _MessageTile({required this.m, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final author = m['author'] as Map<String, dynamic>?;
    final deleted = m['deleted'] == true;
    return InkWell(
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ColleagueAvatar(colleague: author, radius: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(author?['name'] as String? ?? 'Ex membro',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                ),
                const SizedBox(width: 6),
                Text(formatDateTime(m['createdAt'] as String?),
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textTertiary)),
                if (onLongPress != null) ...[
                  const Spacer(),
                  InkWell(
                    onTap: onLongPress,
                    child: const Icon(Icons.more_horiz_rounded, size: 16, color: AppColors.textTertiary),
                  ),
                ],
              ]),
              const SizedBox(height: 2),
              Text(
                deleted ? 'Messaggio eliminato dall\'autore' : (m['content'] as String? ?? ''),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  fontStyle: deleted ? FontStyle.italic : FontStyle.normal,
                  color: deleted ? AppColors.textTertiary : AppColors.textPrimary,
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  const _Composer({required this.controller, required this.sending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 8, MediaQuery.of(context).viewInsets.bottom + 10),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.glassBorder))),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 5,
            maxLength: 5000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Scrivi il tuo contributo (in forma anonima)…',
              counterText: '',
              isDense: true,
            ),
          ),
        ),
        IconButton(
          onPressed: sending ? null : onSend,
          icon: sending
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send_rounded),
        ),
      ]),
    );
  }
}

class _ReportMessageDialog extends StatefulWidget {
  final String messageId;
  const _ReportMessageDialog({required this.messageId});

  @override
  State<_ReportMessageDialog> createState() => _ReportMessageDialogState();
}

class _ReportMessageDialogState extends State<_ReportMessageDialog> {
  String? _reason;
  final _details = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) return;
    setState(() => _sending = true);
    try {
      await ProApi().reportMessage(widget.messageId, _reason!, _details.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        showProError(context, e);
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Segnala messaggio'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ...kReportReasons.entries.map((e) => RadioListTile<String>(
                value: e.key,
                groupValue: _reason,
                onChanged: (v) => setState(() => _reason = v),
                title: Text(e.value, style: const TextStyle(fontSize: 13)),
                dense: true,
                contentPadding: EdgeInsets.zero,
              )),
          TextField(controller: _details, maxLines: 2, decoration: const InputDecoration(labelText: 'Dettagli (facoltativo)')),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
        ElevatedButton(onPressed: _reason == null || _sending ? null : _submit, child: const Text('Invia')),
      ],
    );
  }
}
