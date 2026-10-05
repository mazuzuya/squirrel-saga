const SHEETS = {
  movement: ["LUMA_MOVEMENT_SHEET", "/generated-assets/luma_movement_sheet-transparent.frames.json"],
  action: ["LUMA_ACTION_SHEET", "/generated-assets/luma_action_sheet-transparent.frames.json"],
  status: ["LUMA_STATUS_SHEET", "/generated-assets/luma_status_sheet-transparent.frames.json"],
  woodland: ["ENEMIES_WOODLAND_SHEET", "/generated-assets/enemies_woodland_sheet-transparent.frames.json"],
  elemental: ["ENEMIES_ELEMENTAL_SHEET", "/generated-assets/enemies_elemental_sheet-transparent.frames.json"],
  final: ["ENEMIES_FINAL_SHEET", "/generated-assets/enemies_final_sheet-transparent.frames.json"],
  puzzle: ["PUZZLE_ATLAS", "/generated-assets/puzzle_atlas-transparent.frames.json"],
  world: ["WORLD_EFFECTS_SHEET", "/generated-assets/world_effects_sheet-transparent.frames.json"],
  feedback: ["FEEDBACK_EFFECTS_SHEET", "/generated-assets/feedback_effects_sheet-transparent.frames.json"],
  forestTiles: ["FOREST_PLATFORM_TILES", "/generated-assets/forest_platform_tiles-transparent.frames.json"],
  cavernTiles: ["CAVERN_PLATFORM_TILES", "/generated-assets/cavern_platform_tiles-transparent.frames.json"],
  coreTiles: ["CORE_PLATFORM_TILES", "/generated-assets/core_platform_tiles-transparent.frames.json"],
  newForest: ["ENEMIES_NEW_FOREST_SHEET", "/generated-assets/enemies_new_forest_sheet-transparent.frames.json"],
  newArcane: ["ENEMIES_NEW_ARCANE_SHEET", "/generated-assets/enemies_new_arcane_sheet-transparent.frames.json"],
  newWeird: ["ENEMIES_NEW_WEIRD_SHEET", "/generated-assets/enemies_new_weird_sheet-transparent.frames.json"],
  landmarks: ["AREA_LANDMARK_ATLAS", "/generated-assets/area_landmark_atlas-transparent.frames.json"],
  stormAttack: ["SKIN_07_ATTACK_SHEET", "/generated-assets/skin_07_attack_sheet-transparent.frames.json"],
  chapter3A: ["ENEMIES_CH3_A_SHEET", "/generated-assets/enemies_ch3_a_sheet-transparent.frames.json"],
  chapter3B: ["ENEMIES_CH3_B_SHEET", "/generated-assets/enemies_ch3_b_sheet-transparent.frames.json"],
  landmarks2: ["AREA_LANDMARK_ATLAS_2", "/generated-assets/area_landmark_atlas_2-transparent.frames.json"],
};

for (let index = 1; index <= 20; index += 1) {
  const number = String(index).padStart(2, "0");
  SHEETS[`skin${number}`] = [`SKIN_${number}_SHEET`, `/generated-assets/skin_${number}_sheet-transparent.frames.json`];
}

function loadImage(url) {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.decoding = "async";
    image.onload = () => resolve(image);
    image.onerror = () => reject(new Error(`Gagal memuat ${url}`));
    image.src = url;
  });
}

function assetUrl(assets, key, fallback) {
  try { return assets?.get(key) || fallback; } catch { return fallback; }
}

export async function loadGameAssets(assets) {
  const result = { sheets: {}, backdrops: {}, climbTrees: {} };
  await Promise.all(Object.entries(SHEETS).map(async ([name, [key, framesUrl]]) => {
    try {
      const [image, data] = await Promise.all([
        loadImage(assetUrl(assets, key, framesUrl.replace(".frames.json", ".webp"))),
        fetch(framesUrl).then((response) => {
          if (!response.ok) throw new Error(`Gagal memuat data ${name}`);
          return response.json();
        }),
      ]);
      // Generated content bounds may extend outside a grid cell; preserving
      // them is what keeps wings, tails, and attack poses from being cropped.
      const normalize = (frame) => frame;
      const frames = Object.fromEntries(data.frames.map((frame) => [frame.name, normalize(frame)]));
      const animations = Object.fromEntries((data.animations || []).map((animation) => [animation.name, animation.frames.map(normalize)]));
      result.sheets[name] = { image, data, frames, animations };
    } catch (error) {
      // Optional skins never prevent the base game from reaching play.
      if (!name.startsWith("skin")) throw error;
    }
  }));

  await Promise.all([
    ["FOREST_BACKDROP", "forest"], ["CAVERN_BACKDROP", "cavern"], ["CORE_BACKDROP", "core"],
  ].map(async ([key, name]) => {
    result.backdrops[name] = await loadImage(assetUrl(assets, key, `/generated-assets/${name}_backdrop.webp`));
  }));
  await Promise.all(Array.from({ length: 30 }, (_, index) => {
    const number = String(index + 1).padStart(2, "0");
    const key = `CLIMB_TREE_${number}`;
    return loadImage(assetUrl(assets, key, `/generated-assets/climb_tree_${number}-transparent.webp`))
      .then((image) => { result.climbTrees[key] = image; })
      .catch(() => {});
  }));
  return result;
}

export function getAnimation(library, name) {
  for (const sheet of Object.values(library.sheets)) {
    if (sheet.animations[name]) return { sheet, frames: sheet.animations[name] };
  }
  return null;
}
