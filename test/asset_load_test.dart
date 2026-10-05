import 'package:flame/cache.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:squirrel_saga/game_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('loadLibrary succeeds for all assets', () async {
    final images = Images();
    Object? caught;
    try {
      final lib = await loadLibrary(images);
      // Verify sheets parsed with frames + animations.
      for (final name in lib.sheets.keys) {
        final s = lib.sheets[name]!;
        expect(s.frames.isNotEmpty, isTrue, reason: 'no frames for $name');
      }
      expect(lib.backdrops.length, 3);
      expect(lib.climbTrees.length, 30);
      print(
        'OK sheets=${lib.sheets.length} backdrops=${lib.backdrops.length} climb=${lib.climbTrees.length}',
      );
    } catch (e) {
      caught = e;
      print('LOAD FAILED: $e');
    }
    expect(caught, isNull);
  });
}
