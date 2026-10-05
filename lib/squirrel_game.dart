import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio_manager.dart';
import 'game_assets.dart';
import 'level_models.dart';
import 'levels.dart';
import 'skins.dart';

const double _playerHalf = 22;
const double _gravity = 980;

double _approach(double value, double target, double amount) => value < target
    ? math.min(target, value + amount)
    : math.max(target, value - amount);

double _clampD(double v, double lo, double hi) =>
    v < lo ? lo : (v > hi ? hi : v);

class _Particle {
  _Particle(
    this.x,
    this.y,
    this.vx,
    this.vy,
    this.life,
    this.maxLife,
    this.color,
    this.size,
  );
  double x, y, vx, vy, life, maxLife;
  Color color;
  double size;
}

class _Col {
  _Col(this.x, this.y, this.w, this.h, this.kind, [this.moving]);
  double x, y, w, h;
  String kind;
  MovingPlatform? moving;
}

class SquirrelGame with Game {
  SquirrelGame(this.lib);
  final GameLibrary lib;

  final AudioManager audio = AudioManager.instance;

  late Area area;
  int areaIndex = 0;
  int skinId = 0;

  // input
  bool _left = false, _right = false;
  bool _jumpHeld = false, _jumpEdge = false;
  bool _actionHeld = false, _actionEdge = false;
  bool _attackEdge = false;
  bool _pauseEdge = false;

  // player
  double px = 0, py = 0, vx = 0, vy = 0;
  int facing = 1, hearts = 3, maxHearts = 3;
  double stamina = 100;
  bool onGround = false, gliding = false, climbing = false;
  String anim = 'idle';
  double attackTime = 0,
      attackCooldown = 0,
      hurtTime = 0,
      invincible = 0,
      actionAnim = 0;
  String actionKind = 'dig';
  int airJumps = 0;
  bool hazardShield = false;

  // run state (mirrors JS `state`)
  int collected = 0;
  final Set<String> nodesActivated = {};
  final Set<String> activated = {};
  int sequenceIndex = 0;
  String? carryMode;
  bool mechanismActive = false;
  double clock = 0;
  double campaignTime = 0;
  double timeLeft = 0;
  bool mechanicSlow = false;
  bool lightningOff = false;
  int runEmblems = 0;
  double checkpointX = 0, checkpointY = 0;
  bool resultOpen = false;
  bool won = false;
  String hint = '';
  double hintTimer = 0;

  // audio transition tracking
  bool _wasOnGround = true;
  bool _wasGliding = false;
  bool _lowTimeWarned = false;
  bool _portalWasReady = false;

  final List<_Particle> particles = [];

  // render camera cache
  double _camX = 0, _camY = 0, _scale = 1;
  late ui.Canvas _cv;

  // ---------------- input API (called by main) ----------------
  void setLeft(bool v) => _left = v;
  void setRight(bool v) => _right = v;
  void setJumpHeld(bool v) {
    if (v && !_jumpHeld) _jumpEdge = true;
    _jumpHeld = v;
  }

  void setActionHeld(bool v) {
    if (v && !_actionHeld) _actionEdge = true;
    _actionHeld = v;
  }

  void pressAttack() => _attackEdge = true;
  void pressPause() => _pauseEdge = true;
  void setSkin(int id) {
    skinId = id;
    maxHearts = _statI('maxHearts', 3);
    hazardShield = _statB('hazardShield');
  }

  void advance() {
    if (resultOpen && !won) loadArea(areaIndex + 1);
  }

  bool get isResultOpen => resultOpen;

  void restart() => loadArea(areaIndex);

  void setMove(int dir) {
    setLeft(dir < 0);
    setRight(dir > 0);
  }

  void setClimb(int v) {
    if (v != 0 && !_actionHeld) _actionEdge = true;
    _actionHeld = v != 0;
  }

  void attack() => pressAttack();

  void setAction(bool v) => setActionHeld(v);

  // ---------------- helpers ----------------
  double _statD(String n, double fb) {
    final v = skinById(skinId).stat(n, fb);
    return v is num ? v.toDouble() : fb;
  }

  int _statI(String n, int fb) {
    final v = skinById(skinId).stat(n, fb);
    return v is num ? v.toInt() : fb;
  }

  bool _statB(String n) {
    final v = skinById(skinId).stat(n, false);
    return v == true;
  }

  Sheet? sheet(String name) => lib.sheets[name];

  bool _near(double x, double y, double tx, double ty, double r) =>
      math.sqrt((x - tx) * (x - tx) + (y - ty) * (y - ty)) < r;
  bool _inside(double x, double y, RectZone z) =>
      x > z.x && x < z.x + z.w && y > z.y && y < z.y + z.h;

  void _burst(double x, double y, Color c, [int count = 10]) {
    final amount = math.max(2, (count * 1).round());
    for (var i = 0; i < amount; i += 1) {
      particles.add(
        _Particle(
          x,
          y,
          (math.Random().nextDouble() - .5) * 210,
          -40 - math.Random().nextDouble() * 190,
          .35 + math.Random().nextDouble() * .45,
          .8,
          c,
          4 + math.Random().nextDouble() * 5,
        ),
      );
    }
  }

  // ---------------- load ----------------
  void loadArea(int index) {
    areaIndex = index.clamp(0, areaCount - 1);
    area = makeArea(areaIndex);
    collected = 0;
    nodesActivated.clear();
    activated.clear();
    sequenceIndex = 0;
    mechanismActive = false;
    carryMode = null;
    mechanicSlow = false;
    lightningOff = false;
    runEmblems = 0;
    particles.clear();
    timeLeft = area.timeLimit ?? 0;

    for (final marker in area.crumblePlatforms ?? []) {
      final p = area.platforms.firstWhere(
        (e) =>
            (e.x - (marker['x'] ?? 0)).abs() < 1 &&
            (e.y - (marker['y'] ?? 0)).abs() < 1,
        orElse: () => Platform(0, 0, 0),
      );
      if (p.w != 0) p.kind = 'crumble';
    }

    maxHearts = _statI('maxHearts', 3);
    hazardShield = _statB('hazardShield');
    final start = area.platforms.firstWhere(
      (p) => area.spawn['x']! >= p.x && area.spawn['x']! <= p.x + p.w,
      orElse: () => Platform(0, area.spawn['y']!, 0),
    );
    final startY = start.w != 0 ? start.y : area.spawn['y']!;
    px = area.spawn['x']!;
    py = startY;
    vx = vy = 0;
    facing = 1;
    hearts = maxHearts;
    stamina = 100;
    onGround = true;
    gliding = false;
    climbing = false;
    anim = 'idle';
    attackTime = attackCooldown = hurtTime = invincible = actionAnim = 0;
    airJumps = 0;
    checkpointX = px;
    checkpointY = startY;
    resultOpen = false;
    won = false;
    paused = false;
    hintTimer = 6;
    _wasOnGround = true;
    _wasGliding = false;
    _lowTimeWarned = false;
    _portalWasReady = false;
    hint = 'Jalur akar • batang • kanopi — ${area.tip}';
    audio.play('start');
  }

  // ---------------- update ----------------
  @override
  void update(double dt) {
    dt = dt.clamp(0, 0.033);
    if (_pauseEdge) {
      _pauseEdge = false;
      paused = !paused;
    }
    if (paused || resultOpen) {
      clock += dt * .25;
      return;
    }
    clock += dt;
    campaignTime += dt;
    if (hintTimer > 0) hintTimer = math.max(0, hintTimer - dt);

    if (area.timeLimit != null && area.timeLimit! > 0) {
      timeLeft -= dt;
      if (!_lowTimeWarned && timeLeft <= 10 && timeLeft > 0) {
        _lowTimeWarned = true;
        audio.play('time_warning');
      }
      if (_lowTimeWarned && timeLeft > 12) _lowTimeWarned = false;
      if (timeLeft <= 0) {
        timeLeft = area.timeLimit!;
        _respawn();
        hint = 'Waktu berputar kembali!';
      }
    }

    _updateMovingPlatforms(dt);
    _updatePlayer(dt);
    if (!resultOpen) _updateEnemies(dt);
    _updateParticles(dt);
  }

  void _updateMovingPlatforms(double dt) {
    final slow = mechanicSlow || _statB('movingSlow');
    for (var i = 0; i < (area.movingPlatforms ?? []).length; i += 1) {
      final p = area.movingPlatforms![i];
      final speed = p.speed * (slow ? .55 : 1);
      final phase = clock * speed + i;
      p.currentX = p.vertical ? p.x : p.x + math.sin(phase) * p.range;
      p.currentY = p.vertical ? p.y + math.sin(phase) * p.range : p.y;
      p.dx = math.cos(phase) * p.range * speed * dt;
    }
  }

  List<_Col> _platformList() {
    final list = <_Col>[];
    for (final p in area.platforms) {
      if (p.disabled) continue;
      list.add(_Col(p.x, p.y, p.w, p.h, p.kind));
    }
    for (final p in area.movingPlatforms ?? []) {
      list.add(_Col(p.currentX, p.currentY, p.w, p.h, 'normal', p));
    }
    return list;
  }

  void _updatePlayer(double dt) {
    attackTime = math.max(0, attackTime - dt);
    attackCooldown = math.max(0, attackCooldown - dt);
    hurtTime = math.max(0, hurtTime - dt);
    invincible = math.max(0, invincible - dt);
    actionAnim = math.max(0, actionAnim - dt);

    final axis = (_right ? 1 : 0) - (_left ? 1 : 0);
    if (axis != 0) facing = axis;

    ClimbZone? climbZone;
    for (final z in area.climbZones ?? []) {
      if (px > z.x - 15 &&
          px < z.x + z.w + 15 &&
          py > z.y &&
          py < z.y + z.h + 20) {
        climbZone = z;
        break;
      }
    }
    climbing = climbZone != null && _actionHeld && stamina > 0;

    final plats = _platformList();
    _Col? current;
    for (final p in plats) {
      if (px > p.x && px < p.x + p.w && (py - p.y).abs() < 8) {
        current = p;
        break;
      }
    }
    final traction = current?.kind == 'ice' && !_statB('iceGrip')
        ? 230
        : onGround
        ? 1300
        : 620;
    final target = axis * _statD('speed', 1) * 275;
    vx = _approach(vx, target, traction * dt);
    if (axis == 0 && onGround && current?.kind != 'ice')
      vx = _approach(vx, 0, 1600 * dt);

    if (_jumpEdge) {
      if (onGround) {
        vy = -440 * _statD('jumpBoost', 1);
        onGround = false;
        airJumps = 0;
        audio.play('jump');
      } else if (_statB('doubleJump') && airJumps < 1) {
        vy = -410;
        airJumps += 1;
        audio.play('double_jump');
      }
    }
    _jumpEdge = false;
    if (_attackEdge) _startAttack();
    _attackEdge = false;
    if (_actionEdge) _interact();
    _actionEdge = false;

    gliding = false;
    if (climbing) {
      vy = -155;
      vx = axis * 65;
      stamina = math.max(0, stamina - 27 * _statD('climbCost', 1) * dt);
    } else {
      var g = _gravity;
      if ((area.lowGravityZones ?? []).any((z) => _inside(px, py, z))) g *= .38;
      if (_jumpHeld &&
          !onGround &&
          vy > -120 &&
          stamina > 0 &&
          carryMode != 'heavy') {
        gliding = true;
        g = _statD('glideGravity', 185);
        vy = math.min(vy, 135);
        stamina = math.max(0, stamina - 17 * _statD('glideCost', 1) * dt);
      }
      vy += g * dt;
    }
    if (onGround && !climbing) {
      stamina = math.min(100, stamina + 34 * _statD('staminaRegen', 1) * dt);
    }

    if ((area.shadowZones ?? []).any((z) => _inside(px, py, z))) {
      stamina = math.max(0, stamina - 12 * dt);
    }
    if (!_statB('heatImmune') &&
        (area.hotZones ?? []).any((z) => _inside(px, py, z))) {
      stamina = math.max(0, stamina - 18 * dt);
      if (stamina <= 0 && invincible <= 0) {
        hearts -= 1;
        invincible = _statD('invincible', 1.15);
        hurtTime = .38;
        vy = -240;
        audio.play('hurt');
        if (hearts <= 0) {
          audio.play('lose');
          _respawn(false);
        }
      }
    }

    if (gliding) {
      for (final z in area.updrafts ?? []) {
        if (px > z.x && px < z.x + z.w && py > z.y && py < z.y + z.h) {
          vy = math.max(-360, vy - 760 * _statD('updraft', 1) * dt);
        }
      }
    }
    if (gliding && !_wasGliding) audio.play('glide');
    _wasGliding = gliding;
    for (final z in area.windZones ?? []) {
      if (px > z.x && px < z.x + z.w && py > z.y && py < z.y + z.h)
        vx += (z.force ?? 0) * dt;
    }

    final oldY = py;
    px += vx * dt;
    py += vy * dt;
    px = _clampD(px, 24, (area.worldWidth ?? 2300) - 24);
    onGround = false;

    if (vy >= 0) {
      _Col? landing;
      for (final p in plats) {
        if (px + _playerHalf < p.x || px - _playerHalf > p.x + p.w) continue;
        if (oldY <= p.y + 4 && py >= p.y) {
          if (landing == null || p.y < landing.y) landing = p;
        }
      }
      if (landing != null) {
        py = landing.y;
        vy = 0;
        onGround = true;
        airJumps = 0;
        if (landing.moving != null && !landing.moving!.vertical)
          px += landing.moving!.dx;
      }
    }
    if (!_wasOnGround && onGround) audio.play('land');
    _wasOnGround = onGround;
    // crumble handling on static platforms
    for (final p in area.platforms) {
      if (p.kind != 'crumble' || p.disabled) continue;
      if (onGround && px > p.x && px < p.x + p.w && (py - p.y).abs() < 3) {
        p.crumbleTime += dt;
        if (p.crumbleTime > .65) {
          p.disabled = true;
          onGround = false;
          hint = 'Dahan runtuh!';
          audio.play('crumble');
        }
      }
    }

    for (final m in area.mushrooms ?? []) {
      if (vy >= 0 &&
          (px - m['x']).abs() < 52 &&
          py > ((m['y'] as num).toDouble()) - 55 &&
          py < ((m['y'] as num).toDouble()) + 20) {
        py = ((m['y'] as num).toDouble()) - 52;
        vy = -535;
        onGround = false;
        audio.play('mushroom');
        final expected = area.sequence == null
            ? null
            : area.sequence![sequenceIndex];
        if (expected != null) {
          if (m['color'] == expected) {
            sequenceIndex += 1;
            hint = '${sequenceIndex}/3 urutan benar';
          } else {
            sequenceIndex = m['color'] == area.sequence![0] ? 1 : 0;
            hint = 'Urutan berpendar ulang.';
          }
          if (sequenceIndex == area.sequence!.length) {
            area.keys[0].hidden = false;
            sequenceIndex = 0;
            hint = 'Rune warna terbentuk!';
          }
        }
      }
    }

    for (final h in area.hazards ?? []) {
      if (px > h.x && px < h.x + h.w && py > h.y - 4) {
        if (hazardShield) {
          hazardShield = false;
          vy = -430;
          py = h.y - 30;
          hint = 'Mirestrider menahan racun!';
        } else {
          audio.play('lose');
          _respawn();
        }
        break;
      }
    }

    (area.lightningZones ?? []).asMap().forEach((idx, z) {
      final active = !lightningOff && (clock + idx * .63) % 3.2 > 2.78;
      if (active && px > z.x && px < z.x + z.w && invincible <= 0) {
        hearts -= 1;
        invincible = _statD('invincible', 1.15);
        hurtTime = .4;
        vy = -300;
        audio.play('thunder');
        audio.play('hurt');
        if (hearts <= 0) {
          audio.play('lose');
          _respawn(false);
        }
      }
    });

    if (py > (area.worldHeight ?? 900) + 100) _respawn();

    if (onGround && px > checkpointX + 950) {
      checkpointX = px;
      checkpointY = py;
      hint = 'Checkpoint';
      audio.play('checkpoint');
    }

    for (final item in area.keys) {
      if (!item.collected &&
          !item.hidden &&
          (px - item.x).abs() < 45 &&
          ((py - 30) - item.y).abs() < 60) {
        _collectKey(item);
      }
    }
    for (final e in area.emblems ?? []) {
      if (!e.collected &&
          (px - e.x).abs() < 40 &&
          ((py - 25) - e.y).abs() < 55) {
        e.collected = true;
        runEmblems += 1;
        _burst(e.x, e.y, const Color(0xff8cff7a), 10);
        audio.play('collect_emblem');
      }
    }

    final portalReady =
        collected >= area.required &&
        (area.mechanism == null || mechanismActive) &&
        nodesActivated.length >= (area.nodesRequired ?? 0) &&
        !area.enemies.any((e) => e.gateKeeper && e.alive);
    if (portalReady &&
        (px - area.portal['x']!).abs() < 75 &&
        (py - area.portal['y']!).abs() < 125) {
      _finishArea();
    }

    if (portalReady && !_portalWasReady) audio.play('portal');
    _portalWasReady = portalReady;

    _updateAnimation();
  }

  void _updateEnemies(double dt) {
    for (final e in area.enemies) {
      if (!e.alive) {
        e.defeatTime = math.max(0, e.defeatTime - dt);
        continue;
      }
      e.hitTime = math.max(0, e.hitTime - dt);
      e.timer = (e.timer + dt) % 3.8;
      if (e.hitTime > 0) {
        e.state = 'hit';
      } else if (e.timer < 2.05) {
        e.state = 'patrol';
      } else if (e.timer < 2.68) {
        e.state = 'telegraph';
      } else if (e.timer < 3.15) {
        e.state = 'attack';
      } else {
        e.state = 'patrol';
      }
      e.dir = px >= e.x ? 1 : -1;
      if (e.state == 'patrol') {
        final dir = math.sin(clock * .8 + e.originX) > 0 ? 1 : -1;
        e.x += dir * 170 * .2 * dt;
      } else if (e.state == 'attack') {
        e.x += e.dir * 170 * .75 * dt;
      }
      e.x = _clampD(e.x, e.originX - 100, e.originX + 100);

      final ey = e.y - (e.flying ? 20 : 30);
      final vertical = ((py - 30) - ey).abs();
      if ((px - e.x).abs() < (e.type == 'guardian' ? 72 : 48) &&
          vertical < 58) {
        if (vy > 130 && py < e.y - 8) {
          _damageEnemy(e, 0);
          vy = -330;
        } else if (invincible <= 0) {
          hearts -= 1;
          invincible = _statD('invincible', 1.15);
          hurtTime = .38;
          vx = -e.dir * 240;
          vy = -250;
          _burst(px, py - 30, const Color(0xffff5d86), 12);
          audio.play('hurt');
          if (hearts <= 0) {
            audio.play('lose');
            _respawn(false);
          }
        }
      }
    }
  }

  void _updateParticles(double dt) {
    for (final p in particles) {
      p.life -= dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 360 * dt;
    }
    particles.removeWhere((p) => p.life <= 0);
  }

  void _updateAnimation() {
    if (hurtTime > 0) {
      anim = 'hurt';
    } else if (attackTime > 0) {
      anim = 'tail_attack';
    } else if (actionAnim > 0) {
      anim = actionKind;
    } else if (climbing) {
      anim = 'climb';
    } else if (carryMode != null) {
      anim = 'carry';
    } else if (!onGround) {
      anim = gliding ? 'glide' : 'jump';
    } else if (vx.abs() > 24) {
      anim = 'run';
    } else {
      anim = 'idle';
    }
  }

  // ---------------- combat / skills ----------------
  void _startAttack() {
    if (attackCooldown > 0) return;
    attackTime = .34;
    attackCooldown = _statD('attackCooldown', .46);
    audio.play('attack');
    final hitX = px + facing * 54;
    for (final e in area.enemies) {
      if (!e.alive) continue;
      if ((e.x - hitX).abs() > (e.type == 'guardian' ? 75 : 58)) continue;
      if ((e.y - py).abs() > 82) continue;
      _damageEnemy(e, facing * 70);
    }
  }

  void _damageEnemy(Enemy e, double knock) {
    e.hp -= _statD('attackDamage', 1).toInt();
    e.hitTime = .22;
    e.state = 'hit';
    e.x += knock * .08;
    _burst(e.x, e.y - 35, const Color(0xffffcf65), 12);
    audio.play('hit');
    if (e.hp <= 0) {
      e.alive = false;
      e.state = 'defeat';
      e.defeatTime = 1;
      audio.play('defeat');
    }
  }

  void _collectKey(KeyItem item) {
    item.collected = true;
    _burst(item.x, item.y, const Color(0xffffd75e), 14);
    audio.play('collect_key');
    if (item.frozen) {
      carryMode = 'frozen';
      hint = 'Bawa ke batu panas lalu tekan AKSI.';
    } else if (item.toxic) {
      carryMode = 'toxic';
      hint = 'Sucikan di mata air lalu tekan AKSI.';
    } else if (item.gear) {
      carryMode = 'gear';
      hint = 'Pasang pada mesin dengan AKSI.';
    } else {
      collected += 1;
      if (item.heavy) carryMode = 'heavy';
    }
  }

  void _completeCarry(String mode) {
    if (carryMode != mode) return;
    carryMode = null;
    collected += 1;
    _burst(px, py - 35, const Color(0xff59e7e0), 16);
  }

  void _interact() {
    for (final node in area.mechanicNodes ?? []) {
      if (nodesActivated.contains(node['id']) ||
          !_near(
            px,
            py,
            (node['x'] as num).toDouble(),
            (node['y'] as num).toDouble(),
            120,
          ))
        continue;
      nodesActivated.add(node['id'] as String);
      audio.play('node');
      final effect = node['effect'] as String;
      hint = node['message'] as String;
      if (effect == 'reveal') {
        for (final k in area.keys) k.hidden = false;
      } else if (effect == 'tunnel') {
        px = math.min((area.worldWidth ?? 5900) - 260, px + 260);
        py -= 130;
        vy = -160;
      } else if (effect == 'prism') {
        hearts = maxHearts;
        stamina = 100;
      } else if (effect == 'slow') {
        mechanicSlow = true;
      } else if (effect == 'shield') {
        hazardShield = true;
      } else if (effect == 'time') {
        timeLeft += 30;
      } else if (effect == 'gravity') {
        (area.lowGravityZones ??= []).add(
          RectZone(
            ((node['x'] as num).toDouble()) - 360,
            ((node['y'] as num).toDouble()) - 700,
            720,
            780,
          ),
        );
      } else if (effect == 'lightning') {
        lightningOff = true;
      } else if (effect == 'phase') {
        invincible = 5;
      } else if (effect == 'gust') {
        (area.updrafts ??= []).add(
          RectZone(
            ((node['x'] as num).toDouble()) + 80,
            ((node['y'] as num).toDouble()) - 720,
            150,
            800,
          ),
        );
        vy = -420;
      }
      return;
    }
    for (final t in area.teleporters ?? []) {
      if (_near(
        px,
        py,
        (t['x'] as num).toDouble(),
        (t['y'] as num).toDouble(),
        100,
      )) {
        _burst(px, py - 30, const Color(0xffb283ff), 18);
        audio.play('teleport');
        px = (t['toX'] as num).toDouble();
        py = (t['toY'] as num).toDouble();
        vx = 0;
        vy = -90;
        return;
      }
    }
    for (final spot in area.digSpots ?? []) {
      if (!activated.contains(spot['id']) &&
          (px - ((spot['x'] as num).toDouble())).abs() < 75 &&
          (py - ((spot['y'] as num).toDouble())).abs() < 100) {
        activated.add(spot['id'] as String);
        final item = area.keys.firstWhere(
          (e) => e.id == spot['id'],
          orElse: () => KeyItem('', '', 0, 0),
        );
        if (item.id.isNotEmpty) item.hidden = false;
        actionAnim = .55;
        actionKind = 'dig';
        hint = 'Tanah retak terbuka!';
        audio.play('dig');
        return;
      }
    }
    for (final lever in area.levers ?? []) {
      if (!activated.contains(lever['id']) &&
          _near(
            px,
            py,
            (lever['x'] as num).toDouble(),
            (lever['y'] as num).toDouble(),
            85,
          )) {
        activated.add(lever['id'] as String);
        if (activated.length >= (area.levers ?? []).length)
          area.keys[0].hidden = false;
        audio.play('lever');
        return;
      }
    }
    for (final v in area.vines ?? []) {
      if ((px - ((v['x'] as num).toDouble())).abs() < 85 &&
          ((py - 100) - ((v['y'] as num).toDouble())).abs() < 210) {
        vy = -390;
        vx = facing * 300;
        actionAnim = .5;
        actionKind = 'swing';
        audio.play('vine');
        return;
      }
    }
    if (area.heat != null &&
        _near(px, py, area.heat!.x, area.heat!.y, 105) &&
        carryMode == 'frozen') {
      _completeCarry('frozen');
      hint = 'Es mencair. Kunci siap digunakan!';
      return;
    }
    if (area.spring != null &&
        _near(px, py, area.spring!.x, area.spring!.y, 110) &&
        carryMode == 'toxic') {
      _completeCarry('toxic');
      hint = 'Racun terbilas dari kunci!';
      return;
    }
    if (area.mechanism != null &&
        _near(px, py, area.mechanism!.x, area.mechanism!.y, 115) &&
        carryMode == 'gear') {
      _completeCarry('gear');
      mechanismActive = true;
      hint = 'Roda gigi tersinkron!';
    }
  }

  void _respawn([bool damage = true]) {
    if (damage) {
      hearts -= 1;
      _burst(px, py - 35, const Color(0xffff5d86), 12);
    }
    if (hearts <= 0) hearts = maxHearts;
    px = checkpointX;
    py = checkpointY;
    vx = vy = 0;
    invincible = 1.2;
    hurtTime = .35;
    stamina = 100;
    for (final p in area.platforms) {
      if (p.kind == 'crumble') {
        p.disabled = false;
        p.crumbleTime = 0;
      }
    }
  }

  void _finishArea() {
    resultOpen = true;
    if (areaIndex >= areaCount - 1) {
      won = true;
      hint = 'Yggdrasil Terbangun!';
      audio.play('victory');
    } else {
      hint = 'Portal Pulih!';
      audio.play('win');
    }
  }

  // ================= RENDERING =================
  @override
  void render(ui.Canvas canvas) {
    _cv = canvas;
    final w = size.x;
    final h = size.y;
    _scale = math.max(0.48, math.min(w / 720, h / 720));
    final viewW = w / _scale;
    final viewH = h / _scale;
    final worldW = area.worldWidth ?? 2300;
    final worldH = area.worldHeight ?? 900;
    _camX = math.max(0, math.min(worldW - viewW, px - viewW * 0.42));
    if (worldW < viewW) _camX = 0;
    final centeredY = worldH / 2 - viewH / 2;
    _camY = viewH >= worldH
        ? centeredY
        : math.max(0, math.min(worldH - viewH, py - viewH * 0.56));

    _drawBackdrop(canvas, w, h);

    canvas.save();
    canvas.scale(_scale, _scale);
    canvas.translate(-_camX, -_camY);

    _drawMotes(canvas);
    _drawClimbArt(canvas);
    _drawZones(canvas);
    for (final p in area.platforms) {
      if (!p.disabled) _drawPlatform(canvas, p);
    }
    for (final p in area.movingPlatforms ?? []) {
      _drawMovingPlatform(canvas, p);
    }
    _drawObjects(canvas);
    _drawEnemies(canvas);
    _drawPlayer(canvas);
    _drawParticles(canvas);

    canvas.restore();

    if (hurtTime > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        ui.Paint()
          ..color = Color.fromRGBO(
            255,
            77,
            130,
            math.min(0.18, hurtTime * 0.2),
          ),
      );
    }
    _drawHud(canvas, w, h);
    _drawObjectiveMarkers(canvas, w, h);
  }

  void _drawBackdrop(ui.Canvas canvas, double w, double h) {
    final grad = ui.Gradient.linear(Offset(0, 0), Offset(0, h), [
      Color(_c(area.colors[0])),
      const Color(0xff050510),
    ]);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), ui.Paint()..shader = grad);
    final bd = lib.backdrops[_backdropKey()];
    if (bd != null) {
      final tileH = h * 1.22;
      final tileW = bd.width * (tileH / bd.height);
      final offY = -h * .11 - (_camY * _scale * .035) % (h * .12);
      var start = -((_camX * _scale * 0.12) % tileW) - tileW;
      var index = (_camX * _scale * 0.12 / tileW).floor() - 1;
      final paint = ui.Paint()
        ..color = const Color.fromARGB(184, 255, 255, 255);
      while (start < w + tileW) {
        canvas.save();
        if (index % 2 == 1) {
          canvas.translate(start + tileW, offY);
          canvas.scale(-1, 1);
          canvas.drawImage(bd, Offset(0, 0), paint);
        } else {
          canvas.drawImage(bd, Offset(start, offY), paint);
        }
        canvas.restore();
        start += tileW;
        index += 1;
      }
    }
  }

  String _backdropKey() {
    final b = area.backdrop;
    if (b == 'FOREST_BACKDROP') return 'forest';
    if (b == 'CAVERN_BACKDROP') return 'cavern';
    return 'core';
  }

  void _drawMotes(ui.Canvas canvas) {
    final paint = ui.Paint()
      ..color = Color(_c(area.colors[2])).withValues(alpha: .22);
    for (var i = 0; i < 24; i += 1) {
      final x = ((i * 149 + clock * (8 + i % 3)) % (size.x / _scale + 40)) - 20;
      final y =
          (i * 83 + math.sin(clock + i) * 28) % math.max(size.y / _scale, 1);
      canvas.drawRect(
        Rect.fromLTWH(x, y, i % 4 == 0 ? 3 : 2, i % 4 == 0 ? 3 : 2),
        paint,
      );
    }
  }

  void _drawClimbArt(ui.Canvas canvas) {
    final art = area.climbArt;
    if (art == null) return;
    final img = lib.climbTrees[art.key];
    if (img == null) return;
    final fit = math.min(art.w / img.width, art.h / img.height);
    final dw = img.width * fit;
    final dh = img.height * fit;
    canvas.drawImage(
      img,
      Offset(art.x + (art.w - dw) / 2, art.y + art.h - dh),
      ui.Paint(),
    );
  }

  Sheet _tileSheet() {
    if (area.tiles == 'FOREST_PLATFORM_TILES') return sheet('forestTiles')!;
    if (area.tiles == 'CAVERN_PLATFORM_TILES') return sheet('cavernTiles')!;
    return sheet('coreTiles')!;
  }

  void _drawPlatform(ui.Canvas canvas, Platform p) {
    final ts = _tileSheet();
    final frame = ts.frames['center']!;
    final crop = Rect.fromLTWH(frame.x, frame.y, frame.w, frame.h);
    final targetH = math.max(p.h, 76).toDouble();
    final scaleY = targetH / frame.h;
    final surfaceOffset = ((frame.surfaceY ?? frame.y) - frame.y) * scaleY;
    final x = p.x;
    final y = p.y - surfaceOffset;
    canvas.save();
    if (p.kind == 'crumble') {
      canvas.translate(math.sin(p.crumbleTime * 70) * 3, 0);
    }
    final paint = p.kind == 'crumble'
        ? (ui.Paint()
            ..color = const Color.fromARGB(
              255,
              255,
              255,
              255,
            ).withValues(alpha: math.max(.35, 1 - p.crumbleTime)))
        : ui.Paint();
    canvas.drawImageRect(
      ts.image,
      crop,
      Rect.fromLTWH(x, y, p.w, targetH),
      paint,
    );
    canvas.restore();
    if (p.kind == 'ice') {
      canvas.drawRect(
        Rect.fromLTWH(x, p.y - 4, p.w, 7),
        ui.Paint()..color = const Color(0x5978ebff),
      );
    }
  }

  void _drawMovingPlatform(ui.Canvas canvas, MovingPlatform p) {
    final x = p.currentX;
    final y = p.currentY;
    if (area.name == 'Waterfall Canopy' &&
        sheet('puzzle')?.frames['leaf_raft'] != null) {
      _drawFrameInBox(
        sheet('puzzle')!,
        sheet('puzzle')!.frames['leaf_raft']!,
        x,
        y - 34,
        p.w,
        65,
        1,
      );
    } else {
      final anim = sheet('world')?.animations['gear_loop'];
      final frame = anim == null
          ? null
          : anim[(clock * 8).floor() % anim.length];
      if (frame != null) {
        _drawFrameInBox(sheet('world')!, frame, x, y - 60, p.w, 84, 1);
      } else {
        canvas.drawRect(
          Rect.fromLTWH(x, y, p.w, p.h),
          ui.Paint()..color = const Color(0xaa42d8db),
        );
      }
    }
  }

  void _drawZones(ui.Canvas canvas) {
    for (final z in area.updrafts ?? []) {
      final anim = sheet('world')?.animations['updraft_loop'];
      if (anim != null)
        _drawFrameInBox(
          sheet('world')!,
          anim[(clock * 10).floor() % anim.length],
          z.x,
          z.y,
          z.w,
          z.h,
          .62,
        );
    }
    for (final z in area.climbZones ?? []) {
      if (z.art) continue;
      final g = ui.Gradient.linear(Offset(z.x, z.y), Offset(z.x + z.w, z.y), [
        const Color(0x8c3d1e26),
        const Color(0xd864412f),
        const Color(0x8c3d1e26),
      ]);
      canvas.drawRect(
        Rect.fromLTWH(z.x, z.y, z.w, z.h),
        ui.Paint()..shader = g,
      );
      canvas.drawRect(
        Rect.fromLTWH(z.x + z.w * .45, z.y + 30, 8, 18),
        ui.Paint()..color = const Color(0xa64de9dc),
      );
    }
    for (final h in area.hazards ?? []) {
      final g = ui.Gradient.linear(Offset(0, h.y), Offset(0, h.y + h.h), [
        const Color(0xffd82f91),
        const Color(0xff6e1e77),
        const Color(0xff1e0a3d),
      ]);
      canvas.drawRect(
        Rect.fromLTWH(h.x, h.y, h.w, h.h),
        ui.Paint()..shader = g,
      );
    }
    for (final z in area.windZones ?? []) {
      final paint = ui.Paint()
        ..color = const Color(0x4221eaff)
        ..strokeWidth = 3;
      for (var i = 0; i < 4; i += 1) {
        final yy = z.y + 80 + i * 75 + math.sin(clock * 2 + i) * 18;
        canvas.drawLine(
          Offset(z.x + 15, yy),
          Offset(z.x + z.w - 15, yy),
          paint,
        );
      }
    }
    for (final z in area.lowGravityZones ?? []) {
      canvas.drawRect(
        Rect.fromLTWH(z.x, z.y, z.w, z.h),
        ui.Paint()..color = const Color(0x0d52e2ff),
      );
    }
    for (final z in area.shadowZones ?? []) {
      final g = ui.Gradient.radial(
        Offset(z.x + z.w / 2, z.y + z.h / 2),
        z.w * .65,
        [const Color(0x143d195b), const Color(0x6b04041a)],
      );
      canvas.drawRect(
        Rect.fromLTWH(z.x, z.y, z.w, z.h),
        ui.Paint()..shader = g,
      );
    }
    for (final z in area.hotZones ?? []) {
      canvas.drawRect(
        Rect.fromLTWH(z.x, z.y, z.w, z.h),
        ui.Paint()..color = const Color(0x13ff5b2b),
      );
    }
    (area.lightningZones ?? []).asMap().forEach((i, z) {
      final phase = (clock + i * .63) % 3.2;
      final active = !lightningOff && phase > 2.78;
      canvas.drawRect(
        Rect.fromLTWH(z.x, _camY, z.w, size.y / _scale),
        ui.Paint()
          ..color = active
              ? const Color(0x9efffa82)
              : (phase > 2.35
                    ? const Color(0x2eff6c9b)
                    : const Color(0x00000000)),
      );
    });
  }

  void _drawObjects(ui.Canvas canvas) {
    final puzzle = sheet('puzzle');
    final feedback = sheet('feedback');
    final world = sheet('world');
    final portalFrame = world?.animations['portal_loop'];
    final portalOpen =
        collected >= area.required &&
        (area.mechanism == null || mechanismActive) &&
        nodesActivated.length >= (area.nodesRequired ?? 0) &&
        !area.enemies.any((e) => e.gateKeeper && e.alive);
    if (portalFrame != null && world != null) {
      _drawAnchored(
        world,
        portalFrame[(clock * 8).floor() % portalFrame.length],
        area.portal['x']!,
        area.portal['y']!,
        190,
        1,
        portalOpen ? 1 : .34,
      );
    }

    for (final item in area.keys) {
      if (item.collected || item.hidden) continue;
      if (feedback != null) {
        final glow = feedback.animations['key_glow'];
        if (glow != null) {
          _drawFrameInBox(
            feedback,
            glow[(clock * 8).floor() % glow.length],
            item.x - 38,
            item.y - 44 + math.sin(clock * 3 + item.x) * 4,
            76,
            76,
            .45,
          );
        }
      }
      if (puzzle != null) {
        final f = puzzle.frames[item.sprite];
        if (f != null)
          _drawFrameInBox(
            puzzle,
            f,
            item.x - 24,
            item.y - 30 + math.sin(clock * 3 + item.x) * 4,
            48,
            54,
            1,
          );
      }
    }
    for (final m in area.mushrooms ?? []) {
      if (puzzle != null) {
        final f = puzzle.frames[m['sprite'] as String];
        if (f != null)
          _drawFrameInBox(
            puzzle,
            f,
            ((m['x'] as num).toDouble()) - 34,
            ((m['y'] as num).toDouble()) - 66,
            68,
            68,
            1,
          );
      }
    }
    for (final l in area.levers ?? []) {
      if (puzzle != null) {
        final f = puzzle.frames['wood_lever'];
        if (f != null)
          _drawFrameInBox(
            puzzle,
            f,
            (l['x'] as num).toDouble() - 25,
            (l['y'] as num).toDouble() - 55,
            50,
            62,
            activated.contains(l['id']) ? .65 : 1,
          );
      }
    }
    for (final v in area.vines ?? []) {
      if (feedback != null) {
        final anim = feedback.animations['vine_sway'];
        if (anim != null) {
          _drawAnchored(
            feedback,
            anim[(clock * 7 + ((v['x'] as num).toDouble())).floor() %
                anim.length],
            (v['x'] as num).toDouble(),
            ((v['y'] as num).toDouble()) + 190,
            210,
            1,
            1,
          );
        }
      }
    }
    for (final t in area.teleporters ?? []) {
      final radius = (26 + math.sin(clock * 4) * 4);
      canvas.drawCircle(
        Offset((t['x'] as num).toDouble(), ((t['y'] as num).toDouble()) - 35),
        radius,
        ui.Paint()..color = const Color(0x52b566ff),
      );
    }
    for (final node in area.mechanicNodes ?? []) {
      final active = nodesActivated.contains(node['id']);
      final landmarkSheet = sheet(node['sheet'] as String? ?? 'landmarks');
      if (landmarkSheet != null) {
        final f = landmarkSheet.frames[node['sprite'] as String];
        if (f != null)
          _drawFrameInBox(
            landmarkSheet,
            f,
            ((node['x'] as num).toDouble()) - 48,
            ((node['y'] as num).toDouble()) - 112,
            96,
            112,
            active ? .62 : 1,
          );
      }
    }
    if (area.heat != null && puzzle != null) {
      final f = puzzle.frames['volcanic_rock'];
      if (f != null)
        _drawFrameInBox(
          puzzle,
          f,
          area.heat!.x - 40,
          area.heat!.y - 60,
          80,
          74,
          1,
        );
    }
    if (area.spring != null && puzzle != null) {
      final f = puzzle.frames['purity_spring'];
      if (f != null)
        _drawFrameInBox(
          puzzle,
          f,
          area.spring!.x - 45,
          area.spring!.y - 60,
          90,
          72,
          1,
        );
    }
    if (area.mechanism != null) {
      final anim = world?.animations['gear_loop'];
      if (anim != null && world != null) {
        _drawFrameInBox(
          world,
          anim[(clock * 8).floor() % anim.length],
          area.mechanism!.x - 50,
          area.mechanism!.y - 95,
          100,
          100,
          mechanismActive ? 1 : .55,
        );
      }
    }
    for (final spot in area.digSpots ?? []) {
      if (activated.contains(spot['id'])) continue;
      final p = ui.Path()
        ..moveTo(
          ((spot['x'] as num).toDouble()) - 30,
          ((spot['y'] as num).toDouble()) - 2,
        )
        ..lineTo(
          ((spot['x'] as num).toDouble()),
          ((spot['y'] as num).toDouble()) - 15,
        )
        ..lineTo(
          ((spot['x'] as num).toDouble()) + 30,
          ((spot['y'] as num).toDouble()) - 2,
        );
      canvas.drawPath(
        p,
        ui.Paint()
          ..color = const Color(0xffd3915d)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    for (final e in area.emblems ?? []) {
      if (e.collected) continue;
      canvas.save();
      canvas.translate(e.x, e.y);
      canvas.rotate(clock * 1.2);
      canvas.drawPath(
        (ui.Path()
          ..moveTo(0, -11)
          ..quadraticBezierTo(11, -3, 0, 12)
          ..quadraticBezierTo(-11, -3, 0, -11)),
        ui.Paint()..color = const Color(0xff8cff7a),
      );
      canvas.restore();
    }
  }

  void _drawEnemies(ui.Canvas canvas) {
    for (final e in area.enemies) {
      final sheetKey = enemySheet[e.type] ?? 'woodland';
      final sh = sheet(sheetKey);
      if (sh == null) continue;
      final frame =
          sh.frames['${e.type}_${e.state}'] ?? sh.frames['${e.type}_patrol'];
      if (frame == null) {
        canvas.drawCircle(
          Offset(e.x, e.y),
          18,
          ui.Paint()..color = const Color(0xffff0000),
        );
        continue;
      }
      final flyOff = e.flying ? math.sin(clock * 3 + e.x) * 8 : 0.0;
      final alpha = e.alive ? 1.0 : math.max(0.0, e.defeatTime);
      _drawAnchored(
        sh,
        frame,
        e.x,
        e.y + flyOff,
        e.type == 'guardian' ? 130.0 : 74.0,
        e.dir > 0 ? 1 : -1,
        alpha,
      );
      if (e.state == 'telegraph' && e.alive) {
        canvas.drawCircle(
          Offset(e.x, e.y - 45),
          18,
          ui.Paint()
            ..color = const Color(0xffff4f7d)
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
    }
  }

  void _drawPlayer(ui.Canvas canvas) {
    Sheet? sh = sheet('movement');
    List<Frame>? frames = sh?.animations[anim] ?? sh?.animations['idle'];
    if (skinId > 0) {
      final custom = sheet('skin${skinId.toString().padLeft(2, '0')}');
      if (custom != null) {
        sh = custom;
        final mapped = anim == 'climb'
            ? 'climb'
            : (anim == 'glide' || anim == 'jump')
            ? 'glide'
            : (['tail_attack', 'dig', 'swing', 'hurt'].contains(anim))
            ? 'attack'
            : 'run';
        frames = custom.animations[mapped];
        if (skinId == 7 && mapped == 'attack' && sheet('stormAttack') != null) {
          sh = sheet('stormAttack');
          frames = [
            for (var i = 1; i <= 5; i += 1) sh!.frames['attack_$i']!,
          ].whereType<Frame>().toList();
        }
        if (anim == 'idle' || anim == 'carry' || anim == 'win')
          frames = frames!.isNotEmpty ? [frames[0]] : frames;
      }
    } else {
      if (sheet('action')?.animations[anim] != null) {
        sh = sheet('action');
        frames = sh!.animations[anim];
      } else if (sheet('status')?.animations[anim] != null) {
        sh = sheet('status');
        frames = sh!.animations[anim];
      }
    }
    if (sh == null || frames == null || frames.isEmpty) return;
    final frame =
        frames[(clock * (anim == 'run' ? 13 : 9)).floor() % frames.length];
    final blink = invincible > 0 && (invincible * 16).floor() % 2 == 0
        ? .35
        : 1.0;
    _drawAnchored(
      sh,
      frame,
      px,
      py,
      anim == 'glide' ? 86.0 : 82.0,
      facing,
      blink,
    );
  }

  void _drawParticles(ui.Canvas canvas) {
    for (final p in particles) {
      final a = math.max(0.0, p.life / p.maxLife);
      canvas.drawRect(
        Rect.fromLTWH(p.x - p.size / 2, p.y - p.size / 2, p.size, p.size),
        ui.Paint()..color = p.color.withValues(alpha: a),
      );
    }
  }

  void _drawFrameInBox(
    Sheet sh,
    Frame f,
    double x,
    double y,
    double w,
    double h,
    num alpha,
  ) {
    final crop = Rect.fromLTWH(f.x, f.y, f.w, f.h);
    final scale = math.min(w / f.w, h / f.h);
    final dw = f.w * scale;
    final dh = f.h * scale;
    final paint = ui.Paint()
      ..color = Color.fromARGB((alpha * 255).round(), 255, 255, 255);
    _cv.drawImageRect(
      sh.image,
      crop,
      Rect.fromLTWH(x + (w - dw) / 2, y + (h - dh) / 2, dw, dh),
      paint,
    );
  }

  void _drawAnchored(
    Sheet sh,
    Frame f,
    double x,
    double y,
    double targetHeight,
    int facing,
    num alpha,
  ) {
    final crop = Rect.fromLTWH(f.x, f.y, f.w, f.h);
    final anchor = Offset(f.ax ?? (f.x + f.w / 2), f.ay ?? (f.y + f.h));
    final scale = targetHeight / 380;
    final paint = ui.Paint()
      ..color = Color.fromARGB((alpha * 255).round(), 255, 255, 255);
    _cv.save();
    _cv.translate(x, y);
    _cv.scale(facing.toDouble(), 1);
    _cv.drawImageRect(
      sh.image,
      crop,
      Rect.fromLTWH(
        -(anchor.dx - f.x) * scale,
        -(anchor.dy - f.y) * scale,
        f.w * scale,
        f.h * scale,
      ),
      paint,
    );
    _cv.restore();
  }

  void _drawHud(ui.Canvas canvas, double w, double h) {
    const top = 12.0;
    const panelHeight = 56.0;
    final leftWidth = math.min(178.0, w * .28);
    final rightWidth = math.min(168.0, w * .28);
    final centerWidth = math.min(
      230.0,
      math.max(132.0, w - leftWidth - rightWidth - 64),
    );
    final left = Rect.fromLTWH(12, top, leftWidth, panelHeight);
    final center = Rect.fromLTWH(
      (w - centerWidth) / 2,
      top,
      centerWidth,
      panelHeight,
    );
    final right = Rect.fromLTWH(
      w - rightWidth - 12,
      top,
      rightWidth,
      panelHeight,
    );

    _drawHudPanel(canvas, left);
    _text(
      canvas,
      'NYAWA',
      left.left + 12,
      left.top + 8,
      const Color(0xffaab5ba),
      9,
    );
    for (var i = 0; i < maxHearts; i += 1) {
      _drawHeart(
        canvas,
        left.left + 67 + i * 18,
        left.top + 29,
        16,
        i < hearts,
      );
    }

    _text(
      canvas,
      'STAMINA',
      left.left + 12,
      left.top + 44,
      const Color(0xffaab5ba),
      8,
    );
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(left.left + 64, left.top + 44, left.width - 76, 10),
      const Radius.circular(5),
    );
    canvas.drawRRect(track, ui.Paint()..color = const Color(0xff080d1d));
    final staminaWidth = (left.width - 76) * _clampD(stamina / 100, 0, 1);
    if (staminaWidth > 0) {
      final fill = RRect.fromRectAndRadius(
        Rect.fromLTWH(left.left + 64, left.top + 44, staminaWidth, 10),
        const Radius.circular(5),
      );
      canvas.drawRRect(
        fill,
        ui.Paint()
          ..shader = ui.Gradient.linear(
            Offset(left.left + 64, left.top + 44),
            Offset(left.left + left.width - 12, left.top + 54),
            const [Color(0xff38c9ae), Color(0xffa4ed79)],
          ),
      );
    }

    _drawHudPanel(canvas, center);
    _centerText(
      canvas,
      'AREA ${areaIndex + 1}  /  $areaCount',
      center.center.dx,
      center.top + 10,
      const Color(0xff73e7da),
      8,
    );
    _centerText(
      canvas,
      area.name,
      center.center.dx,
      center.top + 28,
      const Color(0xfffff3d0),
      13,
    );

    _drawHudPanel(canvas, right);
    _text(
      canvas,
      'KUNCI',
      right.left + 11,
      right.top + 8,
      const Color(0xffaab5ba),
      8,
    );
    final diamond = ui.Path()
      ..moveTo(right.left + 20, right.top + 24)
      ..lineTo(right.left + 26, right.top + 30)
      ..lineTo(right.left + 20, right.top + 36)
      ..lineTo(right.left + 14, right.top + 30)
      ..close();
    canvas.drawPath(diamond, ui.Paint()..color = const Color(0xffffd262));
    _text(
      canvas,
      '$collected/${area.required}',
      right.left + 34,
      right.top + 19,
      const Color(0xffffe6a0),
      15,
    );

    final portalReady =
        collected >= area.required &&
        (area.mechanism == null || mechanismActive) &&
        nodesActivated.length >= (area.nodesRequired ?? 0) &&
        !area.enemies.any((e) => e.gateKeeper && e.alive);
    if (timeLeft > 0) {
      final timerColor = timeLeft < 20
          ? const Color(0xffff7185)
          : const Color(0xffffd262);
      _text(
        canvas,
        'WAKTU  ${timeLeft.toStringAsFixed(0)}s',
        right.left + 11,
        right.top + 45,
        timerColor,
        9,
      );
    } else {
      _text(
        canvas,
        portalReady ? 'PORTAL TERBUKA' : 'PORTAL TERKUNCI',
        right.left + 11,
        right.top + 45,
        portalReady ? const Color(0xff73e7da) : const Color(0xff9ba8c7),
        8,
      );
    }

    if (hintTimer > 0 && !resultOpen) {
      final hintWidth = math.min(420.0, w - 32);
      final hintPanel = Rect.fromLTWH(
        (w - hintWidth) / 2,
        h - 48,
        hintWidth,
        30,
      );
      _drawHudPanel(canvas, hintPanel);
      _centerText(
        canvas,
        hint,
        w / 2,
        hintPanel.top + 8,
        const Color(0xffdce5e2),
        10,
        maxWidth: hintWidth - 24,
      );
    }

    if (resultOpen) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        ui.Paint()..color = const Color(0xc7080d14),
      );
      final panelWidth = math.min(420.0, w - 32);
      final resultPanel = Rect.fromLTWH(
        (w - panelWidth) / 2,
        h / 2 - 104,
        panelWidth,
        208,
      );
      _drawHudPanel(canvas, resultPanel);
      _centerText(
        canvas,
        won ? 'YGGDRASIL TERBANGUN' : 'PORTAL PULIH',
        w / 2,
        resultPanel.top + 30,
        const Color(0xffa3ead5),
        17,
        maxWidth: panelWidth - 32,
      );
      _centerText(
        canvas,
        won ? 'Skor $runEmblems emblem' : area.name,
        w / 2,
        resultPanel.top + 66,
        const Color(0xffeff2ec),
        13,
        maxWidth: panelWidth - 32,
      );
      _centerText(
        canvas,
        won
            ? 'Petualanganmu selesai.'
            : '$runEmblems / 3 emblem daun terkumpul',
        w / 2,
        resultPanel.top + 88,
        const Color(0xff9aaab4),
        10,
        maxWidth: panelWidth - 32,
      );
      final button = RRect.fromRectAndRadius(
        Rect.fromLTWH(w / 2 - 88, resultPanel.top + 126, 176, 34),
        const Radius.circular(11),
      );
      canvas.drawRRect(button, ui.Paint()..color = const Color(0xff83dec9));
      _centerText(
        canvas,
        won ? 'MAIN LAGI' : 'LANJUTKAN',
        w / 2,
        resultPanel.top + 136,
        const Color(0xff10201e),
        11,
      );
      _centerText(
        canvas,
        'TAP DI MANA SAJA  /  ENTER',
        w / 2,
        resultPanel.top + 172,
        const Color(0xff899ba4),
        8,
      );
    }
  }

  void _drawHudPanel(ui.Canvas canvas, Rect rect) {
    final panel = RRect.fromRectAndRadius(rect, const Radius.circular(11));
    canvas.drawRRect(panel, ui.Paint()..color = const Color(0xb0121b27));
    canvas.drawRRect(
      panel,
      ui.Paint()
        ..color = const Color(0x33596c76)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = .7,
    );
    canvas.drawLine(
      Offset(rect.left + 12, rect.top + .5),
      Offset(rect.right - 12, rect.top + .5),
      ui.Paint()
        ..color = const Color(0x3375e0ca)
        ..strokeWidth = .7,
    );
  }

  void _drawHeart(
    ui.Canvas canvas,
    double x,
    double y,
    double size,
    bool active,
  ) {
    final scale = size / 16;
    final path = ui.Path()
      ..moveTo(0, 7)
      ..cubicTo(-1.5, 5.5, -8, 1, -8, -3.5)
      ..cubicTo(-8, -8, -2, -9, 0, -4.5)
      ..cubicTo(2, -9, 8, -8, 8, -3.5)
      ..cubicTo(8, 1, 1.5, 5.5, 0, 7)
      ..close();
    canvas.save();
    canvas.translate(x, y);
    canvas.scale(scale);
    canvas.drawPath(
      path,
      ui.Paint()
        ..color = active ? const Color(0xffef6e82) : const Color(0xff3b4853),
    );
    canvas.drawPath(
      path,
      ui.Paint()
        ..color = active ? const Color(0xfff4a1a9) : const Color(0xff68747a)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = .8,
    );
    canvas.restore();
  }

  void _centerText(
    ui.Canvas canvas,
    String text,
    double centerX,
    double y,
    Color color,
    double size, {
    double maxWidth = double.infinity,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, Offset(centerX - painter.width / 2, y));
  }

  void _drawObjectiveMarkers(ui.Canvas canvas, double w, double h) {
    final targets = <Map<String, dynamic>>[];
    for (final k in area.keys) {
      if (!k.collected && !k.hidden) {
        targets.add({'x': k.x, 'y': k.y, 'c': 0xffd262});
      }
    }
    if (collected >= area.required) {
      final pendingNode = (area.mechanicNodes ?? []).firstWhere(
        (n) => !nodesActivated.contains(n['id']),
        orElse: () => <String, dynamic>{},
      );
      final pendingKeeper = area.enemies.firstWhere(
        (e) => e.gateKeeper && e.alive,
        orElse: () => Enemy('', 0, 0),
      );
      if (pendingNode.isNotEmpty) {
        targets.add({
          'x': (pendingNode['x'] as num).toDouble(),
          'y': ((pendingNode['y'] as num).toDouble()) - 70,
          'c': 0xfff36bd8,
        });
      } else if (pendingKeeper.type.isNotEmpty) {
        targets.add({
          'x': pendingKeeper.x,
          'y': pendingKeeper.y - 70,
          'c': 0xffff557d,
        });
      } else {
        targets.add({
          'x': area.portal['x']!,
          'y': area.portal['y']! - 80,
          'c': 0xff4de9dc,
        });
      }
    }
    final margin = 28.0;
    for (final t in targets.take(3)) {
      final sx = (((t['x'] as num).toDouble()) - _camX) * _scale;
      final sy = (((t['y'] as num).toDouble()) - _camY) * _scale;
      if (sx > margin && sx < w - margin && sy > 52 && sy < h - 34) continue;
      final x = _clampD(sx, margin, w - margin);
      final y = _clampD(sy, 52, h - 34);
      final markerColor = Color(t['c'] as int);
      canvas.drawCircle(
        Offset(x, y),
        8,
        ui.Paint()..color = markerColor.withValues(alpha: .18),
      );
      canvas.drawCircle(
        Offset(x, y),
        4.5,
        ui.Paint()
          ..color = markerColor
          ..style = ui.PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(x, y),
        8,
        ui.Paint()
          ..color = markerColor.withValues(alpha: .75)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _text(
    ui.Canvas canvas,
    String t,
    double x,
    double y,
    Color c,
    double size,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(color: c, fontSize: size, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x, y));
  }

  int _c(String hex) => Color(_parse(hex)).toARGB32();
  int _parse(String hex) {
    final v = hex.replaceFirst('#', '');
    return int.parse(v.length == 6 ? 'ff$v' : v, radix: 16);
  }
}
