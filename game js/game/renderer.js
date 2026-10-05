import { ENEMY_SHEET } from "./levels.js";

function frameCrop(frame) { return frame?.content || frame?.source; }

function drawFrameInBox(ctx, sheet, frame, x, y, w, h, alpha = 1) {
  if (!frame) return;
  const crop = frameCrop(frame);
  const scale = Math.min(w / crop.w, h / crop.h);
  const dw = crop.w * scale; const dh = crop.h * scale;
  ctx.save(); ctx.globalAlpha = alpha;
  ctx.drawImage(sheet.image, crop.x, crop.y, crop.w, crop.h, x + (w - dw) / 2, y + (h - dh) / 2, dw, dh);
  ctx.restore();
}

function drawAnchored(ctx, sheet, frame, x, y, targetHeight, facing = 1, alpha = 1) {
  if (!frame) return;
  const crop = frameCrop(frame); const anchor = frame.anchor || { x: crop.x + crop.w / 2, y: crop.y + crop.h };
  const scale = targetHeight / 380;
  ctx.save(); ctx.globalAlpha = alpha; ctx.translate(x, y); ctx.scale(facing, 1);
  ctx.drawImage(sheet.image, crop.x, crop.y, crop.w, crop.h,
    -(anchor.x - crop.x) * scale, -(anchor.y - crop.y) * scale, crop.w * scale, crop.h * scale);
  ctx.restore();
}

export function createRenderer(canvas, library) {
  const ctx = canvas.getContext("2d", { alpha: false });
  let width = 1; let height = 1; let dpr = 1;

  function resize() {
    const rect = canvas.getBoundingClientRect();
    if (!rect.width || !rect.height) return;
    dpr = Math.min(window.devicePixelRatio || 1, 2);
    canvas.width = Math.round(rect.width * dpr);
    canvas.height = Math.round(rect.height * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    width = rect.width; height = rect.height;
    ctx.imageSmoothingEnabled = false;
  }
  const observer = new ResizeObserver(resize); observer.observe(canvas); resize();

  function render(state) {
    const { area, player, clock } = state;
    if (!area) return;
    const scale = Math.max(0.48, Math.min(width / 720, height / 720));
    const viewW = width / scale; const viewH = height / scale;
    const worldW = area.worldWidth || 2300; const worldH = area.worldHeight || 900;
    const cameraX = Math.max(0, Math.min(worldW - viewW, player.x - viewW * 0.42));
    const centeredY = worldH / 2 - viewH / 2;
    const cameraY = viewH >= worldH ? centeredY : Math.max(0, Math.min(worldH - viewH, player.y - viewH * 0.56));
    state.camera = { x: cameraX, y: cameraY, scale, viewW, viewH };
    const sx = (x) => (x - cameraX) * scale;
    const sy = (y) => (y - cameraY) * scale;

    const gradient = ctx.createLinearGradient(0, 0, 0, height);
    gradient.addColorStop(0, area.colors[0]); gradient.addColorStop(1, "#050510");
    ctx.fillStyle = gradient; ctx.fillRect(0, 0, width, height);
    drawBackdrop(area, cameraX, cameraY, scale);

    // Distant motes keep even quiet screens alive without obscuring routes.
    ctx.save(); ctx.fillStyle = area.colors[2]; ctx.globalAlpha = 0.22;
    for (let i = 0; i < 24; i += 1) {
      const x = ((i * 149 + clock * (8 + i % 3)) % (width + 40)) - 20;
      const y = (i * 83 + Math.sin(clock + i) * 28) % Math.max(height, 1);
      ctx.fillRect(Math.round(x), Math.round(y), i % 4 === 0 ? 3 : 2, i % 4 === 0 ? 3 : 2);
    }
    ctx.restore();

    drawClimbStructure(area, sx, sy, scale);
    drawZones(state, sx, sy, scale);
    area.platforms.filter((platform) => !platform.disabled).forEach((platform) => drawPlatform(area, platform, sx, sy, scale));
    (area.movingPlatforms || []).forEach((platform) => drawMovingPlatform(area, platform, sx, sy, scale, clock));
    drawObjects(state, sx, sy, scale);
    drawEnemies(state, sx, sy, scale);
    drawPlayer(state, sx, sy, scale);
    drawParticles(state, sx, sy, scale);
    drawObjectiveMarkers(state, sx, sy);

    if (player.hurtTime > 0) {
      ctx.fillStyle = `rgba(255,77,130,${Math.min(0.18, player.hurtTime * 0.2)})`;
      ctx.fillRect(0, 0, width, height);
    }
  }

  function drawBackdrop(area, cameraX, cameraY, scale) {
    const key = area.backdrop === "FOREST_BACKDROP" ? "forest" : area.backdrop === "CAVERN_BACKDROP" ? "cavern" : "core";
    const image = library.backdrops[key]; if (!image) return;
    const tileH = height * 1.22; const tileW = image.width * (tileH / image.height);
    const offsetY = -height * .11 - (cameraY * scale * .035) % (height * .12);
    let start = -((cameraX * scale * 0.12) % tileW) - tileW;
    let index = Math.floor(cameraX * scale * 0.12 / tileW) - 1;
    for (let x = start; x < width + tileW; x += tileW, index += 1) {
      ctx.save(); ctx.globalAlpha = 0.72;
      if (index % 2) { ctx.translate(x + tileW, offsetY); ctx.scale(-1, 1); ctx.drawImage(image, 0, 0, tileW, tileH); }
      else ctx.drawImage(image, x, offsetY, tileW, tileH);
      ctx.restore();
    }
    const fog = ctx.createLinearGradient(0, 0, 0, height);
    fog.addColorStop(0, "rgba(5,6,20,.08)"); fog.addColorStop(0.7, "rgba(5,6,20,.18)"); fog.addColorStop(1, "rgba(5,6,20,.62)");
    ctx.fillStyle = fog; ctx.fillRect(0, 0, width, height);
  }

  function drawClimbStructure(area, sx, sy, scale) {
    if (!area.climbArt) return;
    const image = library.climbTrees[area.climbArt.key];
    if (!image) return;
    const art = area.climbArt;
    const fit = Math.min(art.w / image.width, art.h / image.height);
    const drawW = image.width * fit; const drawH = image.height * fit;
    ctx.save(); ctx.globalAlpha = .98;
    ctx.drawImage(image, sx(art.x + (art.w - drawW) / 2), sy(art.y + art.h - drawH), drawW * scale, drawH * scale);
    ctx.restore();
  }

  function tileSheet(area) {
    if (area.tiles === "FOREST_PLATFORM_TILES") return library.sheets.forestTiles;
    if (area.tiles === "CAVERN_PLATFORM_TILES") return library.sheets.cavernTiles;
    return library.sheets.coreTiles;
  }

  function drawPlatform(area, platform, sx, sy, scale) {
    const sheet = tileSheet(area); const frame = sheet.frames.center; const crop = frameCrop(frame);
    const targetH = Math.max(platform.h, 76); const scaleY = targetH / crop.h;
    const surfaceOffset = ((frame.surfaceY ?? crop.y) - crop.y) * scaleY;
    const x = sx(platform.x); const y = sy(platform.y - surfaceOffset);
    ctx.save();
    if (platform.kind === "crumble") {
      ctx.globalAlpha = Math.max(.35, 1 - (platform.crumbleTime || 0));
      ctx.translate(Math.sin((platform.crumbleTime || 0) * 70) * 3 * scale, 0);
    }
    ctx.drawImage(sheet.image, crop.x, crop.y, crop.w, crop.h, x, y, platform.w * scale, targetH * scale);
    ctx.restore();
    if (platform.kind === "ice") {
      ctx.fillStyle = "rgba(120,235,255,.35)"; ctx.fillRect(x, sy(platform.y) - 4 * scale, platform.w * scale, 7 * scale);
    }
  }

  function drawMovingPlatform(area, platform, sx, sy, scale, clock) {
    const x = platform.currentX ?? platform.x; const y = platform.currentY ?? platform.y;
    if (area.name === "Waterfall Canopy") {
      drawFrameInBox(ctx, library.sheets.puzzle, library.sheets.puzzle.frames.leaf_raft, sx(x), sy(y - 34), platform.w * scale, 65 * scale);
    } else {
      const frame = library.sheets.world.animations.gear_loop[Math.floor(clock * 8) % 5];
      drawFrameInBox(ctx, library.sheets.world, frame, sx(x), sy(y - 60), platform.w * scale, 84 * scale);
    }
  }

  function drawZones(state, sx, sy, scale) {
    const { area, clock } = state; const world = library.sheets.world;
    (area.updrafts || []).forEach((zone) => {
      const frame = world.animations.updraft_loop[Math.floor(clock * 10) % 5];
      drawFrameInBox(ctx, world, frame, sx(zone.x), sy(zone.y), zone.w * scale, zone.h * scale, 0.62);
    });
    (area.climbZones || []).forEach((zone) => {
      if (zone.art) return;
      const grad = ctx.createLinearGradient(sx(zone.x), sy(zone.y), sx(zone.x + zone.w), sy(zone.y));
      grad.addColorStop(0, "rgba(61,30,38,.55)"); grad.addColorStop(.5, "rgba(100,65,47,.85)"); grad.addColorStop(1, "rgba(61,30,38,.55)");
      ctx.fillStyle = grad; ctx.fillRect(sx(zone.x), sy(zone.y), zone.w * scale, zone.h * scale);
      ctx.fillStyle = "rgba(77,233,220,.65)";
      for (let y = zone.y + 30; y < zone.y + zone.h; y += 58) ctx.fillRect(sx(zone.x + zone.w * .45), sy(y), 8 * scale, 18 * scale);
    });
    (area.hazards || []).forEach((hazard) => {
      const grad = ctx.createLinearGradient(0, sy(hazard.y), 0, sy(hazard.y + hazard.h));
      grad.addColorStop(0, "#d82f91"); grad.addColorStop(.22, "#6e1e77"); grad.addColorStop(1, "#1e0a3d");
      ctx.fillStyle = grad; ctx.fillRect(sx(hazard.x), sy(hazard.y), hazard.w * scale, hazard.h * scale);
      ctx.fillStyle = "rgba(210,255,71,.8)";
      for (let i = 0; i < 4; i += 1) {
        const bx = sx(hazard.x + ((i * 47 + state.clock * 23) % hazard.w));
        const by = sy(hazard.y + 6 + Math.sin(state.clock * 2 + i) * 5);
        ctx.fillRect(bx, by, 4 * scale, 4 * scale);
      }
    });
    (area.windZones || []).forEach((zone) => {
      ctx.strokeStyle = "rgba(145,234,255,.26)"; ctx.lineWidth = 3 * scale;
      for (let i = 0; i < 4; i += 1) {
        const yy = sy(zone.y + 80 + i * 75 + Math.sin(clock * 2 + i) * 18);
        ctx.beginPath(); ctx.moveTo(sx(zone.x + 15), yy); ctx.lineTo(sx(zone.x + zone.w - 15), yy); ctx.stroke();
      }
    });
    (area.lowGravityZones || []).forEach((zone) => {
      ctx.fillStyle = "rgba(82,226,255,.055)"; ctx.fillRect(sx(zone.x), sy(zone.y), zone.w * scale, zone.h * scale);
      ctx.fillStyle = "rgba(150,244,255,.32)";
      for (let i = 0; i < 8; i += 1) {
        const px = sx(zone.x + ((i * 97 + clock * 18) % zone.w));
        const py = sy(zone.y + zone.h - ((i * 131 + clock * 36) % zone.h));
        ctx.fillRect(px, py, 3 * scale, 3 * scale);
      }
    });
    (area.shadowZones || []).forEach((zone) => {
      const gradient = ctx.createRadialGradient(sx(zone.x + zone.w / 2), sy(zone.y + zone.h / 2), 20, sx(zone.x + zone.w / 2), sy(zone.y + zone.h / 2), zone.w * scale * .65);
      gradient.addColorStop(0, "rgba(61,25,91,.08)"); gradient.addColorStop(1, "rgba(4,4,18,.42)");
      ctx.fillStyle = gradient; ctx.fillRect(sx(zone.x), sy(zone.y), zone.w * scale, zone.h * scale);
    });
    (area.hotZones || []).forEach((zone) => {
      ctx.fillStyle = "rgba(255,91,43,.075)"; ctx.fillRect(sx(zone.x), sy(zone.y), zone.w * scale, zone.h * scale);
      ctx.strokeStyle = "rgba(255,172,72,.28)"; ctx.lineWidth = 2 * scale;
      for (let y = zone.y + 60; y < zone.y + zone.h; y += 120) { ctx.beginPath(); ctx.moveTo(sx(zone.x), sy(y)); ctx.lineTo(sx(zone.x + zone.w), sy(y - 25)); ctx.stroke(); }
    });
    (area.lightningZones || []).forEach((zone, index) => {
      const phase = (clock + index * .63) % 3.2; const active = !state.lightningOff && phase > 2.78;
      ctx.fillStyle = active ? "rgba(255,250,130,.62)" : phase > 2.35 ? "rgba(255,90,155,.18)" : "rgba(0,0,0,0)";
      ctx.fillRect(sx(zone.x), 0, zone.w * scale, height);
      if (phase > 2.35) { ctx.strokeStyle = active ? "#fffbd0" : "#ff6ca9"; ctx.lineWidth = 3; ctx.beginPath(); ctx.moveTo(sx(zone.x + zone.w / 2), 0); ctx.lineTo(sx(zone.x + zone.w * .35), height * .45); ctx.lineTo(sx(zone.x + zone.w * .62), height); ctx.stroke(); }
    });
  }

  function drawObjectiveMarkers(state, sx, sy) {
    const targets = state.area.keys.filter((item) => !item.collected && !item.hidden);
    const pendingNode = (state.area.mechanicNodes || []).find((node) => !state.nodesActivated.has(node.id));
    const pendingKeeper = state.area.enemies.find((enemy) => enemy.gateKeeper && enemy.alive);
    if (state.collected >= state.area.required && pendingNode) targets.push({ x: pendingNode.x, y: pendingNode.y - 70, landmark: true });
    else if (state.collected >= state.area.required && pendingKeeper) targets.push({ x: pendingKeeper.x, y: pendingKeeper.y - 70, danger: true });
    else if (state.collected >= state.area.required) targets.push({ x: state.area.portal.x, y: state.area.portal.y - 80, portal: true });
    const margin = 28; const safeTop = 52; const safeBottom = height - 34;
    targets.slice(0, 3).forEach((target) => {
      const rawX = sx(target.x); const rawY = sy(target.y);
      if (rawX > margin && rawX < width - margin && rawY > safeTop && rawY < safeBottom) return;
      const x = Math.max(margin, Math.min(width - margin, rawX));
      const y = Math.max(safeTop, Math.min(safeBottom, rawY));
      const angle = Math.atan2(rawY - y, rawX - x);
      ctx.save(); ctx.translate(x, y); ctx.rotate(angle + Math.PI / 4);
      ctx.fillStyle = target.portal ? "#4de9dc" : target.landmark ? "#f36bd8" : target.danger ? "#ff557d" : "#ffd262"; ctx.strokeStyle = "#07091c"; ctx.lineWidth = 3;
      ctx.fillRect(-8, -8, 16, 16); ctx.strokeRect(-8, -8, 16, 16); ctx.restore();
    });
  }

  function drawObjects(state, sx, sy, scale) {
    const { area, clock } = state; const puzzle = library.sheets.puzzle; const feedback = library.sheets.feedback;
    const portalFrame = library.sheets.world.animations.portal_loop[Math.floor(clock * 8) % 5];
    const portalOpen = state.collected >= area.required && (!area.mechanism || state.mechanismActive)
      && state.nodesActivated.size >= (area.nodesRequired || 0) && !area.enemies.some((enemy) => enemy.gateKeeper && enemy.alive);
    drawAnchored(ctx, library.sheets.world, portalFrame, sx(area.portal.x), sy(area.portal.y), 190 * scale, 1, portalOpen ? 1 : 0.34);

    area.keys.forEach((item) => {
      if (item.collected || item.hidden) return;
      const glow = feedback.animations.key_glow[Math.floor(clock * 8) % 5];
      drawFrameInBox(ctx, feedback, glow, sx(item.x - 38), sy(item.y - 44 + Math.sin(clock * 3 + item.x) * 4), 76 * scale, 76 * scale, .45);
      drawFrameInBox(ctx, puzzle, puzzle.frames[item.sprite], sx(item.x - 24), sy(item.y - 30 + Math.sin(clock * 3 + item.x) * 4), 48 * scale, 54 * scale);
    });
    (area.mushrooms || []).forEach((mushroom) => drawFrameInBox(ctx, puzzle, puzzle.frames[mushroom.sprite], sx(mushroom.x - 34), sy(mushroom.y - 66), 68 * scale, 68 * scale));
    (area.levers || []).forEach((lever) => drawFrameInBox(ctx, puzzle, puzzle.frames.wood_lever, sx(lever.x - 25), sy(lever.y - 55), 50 * scale, 62 * scale, state.activated.has(lever.id) ? .65 : 1));
    (area.vines || []).forEach((vine) => {
      const frame = feedback.animations.vine_sway[Math.floor(clock * 7 + vine.x) % 5];
      drawAnchored(ctx, feedback, frame, sx(vine.x), sy(vine.y + 190), 210 * scale);
    });
    (area.teleporters || []).forEach((teleporter, index) => {
      const radius = (26 + Math.sin(clock * 4 + index) * 4) * scale;
      ctx.save(); ctx.globalCompositeOperation = "lighter"; ctx.strokeStyle = "rgba(181,102,255,.82)"; ctx.lineWidth = 5 * scale;
      ctx.beginPath(); ctx.arc(sx(teleporter.x), sy(teleporter.y - 35), radius, 0, Math.PI * 2); ctx.stroke(); ctx.restore();
    });
    (area.mechanicNodes || []).forEach((node) => {
      const active = state.nodesActivated.has(node.id);
      const landmarkSheet = library.sheets[node.sheet || "landmarks"];
      const frame = landmarkSheet.frames[node.sprite];
      if (!active) {
        ctx.save(); ctx.globalCompositeOperation = "lighter";
        const glow = ctx.createRadialGradient(sx(node.x), sy(node.y - 45), 4, sx(node.x), sy(node.y - 45), 70 * scale);
        glow.addColorStop(0, "rgba(244,98,221,.35)"); glow.addColorStop(1, "rgba(244,98,221,0)");
        ctx.fillStyle = glow; ctx.fillRect(sx(node.x - 75), sy(node.y - 120), 150 * scale, 150 * scale); ctx.restore();
      }
      drawFrameInBox(ctx, landmarkSheet, frame, sx(node.x - 48), sy(node.y - 112), 96 * scale, 112 * scale, active ? .62 : 1);
    });
    if (area.heat) drawFrameInBox(ctx, puzzle, puzzle.frames.volcanic_rock, sx(area.heat.x - 40), sy(area.heat.y - 60), 80 * scale, 74 * scale);
    if (area.spring) drawFrameInBox(ctx, puzzle, puzzle.frames.purity_spring, sx(area.spring.x - 45), sy(area.spring.y - 60), 90 * scale, 72 * scale);
    if (area.mechanism) {
      const frame = library.sheets.world.animations.gear_loop[Math.floor(clock * 8) % 5];
      drawFrameInBox(ctx, library.sheets.world, frame, sx(area.mechanism.x - 50), sy(area.mechanism.y - 95), 100 * scale, 100 * scale, state.mechanismActive ? 1 : .55);
    }
    (area.digSpots || []).forEach((spot) => {
      if (state.activated.has(spot.id)) return;
      ctx.strokeStyle = "#d3915d"; ctx.lineWidth = 3 * scale;
      ctx.beginPath(); ctx.moveTo(sx(spot.x - 30), sy(spot.y - 2)); ctx.lineTo(sx(spot.x), sy(spot.y - 15)); ctx.lineTo(sx(spot.x + 30), sy(spot.y - 2)); ctx.stroke();
    });
    area.emblems.forEach((emblem, index) => {
      if (emblem.collected) return;
      ctx.save(); ctx.translate(sx(emblem.x), sy(emblem.y)); ctx.rotate(clock * 1.2 + index); ctx.fillStyle = "#8cff7a";
      ctx.beginPath(); ctx.moveTo(0, -11 * scale); ctx.quadraticCurveTo(11 * scale, -3 * scale, 0, 12 * scale); ctx.quadraticCurveTo(-11 * scale, -3 * scale, 0, -11 * scale); ctx.fill(); ctx.restore();
    });
  }

  function drawEnemies(state, sx, sy, scale) {
    state.area.enemies.forEach((enemy) => {
      const sheet = library.sheets[ENEMY_SHEET[enemy.type]]; const frame = sheet.frames[`${enemy.type}_${enemy.state || "patrol"}`] || sheet.frames[`${enemy.type}_patrol`];
      const alpha = enemy.alive ? 1 : Math.max(0, enemy.defeatTime || 0);
      drawAnchored(ctx, sheet, frame, sx(enemy.x), sy(enemy.y + (enemy.flying ? Math.sin(state.clock * 3 + enemy.x) * 8 : 0)), (enemy.type === "guardian" ? 130 : 74) * scale, enemy.dir || -1, alpha);
      if (enemy.state === "telegraph" && enemy.alive) {
        ctx.strokeStyle = "#ff4f7d"; ctx.lineWidth = 3 * scale; ctx.beginPath(); ctx.arc(sx(enemy.x), sy(enemy.y - 45), 18 * scale, 0, Math.PI * 2); ctx.stroke();
      }
    });
  }

  function drawPlayer(state, sx, sy, scale) {
    const { player, clock } = state;
    let sheet = library.sheets.movement; let frames = sheet.animations[player.animation] || sheet.animations.idle;
    const customSkin = player.skinId > 0 ? library.sheets[`skin${String(player.skinId).padStart(2, "0")}`] : null;
    if (customSkin) {
      sheet = customSkin;
      const mapped = player.animation === "climb" ? "climb" : player.animation === "glide" || player.animation === "jump" ? "glide" : ["tail_attack", "dig", "swing", "hurt"].includes(player.animation) ? "attack" : "run";
      frames = sheet.animations[mapped];
      if (player.skinId === 7 && mapped === "attack" && library.sheets.stormAttack) {
        sheet = library.sheets.stormAttack;
        frames = [1, 2, 3, 4, 5].map((index) => sheet.frames[`attack_${index}`]);
      }
      if (player.animation === "idle" || player.animation === "carry" || player.animation === "win") frames = [frames[0]];
    } else {
      if (library.sheets.action.animations[player.animation]) { sheet = library.sheets.action; frames = sheet.animations[player.animation]; }
      if (library.sheets.status.animations[player.animation]) { sheet = library.sheets.status; frames = sheet.animations[player.animation]; }
    }
    const frame = frames[Math.floor(clock * (player.animation === "run" ? 13 : 9)) % frames.length];
    const blink = player.invincible > 0 && Math.floor(player.invincible * 16) % 2 === 0 ? .35 : 1;
    drawAnchored(ctx, sheet, frame, sx(player.x), sy(player.y), (player.animation === "glide" ? 86 : 82) * scale, player.facing, blink);
  }

  function drawParticles(state, sx, sy, scale) {
    state.particles.forEach((particle) => {
      ctx.globalAlpha = Math.max(0, particle.life / particle.maxLife); ctx.fillStyle = particle.color;
      const size = particle.size * scale * Math.max(.3, particle.life / particle.maxLife);
      ctx.fillRect(sx(particle.x) - size / 2, sy(particle.y) - size / 2, size, size);
    });
    ctx.globalAlpha = 1;
  }

  return { render, resize, destroy() { observer.disconnect(); } };
}
