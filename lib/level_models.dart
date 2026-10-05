class Platform {
  Platform(this.x, this.y, this.w, [this.h = 46, this.kind = 'normal']);
  double x;
  double y;
  double w;
  double h;
  String kind;
  bool disabled = false;
  double crumbleTime = 0;

  Platform clone() => Platform(x, y, w, h, kind)
    ..disabled = disabled
    ..crumbleTime = crumbleTime;
}

class KeyItem {
  KeyItem(
    this.id,
    this.sprite,
    this.x,
    this.y, {
    this.hidden = false,
    this.frozen = false,
    this.toxic = false,
    this.gear = false,
    this.heavy = false,
  });
  final String id;
  final String sprite;
  double x;
  double y;
  bool collected = false;
  bool hidden;
  bool frozen;
  bool toxic;
  bool gear;
  bool heavy;

  KeyItem clone() => KeyItem(
    id,
    sprite,
    x,
    y,
    hidden: hidden,
    frozen: frozen,
    toxic: toxic,
    gear: gear,
    heavy: heavy,
  )..collected = collected;
}

class Enemy {
  Enemy(
    this.type,
    this.x,
    this.y, {
    this.flying = false,
    this.gateKeeper = false,
    int? hp,
  }) : originX = x,
       hp = hp ?? (type == 'guardian' ? 4 : 1);
  final String type;
  double x;
  double y;
  final double originX;
  bool alive = true;
  int hp;
  bool flying;
  bool gateKeeper;
  String state = 'patrol';
  double hitTime = 0;
  double defeatTime = 0;
  double timer = 0;
  int dir = -1;

  Enemy clone() =>
      Enemy(type, x, y, flying: flying, gateKeeper: gateKeeper, hp: hp)
        ..alive = alive
        ..state = state
        ..hitTime = hitTime
        ..defeatTime = defeatTime
        ..timer = timer
        ..dir = dir;
}

class RectZone {
  RectZone(this.x, this.y, this.w, this.h, [this.force]);
  double x;
  double y;
  double w;
  double h;
  final double? force;

  RectZone clone() => RectZone(x, y, w, h, force);
}

class ClimbZone extends RectZone {
  ClimbZone(super.x, super.y, super.w, super.h, this.art);
  final bool art;

  @override
  ClimbZone clone() => ClimbZone(x, y, w, h, art);
}

class Emblem {
  Emblem(this.x, this.y);
  double x;
  double y;
  bool collected = false;

  Emblem clone() => Emblem(x, y)..collected = collected;
}

class MovingPlatform {
  MovingPlatform(
    this.x,
    this.y,
    this.w,
    this.h,
    this.range,
    this.speed, {
    this.vertical = false,
  });
  double x;
  double y;
  double w;
  double h;
  double range;
  double speed;
  bool vertical;
  double currentX = 0;
  double currentY = 0;
  double dx = 0;

  MovingPlatform clone() =>
      MovingPlatform(x, y, w, h, range, speed, vertical: vertical)
        ..currentX = currentX
        ..currentY = currentY
        ..dx = dx;
}

class ClimbArt {
  ClimbArt(this.key, this.x, this.y, this.w, this.h);
  final String key;
  final double x;
  final double y;
  final double w;
  final double h;
}

class Area {
  Area({
    required this.name,
    required this.mechanic,
    required this.tip,
    required this.backdrop,
    required this.tiles,
    required this.colors,
    required this.spawn,
    required this.portal,
    required this.required,
  });
  final String name;
  final String mechanic;
  final String tip;
  final String backdrop;
  final String tiles;
  final List<String> colors;
  Map<String, double> spawn;
  Map<String, double> portal;
  int required;
  double? timeLimit;
  List<String>? sequence;
  List<Platform> platforms = [];
  List<ClimbZone>? climbZones;
  List<KeyItem> keys = [];
  List<Enemy> enemies = [];
  List<MovingPlatform>? movingPlatforms;
  List<RectZone>? updrafts;
  List<RectZone>? windZones;
  List<RectZone>? hazards;
  List<RectZone>? lowGravityZones;
  List<RectZone>? shadowZones;
  List<RectZone>? hotZones;
  List<RectZone>? lightningZones;
  List<Map<String, dynamic>>? mushrooms;
  List<Map<String, dynamic>>? levers;
  List<Map<String, dynamic>>? vines;
  List<Map<String, dynamic>>? digSpots;
  List<Map<String, dynamic>>? teleporters;
  List<Map<String, dynamic>>? mechanicNodes;
  List<Map<String, double>>? crumblePlatforms;
  RectZone? heat;
  RectZone? spring;
  RectZone? mechanism;
  ClimbArt? climbArt;
  double? worldWidth;
  double? worldHeight;
  int? nodesRequired;
  List<Emblem>? emblems;

  Area clone() {
    final a = Area(
      name: name,
      mechanic: mechanic,
      tip: tip,
      backdrop: backdrop,
      tiles: tiles,
      colors: List.from(colors),
      spawn: Map.from(spawn),
      portal: Map.from(portal),
      required: required,
    );
    a.timeLimit = timeLimit;
    a.sequence = sequence == null ? null : List.from(sequence!);
    a.platforms = platforms.map((e) => e.clone()).toList();
    a.climbZones = climbZones?.map((e) => e.clone()).toList();
    a.keys = keys.map((e) => e.clone()).toList();
    a.enemies = enemies.map((e) => e.clone()).toList();
    a.movingPlatforms = movingPlatforms?.map((e) => e.clone()).toList();
    a.updrafts = updrafts?.map((e) => e.clone()).toList();
    a.windZones = windZones?.map((e) => e.clone()).toList();
    a.hazards = hazards?.map((e) => e.clone()).toList();
    a.lowGravityZones = lowGravityZones?.map((e) => e.clone()).toList();
    a.shadowZones = shadowZones?.map((e) => e.clone()).toList();
    a.hotZones = hotZones?.map((e) => e.clone()).toList();
    a.lightningZones = lightningZones?.map((e) => e.clone()).toList();
    a.mushrooms = mushrooms?.map((e) => Map<String, dynamic>.from(e)).toList();
    a.levers = levers?.map((e) => Map<String, dynamic>.from(e)).toList();
    a.vines = vines?.map((e) => Map<String, dynamic>.from(e)).toList();
    a.digSpots = digSpots?.map((e) => Map<String, dynamic>.from(e)).toList();
    a.teleporters = teleporters
        ?.map((e) => Map<String, dynamic>.from(e))
        .toList();
    a.mechanicNodes = mechanicNodes
        ?.map((e) => Map<String, dynamic>.from(e))
        .toList();
    a.crumblePlatforms = crumblePlatforms
        ?.map((e) => Map<String, double>.from(e))
        .toList();
    a.heat = heat?.clone();
    a.spring = spring?.clone();
    a.mechanism = mechanism?.clone();
    a.climbArt = climbArt;
    a.worldWidth = worldWidth;
    a.worldHeight = worldHeight;
    a.nodesRequired = nodesRequired;
    a.emblems = emblems?.map((e) => e.clone()).toList();
    return a;
  }
}

Platform p(
  double x,
  double y,
  double w, [
  double h = 46,
  String kind = 'normal',
]) => Platform(x, y, w, h, kind);

KeyItem key(
  String id,
  String sprite,
  double x,
  double y, [
  Map<String, dynamic> extra = const {},
]) => KeyItem(
  id,
  sprite,
  x,
  y,
  hidden: extra['hidden'] == true,
  frozen: extra['frozen'] == true,
  toxic: extra['toxic'] == true,
  gear: extra['gear'] == true,
  heavy: extra['heavy'] == true,
);

Enemy enemy(
  String type,
  double x,
  double y, [
  Map<String, dynamic> extra = const {},
]) => Enemy(
  type,
  x,
  y,
  flying: extra['flying'] == true,
  gateKeeper: extra['gateKeeper'] == true,
  hp: extra['hp'] as int?,
);

const Set<String> flySet = {'hawk', 'owl', 'mosquito'};
bool fly(String t) => flySet.contains(t);

const Map<String, String> enemySheet = {
  'beetle': 'woodland',
  'woodpecker': 'woodland',
  'hawk': 'woodland',
  'mole': 'woodland',
  'snail': 'elemental',
  'frog': 'elemental',
  'owl': 'elemental',
  'clockbeetle': 'elemental',
  'mosquito': 'final',
  'guardian': 'final',
  'thornboar': 'newForest',
  'conewasp': 'newForest',
  'sapslime': 'newForest',
  'barkmantis': 'newForest',
  'windserpent': 'newArcane',
  'crystalmite': 'newArcane',
  'embermoth': 'newArcane',
  'moonwraith': 'newArcane',
  'gearspider': 'newWeird',
  'bogstalker': 'newWeird',
  'skyjelly': 'newWeird',
  'starwraith': 'newWeird',
  'sunscarab': 'chapter3A',
  'voidbat': 'chapter3A',
  'thornwolf': 'chapter3A',
  'riverwyrm': 'chapter3A',
  'lavacrab': 'chapter3B',
  'cloudray': 'chapter3B',
  'prismlion': 'chapter3B',
  'eclipseowl': 'chapter3B',
};
