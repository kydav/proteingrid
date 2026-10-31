import 'package:flutter_test/flutter_test.dart';
import 'package:proteingrid/data/presets.dart';

void main() {
  test('default buttons give the classic 30/40/50g shortcuts', () {
    expect(shortcutPresets(kDefaultPresets).map(shortcutTitle), [
      'Log 30g',
      'Log 40g',
      'Log 50g',
    ]);
  });

  test('edited buttons give their first three, with names', () {
    const mine = [
      QuickPreset(40, 'Shake'),
      QuickPreset(25, 'Greek yogurt'),
      QuickPreset(35),
      QuickPreset(50, 'Chicken'),
    ];
    expect(shortcutPresets(mine).map(shortcutTitle), [
      'Shake · 40g',
      'Greek yogurt · 25g',
      'Log 35g',
    ]);
  });

  test('a button keeps its icon through save/load, and unknown icons drop', () {
    final saved = const QuickPreset(40, 'Shake', 'pg_bolt').toJson();
    expect(QuickPreset.fromJson(saved)?.icon, 'pg_bolt');
    expect(QuickPreset.fromJson({'g': 40, 'i': 'nope'})?.icon, '');
  });

  test('icons default by position, and changing one counts as an edit', () {
    expect(iconKeyFor(const QuickPreset(30), 0), 'egg');
    expect(iconKeyFor(const QuickPreset(30), 2), 'chicken');
    expect(iconKeyFor(const QuickPreset(30, '', 'pg_fish'), 0), 'pg_fish');
    final iconOnly = [
      kDefaultPresets.first.copyWith(icon: 'pg_bolt'),
      ...kDefaultPresets.skip(1),
    ];
    expect(shortcutPresets(iconOnly).first.icon, 'pg_bolt');
    for (final key in kShortcutIcons.keys) {
      expect(key, matches(RegExp(r'^[a-z_]+$'))); // valid Android resource
    }
  });
}
