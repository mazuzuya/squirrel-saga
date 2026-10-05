import 'dart:math' as math;

import 'level_models.dart';
import 'levels_ch2.dart';

const Set<String> fly2Set = {
  'conewasp',
  'windserpent',
  'embermoth',
  'moonwraith',
  'skyjelly',
  'starwraith',
};

void buildChapterThree(List<Area> list) {
  final configs = [
    [
      'Verdant Colossus',
      'Benih Raksasa',
      'CLIMB_TREE_21',
      'FOREST_BACKDROP',
      'FOREST_PLATFORM_TILES',
      ['#061c1a', '#286044', '#7df079', '#ffd66a'],
      'sunscarab',
      'thornwolf',
      'growth',
    ],
    [
      'Thunder Nest',
      'Sarang Petir',
      'CLIMB_TREE_22',
      'FOREST_BACKDROP',
      'FOREST_PLATFORM_TILES',
      ['#090d2b', '#3f4780', '#50e6ff', '#ffe468'],
      'voidbat',
      'eclipseowl',
      'storm',
    ],
    [
      'Mirrorwood',
      'Dunia Pantulan',
      'CLIMB_TREE_23',
      'CAVERN_BACKDROP',
      'CAVERN_PLATFORM_TILES',
      ['#0b0922', '#4d3a68', '#a9efff', '#e889ff'],
      'prismlion',
      'moonwraith',
      'mirror',
    ],
    [
      'Lava Sap Foundry',
      'Pabrik Getah Api',
      'CLIMB_TREE_24',
      'CORE_BACKDROP',
      'CORE_PLATFORM_TILES',
      ['#18080a', '#63332b', '#ff7148', '#ffd26a'],
      'lavacrab',
      'gearspider',
      'lava',
    ],
    [
      'Abyssal Roots',
      'Akar Jurang',
      'CLIMB_TREE_25',
      'CAVERN_BACKDROP',
      'CAVERN_PLATFORM_TILES',
      ['#050615', '#25234e', '#4de2d9', '#f15bb5'],
      'voidbat',
      'bogstalker',
      'abyss',
    ],
    [
      'Cloud Temple',
      'Kuil Langit',
      'CLIMB_TREE_26',
      'FOREST_BACKDROP',
      'FOREST_PLATFORM_TILES',
      ['#07182e', '#4d78a0', '#d9f3ff', '#f2cf68'],
      'cloudray',
      'skyjelly',
      'cloud',
    ],
    [
      'Prism Orchard',
      'Kebun Spektrum',
      'CLIMB_TREE_27',
      'FOREST_BACKDROP',
      'FOREST_PLATFORM_TILES',
      ['#100d2d', '#503b7a', '#58f0e4', '#ff8bd5'],
      'prismlion',
      'crystalmite',
      'prism',
    ],
    [
      'Bonewood Catacomb',
      'Katakombe Fosil',
      'CLIMB_TREE_28',
      'CAVERN_BACKDROP',
      'CAVERN_PLATFORM_TILES',
      ['#100c18', '#4f4037', '#efdcaa', '#e8a950'],
      'thornwolf',
      'riverwyrm',
      'bone',
    ],
    [
      'Eclipse Canopy',
      'Kanopi Gerhana',
      'CLIMB_TREE_29',
      'CORE_BACKDROP',
      'CORE_PLATFORM_TILES',
      ['#070619', '#452850', '#ffd45d', '#aa72ff'],
      'eclipseowl',
      'starwraith',
      'eclipse',
    ],
    [
      'Heart of Seasons',
      'Jantung Empat Musim',
      'CLIMB_TREE_30',
      'CORE_BACKDROP',
      'CORE_PLATFORM_TILES',
      ['#071424', '#3b5c50', '#7de58a', '#ffd166'],
      'sunscarab',
      'guardian',
      'seasons',
    ],
  ];
  for (var i = 0; i < configs.length; i += 1) {
    final c = configs[i];
    final kind = c[8] as String;
    final area =
        Area(
            name: c[0] as String,
            mechanic: c[1] as String,
            tip: 'Gunakan seluruh tinggi dunia dan kalahkan penjaga jalur.',
            backdrop: c[3] as String,
            tiles: c[4] as String,
            colors: List<String>.from(c[5] as List),
            spawn: {'x': 110, 'y': 980},
            portal: {'x': 4510, 'y': 420},
            required: i == 9 ? 5 : 4,
          )
          ..platforms = widePlatforms()
          ..climbArt = ClimbArt(c[2] as String, 1740, 120, 560, 1270)
          ..climbZones = [ClimbZone(1980, 170, 98, 1190, true)]
          ..keys = [
            key('$kind-1', 'wind_key', 760, 835),
            key('$kind-2', 'root_key', 2020, 1255),
            key('$kind-3', 'ice_key', 3000, 755),
            key('$kind-4', 'fire_key', 3710, 595),
          ]
          ..enemies = [
            ...crowd([
              c[6] as String,
              c[7] as String,
              i % 2 == 1 ? 'starwraith' : 'gearspider',
            ]),
            enemy(c[6] as String, 4380, 500),
          ]
          ..emblems = [Emblem(610, 650), Emblem(2200, 430), Emblem(4070, 500)]
          ..worldWidth = 4700
          ..worldHeight = 1900;
    if (i == 9) area.keys.add(key('seasons-5', 'round_walnut', 4200, 515));
    if (['storm', 'eclipse'].contains(kind))
      area.lightningZones = [
        RectZone(620, 0, 190, 0),
        RectZone(2880, 0, 220, 0),
        RectZone(3950, 0, 210, 0),
      ];
    if (['mirror', 'cloud', 'prism'].contains(kind))
      area.lowGravityZones = [RectZone(1300, 240, 1250, 1250)];
    if (kind == 'mirror')
      area.teleporters = [
        {'id': 'mirror-a', 'x': 1050, 'y': 760, 'toX': 3050, 'toY': 700},
        {'id': 'mirror-b', 'x': 3050, 'y': 700, 'toX': 1050, 'toY': 760},
      ];
    if (kind == 'lava') {
      area.hotZones = [
        RectZone(500, 350, 900, 1100),
        RectZone(2750, 300, 900, 1150),
      ];
      area.updrafts = [RectZone(1500, 350, 130, 1000)];
    }
    if (kind == 'abyss')
      area.shadowZones = [
        RectZone(700, 260, 1100, 1250),
        RectZone(3000, 230, 900, 1280),
      ];
    if (kind == 'cloud')
      area.updrafts = [
        RectZone(520, 240, 130, 1200),
        RectZone(2800, 220, 130, 1250),
      ];
    if (kind == 'bone')
      area.crumblePlatforms = [
        {'x': 970, 'y': 820},
        {'x': 2440, 'y': 680},
        {'x': 3590, 'y': 660},
      ];
    if (kind == 'seasons') {
      area.updrafts = [RectZone(900, 230, 130, 1250)];
      area.shadowZones = [RectZone(3300, 220, 700, 1250)];
      area.timeLimit = 220;
    }
    for (final foe in area.enemies) {
      if (foe.flying) continue;
      final plat = area.platforms.cast<Platform?>().firstWhere(
        (e) => foe.x >= e!.x && foe.x <= e.x + e.w,
        orElse: () => null,
      );
      if (plat != null) foe.y = plat.y;
    }
    list.add(area);
  }
}

void applyLandmarkGauntlet(List<Area> list) {
  const landmarks = [
    ['oak_gust_bell', 'gust', 'Lonceng angin membuka arus menuju portal.'],
    [
      'pine_resin_lantern',
      'reveal',
      'Lentera resin menyingkap jalur tersembunyi.',
    ],
    ['canyon_wind_turbine', 'gust', 'Turbin daun membangkitkan arus kuat.'],
    [
      'root_burrow_switch',
      'tunnel',
      'Sakelar akar melontarkan Luma ke jalur atas.',
    ],
    ['cavern_color_prism', 'prism', 'Prisma warna memulihkan tenaga dan hati.'],
    [
      'waterfall_waterwheel',
      'slow',
      'Roda air memperlambat semua mesin bergerak.',
    ],
    [
      'frost_heat_brazier',
      'shield',
      'Bara kuno memberi pelindung dari bahaya.',
    ],
    ['clockwork_time_switch', 'time', 'Sakelar waktu memberi waktu tambahan.'],
    [
      'swamp_purifier_flower',
      'shield',
      'Bunga pemurni memberi pelindung racun.',
    ],
    [
      'core_gravity_totem',
      'gravity',
      'Totem membentuk kantong gravitasi ringan.',
    ],
    ['redwood_tide_valve', 'slow', 'Katup pasang memperlambat rakit daun.'],
    [
      'orchard_lightning_rod',
      'lightning',
      'Penangkal petir mematikan sambaran.',
    ],
    ['hive_honey_prism', 'prism', 'Prisma madu memulihkan seluruh tenaga.'],
    ['ashen_ember_vent', 'gust', 'Ventilasi bara menciptakan arus panas.'],
    ['moon_mirror', 'phase', 'Cermin bulan memberi perlindungan bayangan.'],
    [
      'skyroot_sky_anchor',
      'slow',
      'Jangkar langit menstabilkan pulau bergerak.',
    ],
    [
      'amber_fossil_drill',
      'reveal',
      'Bor fosil membuka semua retakan terkubur.',
    ],
    ['chrono_master_dial', 'time', 'Dial utama menambahkan waktu perjalanan.'],
    [
      'dreamcap_dream_mirror',
      'tunnel',
      'Cermin mimpi memindahkan Luma ke kanopi.',
    ],
    [
      'celestial_star_seal',
      'prism',
      'Segel bintang memulihkan kekuatan terakhir.',
    ],
    [
      'worldseed_loom',
      'prism',
      'Alat tenun benih menumbuhkan jalan terakhir.',
      'landmarks2',
    ],
    [
      'storm_nest_beacon',
      'lightning',
      'Mercusuar sarang menetralkan petir.',
      'landmarks2',
    ],
    [
      'mirrorwood_lens',
      'phase',
      'Lensa cermin memberi perlindungan pantulan.',
      'landmarks2',
    ],
    [
      'lava_sap_forge',
      'shield',
      'Tempa getah memberi pelindung panas.',
      'landmarks2',
    ],
    [
      'abyss_echo_conch',
      'tunnel',
      'Gema jurang melontarkan Luma ke jalur atas.',
      'landmarks2',
    ],
    [
      'cloud_temple_bell',
      'gust',
      'Lonceng kuil membangkitkan arus langit.',
      'landmarks2',
    ],
    [
      'prism_orchard_core',
      'prism',
      'Inti prisma memulihkan tenaga.',
      'landmarks2',
    ],
    [
      'bonewood_archive',
      'reveal',
      'Arsip fosil menyingkap jalur rahasia.',
      'landmarks2',
    ],
    ['eclipse_orrery', 'time', 'Orrery gerhana menambah waktu.', 'landmarks2'],
    [
      'seasons_heart',
      'prism',
      'Jantung musim memulihkan seluruh kekuatan.',
      'landmarks2',
    ],
  ];
  const newEnemyTypes = [
    'thornboar',
    'conewasp',
    'sapslime',
    'barkmantis',
    'windserpent',
    'crystalmite',
    'embermoth',
    'moonwraith',
    'gearspider',
    'bogstalker',
    'skyjelly',
    'starwraith',
  ];
  for (var index = 0; index < list.length; index += 1) {
    final area = list[index];
    final baseY = math.max(320, math.min(1460, area.portal['y']! + 90));
    area.platforms.addAll([
      p(4600, baseY + 50, 290),
      p(4850, baseY - 20, 290),
      p(5100, baseY - 90, 290),
      p(5350, baseY - 20, 290),
      p(5580, baseY - 100, 260),
    ]);
    final lm = landmarks[index];
    final sheet = lm.length > 3 ? lm[3] : 'landmarks';
    area.mechanicNodes = [
      {
        'id': 'landmark-${index + 1}',
        'sprite': lm[0],
        'effect': lm[1],
        'message': lm[2],
        'sheet': sheet,
        'x': 5440,
        'y': baseY - 90,
      },
    ];
    area.nodesRequired = 1;
    final firstType = newEnemyTypes[index % newEnemyTypes.length];
    final secondType = newEnemyTypes[(index + 5) % newEnemyTypes.length];
    final thirdType = newEnemyTypes[(index + 9) % newEnemyTypes.length];
    area.enemies.add(
      enemy(firstType, 4750, baseY + 50, {
        'flying': fly2Set.contains(firstType),
      }),
    );
    area.enemies.add(
      enemy(
        secondType,
        5220,
        baseY - (fly2Set.contains(secondType) ? 170 : 90),
        {'flying': fly2Set.contains(secondType)},
      ),
    );
    area.enemies.add(
      enemy(
        thirdType,
        5650,
        baseY - (fly2Set.contains(thirdType) ? 210 : 100),
        {'flying': fly2Set.contains(thirdType)},
      ),
    );
    area.portal = {'x': 5750, 'y': baseY - 180};
    area.worldWidth = 5900;
    area.worldHeight = 1900;
  }
}

void applyKeeperGauntlet(List<Area> list) {
  const ch3Types = [
    'sunscarab',
    'voidbat',
    'thornwolf',
    'riverwyrm',
    'lavacrab',
    'cloudray',
    'prismlion',
    'eclipseowl',
  ];
  const ch3Flying = {'voidbat', 'cloudray', 'eclipseowl'};
  for (var index = 0; index < list.length; index += 1) {
    final area = list[index];
    final baseY = math.max(340, math.min(1580, area.portal['y']! + 100));
    area.platforms.addAll([
      p(5850, baseY + 60, 300),
      p(6120, baseY - 10, 300),
      p(6390, baseY - 80, 300),
      p(6660, baseY - 10, 300),
      p(6930, baseY - 90, 350),
    ]);
    final keepers = [
      ch3Types[index % 8],
      ch3Types[(index + 3) % 8],
      ch3Types[(index + 6) % 8],
    ];
    area.enemies.add(
      enemy(keepers[0], 6020, baseY + 60, {
        'flying': ch3Flying.contains(keepers[0]),
        'gateKeeper': true,
      }),
    );
    area.enemies.add(
      enemy(
        keepers[1],
        6500,
        baseY - (ch3Flying.contains(keepers[1]) ? 190 : 80),
        {'flying': ch3Flying.contains(keepers[1]), 'gateKeeper': true},
      ),
    );
    area.enemies.add(
      enemy(
        keepers[2],
        7040,
        baseY - (ch3Flying.contains(keepers[2]) ? 210 : 90),
        {'flying': ch3Flying.contains(keepers[2]), 'gateKeeper': true},
      ),
    );
    area.portal = {'x': 7180, 'y': baseY - 170};
    area.worldWidth = 7350;
    area.worldHeight = 2100;
  }
}
