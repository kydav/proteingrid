import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:proteingrid/core/home_style.dart';
import 'package:proteingrid/features/history/history_screen.dart';
import 'package:proteingrid/features/home/home_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  static const _screens = [HomeScreen(), HistoryScreen()];

  @override
  Widget build(BuildContext context) {
    // The tab bar takes the Today style's colours and names.
    final style = ref.watch(homeStyleProvider);
    final p = style.palette;
    final (today, history) = style.navLabels;
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: p.bg,
          border: Border(top: BorderSide(color: p.line, width: 1.5)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: p.bg,
            indicatorColor: Colors.transparent,
            iconTheme: WidgetStateProperty.resolveWith(
              (s) => IconThemeData(
                color: s.contains(WidgetState.selected)
                    ? p.accent
                    : p.muted.withValues(alpha: 0.6),
              ),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith(
              (s) => GoogleFonts.vt323(
                fontSize: 20,
                letterSpacing: 1,
                color: s.contains(WidgetState.selected)
                    ? p.accent
                    : p.muted.withValues(alpha: 0.6),
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_outlined),
                label: today,
              ),
              NavigationDestination(
                icon: const Icon(Icons.bar_chart_outlined),
                selectedIcon: const Icon(Icons.bar_chart_rounded),
                label: history,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
