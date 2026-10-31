import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A one-tap amount on the log sheet, optionally named ("Shake").
class QuickPreset {
  const QuickPreset(this.grams, [this.label = '']);

  final double grams;
  final String label;

  Map<String, dynamic> toJson() => {'g': grams, 'l': label};

  static QuickPreset? fromJson(Object? m) {
    if (m is! Map) return null;
    final g = (m['g'] as num?)?.toDouble();
    if (g == null || g <= 0) return null;
    return QuickPreset(g, (m['l'] as String?) ?? '');
  }
}

const kDefaultPresets = [
  QuickPreset(20),
  QuickPreset(25),
  QuickPreset(30),
  QuickPreset(40),
  QuickPreset(50),
];

/// The most quick-log buttons the sheet shows.
const kMaxPresets = 8;

const _key = 'quick_presets_v1';

/// The log sheet's quick buttons. Editable with Pro; everyone gets the
/// defaults.
final presetsProvider =
    StateNotifierProvider<PresetsNotifier, List<QuickPreset>>(
      (_) => PresetsNotifier(),
    );

class PresetsNotifier extends StateNotifier<List<QuickPreset>> {
  PresetsNotifier() : super(kDefaultPresets) {
    _load();
  }

  Future<void> _load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null) return;
    try {
      final list = [
        for (final m in jsonDecode(raw) as List) ?QuickPreset.fromJson(m),
      ];
      if (list.isNotEmpty) state = list;
    } catch (_) {}
  }

  Future<void> save(List<QuickPreset> presets) async {
    state = presets.isEmpty ? kDefaultPresets : presets;
    await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode([for (final p in state) p.toJson()]),
    );
  }

  Future<void> reset() => save(kDefaultPresets);
}

/// The long-press home-screen shortcuts (before "Custom amount"): 30/40/50g
/// with the default buttons, or the first three once they've been edited.
List<QuickPreset> shortcutPresets(List<QuickPreset> presets) {
  String key(QuickPreset p) => '${p.grams}|${p.label}';
  final edited =
      presets.length != kDefaultPresets.length ||
      [
        for (var i = 0; i < presets.length; i++) i,
      ].any((i) => key(presets[i]) != key(kDefaultPresets[i]));
  return edited
      ? presets.take(3).toList()
      : const [QuickPreset(30), QuickPreset(40), QuickPreset(50)];
}

/// How a shortcut reads on the home screen: "Log 40g" or "Shake · 40g".
String shortcutTitle(QuickPreset p) => p.label.isEmpty
    ? 'Log ${p.grams.toStringAsFixed(0)}g'
    : '${p.label} · ${p.grams.toStringAsFixed(0)}g';
