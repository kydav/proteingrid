import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:proteingrid/core/notifications_service.dart';
import 'package:proteingrid/core/router.dart';
import 'package:proteingrid/core/theme.dart';
import 'package:proteingrid/data/protein_log.dart';
import 'package:proteingrid/data/providers.dart';
import 'package:quick_actions/quick_actions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ProteinLogAdapter());
  await Hive.openBox<ProteinLog>('protein_logs');
  await NotificationsService.init();
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
