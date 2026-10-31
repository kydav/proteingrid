import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:proteingrid/core/home_style.dart';
import 'package:proteingrid/core/notifications_service.dart';
import 'package:proteingrid/core/purchases_service.dart';
import 'package:proteingrid/core/router.dart';
import 'package:proteingrid/core/theme.dart';
import 'package:proteingrid/data/presets.dart';
import 'package:proteingrid/data/protein_log.dart';
import 'package:proteingrid/data/providers.dart';
import 'package:proteingrid/features/pro/pro_paywall_sheet.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ProteinLogAdapter());
  await Hive.openBox<ProteinLog>('protein_logs');
  await NotificationsService.init();
  await initPurchases();
  runApp(const ProviderScope(child: ProteinGridApp()));
}

class ProteinGridApp extends ConsumerStatefulWidget {
  const ProteinGridApp({super.key});

  @override
  ConsumerState<ProteinGridApp> createState() => _ProteinGridAppState();
}

class _ProteinGridAppState extends ConsumerState<ProteinGridApp> {
  @override
  void initState() {
    super.initState();
    _initQuickActions();
    // Reminders skip a day once its goal is hit (and come back tomorrow).
    ref.listenManual<bool>(goalHitTodayProvider, (prev, hit) {
      NotificationsService.refreshForToday(goalHit: hit).ignore();
      if (prev == false && hit) _celebrateGoal().ignore();
    }, fireImmediately: true);
  }

  /// The one upsell that isn't a tap on a Pro feature: the third day they hit
  /// their goal, right after the win, show the Grid once.
  Future<void> _celebrateGoal() async {
    const countKey = 'goal_hit_days';
    const shownKey = 'grid_upsell_shown';
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final stamp = '${today.year}-${today.month}-${today.day}';
    if (prefs.getString('goal_hit_last_day') == stamp) return;
    await prefs.setString('goal_hit_last_day', stamp);
    final count = (prefs.getInt(countKey) ?? 0) + 1;
    await prefs.setInt(countKey, count);
    // Ratings move App Store rank most, and the fifth win is a happy moment
    // to ask. The OS decides whether to actually show it (a few times a year).
    if (count == 5) {
      try {
        if (await InAppReview.instance.isAvailable()) {
          await InAppReview.instance.requestReview();
        }
      } catch (_) {}
      return;
    }
    if (count < 3 || (prefs.getBool(shownKey) ?? false)) return;
    if (ref.read(isProNowProvider) || !purchasesAvailable) return;
    await prefs.setBool(shownKey, true);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    final context = navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    await showProPaywall(context, reason: ProReason.grid);
  }

  static const _quickActions = QuickActions();

  void _initQuickActions() {
    _quickActions.initialize((type) {
      final pending = _parseShortcut(type);
      if (pending != null) {
        ref.read(pendingQuickActionGramsProvider.notifier).state = pending;
      }
    });
    // The shortcuts follow the quick-log buttons (Pro users can edit those).
    ref.listenManual<List<QuickPreset>>(
      presetsProvider,
      (_, presets) => _setShortcuts(presets).ignore(),
      fireImmediately: true,
    );
  }

  /// Long-press shortcuts: three amounts plus "Custom amount". With the
  /// default buttons that's 30/40/50g as before; once the buttons are
  /// edited, it's the first three of them, with their names.
  Future<void> _setShortcuts(List<QuickPreset> presets) async {
    final picks = shortcutPresets(presets);
    const icons = ['egg', 'shake', 'chicken'];
    await _quickActions.setShortcutItems([
      for (var i = 0; i < picks.length; i++)
        ShortcutItem(
          // The amount and name travel in the type, so the handler needs no
          // lookup (and old shortcuts still work after the buttons change).
          type: 'log|${picks[i].grams}|${picks[i].label}',
          localizedTitle: shortcutTitle(picks[i]),
          icon: icons[i],
        ),
      const ShortcutItem(
        type: 'log_custom',
        localizedTitle: 'Custom amount',
        icon: 'plus',
      ),
    ]);
  }

  static PendingQuickLog? _parseShortcut(String type) {
    if (type == 'log_custom') return (grams: 0, label: null);
    // Shortcuts from before they followed the buttons.
    final legacy = RegExp(r'^log_(\d+)g$').firstMatch(type);
    if (legacy != null) {
      return (grams: double.parse(legacy.group(1)!), label: null);
    }
    final parts = type.split('|');
    if (parts.length >= 2 && parts.first == 'log') {
      final grams = double.tryParse(parts[1]);
      if (grams == null) return null;
      final label = parts.skip(2).join('|');
      return (grams: grams, label: label.isEmpty ? null : label);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Every screen follows the Today style picked in Settings.
    final theme = arcadeTheme(ref.watch(homeStyleProvider).palette);
    return MaterialApp(
      title: 'ProteinGrid',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      onGenerateRoute: ProteinGridRouter.onGenerateRoute,
      initialRoute: '/',
    );
  }
}
