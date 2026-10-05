import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flutter/services.dart';

class Frame {
  Frame(this.x, this.y, this.w, this.h, [this.ax, this.ay, this.surfaceY]);

  factory Frame.fromJson(Map<dynamic, dynamic> f) {
    final crop = (f['content'] as Map?) ?? (f['source'] as Map?);
    if (crop == null) return Frame(0, 0, 1, 1);
    final a = f['anchor'] as Map?;
    return Frame(
      (crop['x'] as num).toDouble(),
      (crop['y'] as num).toDouble(),
      (crop['w'] as num).toDouble(),
      (crop['h'] as num).toDouble(),
      a == null ? null : (a['x'] as num).toDouble(),
      a == null ? null : (a['y'] as num).toDouble(),
      (f['surfaceY'] as num?)?.toDouble(),
    );
  }

  final double x;
  final double y;
  final double w;
  final double h;
  final double? ax;
  final double? ay;
  final double? surfaceY;
}

class Sheet {
  Sheet(this.image, Map<dynamic, dynamic> json) {
    for (final f in json['frames'] as List) {
      frames[(f['name'] as String)] = Frame.fromJson(f as Map);
    }
    for (final a in (json['animations'] as List?) ?? []) {
      final name = a['name'] as String;
      animations[name] = [
        for (final f in a['frames'] as List) Frame.fromJson(f as Map),
      ];
    }
  }

  final ui.Image image;
  final Map<String, Frame> frames = {};
  final Map<String, List<Frame>> animations = {};

  Frame? frame(String name) => frames[name];

  List<Frame>? animation(String name) => animations[name];
}

class GameLibrary {
  GameLibrary();

  final Map<String, Sheet> sheets = {};
  final Map<String, ui.Image> backdrops = {};
  final Map<String, ui.Image> climbTrees = {};

  Sheet sheet(String name) => sheets[name]!;

  Sheet? trySheet(String name) => sheets[name];
}

/// Defines every sprite sheet, mirroring game js/game/assets.js.
const Map<String, List<String>> _sheetDefs = {
  'movement': [
    'luma_movement_sheet-transparent.webp',
    'luma_movement_sheet-transparent.frames.json',
  ],
  'action': [
    'luma_action_sheet-transparent.webp',
    'luma_action_sheet-transparent.frames.json',
  ],
  'status': [
    'luma_status_sheet-transparent.webp',
    'luma_status_sheet-transparent.frames.json',
  ],
  'woodland': [
    'enemies_woodland_sheet-transparent.webp',
    'enemies_woodland_sheet-transparent.frames.json',
  ],
  'elemental': [
    'enemies_elemental_sheet-transparent.webp',
    'enemies_elemental_sheet-transparent.frames.json',
  ],
  'final': [
    'enemies_final_sheet-transparent.webp',
    'enemies_final_sheet-transparent.frames.json',
  ],
  'puzzle': [
    'puzzle_atlas-transparent.webp',
    'puzzle_atlas-transparent.frames.json',
  ],
  'world': [
    'world_effects_sheet-transparent.webp',
    'world_effects_sheet-transparent.frames.json',
  ],
  'feedback': [
    'feedback_effects_sheet-transparent.webp',
    'feedback_effects_sheet-transparent.frames.json',
  ],
  'forestTiles': [
    'forest_platform_tiles-transparent.webp',
    'forest_platform_tiles-transparent.frames.json',
  ],
  'cavernTiles': [
    'cavern_platform_tiles-transparent.webp',
    'cavern_platform_tiles-transparent.frames.json',
  ],
  'coreTiles': [
    'core_platform_tiles-transparent.webp',
    'core_platform_tiles-transparent.frames.json',
  ],
  'newForest': [
    'enemies_new_forest_sheet-transparent.webp',
    'enemies_new_forest_sheet-transparent.frames.json',
  ],
  'newArcane': [
    'enemies_new_arcane_sheet-transparent.webp',
    'enemies_new_arcane_sheet-transparent.frames.json',
  ],
  'newWeird': [
    'enemies_new_weird_sheet-transparent.webp',
    'enemies_new_weird_sheet-transparent.frames.json',
  ],
  'landmarks': [
    'area_landmark_atlas-transparent.webp',
    'area_landmark_atlas-transparent.frames.json',
  ],
  'stormAttack': [
    'skin_07_attack_sheet-transparent.webp',
    'skin_07_attack_sheet-transparent.frames.json',
  ],
  'chapter3A': [
    'enemies_ch3_a_sheet-transparent.webp',
    'enemies_ch3_a_sheet-transparent.frames.json',
  ],
  'chapter3B': [
    'enemies_ch3_b_sheet-transparent.webp',
    'enemies_ch3_b_sheet-transparent.frames.json',
  ],
  'landmarks2': [
    'area_landmark_atlas_2-transparent.webp',
    'area_landmark_atlas_2-transparent.frames.json',
  ],
};

Future<GameLibrary> loadLibrary(Images images) async {
  final lib = GameLibrary();

  final defs = <String, List<String>>{};
  defs.addAll(_sheetDefs);
  for (var index = 1; index <= 20; index += 1) {
    final n = index.toString().padLeft(2, '0');
    defs['skin$n'] = [
      'skin_${n}_sheet-transparent.webp',
      'skin_${n}_sheet-transparent.frames.json',
    ];
  }

  for (final entry in defs.entries) {
    try {
      final img = await images.load(entry.value[0]);
      final data =
          jsonDecode(
                await rootBundle.loadString('assets/json/${entry.value[1]}'),
              )
              as Map<dynamic, dynamic>;
      lib.sheets[entry.key] = Sheet(img, data);
    } catch (_) {
      // Optional skins must not block the base game, exactly like the JS loader.
      if (!entry.key.startsWith('skin')) rethrow;
    }
  }

  const backdrops = [
    ('FOREST_BACKDROP', 'forest'),
    ('CAVERN_BACKDROP', 'cavern'),
    ('CORE_BACKDROP', 'core'),
  ];
  for (final (_, name) in backdrops) {
    try {
      lib.backdrops[name] = await images.load('${name}_backdrop.webp');
    } catch (_) {
      // Backdrop missing is non-fatal.
    }
  }

  for (var index = 1; index <= 30; index += 1) {
    final n = index.toString().padLeft(2, '0');
    final key = 'CLIMB_TREE_$n';
    try {
      lib.climbTrees[key] = await images.load('climb_tree_$n-transparent.webp');
    } catch (_) {
      // Climb art missing is non-fatal.
    }
  }

  return lib;
}
