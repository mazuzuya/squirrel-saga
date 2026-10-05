import 'dart:math' as math;

class Skin {
  const Skin({
    required this.id,
    required this.name,
    required this.buff,
    required this.color,
    required this.stats,
  });

  final int id;
  final String name;
  final String buff;
  final String color;
  final Map<String, dynamic> stats;

  dynamic stat(String key, [dynamic fallback]) => stats[key] ?? fallback;
}

const List<Skin> skins = [
  Skin(id: 0, name: 'Luma Asli', buff: 'Seimbang', color: '#f0a45d', stats: {}),
  Skin(
    id: 1,
    name: 'Zephyr Scout',
    buff: 'Glide -30% stamina',
    color: '#62eaf4',
    stats: {'glideCost': 0.7},
  ),
  Skin(
    id: 2,
    name: 'Ironbark',
    buff: '+1 hati',
    color: '#89b45f',
    stats: {'maxHearts': 4},
  ),
  Skin(
    id: 3,
    name: 'Embertail',
    buff: 'Serangan 2x',
    color: '#ff744b',
    stats: {'attackDamage': 2},
  ),
  Skin(
    id: 4,
    name: 'Frostpaw',
    buff: 'Tidak licin di es',
    color: '#9cecff',
    stats: {'iceGrip': true},
  ),
  Skin(
    id: 5,
    name: 'Rootwarden',
    buff: 'Panjat -35% stamina',
    color: '#69d779',
    stats: {'climbCost': 0.65},
  ),
  Skin(
    id: 6,
    name: 'Moonshade',
    buff: 'Kebal lebih lama',
    color: '#b283ff',
    stats: {'invincible': 1.65},
  ),
  Skin(
    id: 7,
    name: 'Stormwing',
    buff: 'Updraft 50% kuat',
    color: '#55dfff',
    stats: {'updraft': 1.5},
  ),
  Skin(
    id: 8,
    name: 'Gearbound',
    buff: 'Serangan lebih cepat',
    color: '#e9b04f',
    stats: {'attackCooldown': 0.28},
  ),
  Skin(
    id: 9,
    name: 'Mirestrider',
    buff: 'Tahan racun sekali',
    color: '#b9ec55',
    stats: {'hazardShield': true},
  ),
  Skin(
    id: 10,
    name: 'Astral Heart',
    buff: '+18% lari & stamina',
    color: '#f4e38f',
    stats: {'speed': 1.18, 'staminaRegen': 1.25},
  ),
  Skin(
    id: 11,
    name: 'Solarflare',
    buff: 'Lompat tinggi & tahan panas',
    color: '#ffb347',
    stats: {'jumpBoost': 1.15, 'heatImmune': true},
  ),
  Skin(
    id: 12,
    name: 'Voidwing',
    buff: 'Glide -50% stamina',
    color: '#705cff',
    stats: {'glideCost': 0.5},
  ),
  Skin(
    id: 13,
    name: 'Thorn Knight',
    buff: '+1 hati & serang kuat',
    color: '#75bd63',
    stats: {'maxHearts': 4, 'attackDamage': 1.5},
  ),
  Skin(
    id: 14,
    name: 'River Spirit',
    buff: '+12% lari',
    color: '#49dbd1',
    stats: {'speed': 1.12},
  ),
  Skin(
    id: 15,
    name: 'Prism Sage',
    buff: 'Stamina pulih 60% cepat',
    color: '#e68cff',
    stats: {'staminaRegen': 1.6},
  ),
  Skin(
    id: 16,
    name: 'Lavaforged',
    buff: 'Kebal panas & tahan bahaya',
    color: '#ff6948',
    stats: {'heatImmune': true, 'hazardShield': true},
  ),
  Skin(
    id: 17,
    name: 'Cloud Monk',
    buff: 'Bisa lompat dua kali',
    color: '#d9f3ff',
    stats: {'doubleJump': 1},
  ),
  Skin(
    id: 18,
    name: 'Chronosprint',
    buff: 'Mesin lambat, lari cepat',
    color: '#e5b957',
    stats: {'speed': 1.12, 'movingSlow': 1},
  ),
  Skin(
    id: 19,
    name: 'Dreamweaver',
    buff: 'Kebal lebih lama',
    color: '#cb77ff',
    stats: {'invincible': 2},
  ),
  Skin(
    id: 20,
    name: 'Worldseed',
    buff: 'Semua kemampuan meningkat',
    color: '#dff58b',
    stats: {
      'maxHearts': 4,
      'speed': 1.12,
      'glideCost': 0.8,
      'climbCost': 0.8,
      'staminaRegen': 1.2,
    },
  ),
];

Skin skinById(int id) => skins[math.min(skins.length - 1, math.max(0, id))];

final List<int> skinIds = [for (var i = 0; i < skins.length; i += 1) i];
