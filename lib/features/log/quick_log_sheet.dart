import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

/// Shows the quick-log bottom sheet. Returns true if a log was saved.
Future<bool> showQuickLogSheet(
  BuildContext context, {
  double? prefilledGrams,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _QuickLogSheet(prefilledGrams: prefilledGrams),
  );
  return result ?? false;
}

class _QuickLogSheet extends ConsumerStatefulWidget {
  const _QuickLogSheet({this.prefilledGrams});
  final double? prefilledGrams;

  @override
  ConsumerState<_QuickLogSheet> createState() => _QuickLogSheetState();
}

class _QuickLogSheetState extends ConsumerState<_QuickLogSheet> {
  final _gramsCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  bool _showCustom = false;
  bool _saving = false;

  static const _presets = [20.0, 25.0, 30.0, 40.0, 50.0];

  @override
  void initState() {
    super.initState();
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

  Future<void> _log(double grams) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final label =
          _labelCtrl.text.trim().isNotEmpty ? _labelCtrl.text.trim() : null;
      await ref
          .read(todayLogsProvider.notifier)
          .add(grams: grams, label: label);
      HapticFeedback.mediumImpact();
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
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'How much protein are you logging?',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),

          // Preset buttons
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ..._presets.map(
                (g) => _PresetChip(
                  grams: g,
                  onTap: _saving ? null : () => _log(g),
                  cs: cs,
                ),
              ),
              ActionChip(
                label: const Text('Custom'),
                avatar: const Icon(Icons.edit_outlined, size: 16),
                onPressed: () => setState(() => _showCustom = !_showCustom),
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
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
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
    required this.grams,
    required this.onTap,
    required this.cs,
  });

  final double grams;
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
          '${grams.toStringAsFixed(0)}g',
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
