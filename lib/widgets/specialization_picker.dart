import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/specialization_data.dart';

/// Widget che gestisce la selezione gerarchica delle specializzazioni.
/// Espone [selectedCodes] (Set<String>) aggiornato via [onChanged].
class SpecializationPicker extends StatefulWidget {
  final Set<String> selectedCodes;
  final ValueChanged<Set<String>> onChanged;

  const SpecializationPicker({
    super.key,
    required this.selectedCodes,
    required this.onChanged,
  });

  @override
  State<SpecializationPicker> createState() => _SpecializationPickerState();
}

class _SpecializationPickerState extends State<SpecializationPicker> {
  final List<TaxMacro> _taxonomy = kTaxonomy;

  TaxMacro? _selMacro;
  TaxSub?   _selSub;

  void _toggle(String code) {
    final next = Set<String>.from(widget.selectedCodes);
    if (next.contains(code)) {
      next.remove(code);
    } else {
      next.add(code);
    }
    widget.onChanged(next);
  }

  void _removeTag(String code) {
    final next = Set<String>.from(widget.selectedCodes)..remove(code);
    widget.onChanged(next);
  }

  // Costruisce la mappa code → label dall'intera taxonomy
  Map<String, String> get _labelMap {
    final m = <String, String>{};
    for (final macro in _taxonomy) {
      for (final leaf in macro.allLeaves()) {
        m[leaf.code] = leaf.label;
      }
    }
    return m;
  }

  // Foglie da mostrare in base alla selezione corrente
  List<TaxLeaf> get _currentLeaves {
    if (_selMacro == null) return [];
    if (_selMacro!.hasSubs) {
      if (_selSub == null) return [];
      return _selSub!.leaves;
    }
    return _selMacro!.leaves ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final labelMap = _labelMap;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Tag selezionati ─────────────────────────────────────────────────
        if (widget.selectedCodes.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: widget.selectedCodes.map((code) {
              final label = labelMap[code] ?? code;
              return Chip(
                label: Text(label, style: const TextStyle(fontSize: 11)),
                deleteIcon: const Icon(Icons.close_rounded, size: 14),
                onDeleted: () => _removeTag(code),
                backgroundColor: AppColors.bgInverse,
                labelStyle: const TextStyle(color: AppColors.textInverse, fontSize: 11),
                deleteIconColor: AppColors.textInverse,
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
        ],

        // ── Dropdown 1: macro categoria ─────────────────────────────────────
        DropdownButtonFormField<TaxMacro>(
          value: _selMacro,
          isExpanded: true,
          dropdownColor: AppColors.bg,
          decoration: const InputDecoration(labelText: 'Categoria principale'),
          hint: const Text('Seleziona categoria'),
          items: _taxonomy.map((m) => DropdownMenuItem(
            value: m,
            child: Text(m.label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
          )).toList(),
          onChanged: (v) => setState(() { _selMacro = v; _selSub = null; }),
        ),

        // ── Dropdown 2: sub (solo se la macro le ha) ────────────────────────
        if (_selMacro != null && _selMacro!.hasSubs) ...[
          const SizedBox(height: 10),
          DropdownButtonFormField<TaxSub>(
            value: _selSub,
            isExpanded: true,
            dropdownColor: AppColors.bg,
            decoration: const InputDecoration(labelText: 'Sottocategoria'),
            hint: const Text('Seleziona sottocategoria'),
            items: _selMacro!.subs!.map((s) => DropdownMenuItem(
              value: s,
              child: Text(s.label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
            )).toList(),
            onChanged: (v) => setState(() => _selSub = v),
          ),
        ],

        // ── Foglie multi-select ─────────────────────────────────────────────
        if (_currentLeaves.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Seleziona uno o più disturbi/aree:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _currentLeaves.map((leaf) {
              final selected = widget.selectedCodes.contains(leaf.code);
              return FilterChip(
                label: Text(leaf.label),
                selected: selected,
                onSelected: (_) => _toggle(leaf.code),
                selectedColor: AppColors.bgInverse,
                checkmarkColor: AppColors.textInverse,
                labelStyle: TextStyle(
                  fontSize: 12,
                  color: selected ? AppColors.textInverse : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(color: selected ? AppColors.bgInverse : AppColors.glassBorder),
                backgroundColor: AppColors.bg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
