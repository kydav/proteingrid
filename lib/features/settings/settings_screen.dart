import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:proteingrid/core/home_style.dart';
import 'package:proteingrid/core/notifications_service.dart';
import 'package:proteingrid/core/purchases_service.dart';
import 'package:proteingrid/data/log_repository.dart';
import 'package:proteingrid/data/presets.dart';
import 'package:proteingrid/data/providers.dart';
import 'package:proteingrid/features/pro/pro_paywall_sheet.dart';
import 'package:proteingrid/features/settings/presets_editor.dart';
import 'package:share_plus/share_plus.dart' show Share;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _goalCtrl;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  List<TimeOfDay> _extraReminders = const [];
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
    final extras = await NotificationsService.getExtraReminders();
    if (mounted) {
      setState(() {
        _reminderEnabled = settings.enabled;
        _reminderTime = settings.time;
        _extraReminders = extras;
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
            content: Text('Enable notifications in Settings to use reminders.'),
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

  /// Pro: another reminder through the day.
  Future<void> _addExtraReminder() async {
    if (!await requirePro(context, ref, reason: ProReason.reminders)) return;
    if (!mounted) return;
    final granted = await NotificationsService.requestPermission();
    if (!granted && mounted && Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable notifications in Settings to use reminders.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 13, minute: 0),
    );
    if (picked == null) return;
    final next = [..._extraReminders, picked];
    await NotificationsService.setExtraReminders(next);
    if (mounted) setState(() => _extraReminders = next);
  }

  Future<void> _removeExtraReminder(int i) async {
    final next = [..._extraReminders]..removeAt(i);
    await NotificationsService.setExtraReminders(next);
    if (mounted) setState(() => _extraReminders = next);
  }

  Future<void> _exportCsv() async {
    final repo = LogRepository();
    final logs = repo.allLogs();
    if (logs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No logs to export.')));
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

    await Share.share(buf.toString(), subject: 'ProteinGrid export');
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
    if ((confirmed ?? false) && mounted) {
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
      appBar: AppBar(title: const Text('SETTINGS')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _ProSection(),
          const SizedBox(height: 24),

          // ── Look ────────────────────────────────────────────────────────
          _sectionHeader(context, 'Today screen style'),
          const _StylePicker(),
          const SizedBox(height: 24),

          // ── Daily goal ──────────────────────────────────────────────────
          _sectionHeader(context, 'Daily protein goal'),
          Text(
            'How many grams of protein do you aim for each day?',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
            for (var i = 0; i < _extraReminders.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.alarm_rounded, color: cs.primary),
                title: Text('Also at ${_extraReminders[i].format(context)}'),
                trailing: IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => _removeExtraReminder(i),
                ),
              ),
            if (_extraReminders.length < kMaxExtraReminders)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addExtraReminder,
                  icon: const Icon(Icons.add_alarm_rounded),
                  label: const Text('Add another reminder'),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Reminders skip the rest of a day once you hit your goal. You '
              'also get a notification when you hit it.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
            'Long-press the Protein Grid icon on your home screen to log in one tap. '
            'Once you edit your quick-log buttons, the first three show here too.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.tune_rounded, color: cs.primary),
            title: const Text('Edit quick-log buttons'),
            subtitle: const Text('Your own amounts and names'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              if (!await requirePro(context, ref, reason: ProReason.presets)) {
                return;
              }
              if (context.mounted) await showPresetsEditor(context);
            },
          ),
          const SizedBox(height: 8),
          ...[
            for (final p in shortcutPresets(ref.watch(presetsProvider)))
              shortcutTitle(p),
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
          // Debug builds only: fill a year so screenshots show a lit Grid.
          if (kDebugMode) ...[
            const SizedBox(height: 24),
            _sectionHeader(context, 'Debug'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pretend Pro'),
              value: ref.watch(debugPretendProProvider),
              onChanged: (v) =>
                  ref.read(debugPretendProProvider.notifier).state = v,
            ),
            OutlinedButton(
              onPressed: () async {
                await LogRepository().fillSampleYear(
                  goal: ref.read(dailyGoalProvider),
                );
                ref.invalidate(todayLogsProvider);
              },
              child: const Text('Fill a sample year'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                await LogRepository().clearSampleYear();
                ref.invalidate(todayLogsProvider);
              },
              child: const Text('Clear sample data'),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // Pixel headers in the style's accent, like the Today screens.
  Widget _sectionHeader(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

/// Pro status, or the way in. Restore lives here too, for a new phone.
class _ProSection extends ConsumerWidget {
  const _ProSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    if (!purchasesAvailable) return const SizedBox.shrink();
    final pro = ref.watch(isProNowProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer,

        border: Border.all(color: cs.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            pro ? Icons.verified_rounded : Icons.grid_view_rounded,
            color: cs.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pro ? 'ProteinGrid Pro' : 'Get ProteinGrid Pro',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  pro
                      ? 'Thanks for supporting a tiny indie app.'
                      : 'Your whole year on the Grid, full history, your own '
                            'buttons, more reminders.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!pro)
            FilledButton(
              onPressed: () => showProPaywall(context),
              child: const Text('See Pro'),
            ),
        ],
      ),
    );
  }
}

/// The three Today looks. Block Meter is free; the others are Pro while
/// [kStylesArePro] is on.
class _StylePicker extends ConsumerWidget {
  const _StylePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(homeStyleProvider);
    final pro = ref.watch(isProNowProvider);
    return Column(
      children: [
        for (final style in HomeStyle.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () async {
                final locked =
                    kStylesArePro && style != HomeStyle.blockMeter && !pro;
                if (locked &&
                    !await requirePro(context, ref, reason: ProReason.styles)) {
                  return;
                }
                await ref.read(homeStyleProvider.notifier).set(style);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: style.palette.bg,
                  border: Border.all(
                    color: style == current
                        ? style.palette.accent
                        : style.palette.line,
                    width: style == current ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // A swatch of the style's two colours.
                    for (final c in [
                      style.palette.accent,
                      style.palette.accent2,
                    ])
                      Container(
                        width: 14,
                        height: 28,
                        margin: const EdgeInsets.only(right: 4),
                        color: c,
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            style.label,
                            style: TextStyle(
                              color: style.palette.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            style.tagline,
                            style: TextStyle(
                              color: style.palette.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (style == current)
                      Icon(Icons.check_rounded, color: style.palette.accent)
                    else if (kStylesArePro &&
                        style != HomeStyle.blockMeter &&
                        !pro)
                      Icon(
                        Icons.lock_rounded,
                        size: 18,
                        color: style.palette.muted,
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
