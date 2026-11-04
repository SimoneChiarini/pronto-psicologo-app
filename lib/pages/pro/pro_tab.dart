import 'package:flutter/material.dart';
import '../../services/pro_api.dart';
import '../../theme/app_theme.dart';
import 'intervision_tab.dart';
import 'pro_widgets.dart';
import 'supervision_tab.dart';

/// Tab "Colleghi" della home psicologo: Intervisioni · Supervisioni.
/// Visibile a tutti gli psicologi, utilizzabile solo da verificati con abbonamento attivo.
class ProTab extends StatefulWidget {
  const ProTab({super.key});

  @override
  State<ProTab> createState() => _ProTabState();
}

class _ProTabState extends State<ProTab> {
  bool _loading = true;
  String? _locked;
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ProApi().checkAccess();
      if (mounted) setState(() { _locked = null; _loading = false; });
    } on ProAreaLocked catch (e) {
      if (mounted) setState(() { _locked = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = errorText(e); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_locked != null || _error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(_locked != null ? Icons.lock_outline_rounded : Icons.cloud_off_rounded,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 14),
            const Text('Intervisioni e supervisioni',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              _locked ?? _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            if (_locked != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Completa la verifica dell\'albo e attiva l\'abbonamento dal tuo profilo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _check, child: const Text('Riprova')),
          ]),
        ),
      );
    }
    return const DefaultTabController(
      length: 2,
      child: Column(children: [
        TabBar(tabs: [
          Tab(icon: Icon(Icons.forum_outlined, size: 20), text: 'Intervisioni'),
          Tab(icon: Icon(Icons.school_outlined, size: 20), text: 'Supervisioni'),
        ]),
        Expanded(child: TabBarView(children: [IntervisionTab(), SupervisionTab()])),
      ]),
    );
  }
}
