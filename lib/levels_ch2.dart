import 'level_models.dart';

List<Platform> widePlatforms() => [
  p(0, 980, 470, 90),
  p(560, 900, 320, 50),
  p(970, 820, 300, 50),
  p(1350, 1040, 330, 60),
  p(1770, 1320, 430, 70),
  p(1930, 1040, 410, 55),
  p(1940, 760, 400, 55),
  p(2030, 500, 330, 50),
  p(2440, 680, 320, 50),
  p(2820, 820, 340, 55),
  p(3220, 740, 310, 50),
  p(3590, 660, 300, 50),
  p(3970, 580, 290, 50),
  p(4310, 500, 390, 70),
];

List<Enemy> crowd(List<String> types) => [
  enemy(types[0], 380, 980),
  enemy(types[1], 720, 870, {'flying': fly(types[1])}),
  enemy(types[2], 1120, 720, {'flying': fly(types[2])}),
  enemy(types[0], 1510, 1040),
  enemy(types[1], 1990, 1320, {'flying': fly(types[1])}),
  enemy(types[2], 2180, 760, {'flying': fly(types[2])}),
  enemy(types[0], 2590, 680),
  enemy(types[1], 3000, 820, {'flying': fly(types[1])}),
  enemy(types[2], 3410, 570, {'flying': fly(types[2])}),
  enemy(types[0], 4120, 620),
];

class Ch2 {
  Ch2(
    this.name,
    this.mechanic,
    this.tip,
    this.backdrop,
    this.tiles,
    this.colors,
    this.tree,
    this.cy,
    this.required,
    this.keys,
    this.enemies, {
    this.extra,
  });
  final String name;
  final String mechanic;
  final String tip;
  final String backdrop;
  final String tiles;
  final List<String> colors;
  final String tree;
  final double cy;
  final int required;
  final List<KeyItem> keys;
  final List<Enemy> enemies;
  final void Function(Area)? extra;
}

List<Ch2> chapterTwoDefs() => [
  Ch2(
    'Sunken Redwood',
    'Pasang-Surut Kanopi',
    'Naiki batang saat rakit daun bergerak mengikuti arus.',
    'FOREST_BACKDROP',
    'FOREST_PLATFORM_TILES',
    ['#061929', '#16536b', '#42dfbf', '#ffca6a'],
    'CLIMB_TREE_11',
    210,
    4,
    [
      key('karang', 'root_key', 760, 800),
      key('palung', 'ice_key', 2030, 1250),
      key('pasang', 'round_walnut', 3020, 850),
      key('mahkota', 'wind_key', 3720, 400),
    ],
    crowd(['frog', 'mosquito', 'snail']),
    extra: (a) {
      a.climbArt = ClimbArt('CLIMB_TREE_11', 1780, 210, 470, 1150);
      a.climbZones = [ClimbZone(1970, 250, 90, 1090, true)];
      a.movingPlatforms = [
        MovingPlatform(480, 1120, 150, 24, 260, 0.9, vertical: true),
        MovingPlatform(2690, 1120, 160, 24, 280, 1.1, vertical: true),
      ];
      a.hazards = [
        RectZone(470, 1450, 1220, 300),
        RectZone(2360, 1450, 1210, 300),
      ];
      a.worldWidth = 4700;
      a.worldHeight = 1800;
    },
  ),
  Ch2(
    'Tempest Orchard',
    'Petir & Angin Silang',
    'Lihat kilatan tanah sebelum petir menyambar.',
    'FOREST_BACKDROP',
    'FOREST_PLATFORM_TILES',
    ['#090d2b', '#303b76', '#4eeaff', '#ffe06b'],
    'CLIMB_TREE_12',
    180,
    4,
    [
      key('buah-badai', 'wind_key', 1100, 650),
      key('akar-petir', 'root_key', 2010, 1240),
      key('kilat', 'fire_key', 3370, 600),
      key('awan', 'ice_key', 3700, 400),
    ],
    crowd(['woodpecker', 'hawk', 'owl']),
    extra: (a) {
      a.climbArt = ClimbArt('CLIMB_TREE_12', 1780, 180, 500, 1190);
      a.climbZones = [ClimbZone(1980, 220, 92, 1120, true)];
      a.updrafts = [
        RectZone(880, 360, 120, 900),
        RectZone(2760, 300, 120, 1050),
      ];
      a.windZones = [
        RectZone(400, 300, 1100, 1150, 145),
        RectZone(2500, 260, 1300, 1180, -165),
      ];
      a.lightningZones = [
        RectZone(620, 0, 190, 0),
        RectZone(1450, 0, 220, 0),
        RectZone(2900, 0, 230, 0),
        RectZone(3920, 0, 210, 0),
      ];
      a.worldWidth = 4700;
      a.worldHeight = 1800;
    },
  ),
  Ch2(
    'Crystal Hive',
    'Gravitasi Kristal',
    'Zona kristal membuat lompatan dan glide lebih ringan.',
    'CAVERN_BACKDROP',
    'CAVERN_PLATFORM_TILES',
    ['#0b0824', '#472c69', '#74f0ff', '#f2a44f'],
    'CLIMB_TREE_13',
    190,
    4,
    [
      key('madu', 'round_walnut', 760, 800),
      key('sarang', 'root_key', 2010, 1240),
      key('prisma', 'ice_key', 3000, 850),
      key('ratu', 'fire_key', 3720, 400),
    ],
    crowd(['snail', 'mosquito', 'clockbeetle']),
    extra: (a) {
      a.climbArt = ClimbArt('CLIMB_TREE_13', 1780, 190, 460, 1170);
      a.climbZones = [ClimbZone(1960, 230, 90, 1110, true)];
      a.lowGravityZones = [
        RectZone(430, 280, 680, 1100),
        RectZone(2390, 250, 820, 1180),
      ];
      a.mushrooms = [
        {'color': 'blue', 'sprite': 'blue_mushroom', 'x': 1280, 'y': 1040},
        {'color': 'green', 'sprite': 'green_mushroom', 'x': 3170, 'y': 920},
      ];
      a.worldWidth = 4700;
      a.worldHeight = 1800;
    },
  ),
  Ch2(
    'Ashen Crown',
    'Panas & Ventilasi Bara',
    'Berhenti di batu gelap untuk memulihkan stamina dari panas.',
    'CORE_BACKDROP',
    'CORE_PLATFORM_TILES',
    ['#16080c', '#5b2b26', '#ff7a43', '#ffd16a'],
    'CLIMB_TREE_14',
    180,
    4,
    [
      key('abu', 'root_key', 760, 800),
      key('bara', 'fire_key', 2020, 1240),
      key('asap', 'wind_key', 3000, 850),
      key('mahkota-api', 'fire_key', 3710, 400),
    ],
    crowd(['clockbeetle', 'hawk', 'guardian']),
    extra: (a) {
      a.climbArt = ClimbArt('CLIMB_TREE_14', 1760, 180, 520, 1190);
      a.climbZones = [ClimbZone(1980, 220, 94, 1120, true)];
      a.hotZones = [
        RectZone(470, 520, 650, 850),
        RectZone(2520, 400, 720, 1000),
      ];
      a.updrafts = [
        RectZone(1220, 500, 130, 900),
        RectZone(3510, 250, 130, 1100),
      ];
      a.worldWidth = 4700;
      a.worldHeight = 1800;
    },
  ),
  Ch2(
    'Moonlit Grove',
    'Bayangan & Akar Pindah',
    'AKSI pada pusaran ungu untuk berpindah antarakar.',
    'CAVERN_BACKDROP',
    'CAVERN_PLATFORM_TILES',
    ['#07081b', '#292452', '#9a77ff', '#d8e4ff'],
    'CLIMB_TREE_15',
    170,
    4,
    [
      key('rembulan', 'ice_key', 760, 800),
      key('bayang', 'root_key', 2020, 1240),
      key('bintang', 'wind_key', 3000, 850),
      key('fajar', 'fire_key', 3710, 400),
    ],
    crowd(['mosquito', 'owl', 'mole']),
    extra: (a) {
      a.climbArt = ClimbArt('CLIMB_TREE_15', 1770, 170, 500, 1200);
      a.climbZones = [ClimbZone(1970, 210, 92, 1130, true)];
      a.shadowZones = [
        RectZone(780, 350, 620, 1050),
        RectZone(2680, 260, 650, 1180),
      ];
      a.teleporters = [
        {'id': 'bulan-a', 'x': 1040, 'y': 650, 'toX': 2860, 'toY': 850},
        {'id': 'bulan-b', 'x': 2860, 'y': 850, 'toX': 1040, 'toY': 650},
      ];
      a.worldWidth = 4700;
      a.worldHeight = 1800;
    },
  ),
  Ch2(
    'Skyroot Archipelago',
    'Pulau Akar Terapung',
    'Rangkai updraft; satu glide yang salah menjatuhkanmu ke akar bawah.',
    'FOREST_BACKDROP',
    'FOREST_PLATFORM_TILES',
    ['#07162d', '#35628b', '#8cecff', '#fff0a0'],
    'CLIMB_TREE_16',
    160,
    4,
    [
      key('pulau', 'root_key', 760, 800),
      key('awan', 'ice_key', 2020, 1240),
      key('angin', 'wind_key', 3000, 850),
      key('langit', 'fire_key', 3710, 400),
    ],
    crowd(['hawk', 'owl', 'mosquito']),
    extra: (a) {
      a.climbArt = ClimbArt('CLIMB_TREE_16', 1760, 160, 520, 1210);
      a.climbZones = [ClimbZone(1980, 200, 94, 1140, true)];
      a.updrafts = [
        RectZone(460, 300, 120, 1120),
        RectZone(1260, 270, 120, 1160),
        RectZone(2780, 250, 130, 1180),
        RectZone(3900, 210, 120, 1200),
      ];
      a.lowGravityZones = [RectZone(1500, 250, 1000, 1200)];
      a.movingPlatforms = [
        MovingPlatform(760, 1120, 140, 24, 260, 1.4, vertical: true),
        MovingPlatform(3370, 900, 140, 24, 300, 1.55, vertical: true),
      ];
      a.worldWidth = 4700;
      a.worldHeight = 1800;
    },
  ),
  Ch2(
    'Amber Fossil Deep',
    'Ekskavasi Fosil',
    'Semua kunci terkubur; cari retakan yang dijaga musuh.',
    'CAVERN_BACKDROP',
    'CAVERN_PLATFORM_TILES',
    ['#120c1c', '#54362a', '#ffbf55', '#81e0c0'],
    'CLIMB_TREE_17',
    190,
    4,
    [
      key('fosil-1', 'triangle_walnut', 760, 800, {'hidden': true}),
      key('fosil-2', 'root_key', 2020, 1240, {'hidden': true}),
      key('fosil-3', 'round_walnut', 3000, 850, {'hidden': true}),
      key('fosil-4', 'fire_key', 3710, 400, {'hidden': true}),
    ],
    crowd(['mole', 'snail', 'beetle']),
    extra: (a) {
      a.climbArt = ClimbArt('CLIMB_TREE_17', 1790, 190, 450, 1170);
      a.climbZones = [ClimbZone(1970, 230, 90, 1110, true)];
      a.digSpots = [
        {'id': 'fosil-1', 'x': 760, 'y': 870},
        {'id': 'fosil-2', 'x': 2020, 'y': 1320},
        {'id': 'fosil-3', 'x': 3000, 'y': 920},
        {'id': 'fosil-4', 'x': 3710, 'y': 470},
      ];
      a.crumblePlatforms = [
        {'x': 2440, 'y': 680},
        {'x': 3590, 'y': 470},
      ];
      a.worldWidth = 4700;
      a.worldHeight = 1800;
    },
  ),
  Ch2(
    'Chrono Bark',
    'Platform Waktu',
    'Gear bergerak cepat dan beberapa dahan runtuh setelah diinjak.',
    'CORE_BACKDROP',
    'CORE_PLATFORM_TILES',
    ['#0c0b1f', '#493a35', '#43e2de', '#e6b95d'],
    'CLIMB_TREE_18',
    160,
    4,
    [
      key('detik', 'gear_key', 760, 800),
      key('jam', 'root_key', 2020, 1240),
      key('masa', 'wind_key', 3000, 850),
      key('abadi', 'fire_key', 3710, 400),
    ],
    crowd(['clockbeetle', 'mosquito', 'guardian']),
    extra: (a) {
      a.climbArt = ClimbArt('CLIMB_TREE_18', 1750, 160, 540, 1210);
      a.climbZones = [ClimbZone(1980, 200, 94, 1140, true)];
      a.movingPlatforms = [
        MovingPlatform(480, 1160, 130, 24, 300, 2.1, vertical: true),
        MovingPlatform(2650, 1040, 130, 24, 320, 2.35, vertical: true),
        MovingPlatform(3820, 900, 130, 24, 310, 2.6, vertical: true),
      ];
      a.crumblePlatforms = [
        {'x': 970, 'y': 720},
        {'x': 2440, 'y': 680},
        {'x': 3220, 'y': 680},
      ];
      a.timeLimit = 140;
      a.worldWidth = 4700;
      a.worldHeight = 1800;
    },
  ),
  Ch2(
    'Dreamcap Nexus',
    'Portal Jamur',
    'Jamur dan pusaran ungu mengubah jalurmu—ingat pasangan portal.',
    'CAVERN_BACKDROP',
    'CAVERN_PLATFORM_TILES',
    ['#0d0720', '#4e2469', '#50e7ff', '#ff68bf'],
    'CLIMB_TREE_19',
    150,
    4,
    [
      key('mimpi', 'ice_key', 760, 800),
      key('spora', 'root_key', 2020, 1240),
      key('gema', 'wind_key', 3000, 850),
      key('bangun', 'fire_key', 3710, 400),
    ],
    crowd(['snail', 'mosquito', 'mole']),
    extra: (a) {
      a.climbArt = ClimbArt('CLIMB_TREE_19', 1760, 150, 520, 1220);
      a.climbZones = [ClimbZone(1980, 190, 94, 1150, true)];
      a.mushrooms = [
        {'color': 'red', 'sprite': 'red_mushroom', 'x': 500, 'y': 980},
        {'color': 'blue', 'sprite': 'blue_mushroom', 'x': 1280, 'y': 1040},
        {'color': 'green', 'sprite': 'green_mushroom', 'x': 3180, 'y': 920},
      ];
      a.teleporters = [
        {'id': 'mimpi-a', 'x': 1080, 'y': 650, 'toX': 3010, 'toY': 850},
        {'id': 'mimpi-b', 'x': 3010, 'y': 850, 'toX': 1080, 'toY': 650},
      ];
      a.lowGravityZones = [RectZone(1450, 260, 1050, 1180)];
      a.worldWidth = 4700;
      a.worldHeight = 1800;
    },
  ),
  Ch2(
    'Celestial Crown',
    'Ujian Langit',
    'Semua mekanik kembali; pilih skin yang cocok sebelum mendaki.',
    'CORE_BACKDROP',
    'CORE_PLATFORM_TILES',
    ['#06071a', '#39275d', '#58f0e4', '#ffd569'],
    'CLIMB_TREE_20',
    120,
    5,
    [
      key('angin-final', 'wind_key', 760, 800),
      key('es-final', 'ice_key', 2020, 1240),
      key('akar-final', 'root_key', 2600, 610),
      key('api-final', 'fire_key', 3370, 610),
      key('bintang-final', 'round_walnut', 4070, 550),
    ],
    [
      ...crowd(['guardian', 'owl', 'mosquito']),
      enemy('guardian', 4380, 430),
    ],
    extra: (a) {
      a.climbArt = ClimbArt('CLIMB_TREE_20', 1740, 120, 560, 1250);
      a.climbZones = [ClimbZone(1980, 160, 98, 1180, true)];
      a.updrafts = [
        RectZone(820, 260, 130, 1170),
        RectZone(2760, 230, 130, 1200),
      ];
      a.windZones = [RectZone(3000, 250, 900, 1180, -180)];
      a.lowGravityZones = [RectZone(1350, 240, 1180, 1220)];
      a.shadowZones = [RectZone(3550, 210, 700, 1220)];
      a.movingPlatforms = [
        MovingPlatform(600, 1180, 130, 24, 300, 2, vertical: true),
        MovingPlatform(3290, 980, 130, 24, 330, 2.25, vertical: true),
      ];
      a.vines = [
        {'x': 1180, 'y': 420},
        {'x': 3060, 'y': 280},
        {'x': 4050, 'y': 220},
      ];
      a.timeLimit = 190;
      a.worldWidth = 4700;
      a.worldHeight = 1800;
    },
  ),
];

void pushChapterTwo(List<Area> list) {
  for (final def in chapterTwoDefs()) {
    final area =
        Area(
            name: def.name,
            mechanic: def.mechanic,
            tip: def.tip,
            backdrop: def.backdrop,
            tiles: def.tiles,
            colors: def.colors,
            spawn: {'x': 110, 'y': 980},
            portal: {'x': 4510, 'y': 350},
            required: def.required,
          )
          ..platforms = widePlatforms()
          ..climbArt = ClimbArt(def.tree, 1740, def.cy, 560, 1250)
          ..climbZones = [ClimbZone(1980, def.cy - 50, 98, 1190, true)]
          ..keys = def.keys
          ..enemies = def.enemies
          ..emblems = [Emblem(610, 650), Emblem(2200, 430), Emblem(4070, 500)];
    def.extra?.call(area);
    list.add(area);
  }

  // Snap chapter-two objectives & ground enemies to their routes.
  for (final area in list.sublist(
    10,
    list.length - 10 < 0 ? list.length : list.length,
  )) {
    area.portal = {'x': area.portal['x']!, 'y': 420};
    for (final item in area.keys) {
      final plat = area.platforms.cast<Platform?>().firstWhere(
        (e) => item.x >= e!.x && item.x <= e.x + e.w,
        orElse: () => null,
      );
      if (plat != null) item.y = plat.y - 65;
    }
    for (final foe in area.enemies) {
      if (foe.flying) continue;
      final plat = area.platforms.cast<Platform?>().firstWhere(
        (e) => foe.x >= e!.x && foe.x <= e.x + e.w,
        orElse: () => null,
      );
      if (plat != null) foe.y = plat.y;
    }
    area.worldWidth ??= 4700;
    area.worldHeight ??= 1800;
  }
}
