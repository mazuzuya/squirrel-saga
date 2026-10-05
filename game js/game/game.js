import { loadGameAssets } from "./assets.js";
import { createAudio } from "./audio.js";
import { createInput } from "./input.js";
import { AREA_COUNT, makeArea } from "./levels.js";
import { createRenderer } from "./renderer.js";
import { SKINS, skinById } from "./skins.js";
import { createUI } from "./ui.js";

const PLAYER_HALF = 22;

function near(player, target, radius = 70) {
  return Math.hypot(player.x - target.x, player.y - target.y) < radius;
}

function inside(player, zone) {
  return player.x > zone.x && player.x < zone.x + zone.w && player.y > zone.y && player.y < zone.y + zone.h;
}

function approach(value, target, amount) {
  return value < target ? Math.min(target, value + amount) : Math.max(target, value - amount);
}

export function createGame({ mount, sdk, tweaks, assets }) {
  let ui; let input; let renderer; let audio; let raf = 0; let lastTime = 0;
  let destroyed = false; let paused = false; let resultOpen = false; let soundEnabled = true;
  const unsubscribes = []; const domCleanup = [];
  const balance = {
    speed: Number(tweaks.get("playerSpeed")),
    glideGravity: Number(tweaks.get("glideGravity")),
    enemySpeed: Number(tweaks.get("enemySpeed")),
    effects: Number(tweaks.get("effectsIntensity")),
  };
  const save = { version: 2, unlockedArea: 0, emblems: Array(AREA_COUNT).fill(0), campaignBest: 0, selectedSkin: 0 };
  const state = {
    areaIndex: 0, area: null, player: null, collected: 0, activated: new Set(), nodesActivated: new Set(), sequenceIndex: 0,
    mechanismActive: false, carryMode: null, clock: 0, campaignTime: 0, timeLeft: 0,
    particles: [], runEmblems: 0, checkpoint: { x: 0, y: 0 }, ready: true, camera: null, mechanicSlow: false, lightningOff: false,
  };

  function listen(target, type, handler, options) {
    target.addEventListener(type, handler, options);
    domCleanup.push(() => target.removeEventListener(type, handler, options));
  }

  function vibrate(pattern) {
    try { if (sdk.device.haptics.isSupported()) void sdk.device.haptics.vibrate(pattern); } catch { /* optional */ }
  }

  function burst(x, y, color, count = 10) {
    const amount = Math.max(2, Math.round(count * balance.effects));
    for (let i = 0; i < amount; i += 1) {
      state.particles.push({ x, y, vx: (Math.random() - .5) * 210, vy: -40 - Math.random() * 190, life: .35 + Math.random() * .45, maxLife: .8, color, size: 4 + Math.random() * 5 });
    }
  }

  function loadArea(index, showTip = true) {
    const clamped = Math.max(0, Math.min(AREA_COUNT - 1, index));
    state.areaIndex = clamped; state.area = makeArea(clamped); state.collected = 0;
    state.activated = new Set(); state.nodesActivated = new Set(); state.sequenceIndex = 0; state.mechanismActive = false; state.carryMode = null;
    state.mechanicSlow = false; state.lightningOff = false;
    state.runEmblems = 0; state.particles = []; state.timeLeft = state.area.timeLimit || 0;
    for (const marker of state.area.crumblePlatforms || []) {
      const platform = state.area.platforms.find((entry) => entry.x === marker.x && entry.y === marker.y);
      if (platform) platform.kind = "crumble";
    }
    const selectedSkin = skinById(save.selectedSkin);
    const maxHearts = selectedSkin.stats.maxHearts || 3;
    const startPlatform = state.area.platforms.find((platform) => state.area.spawn.x >= platform.x && state.area.spawn.x <= platform.x + platform.w);
    const startY = startPlatform?.y ?? state.area.spawn.y;
    state.player = {
      x: state.area.spawn.x, y: startY, vx: 0, vy: 0, facing: 1, hearts: maxHearts, maxHearts, skinId: selectedSkin.id, stamina: 100,
      onGround: true, gliding: false, climbing: false, animation: "idle", attackTime: 0,
      attackCooldown: 0, hurtTime: 0, invincible: 0, actionAnim: 0, actionKind: "dig", hazardShield: Boolean(selectedSkin.stats.hazardShield), airJumps: 0,
    };
    state.checkpoint = { x: state.area.spawn.x, y: startY }; state.ready = true; paused = false; resultOpen = false;
    ui.hideResult(); ui.showPause(false); ui.update(state);
    ui.buildAreaSelect(AREA_COUNT, save.unlockedArea, clamped, (areaIndex) => { loadArea(areaIndex); });
    ui.buildSkinSelect(SKINS, save.selectedSkin, selectSkin);
    if (showTip) window.setTimeout(() => { if (!destroyed && state.areaIndex === clamped) ui.hint(`Jalur akar • batang • kanopi — ${state.area.tip}`, 4200); }, 300);
  }

  function saveProgress() {
    const payload = { version: 2, unlockedArea: save.unlockedArea, emblems: save.emblems, campaignBest: save.campaignBest, selectedSkin: save.selectedSkin };
    void sdk.gameState.save(payload).catch(() => {});
  }

  function selectSkin(id) {
    save.selectedSkin = skinById(id).id;
    const selected = skinById(save.selectedSkin);
    state.player.skinId = selected.id; state.player.maxHearts = selected.stats.maxHearts || 3;
    state.player.hearts = Math.min(state.player.maxHearts, Math.max(state.player.hearts, state.player.maxHearts));
    state.player.hazardShield = Boolean(selected.stats.hazardShield);
    ui.buildSkinSelect(SKINS, save.selectedSkin, selectSkin); ui.update(state); saveProgress();
    ui.hint(`${selected.name}: ${selected.buff}`, 2200);
  }

  function setPaused(value) {
    if (resultOpen) return;
    paused = value; ui.showPause(value);
    input.clearPressed();
  }

  function respawn(damage = true) {
    const player = state.player;
    if (damage) {
      player.hearts -= 1; audio?.play("hurt"); vibrate([45]); burst(player.x, player.y - 35, "#ff5d86", 12);
    }
    if (player.hearts <= 0) { player.hearts = player.maxHearts; ui.hint("Luma kembali ke checkpoint.", 1800); }
    player.x = state.checkpoint.x; player.y = state.checkpoint.y; player.vx = 0; player.vy = 0;
    player.invincible = 1.2; player.hurtTime = .35; player.stamina = 100;
    state.area.platforms.forEach((platform) => { if (platform.kind === "crumble") { platform.disabled = false; platform.crumbleTime = 0; } });
  }

  function collectKey(item) {
    item.collected = true; audio?.play("key"); vibrate([18]); burst(item.x, item.y, "#ffd75e", 14);
    if (item.frozen) { state.carryMode = "frozen"; ui.hint("Bawa ke batu panas lalu tekan AKSI."); }
    else if (item.toxic) { state.carryMode = "toxic"; ui.hint("Sucikan di mata air lalu tekan AKSI."); }
    else if (item.gear) { state.carryMode = "gear"; ui.hint("Pasang pada mesin dengan AKSI."); }
    else { state.collected += 1; if (item.heavy) state.carryMode = "heavy"; }
    ui.update(state);
  }

  function completeCarry(mode) {
    if (state.carryMode !== mode) return;
    state.carryMode = null; state.collected += 1; audio?.play("key"); burst(state.player.x, state.player.y - 35, "#59e7e0", 16); ui.update(state);
  }

  function interact() {
    const { area, player } = state;
    for (const node of area.mechanicNodes || []) {
      if (state.nodesActivated.has(node.id) || !near(player, node, 120)) continue;
      state.nodesActivated.add(node.id); audio?.play("portal"); vibrate([25, 35, 25]); burst(node.x, node.y - 40, "#58f0e4", 22);
      if (node.effect === "reveal") area.keys.forEach((item) => { item.hidden = false; });
      else if (node.effect === "tunnel") { player.x = Math.min((area.worldWidth || 5900) - 260, player.x + 260); player.y -= 130; player.vy = -160; }
      else if (node.effect === "prism") { player.hearts = player.maxHearts; player.stamina = 100; }
      else if (node.effect === "slow") state.mechanicSlow = true;
      else if (node.effect === "shield") player.hazardShield = true;
      else if (node.effect === "time") state.timeLeft += 30;
      else if (node.effect === "gravity") (area.lowGravityZones ||= []).push({ x: node.x - 360, y: node.y - 700, w: 720, h: 780 });
      else if (node.effect === "lightning") state.lightningOff = true;
      else if (node.effect === "phase") player.invincible = 5;
      else if (node.effect === "gust") { (area.updrafts ||= []).push({ x: node.x + 80, y: node.y - 720, w: 150, h: 800 }); player.vy = -420; }
      ui.hint(node.message, 2400); return;
    }
    for (const teleporter of area.teleporters || []) {
      if (near(player, teleporter, 100)) {
        burst(player.x, player.y - 30, "#b283ff", 18); player.x = teleporter.toX; player.y = teleporter.toY;
        player.vx = 0; player.vy = -90; audio?.play("portal"); ui.hint("Akar mimpi berpindah!", 1000); return;
      }
    }
    for (const spot of area.digSpots || []) {
      if (!state.activated.has(spot.id) && Math.abs(player.x - spot.x) < 75 && Math.abs(player.y - spot.y) < 100) {
        state.activated.add(spot.id); const item = area.keys.find((entry) => entry.id === spot.id); if (item) item.hidden = false;
        player.actionAnim = .55; player.actionKind = "dig"; audio?.play("hit"); burst(spot.x, spot.y - 5, "#d3915d", 10); return;
      }
    }
    for (const lever of area.levers || []) {
      if (!state.activated.has(lever.id) && near(player, lever, 85)) {
        state.activated.add(lever.id); audio?.play("hit"); burst(lever.x, lever.y - 25, "#58d9d3", 8);
        if (state.activated.size >= area.levers.length) { area.keys[0].hidden = false; ui.hint("Arus berubah—kunci kini dapat diraih!"); }
        return;
      }
    }
    for (const vine of area.vines || []) {
      if (Math.abs(player.x - vine.x) < 85 && Math.abs((player.y - 100) - vine.y) < 210) {
        player.vy = -390; player.vx = player.facing * 300; player.actionAnim = .5; player.actionKind = "swing"; audio?.play("jump"); return;
      }
    }
    if (area.heat && near(player, area.heat, 105) && state.carryMode === "frozen") { completeCarry("frozen"); ui.hint("Es mencair. Kunci siap digunakan!"); return; }
    if (area.spring && near(player, area.spring, 110) && state.carryMode === "toxic") { completeCarry("toxic"); ui.hint("Racun terbilas dari kunci!"); return; }
    if (area.mechanism && near(player, area.mechanism, 115) && state.carryMode === "gear") {
      completeCarry("gear"); state.mechanismActive = true; audio?.play("portal"); ui.hint("Roda gigi tersinkron!");
    }
  }

  function startAttack() {
    const player = state.player;
    if (player.attackCooldown > 0) return;
    const skin = skinById(player.skinId);
    player.attackTime = .34; player.attackCooldown = skin.stats.attackCooldown || .46; audio?.play("hit"); vibrate([12]);
    const hitX = player.x + player.facing * 54;
    state.area.enemies.forEach((enemy) => {
      if (!enemy.alive || Math.abs(enemy.x - hitX) > (enemy.type === "guardian" ? 75 : 58) || Math.abs(enemy.y - player.y) > 82) return;
      damageEnemy(enemy, player.facing * 70, skin.stats.attackDamage || 1);
    });
  }

  function damageEnemy(enemy, knock = 0, amount = 1) {
    enemy.hp -= amount; enemy.hitTime = .22; enemy.state = "hit"; enemy.x += knock * .08;
    burst(enemy.x, enemy.y - 35, "#ffcf65", 12); vibrate([20]);
    if (enemy.hp <= 0) { enemy.alive = false; enemy.state = "defeat"; enemy.defeatTime = 1; }
  }

  function updateMovingPlatforms(dt) {
    state.area.movingPlatforms?.forEach((platform, index) => {
      const speed = platform.speed * (state.mechanicSlow || skinById(state.player.skinId).stats.movingSlow ? .55 : 1);
      const phase = state.clock * speed + index;
      platform.currentX = platform.vertical ? platform.x : platform.x + Math.sin(phase) * platform.range;
      platform.currentY = platform.vertical ? platform.y + Math.sin(phase) * platform.range : platform.y;
      platform.dx = Math.cos(phase) * platform.range * speed * dt;
    });
  }

  function platformList() {
    return [
      ...state.area.platforms.filter((platform) => !platform.disabled),
      ...(state.area.movingPlatforms || []).map((platform) => ({ x: platform.currentX, y: platform.currentY, w: platform.w, h: platform.h, moving: platform })),
    ];
  }

  function updatePlayer(dt) {
    const { player, area } = state;
    const skin = skinById(player.skinId);
    player.attackTime = Math.max(0, player.attackTime - dt); player.attackCooldown = Math.max(0, player.attackCooldown - dt);
    player.hurtTime = Math.max(0, player.hurtTime - dt); player.invincible = Math.max(0, player.invincible - dt); player.actionAnim = Math.max(0, player.actionAnim - dt);
    const axis = Number(input.held.right) - Number(input.held.left);
    if (axis) player.facing = axis;

    const climb = (area.climbZones || []).find((zone) => player.x > zone.x - 15 && player.x < zone.x + zone.w + 15 && player.y > zone.y && player.y < zone.y + zone.h + 20);
    player.climbing = Boolean(climb && input.held.action && player.stamina > 0);
    const currentPlatform = platformList().find((platform) => player.x > platform.x && player.x < platform.x + platform.w && Math.abs(player.y - platform.y) < 8);
    const traction = currentPlatform?.kind === "ice" && !skin.stats.iceGrip ? 230 : player.onGround ? 1300 : 620;
    const targetSpeed = axis * balance.speed * (skin.stats.speed || 1);
    player.vx = approach(player.vx, targetSpeed, traction * dt);
    if (!axis && player.onGround && currentPlatform?.kind !== "ice") player.vx = approach(player.vx, 0, 1600 * dt);

    if (input.take("jump")) {
      if (player.onGround) { player.vy = -440 * (skin.stats.jumpBoost || 1); player.onGround = false; player.airJumps = 0; audio?.play("jump"); }
      else if (skin.stats.doubleJump && player.airJumps < 1) { player.vy = -410; player.airJumps += 1; audio?.play("jump"); burst(player.x, player.y, "#d9f3ff", 9); }
    }
    if (input.take("attack")) startAttack();
    if (input.take("action")) interact();

    player.gliding = false;
    if (player.climbing) {
      player.vy = -155; player.vx = axis * 65; player.stamina = Math.max(0, player.stamina - 27 * (skin.stats.climbCost || 1) * dt);
    } else {
      let gravity = 980;
      if ((area.lowGravityZones || []).some((zone) => inside(player, zone))) gravity *= .38;
      if (input.held.jump && !player.onGround && player.vy > -120 && player.stamina > 0 && state.carryMode !== "heavy") {
        player.gliding = true; gravity = balance.glideGravity; player.vy = Math.min(player.vy, 135); player.stamina = Math.max(0, player.stamina - 17 * (skin.stats.glideCost || 1) * dt);
      }
      player.vy += gravity * dt;
    }
    if (player.onGround && !player.climbing) player.stamina = Math.min(100, player.stamina + 34 * (skin.stats.staminaRegen || 1) * dt);

    if ((area.shadowZones || []).some((zone) => inside(player, zone))) player.stamina = Math.max(0, player.stamina - 12 * dt);
    if (!skin.stats.heatImmune && (area.hotZones || []).some((zone) => inside(player, zone))) {
      player.stamina = Math.max(0, player.stamina - 18 * dt);
      if (player.stamina <= 0 && player.invincible <= 0) {
        player.hearts -= 1; player.invincible = skin.stats.invincible || 1.15; player.hurtTime = .38; player.vy = -240; audio?.play("hurt");
        if (player.hearts <= 0) respawn(false);
      }
    }

    for (const zone of area.updrafts || []) {
      if (player.gliding && player.x > zone.x && player.x < zone.x + zone.w && player.y > zone.y && player.y < zone.y + zone.h) player.vy = Math.max(-360, player.vy - 760 * (skin.stats.updraft || 1) * dt);
    }
    for (const zone of area.windZones || []) {
      if (player.x > zone.x && player.x < zone.x + zone.w && player.y > zone.y && player.y < zone.y + zone.h) player.vx += zone.force * dt;
    }

    const oldY = player.y; player.x += player.vx * dt; player.y += player.vy * dt;
    player.x = Math.max(24, Math.min((area.worldWidth || 2300) - 24, player.x)); player.onGround = false;
    if (player.vy >= 0) {
      let landing = null;
      for (const platform of platformList()) {
        if (player.x + PLAYER_HALF < platform.x || player.x - PLAYER_HALF > platform.x + platform.w) continue;
        if (oldY <= platform.y + 4 && player.y >= platform.y && (!landing || platform.y < landing.y)) landing = platform;
      }
      if (landing) {
        player.y = landing.y; player.vy = 0; player.onGround = true; player.airJumps = 0;
        if (landing.moving && !landing.moving.vertical) player.x += landing.moving.dx || 0;
        if (landing.kind === "crumble") {
          landing.crumbleTime = (landing.crumbleTime || 0) + dt;
          if (landing.crumbleTime > .65) { landing.disabled = true; player.onGround = false; ui.hint("Dahan runtuh!", 700); }
        }
      }
    }

    for (const mushroom of area.mushrooms || []) {
      if (player.vy >= 0 && Math.abs(player.x - mushroom.x) < 52 && player.y > mushroom.y - 55 && player.y < mushroom.y + 20) {
        player.y = mushroom.y - 52; player.vy = -535; player.onGround = false; audio?.play("bounce"); burst(mushroom.x, mushroom.y - 20, mushroom.color === "red" ? "#ff5475" : mushroom.color === "blue" ? "#50d8ff" : "#78ef73", 9);
        const expected = area.sequence?.[state.sequenceIndex];
        if (expected) {
          if (mushroom.color === expected) { state.sequenceIndex += 1; ui.hint(`${state.sequenceIndex}/3 urutan benar`, 900); }
          else { state.sequenceIndex = mushroom.color === area.sequence[0] ? 1 : 0; ui.hint("Urutan berpendar ulang.", 900); }
          if (state.sequenceIndex === area.sequence.length) { area.keys[0].hidden = false; state.sequenceIndex = 0; ui.hint("Rune warna terbentuk!"); }
        }
      }
    }

    for (const hazard of area.hazards || []) {
      if (player.x > hazard.x && player.x < hazard.x + hazard.w && player.y > hazard.y - 4) {
        if (player.hazardShield) { player.hazardShield = false; player.vy = -430; player.y = hazard.y - 30; ui.hint("Mirestrider menahan racun!", 1200); }
        else respawn();
        break;
      }
    }
    (area.lightningZones || []).forEach((zone, index) => {
      const active = !state.lightningOff && (state.clock + index * .63) % 3.2 > 2.78;
      if (active && player.x > zone.x && player.x < zone.x + zone.w && player.invincible <= 0) {
        player.hearts -= 1; player.invincible = skin.stats.invincible || 1.15; player.hurtTime = .4; player.vy = -300; audio?.play("hurt"); burst(player.x, player.y - 30, "#fff47a", 16);
        if (player.hearts <= 0) respawn(false);
      }
    });
    if (player.y > (area.worldHeight || 900) + 100) respawn();
    if (player.onGround && player.x > state.checkpoint.x + 950) { state.checkpoint = { x: player.x, y: player.y }; ui.hint("Checkpoint", 900); }

    for (const item of area.keys) if (!item.collected && !item.hidden && Math.abs(player.x - item.x) < 45 && Math.abs((player.y - 30) - item.y) < 60) collectKey(item);
    area.emblems.forEach((emblem) => {
      if (!emblem.collected && Math.abs(player.x - emblem.x) < 40 && Math.abs((player.y - 25) - emblem.y) < 55) {
        emblem.collected = true; state.runEmblems += 1; audio?.play("key"); burst(emblem.x, emblem.y, "#8cff7a", 10); ui.hint(`Emblem Daun ${state.runEmblems}/3`, 1000);
      }
    });

    const portalReady = state.collected >= area.required && (!area.mechanism || state.mechanismActive)
      && state.nodesActivated.size >= (area.nodesRequired || 0) && !area.enemies.some((enemy) => enemy.gateKeeper && enemy.alive);
    if (portalReady && Math.abs(player.x - area.portal.x) < 75 && Math.abs(player.y - area.portal.y) < 125) finishArea();
    updateAnimation();
  }

  function updateEnemies(dt) {
    const player = state.player;
    state.area.enemies.forEach((enemy) => {
      if (!enemy.alive) { enemy.defeatTime = Math.max(0, enemy.defeatTime - dt); return; }
      enemy.hitTime = Math.max(0, (enemy.hitTime || 0) - dt);
      enemy.timer = ((enemy.timer || 0) + dt) % 3.8;
      if (enemy.hitTime > 0) enemy.state = "hit";
      else if (enemy.timer < 2.05) enemy.state = "patrol";
      else if (enemy.timer < 2.68) enemy.state = "telegraph";
      else if (enemy.timer < 3.15) enemy.state = "attack";
      else enemy.state = "patrol";
      enemy.dir = player.x >= enemy.x ? 1 : -1;
      if (enemy.state === "patrol") {
        const patrolDir = Math.sin(state.clock * .8 + enemy.originX) > 0 ? 1 : -1;
        enemy.x += patrolDir * balance.enemySpeed * .2 * dt;
      } else if (enemy.state === "attack") enemy.x += enemy.dir * balance.enemySpeed * .75 * dt;
      enemy.x = Math.max(enemy.originX - 100, Math.min(enemy.originX + 100, enemy.x));

      const vertical = Math.abs((player.y - 30) - (enemy.y - (enemy.flying ? 20 : 30)));
      if (Math.abs(player.x - enemy.x) < (enemy.type === "guardian" ? 72 : 48) && vertical < 58) {
        if (player.vy > 130 && player.y < enemy.y - 8) { damageEnemy(enemy); player.vy = -330; audio?.play("bounce"); }
        else if (player.invincible <= 0) {
          player.hearts -= 1; player.invincible = skinById(player.skinId).stats.invincible || 1.15; player.hurtTime = .38; player.vx = -enemy.dir * 240; player.vy = -250;
          audio?.play("hurt"); vibrate([50]); burst(player.x, player.y - 30, "#ff5d86", 12);
          if (player.hearts <= 0) respawn(false);
        }
      }
    });
  }

  function updateAnimation() {
    const player = state.player;
    if (player.hurtTime > 0) player.animation = "hurt";
    else if (player.attackTime > 0) player.animation = "tail_attack";
    else if (player.actionAnim > 0) player.animation = player.actionKind;
    else if (player.climbing) player.animation = "climb";
    else if (state.carryMode) player.animation = "carry";
    else if (!player.onGround) player.animation = player.gliding ? "glide" : "jump";
    else if (Math.abs(player.vx) > 24) player.animation = "run";
    else player.animation = "idle";
  }

  function updateParticles(dt) {
    state.particles.forEach((particle) => { particle.life -= dt; particle.x += particle.vx * dt; particle.y += particle.vy * dt; particle.vy += 360 * dt; });
    state.particles = state.particles.filter((particle) => particle.life > 0);
  }

  function finishArea() {
    if (resultOpen) return;
    resultOpen = true; state.player.animation = "win"; audio?.play("portal"); vibrate([30, 40, 55]);
    save.emblems[state.areaIndex] = Math.max(save.emblems[state.areaIndex] || 0, state.runEmblems);
    save.unlockedArea = Math.max(save.unlockedArea, Math.min(AREA_COUNT - 1, state.areaIndex + 1));
    const victory = state.areaIndex === AREA_COUNT - 1; const totalEmblems = save.emblems.reduce((sum, value) => sum + value, 0);
    if (victory && (!save.campaignBest || state.campaignTime < save.campaignBest)) save.campaignBest = Math.round(state.campaignTime);
    saveProgress();
    const score = totalEmblems * 10000 + Math.max(0, 10000 - Math.floor(state.campaignTime));
    ui.showResult({ victory, areaName: state.area.name, emblems: state.runEmblems, totalEmblems, totalPossible: AREA_COUNT * 3, score, seconds: Math.floor(state.campaignTime) });
    if (victory) void sdk.leaderboard.submit(score).catch(() => {});
  }

  function frame(timestamp) {
    if (destroyed) return;
    const dt = Math.min(.033, Math.max(0, (timestamp - lastTime) / 1000 || 0)); lastTime = timestamp;
    if (input.take("pause")) setPaused(!paused);
    const anyInput = Object.values(input.held).some(Boolean);
    if (state.ready && anyInput) { state.ready = false; ui.hint("Jelajahi atas dan bawah—penanda emas menunjukkan kunci.", 2600); }
    if (!paused && !resultOpen && !state.ready) {
      state.clock += dt; state.campaignTime += dt;
      if (state.area.timeLimit) {
        state.timeLeft -= dt;
        if (state.timeLeft <= 0) { state.timeLeft = state.area.timeLimit; respawn(); ui.hint("Waktu berputar kembali!", 1700); }
      }
      updateMovingPlatforms(dt); updatePlayer(dt); updateEnemies(dt); updateParticles(dt);
    } else state.clock += dt * .25;
    ui.update(state); renderer.render(state); raf = requestAnimationFrame(frame);
  }

  async function start() {
    ui = createUI(mount); input = createInput(ui.shell);
    listen(ui.buttons.pause, "click", () => setPaused(true));
    listen(ui.buttons.resume, "click", () => setPaused(false));
    listen(ui.buttons.retry, "click", () => { setPaused(false); respawn(false); });
    listen(ui.buttons.next, "click", () => loadArea(state.areaIndex === AREA_COUNT - 1 ? 0 : state.areaIndex + 1));
    listen(ui.buttons.reload, "click", () => window.location.reload());
    listen(ui.buttons.sound, "click", () => { soundEnabled = !soundEnabled; audio?.setEnabled(soundEnabled); ui.setSoundLabel(soundEnabled); });

    try {
      const [library, loadedSave, audioController] = await Promise.all([
        loadGameAssets(assets), sdk.gameState.load().catch(() => null), createAudio(sdk),
      ]);
      if (destroyed) return;
      if (loadedSave?.version === 1 || loadedSave?.version === 2) {
        save.unlockedArea = Math.max(0, Math.min(AREA_COUNT - 1, Number(loadedSave.unlockedArea) || 0));
        save.emblems = Array.from({ length: AREA_COUNT }, (_, index) => Math.max(0, Math.min(3, Number(loadedSave.emblems?.[index]) || 0)));
        save.campaignBest = Math.max(0, Number(loadedSave.campaignBest) || 0);
        save.selectedSkin = Math.max(0, Math.min(20, Number(loadedSave.selectedSkin) || 0));
      }
      audio = audioController; renderer = createRenderer(ui.canvas, library); loadArea(save.unlockedArea); ui.ready();
      const unlock = () => { void audio.unlock(); ui.shell.removeEventListener("pointerdown", unlock, true); window.removeEventListener("keydown", unlock, true); };
      ui.shell.addEventListener("pointerdown", unlock, true); window.addEventListener("keydown", unlock, true);
      domCleanup.push(() => { ui.shell.removeEventListener("pointerdown", unlock, true); window.removeEventListener("keydown", unlock, true); });
      lastTime = performance.now(); raf = requestAnimationFrame(frame);
    } catch (error) {
      console.error("Game startup failed", error); ui.showError();
    }
  }

  unsubscribes.push(
    tweaks.subscribe("playerSpeed", (value) => { balance.speed = Number(value); }),
    tweaks.subscribe("glideGravity", (value) => { balance.glideGravity = Number(value); }),
    tweaks.subscribe("enemySpeed", (value) => { balance.enemySpeed = Number(value); }),
    tweaks.subscribe("effectsIntensity", (value) => { balance.effects = Number(value); }),
  );

  return {
    start,
    destroy() {
      destroyed = true; cancelAnimationFrame(raf); domCleanup.forEach((off) => off()); unsubscribes.forEach((off) => off?.());
      input?.destroy(); renderer?.destroy(); void audio?.destroy(); ui?.destroy();
    },
  };
}
