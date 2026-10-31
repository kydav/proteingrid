import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proteingrid/data/presets.dart';

/// Pro: edit the log sheet's quick buttons — amount and an optional name
/// ("Shake", "Greek yogurt"), up to [kMaxPresets].
Future<void> showPresetsEditor(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _PresetsEditor(),
  );
}

class _Row {
  _Row(QuickPreset p)
    : grams = TextEditingController(text: p.grams.toStringAsFixed(0)),
      label = TextEditingController(text: p.label),
      icon = p.icon;

  final TextEditingController grams;
  final TextEditingController label;
  String icon;

  QuickPreset? get preset {
    final g = double.tryParse(grams.text.trim());
    return g == null || g <= 0 ? null : QuickPreset(g, label.text.trim(), icon);
  }

  void dispose() {
    grams.dispose();
    label.dispose();
  }
}

class _PresetsEditor extends ConsumerStatefulWidget {
  const _PresetsEditor();

  @override
  ConsumerState<_PresetsEditor> createState() => _PresetsEditorState();
}

class _PresetsEditorState extends ConsumerState<_PresetsEditor> {
  late final List<_Row> _rows = [
    for (final p in ref.read(presetsProvider)) _Row(p),
  ];

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _pickIcon(int i) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in kShortcutIcons.entries)
                SizedBox(
                  width: 76,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx, e.key),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          Icon(
                            e.value.icon,
                            size: 30,
                            color: Theme.of(ctx).colorScheme.primary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            e.value.name,
                            style: Theme.of(ctx).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _rows[i].icon = picked);
  }

  Future<void> _save() async {
    await ref.read(presetsProvider.notifier).save([
      for (final r in _rows) ?r.preset,
    ]);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + kb),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick buttons',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'One tap logs the amount, with its name as the label. The first '
              'three are also your home-screen shortcuts, with their icons.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < _rows.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    // The icon (also used for its home-screen shortcut).
                    IconButton(
                      tooltip: 'Icon',
                      onPressed: () => _pickIcon(i),
                      icon: Icon(
                        kShortcutIcons[iconKeyFor(
                              QuickPreset(1, '', _rows[i].icon),
                              i,
                            )]!
                            .icon,
                        color: cs.primary,
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _rows[i].grams,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          suffixText: 'g',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _rows[i].label,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Name (optional)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _rows.length <= 1
                          ? null
                          : () => setState(() => _rows.removeAt(i).dispose()),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                if (_rows.length < kMaxPresets)
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _rows.add(_Row(const QuickPreset(30)))),
                    icon: const Icon(Icons.add),
                    label: const Text('Add button'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    for (final r in _rows) {
                      r.dispose();
                    }
                    _rows
                      ..clear()
                      ..addAll(kDefaultPresets.map(_Row.new));
                  }),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
