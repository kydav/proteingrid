import 'package:flutter/material.dart';
import 'package:proteingrid/features/settings/settings_screen.dart';
import 'package:proteingrid/features/shell/main_shell.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class ProteinGridRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      '/settings' => MaterialPageRoute(builder: (_) => const SettingsScreen()),
      _ => MaterialPageRoute(builder: (_) => const MainShell()),
    };
  }
}
