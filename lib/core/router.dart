import 'package:flutter/material.dart';
import 'package:proteinping/features/home/home_screen.dart';
import 'package:proteinping/features/settings/settings_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class ProteinPingRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      '/settings' => MaterialPageRoute(builder: (_) => const SettingsScreen()),
      _ => MaterialPageRoute(builder: (_) => const HomeScreen()),
    };
  }
}
