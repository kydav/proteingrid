import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:proteingrid/core/notifications_service.dart';
import 'package:proteingrid/core/purchases_service.dart';
import 'package:proteingrid/core/router.dart';
import 'package:proteingrid/core/theme.dart';
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

  void _initQuickActions() {
    const quickActions = QuickActions();

    quickActions.initialize((shortcutType) {
      double? grams;
      if (shortcutType == 'log_30g') grams = 30;
      if (shortcutType == 'log_40g') grams = 40;
      if (shortcutType == 'log_50g') grams = 50;
      if (shortcutType == 'log_custom') grams = 0;

      if (grams != null) {
        ref.read(pendingQuickActionGramsProvider.notifier).state = grams;
      }
    });

    quickActions.setShortcutItems(const [
      ShortcutItem(type: 'log_30g', localizedTitle: 'Log 30g', icon: 'egg'),
      ShortcutItem(type: 'log_40g', localizedTitle: 'Log 40g', icon: 'shake'),
      ShortcutItem(type: 'log_50g', localizedTitle: 'Log 50g', icon: 'chicken'),
      ShortcutItem(
        type: 'log_custom',
        localizedTitle: 'Custom amount',
        icon: 'plus',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProteinGrid',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: arcadeTheme(),
      darkTheme: arcadeTheme(),
      themeMode: ThemeMode.dark,
      onGenerateRoute: ProteinGridRouter.onGenerateRoute,
      initialRoute: '/',
    );
  }
}
