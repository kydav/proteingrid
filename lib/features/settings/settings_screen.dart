import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart' show Share;

import '../../core/notifications_service.dart';
import '../../data/log_repository.dart';
import '../../data/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _goalCtrl;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _notifLoaded = false;

  @override
  void initState() {
    super.initState();
    final goal = ref.read(dailyGoalProvider);
    _goalCtrl = TextEditingController(text: goal.toString());
    _loadReminderSettings();
  }

  Future<void> _loadReminderSettings() async {
    final settings = await NotificationsService.getReminderSettings();
    if (mounted) {
      setState(() {
        _reminderEnabled = settings.enabled;
        _reminderTime = settings.time;
        _notifLoaded = true;
      });
    }
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

  Future<void> _toggleReminder(bool enabled) async {
    if (enabled) {
      final granted = await NotificationsService.requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Enable notifications in Settings to use reminders.',
            ),
          ),
        );
        return;
      }
      await NotificationsService.scheduleDailyReminder(_reminderTime);
    } else {
      await NotificationsService.cancelDailyReminder();
    }
    if (mounted) setState(() => _reminderEnabled = enabled);
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
      if (_reminderEnabled) {
        await NotificationsService.scheduleDailyReminder(picked);
      }
    }
  }

  Future<void> _exportCsv() async {
    final repo = LogRepository();
    final logs = repo.allLogs();
    if (logs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No logs to export.')),
        );
      }
      return;
    }

    final dateFmt = DateFormat('yyyy-MM-dd');
    final timeFmt = DateFormat('HH:mm:ss');
    final buf = StringBuffer('Date,Time,Grams,Label\n');
    for (final log in logs) {
      final label = (log.label ?? '').replaceAll(',', ';');
      buf.writeln(
        '${dateFmt.format(log.timestamp)},${timeFmt.format(log.timestamp)},${log.grams.toStringAsFixed(1)},$label',
      );
    }

    await Share.share(buf.toString(), subject: 'ProteinPing export');
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
          // ── Daily goal ──────────────────────────────────────────────────
          _sectionHeader(context, 'Daily protein goal'),
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
              FilledButton(onPressed: _saveGoal, child: const Text('Save')),
            ],
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // ── Notifications ───────────────────────────────────────────────
          _sectionHeader(context, 'Notifications'),
          if (_notifLoaded) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Daily reminder'),
              subtitle: Text(
                _reminderEnabled
                    ? 'Reminds you at ${_reminderTime.format(context)}'
                    : 'Off',
              ),
              value: _reminderEnabled,
              onChanged: _toggleReminder,
            ),
            if (_reminderEnabled)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reminder time'),
                trailing: Text(
                  _reminderTime.format(context),
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: _pickReminderTime,
              ),
            const SizedBox(height: 4),
            Text(
              'You also receive a notification when you hit your daily goal.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(),
              ),
            ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // ── Quick actions ───────────────────────────────────────────────
          _sectionHeader(context, 'Quick action shortcuts'),
          Text(
            'Long-press the ProteinPing app icon on your home screen to instantly log common amounts.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ...[
            'Log 30g',
            'Log 40g',
            'Log 50g',
            'Custom amount',
          ].map(
            (label) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(
                Icons.flash_on_rounded,
                color: cs.primary,
                size: 20,
              ),
              title: Text(label),
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // ── Data ────────────────────────────────────────────────────────
          _sectionHeader(context, 'Data'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _exportCsv,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Export all logs as CSV'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      );
}
