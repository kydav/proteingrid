import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _goalCtrl;

  @override
  void initState() {
    super.initState();
    final goal = ref.read(dailyGoalProvider);
    _goalCtrl = TextEditingController(text: goal.toString());
  }

  @override
  void dispose() {
    _goalCtrl.dispose();
    super.dispose();
  }

  void _saveGoal() {
    final val = int.tryParse(_goalCtrl.text.trim());
    if (val != null && val > 0) {
      ref.read(dailyGoalProvider.notifier).setGoal(val);
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Daily goal set to ${val}g'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmClearToday() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clear today's log?"),
        content: const Text(
          "This will remove all of today's protein entries. This can't be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final logs = ref.read(todayLogsProvider);
      for (final log in logs) {
        await ref.read(todayLogsProvider.notifier).remove(log.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Daily protein goal',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'How many grams of protein do you aim for each day?',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _goalCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveGoal(),
                  decoration: const InputDecoration(
                    suffixText: 'g',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _saveGoal,
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Quick action shortcuts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Long-press the ProteinPing app icon on your home screen to instantly log common amounts without opening the app.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ...[
            ('log_30g', 'Log 30g'),
            ('log_40g', 'Log 40g'),
            ('log_50g', 'Log 50g'),
            ('log_custom', 'Custom amount'),
          ].map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.flash_on_rounded,
                  color: cs.onPrimaryContainer,
                  size: 20,
                ),
              ),
              title: Text(item.$2),
            ),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _confirmClearToday,
            icon: const Icon(Icons.delete_outline),
            label: const Text("Clear today's log"),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.error,
              side: BorderSide(color: cs.error),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
