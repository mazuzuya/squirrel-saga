import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:squirrel_saga/game_assets.dart';
import 'package:squirrel_saga/main.dart';
import 'package:squirrel_saga/squirrel_game.dart';

void main() {
  testWidgets('Squirrel Saga app boots without throwing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SquirrelApp());
    // Loading shell (MaterialApp) is present immediately.
    expect(find.byType(MaterialApp), findsOneWidget);
    // Allow the async asset boot + a few frames to run (no settle: the game loops).
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Game loop resumes when pause is cleared', (
    WidgetTester tester,
  ) async {
    final game = _ProbeGame()..paused = true;
    await tester.pumpWidget(GameWidget(game: game));
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.updates, 0);

    game.paused = false;
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.updates, greaterThan(0));
  });
}

class _ProbeGame extends SquirrelGame {
  _ProbeGame() : super(GameLibrary());

  int updates = 0;

  @override
  void update(double dt) => updates += 1;

  @override
  void render(ui.Canvas canvas) {}
}
