import 'dart:math' as math;

import 'level_models.dart';
import 'levels_expansion.dart';
import 'levels_ch2.dart';
import 'levels_ch3.dart';

final List<Area> areas = _buildAreas();

int get areaCount => areas.length;

Area makeArea(int index) => areas[index].clone();

List<Area> _buildAreas() {
  final list = <Area>[];

  Area base(
    String name,
    String mechanic,
    String tip,
    String backdrop,
    String tiles,
    List<String> colors,
    Map<String, double> spawn,
    Map<String, double> portal,
    int required,
  ) => Area(
    name: name,
    mechanic: mechanic,
    tip: tip,
    backdrop: backdrop,
    tiles: tiles,
    colors: colors,
    spawn: spawn,
    portal: portal,
    required: required,
  );

  // ---------- Chapter one (base) ----------
  list.add(
    base(
        'Oak Canopy',
        'Dasar Melayang',
        'Tahan LOMPAT di udara untuk membuka patagium.',
        'FOREST_BACKDROP',
        'FOREST_PLATFORM_TILES',
        ['#081329', '#173b45', '#57d47f', '#ffd36a'],
        {'x': 110, 'y': 610},
        {'x': 2010, 'y': 470},
        2,
      )
      ..platforms = [
        p(0, 680, 520, 90),
        p(610, 610, 330),
        p(1030, 520, 360),
        p(1490, 590, 300),
        p(1880, 520, 310),
      ]
      ..keys = [
        key('segitiga', 'triangle_walnut', 785, 545),
        key('bulat', 'round_walnut', 1210, 455),
      ]
      ..enemies = [enemy('beetle', 390, 680), enemy('beetle', 1580, 590)]
      ..emblems = [Emblem(930, 430), Emblem(1430, 395), Emblem(2120, 390)],
  );

  list.add(
    base(
        'Whispering Pines',
        'Panjat & Stamina',
        'Tahan AKSI di batang bercahaya untuk memanjat.',
        'FOREST_BACKDROP',
        'FOREST_PLATFORM_TILES',
        ['#071a26', '#174635', '#7ad45c', '#efc56f'],
        {'x': 100, 'y': 610},
        {'x': 2020, 'y': 300},
        2,
      )
      ..platforms = [
        p(0, 680, 430, 90),
        p(500, 560, 250),
        p(830, 430, 250),
        p(1160, 650, 300),
        p(1510, 480, 260),
        p(1860, 350, 360),
      ]
      ..climbZones = [
        ClimbZone(415, 330, 95, 350, false),
        ClimbZone(1440, 310, 85, 340, false),
        ClimbZone(1780, 205, 90, 360, false),
      ]
      ..keys = [
        key('akar', 'tier_key_a', 255, 610),
        key('puncak', 'tier_key_b', 1660, 415),
      ]
      ..enemies = [
        enemy('woodpecker', 690, 560),
        enemy('woodpecker', 1330, 650),
      ]
      ..emblems = [Emblem(600, 430), Emblem(1280, 565), Emblem(2110, 220)],
  );

  list.add(
    base(
        'Wind Draft Canyon',
        'Arus Angin',
        'Melayang di atas arus untuk terangkat; kunci batu terlalu berat.',
        'FOREST_BACKDROP',
        'FOREST_PLATFORM_TILES',
        ['#0b1631', '#245477', '#71e6e1', '#e0c17b'],
        {'x': 100, 'y': 610},
        {'x': 2050, 'y': 400},
        1,
      )
      ..platforms = [
        p(0, 680, 370, 90),
        p(570, 570, 270),
        p(1030, 400, 260),
        p(1470, 590, 280),
        p(1900, 450, 350),
      ]
      ..updrafts = [
        RectZone(370, 350, 200, 380),
        RectZone(840, 220, 190, 500),
        RectZone(1750, 260, 150, 450),
      ]
      ..keys = [
        key('batu', 'stone_acorn', 1160, 335, {'heavy': true}),
      ]
      ..enemies = [
        enemy('hawk', 710, 440, {'flying': true}),
        enemy('hawk', 1600, 390, {'flying': true}),
      ]
      ..emblems = [Emblem(470, 310), Emblem(935, 180), Emblem(1815, 230)],
  );

  list.add(
    base(
        'Underground Roots',
        'Menggali',
        'Cari tanah retak lalu tekan AKSI untuk menggali.',
        'CAVERN_BACKDROP',
        'CAVERN_PLATFORM_TILES',
        ['#100d25', '#392552', '#4de0b2', '#d3915d'],
        {'x': 100, 'y': 610},
        {'x': 2040, 'y': 500},
        2,
      )
      ..platforms = [
        p(0, 680, 530, 90),
        p(610, 590, 330),
        p(1010, 680, 380),
        p(1470, 540, 300),
        p(1850, 550, 390),
      ]
      ..digSpots = [
        {'id': 'kiri', 'x': 750, 'y': 590},
        {'id': 'kanan', 'x': 1210, 'y': 680},
      ]
      ..keys = [
        key('kiri', 'left_key_half', 750, 525, {'hidden': true}),
        key('kanan', 'right_key_half', 1210, 615, {'hidden': true}),
      ]
      ..enemies = [enemy('mole', 420, 680), enemy('mole', 1580, 540)]
      ..emblems = [Emblem(865, 500), Emblem(1320, 580), Emblem(1760, 410)],
  );

  list.add(
    base(
        'Bioluminescent Cavern',
        'Jamur Membal',
        'Pantulkan jamur MERAH → BIRU → HIJAU.',
        'CAVERN_BACKDROP',
        'CAVERN_PLATFORM_TILES',
        ['#09081f', '#36235d', '#45e8ff', '#ff5d86'],
        {'x': 100, 'y': 610},
        {'x': 2030, 'y': 440},
        1,
      )
      ..platforms = [
        p(0, 680, 430, 90),
        p(600, 560, 240),
        p(1020, 430, 250),
        p(1420, 590, 250),
        p(1850, 490, 390),
      ]
      ..sequence = ['red', 'blue', 'green']
      ..mushrooms = [
        {'color': 'red', 'sprite': 'red_mushroom', 'x': 480, 'y': 680},
        {'color': 'blue', 'sprite': 'blue_mushroom', 'x': 920, 'y': 680},
        {'color': 'green', 'sprite': 'green_mushroom', 'x': 1320, 'y': 680},
      ]
      ..keys = [
        key('warna', 'wind_key', 1560, 515, {'hidden': true}),
      ]
      ..enemies = [enemy('snail', 720, 560), enemy('snail', 1970, 490)]
      ..emblems = [Emblem(720, 470), Emblem(1135, 340), Emblem(1740, 410)],
  );

  list.add(
    base(
        'Waterfall Canopy',
        'Daun Rakit & Tuas',
        'Aktifkan dua tuas agar arus membawa kunci.',
        'FOREST_BACKDROP',
        'FOREST_PLATFORM_TILES',
        ['#07192c', '#185970', '#4ed7c2', '#ffd470'],
        {'x': 100, 'y': 610},
        {'x': 2040, 'y': 420},
        1,
      )
      ..platforms = [
        p(0, 680, 390, 90),
        p(570, 550, 260),
        p(1050, 650, 260),
        p(1510, 520, 250),
        p(1900, 470, 340),
      ]
      ..movingPlatforms = [
        MovingPlatform(390, 650, 150, 24, 180, 0.8),
        MovingPlatform(1320, 610, 160, 24, 160, 1.1),
      ]
      ..levers = [
        {'id': 'barat', 'x': 690, 'y': 495},
        {'id': 'timur', 'x': 1620, 'y': 465},
      ]
      ..keys = [
        key('air', 'round_walnut', 1780, 395, {'hidden': true}),
      ]
      ..enemies = [enemy('frog', 1130, 650), enemy('frog', 2000, 470)]
      ..emblems = [Emblem(470, 560), Emblem(1180, 520), Emblem(1810, 340)],
  );

  list.add(
    base(
        'Frosty Peaks',
        'Es & Angin Kencang',
        'Bawa kunci beku ke batu panas; permukaan es sangat licin.',
        'CORE_BACKDROP',
        'CORE_PLATFORM_TILES',
        ['#071427', '#1d4d6b', '#9cecff', '#ff975e'],
        {'x': 100, 'y': 610},
        {'x': 2040, 'y': 420},
        1,
      )
      ..platforms = [
        p(0, 680, 460, 90, 'ice'),
        p(590, 570, 350, 46, 'ice'),
        p(1050, 450, 270, 46, 'ice'),
        p(1440, 610, 300, 46, 'ice'),
        p(1880, 470, 360, 60),
      ]
      ..windZones = [
        RectZone(500, 260, 390, 420, -90),
        RectZone(1360, 280, 420, 420, 110),
      ]
      ..heat = RectZone(1570, 540, 0, 0)
      ..keys = [
        key('beku', 'frozen_key', 1170, 380, {'frozen': true}),
      ]
      ..enemies = [
        enemy('owl', 760, 420, {'flying': true}),
        enemy('owl', 1640, 460, {'flying': true}),
      ]
      ..emblems = [Emblem(515, 480), Emblem(1270, 330), Emblem(1810, 370)],
  );

  list.add(
    base(
        'Clockwork Hollow',
        'Gear & Timing',
        'Pasang gear dengan AKSI, lalu lewati mesin saat sejajar.',
        'CORE_BACKDROP',
        'CORE_PLATFORM_TILES',
        ['#100d20', '#4c3427', '#42d8db', '#e8ad55'],
        {'x': 100, 'y': 610},
        {'x': 2050, 'y': 360},
        1,
      )
      ..platforms = [
        p(0, 680, 400, 90),
        p(530, 540, 250),
        p(940, 650, 250),
        p(1350, 470, 270),
        p(1830, 410, 410),
      ]
      ..movingPlatforms = [
        MovingPlatform(390, 610, 120, 24, 140, 1.5, vertical: true),
        MovingPlatform(1220, 570, 120, 24, 130, 1.8, vertical: true),
      ]
      ..mechanism = RectZone(1510, 405, 0, 0)
      ..keys = [
        key('gear', 'gear_key', 1060, 585, {'gear': true}),
      ]
      ..enemies = [
        enemy('clockbeetle', 650, 540),
        enemy('clockbeetle', 1940, 410),
      ]
      ..emblems = [Emblem(455, 460), Emblem(1280, 390), Emblem(1720, 310)],
  );

  list.add(
    base(
        'Toxic Swampland',
        'Ayun Sulur',
        'AKSI di dekat sulur untuk mengayun; sucikan kunci di mata air.',
        'CAVERN_BACKDROP',
        'CAVERN_PLATFORM_TILES',
        ['#0c1021', '#314426', '#9ddc44', '#f15bb5'],
        {'x': 100, 'y': 610},
        {'x': 2050, 'y': 410},
        1,
      )
      ..platforms = [
        p(0, 680, 320, 90),
        p(520, 570, 230),
        p(940, 660, 240),
        p(1390, 540, 260),
        p(1870, 460, 370),
      ]
      ..hazards = [
        RectZone(320, 690, 200, 180),
        RectZone(750, 690, 190, 180),
        RectZone(1180, 690, 210, 180),
        RectZone(1650, 690, 220, 180),
      ]
      ..vines = [
        {'x': 420, 'y': 350},
        {'x': 835, 'y': 315},
        {'x': 1280, 'y': 340},
        {'x': 1760, 'y': 280},
      ]
      ..spring = RectZone(1510, 475, 0, 0)
      ..keys = [
        key('racun', 'toxic_key', 1070, 595, {'toxic': true}),
      ]
      ..enemies = [
        enemy('mosquito', 670, 420, {'flying': true}),
        enemy('mosquito', 1580, 360, {'flying': true}),
      ]
      ..emblems = [Emblem(430, 310), Emblem(1260, 300), Emblem(1770, 245)],
  );

  list.add(
    base(
        'Grand Yggdrasil Core',
        'Empat Elemen',
        'Kumpulkan empat kunci sebelum waktu habis.',
        'CORE_BACKDROP',
        'CORE_PLATFORM_TILES',
        ['#09091d', '#412b4e', '#4de9dc', '#ff9c50'],
        {'x': 100, 'y': 610},
        {'x': 2110, 'y': 350},
        4,
      )
      ..timeLimit = 95
      ..platforms = [
        p(0, 680, 360, 90),
        p(500, 560, 250),
        p(870, 420, 240),
        p(1230, 640, 250),
        p(1580, 500, 260),
        p(1980, 400, 320),
      ]
      ..climbZones = [ClimbZone(360, 300, 95, 380, false)]
      ..updrafts = [RectZone(750, 210, 120, 500)]
      ..digSpots = [
        {'id': 'api', 'x': 1360, 'y': 640},
      ]
      ..vines = [
        {'x': 1510, 'y': 300},
      ]
      ..keys = [
        key('angin', 'wind_key', 980, 350),
        key('es', 'ice_key', 620, 495),
        key('akar', 'root_key', 1710, 435),
        key('api', 'fire_key', 1360, 575, {'hidden': true}),
      ]
      ..enemies = [enemy('guardian', 1840, 500)]
      ..emblems = [Emblem(780, 170), Emblem(1510, 260), Emblem(2240, 290)],
  );

  // ---------- Expansions ----------
  final exps = expansionData();
  for (var i = 0; i < exps.length; i += 1) {
    final area = list[i];
    final e = exps[i];
    for (final plat in (e['platforms'] as List<Platform>))
      area.platforms.add(plat.clone());
    if (e['climbZones'] != null) {
      area.climbZones ??= [];
      for (final z in (e['climbZones'] as List<ClimbZone>))
        area.climbZones!.add(z.clone());
    }
    if (e['keys'] != null) {
      for (final k in (e['keys'] as List<KeyItem>)) area.keys.add(k.clone());
    }
    for (final en in (e['enemies'] as List<Enemy>))
      area.enemies.add(en.clone());
    if (e['movingPlatforms'] != null) {
      area.movingPlatforms ??= [];
      for (final m in (e['movingPlatforms'] as List<MovingPlatform>))
        area.movingPlatforms!.add(m.clone());
    }
    if (e['updrafts'] != null) {
      area.updrafts ??= [];
      for (final z in (e['updrafts'] as List<RectZone>))
        area.updrafts!.add(z.clone());
    }
    if (e['windZones'] != null) {
      area.windZones ??= [];
      for (final z in (e['windZones'] as List<RectZone>))
        area.windZones!.add(z.clone());
    }
    if (e['digSpots'] != null)
      area.digSpots = [
        for (final d in (e['digSpots'] as List)) Map<String, dynamic>.from(d),
      ];
    if (e['mushrooms'] != null)
      area.mushrooms = [
        for (final m in (e['mushrooms'] as List)) Map<String, dynamic>.from(m),
      ];
    if (e['hazards'] != null) {
      area.hazards ??= [];
      for (final z in (e['hazards'] as List<RectZone>))
        area.hazards!.add(z.clone());
    }
    if (e['vines'] != null)
      area.vines = [
        for (final v in (e['vines'] as List)) Map<String, dynamic>.from(v),
      ];
    final ca = e['climbArt'] as Map;
    area.climbArt = ClimbArt(
      ca['key'] as String,
      (ca['x'] as num).toDouble(),
      (ca['y'] as num).toDouble(),
      (ca['w'] as num).toDouble(),
      (ca['h'] as num).toDouble(),
    );
    area.portal = (e['portal'] as Map).map(
      (k, v) => MapEntry(k as String, (v as num).toDouble()),
    );
    area.required = e['required'] as int;
    if (e['timeLimit'] != null)
      area.timeLimit = (e['timeLimit'] as num).toDouble();
    area.worldWidth = 3800;
    area.worldHeight = 1500;
  }

  // AREAS[9] key repositioning.
  list[9].keys[0].x = 2760;
  list[9].keys[0].y = 360;
  list[9].keys[1].x = 2440;
  list[9].keys[1].y = 1200;
  list[9].keys[2].x = 3260;
  list[9].keys[2].y = 230;
  list[9].keys[3].x = 2950;
  list[9].keys[3].y = 820;
  list[9].keys[3].hidden = false;

  // Final approach extension on chapter one.
  const oldAreaEnemy = [
    'beetle',
    'woodpecker',
    'hawk',
    'mole',
    'snail',
    'frog',
    'owl',
    'clockbeetle',
    'mosquito',
    'guardian',
  ];
  for (var i = 0; i < 10; i += 1) {
    final area = list[i];
    final routeY = math.max(280, math.min(1420, area.portal['y']! + 50));
    area.platforms.add(p(3700, routeY + 120, 300));
    area.platforms.add(p(3980, routeY + 20, 300));
    area.platforms.add(p(4260, routeY - 70, 420));
    area.enemies.add(
      enemy(oldAreaEnemy[i], 3820, routeY + 120, {
        'flying': fly(oldAreaEnemy[i]),
      }),
    );
    area.enemies.add(
      enemy(i % 2 == 1 ? 'hawk' : 'clockbeetle', 4140, routeY - 40, {
        'flying': i % 2 == 1,
      }),
    );
    if (i < 9) {
      area.keys.add(
        key(
          'ujian-$i',
          i % 2 == 1 ? 'fire_key' : 'wind_key',
          4140,
          routeY - 50,
        ),
      );
      area.required += 1;
    }
    area.portal = {'x': 4490, 'y': routeY - 120};
    area.worldWidth = 4700;
    area.worldHeight = 1800;
  }

  // ---------- Chapter two / three / gauntlets ----------
  pushChapterTwo(list);
  buildChapterThree(list);
  applyLandmarkGauntlet(list);
  applyKeeperGauntlet(list);

  return list;
}
