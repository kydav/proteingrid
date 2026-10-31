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
