import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:proteingrid/data/presets.dart';
import 'package:proteingrid/data/providers.dart';
import 'package:proteingrid/features/pro/pro_paywall_sheet.dart';
import 'package:proteingrid/features/settings/presets_editor.dart';

/// Shows the quick-log bottom sheet. Returns true if a log was saved.
Future<bool> showQuickLogSheet(
  BuildContext context, {
  double? prefilledGrams,
  String? prefilledLabel,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _QuickLogSheet(
      prefilledGrams: prefilledGrams,
      prefilledLabel: prefilledLabel,
    ),
  );
  return result ?? false;
}

class _QuickLogSheet extends ConsumerStatefulWidget {
  const _QuickLogSheet({this.prefilledGrams, this.prefilledLabel});
  final double? prefilledGrams;
  final String? prefilledLabel;

  @override
  ConsumerState<_QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends ConsumerState<_QuickLogSheet> {
  final _gramsCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  bool _showCustom = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledLabel?.isNotEmpty ?? false) {
      _labelCtrl.text = widget.prefilledLabel!;
    }
    if (widget.prefilledGrams != null && widget.prefilledGrams! > 0) {
      _gramsCtrl.text = widget.prefilledGrams!.toStringAsFixed(0);
      _showCustom = true;
    } else if (widget.prefilledGrams == 0) {
      // 0 means "open custom entry directly"
      _showCustom = true;
    }
  }

  @override
  void dispose() {
    _gramsCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _log(double grams, {String? presetLabel}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final typed = _labelCtrl.text.trim();
      final label = typed.isNotEmpty
          ? typed
          : (presetLabel?.isNotEmpty ?? false)
          ? presetLabel
          : null;
      final goal = ref.read(dailyGoalProvider);
      await ref
          .read(todayLogsProvider.notifier)
          .add(grams: grams, label: label, goal: goal);
      await HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logCustom() async {
    final grams = double.tryParse(_gramsCtrl.text.trim());
    if (grams == null || grams <= 0) return;
    await _log(grams);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final recentLabels = ref.watch(recentLabelsProvider);
    final presets = ref.watch(presetsProvider);
    final kb = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + kb),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Log protein',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'How much protein are you logging?',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),

          // Preset buttons
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ...presets.map(
                (p) => _PresetChip(
                  preset: p,
                  onTap: _saving
                      ? null
                      : () => _log(p.grams, presetLabel: p.label),
                  cs: cs,
                ),
              ),
              ActionChip(
                label: const Text('Custom'),
                avatar: const Icon(Icons.edit_outlined, size: 16),
                onPressed: () => setState(() => _showCustom = !_showCustom),
              ),
              // Pro: make these buttons your own.
              ActionChip(
                label: const Text('Edit'),
                avatar: const Icon(Icons.tune_rounded, size: 16),
                onPressed: () async {
                  if (!await requirePro(
                    context,
                    ref,
                    reason: ProReason.presets,
                  )) {
                    return;
                  }
                  if (context.mounted) await showPresetsEditor(context);
                },
              ),
            ],
          ),

          // Custom entry
          if (_showCustom) ...[
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _gramsCtrl,
                    autofocus: widget.prefilledGrams != null,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Grams',
                      suffixText: 'g',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _labelCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _logCustom(),
                    decoration: const InputDecoration(
                      labelText: 'Label (optional)',
                      hintText: 'e.g. chicken breast',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _logCustom,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Log'),
            ),
          ],

          // Recent label shortcuts
          if (recentLabels.isNotEmpty && !_showCustom) ...[
            const SizedBox(height: 20),
            Text(
              'Recent',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recentLabels
                  .map(
                    (label) => ActionChip(
                      label: Text(label),
                      onPressed: () {
                        _labelCtrl.text = label;
                        setState(() => _showCustom = true);
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.preset,
    required this.onTap,
    required this.cs,
  });

  final QuickPreset preset;
  final VoidCallback? onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          preset.label.isEmpty
              ? '${preset.grams.toStringAsFixed(0)}g'
              : '${preset.label} · ${preset.grams.toStringAsFixed(0)}g',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: cs.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
