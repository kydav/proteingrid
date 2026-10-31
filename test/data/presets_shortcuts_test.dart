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
}
