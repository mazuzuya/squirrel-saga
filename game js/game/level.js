const p = (x, y, w, h = 46, kind = "normal") => ({ x, y, w, h, kind });
const key = (id, sprite, x, y, extra = {}) => ({ id, sprite, x, y, collected: false, ...extra });
const enemy = (type, x, y, extra = {}) => ({ type, x, y, originX: x, alive: true, hp: type === "guardian" ? 4 : 1, ...extra });

export const AREAS = [
  {
    name: "Oak Canopy",
    mechanic: "Dasar Melayang",
    tip: "Tahan LOMPAT di udara untuk membuka patagium.",
    backdrop: "FOREST_BACKDROP",
    tiles: "FOREST_PLATFORM_TILES",
    colors: ["#081329", "#173b45", "#57d47f", "#ffd36a"],
    spawn: { x: 110, y: 610 }, portal: { x: 2010, y: 470 }, required: 2,
    platforms: [p(0, 680, 520, 90), p(610, 610, 330), p(1030, 520, 360), p(1490, 590, 300), p(1880, 520, 310)],
    keys: [key("segitiga", "triangle_walnut", 785, 545), key("bulat", "round_walnut", 1210, 455)],
    enemies: [enemy("beetle", 390, 680), enemy("beetle", 1580, 590)],
    emblems: [{ x: 930, y: 430 }, { x: 1430, y: 395 }, { x: 2120, y: 390 }],
  },
  {
    name: "Whispering Pines",
    mechanic: "Panjat & Stamina",
    tip: "Tahan AKSI di batang bercahaya untuk memanjat.",
    backdrop: "FOREST_BACKDROP", tiles: "FOREST_PLATFORM_TILES",
    colors: ["#071a26", "#174635", "#7ad45c", "#efc56f"],
    spawn: { x: 100, y: 610 }, portal: { x: 2020, y: 300 }, required: 2,
    platforms: [p(0, 680, 430, 90), p(500, 560, 250), p(830, 430, 250), p(1160, 650, 300), p(1510, 480, 260), p(1860, 350, 360)],
    climbZones: [{ x: 415, y: 330, w: 95, h: 350 }, { x: 1440, y: 310, w: 85, h: 340 }, { x: 1780, y: 205, w: 90, h: 360 }],
    keys: [key("akar", "tier_key_a", 255, 610), key("puncak", "tier_key_b", 1660, 415)],
    enemies: [enemy("woodpecker", 690, 560), enemy("woodpecker", 1330, 650)],
    emblems: [{ x: 600, y: 430 }, { x: 1280, y: 565 }, { x: 2110, y: 220 }],
  },
  {
    name: "Wind Draft Canyon",
    mechanic: "Arus Angin",
    tip: "Melayang di atas arus untuk terangkat; kunci batu terlalu berat.",
    backdrop: "FOREST_BACKDROP", tiles: "FOREST_PLATFORM_TILES",
    colors: ["#0b1631", "#245477", "#71e6e1", "#e0c17b"],
    spawn: { x: 100, y: 610 }, portal: { x: 2050, y: 400 }, required: 1,
    platforms: [p(0, 680, 370, 90), p(570, 570, 270), p(1030, 400, 260), p(1470, 590, 280), p(1900, 450, 350)],
    updrafts: [{ x: 370, y: 350, w: 200, h: 380 }, { x: 840, y: 220, w: 190, h: 500 }, { x: 1750, y: 260, w: 150, h: 450 }],
    keys: [key("batu", "stone_acorn", 1160, 335, { heavy: true })],
    enemies: [enemy("hawk", 710, 440, { flying: true }), enemy("hawk", 1600, 390, { flying: true })],
    emblems: [{ x: 470, y: 310 }, { x: 935, y: 180 }, { x: 1815, y: 230 }],
  },
  {
    name: "Underground Roots",
    mechanic: "Menggali",
    tip: "Cari tanah retak lalu tekan AKSI untuk menggali.",
    backdrop: "CAVERN_BACKDROP", tiles: "CAVERN_PLATFORM_TILES",
    colors: ["#100d25", "#392552", "#4de0b2", "#d3915d"],
    spawn: { x: 100, y: 610 }, portal: { x: 2040, y: 500 }, required: 2,
    platforms: [p(0, 680, 530, 90), p(610, 590, 330), p(1010, 680, 380), p(1470, 540, 300), p(1850, 550, 390)],
    digSpots: [{ id: "kiri", x: 750, y: 590 }, { id: "kanan", x: 1210, y: 680 }],
    keys: [key("kiri", "left_key_half", 750, 525, { hidden: true }), key("kanan", "right_key_half", 1210, 615, { hidden: true })],
    enemies: [enemy("mole", 420, 680), enemy("mole", 1580, 540)],
    emblems: [{ x: 865, y: 500 }, { x: 1320, y: 580 }, { x: 1760, y: 410 }],
  },
  {
    name: "Bioluminescent Cavern",
    mechanic: "Jamur Membal",
    tip: "Pantulkan jamur MERAH → BIRU → HIJAU.",
    backdrop: "CAVERN_BACKDROP", tiles: "CAVERN_PLATFORM_TILES",
    colors: ["#09081f", "#36235d", "#45e8ff", "#ff5d86"],
    spawn: { x: 100, y: 610 }, portal: { x: 2030, y: 440 }, required: 1, sequence: ["red", "blue", "green"],
    platforms: [p(0, 680, 430, 90), p(600, 560, 240), p(1020, 430, 250), p(1420, 590, 250), p(1850, 490, 390)],
    mushrooms: [{ color: "red", sprite: "red_mushroom", x: 480, y: 680 }, { color: "blue", sprite: "blue_mushroom", x: 920, y: 680 }, { color: "green", sprite: "green_mushroom", x: 1320, y: 680 }],
    keys: [key("warna", "wind_key", 1560, 515, { hidden: true })],
    enemies: [enemy("snail", 720, 560), enemy("snail", 1970, 490)],
    emblems: [{ x: 720, y: 470 }, { x: 1135, y: 340 }, { x: 1740, y: 410 }],
  },
  {
    name: "Waterfall Canopy",
    mechanic: "Daun Rakit & Tuas",
    tip: "Aktifkan dua tuas agar arus membawa kunci.",
    backdrop: "FOREST_BACKDROP", tiles: "FOREST_PLATFORM_TILES",
    colors: ["#07192c", "#185970", "#4ed7c2", "#ffd470"],
    spawn: { x: 100, y: 610 }, portal: { x: 2040, y: 420 }, required: 1,
    platforms: [p(0, 680, 390, 90), p(570, 550, 260), p(1050, 650, 260), p(1510, 520, 250), p(1900, 470, 340)],
    movingPlatforms: [{ x: 390, y: 650, w: 150, h: 24, range: 180, speed: 0.8 }, { x: 1320, y: 610, w: 160, h: 24, range: 160, speed: 1.1 }],
    levers: [{ id: "barat", x: 690, y: 495 }, { id: "timur", x: 1620, y: 465 }],
    keys: [key("air", "round_walnut", 1780, 395, { hidden: true })],
    enemies: [enemy("frog", 1130, 650), enemy("frog", 2000, 470)],
    emblems: [{ x: 470, y: 560 }, { x: 1180, y: 520 }, { x: 1810, y: 340 }],
  },
  {
    name: "Frosty Peaks",
    mechanic: "Es & Angin Kencang",
    tip: "Bawa kunci beku ke batu panas; permukaan es sangat licin.",
    backdrop: "CORE_BACKDROP", tiles: "CORE_PLATFORM_TILES",
    colors: ["#071427", "#1d4d6b", "#9cecff", "#ff975e"],
    spawn: { x: 100, y: 610 }, portal: { x: 2040, y: 420 }, required: 1,
    platforms: [p(0, 680, 460, 90, "ice"), p(590, 570, 350, 46, "ice"), p(1050, 450, 270, 46, "ice"), p(1440, 610, 300, 46, "ice"), p(1880, 470, 360, 60)],
    windZones: [{ x: 500, y: 260, w: 390, h: 420, force: -90 }, { x: 1360, y: 280, w: 420, h: 420, force: 110 }],
    heat: { x: 1570, y: 540 }, keys: [key("beku", "frozen_key", 1170, 380, { frozen: true })],
    enemies: [enemy("owl", 760, 420, { flying: true }), enemy("owl", 1640, 460, { flying: true })],
    emblems: [{ x: 515, y: 480 }, { x: 1270, y: 330 }, { x: 1810, y: 370 }],
  },
  {
    name: "Clockwork Hollow",
    mechanic: "Gear & Timing",
    tip: "Pasang gear dengan AKSI, lalu lewati mesin saat sejajar.",
    backdrop: "CORE_BACKDROP", tiles: "CORE_PLATFORM_TILES",
    colors: ["#100d20", "#4c3427", "#42d8db", "#e8ad55"],
    spawn: { x: 100, y: 610 }, portal: { x: 2050, y: 360 }, required: 1,
    platforms: [p(0, 680, 400, 90), p(530, 540, 250), p(940, 650, 250), p(1350, 470, 270), p(1830, 410, 410)],
    movingPlatforms: [{ x: 390, y: 610, w: 120, h: 24, range: 140, speed: 1.5, vertical: true }, { x: 1220, y: 570, w: 120, h: 24, range: 130, speed: 1.8, vertical: true }],
    mechanism: { x: 1510, y: 405 }, keys: [key("gear", "gear_key", 1060, 585, { gear: true })],
    enemies: [enemy("clockbeetle", 650, 540), enemy("clockbeetle", 1940, 410)],
    emblems: [{ x: 455, y: 460 }, { x: 1280, y: 390 }, { x: 1720, y: 310 }],
  },
  {
    name: "Toxic Swampland",
    mechanic: "Ayun Sulur",
    tip: "AKSI di dekat sulur untuk mengayun; sucikan kunci di mata air.",
    backdrop: "CAVERN_BACKDROP", tiles: "CAVERN_PLATFORM_TILES",
    colors: ["#0c1021", "#314426", "#9ddc44", "#f15bb5"],
    spawn: { x: 100, y: 610 }, portal: { x: 2050, y: 410 }, required: 1,
    platforms: [p(0, 680, 320, 90), p(520, 570, 230), p(940, 660, 240), p(1390, 540, 260), p(1870, 460, 370)],
    hazards: [{ x: 320, y: 690, w: 200, h: 180 }, { x: 750, y: 690, w: 190, h: 180 }, { x: 1180, y: 690, w: 210, h: 180 }, { x: 1650, y: 690, w: 220, h: 180 }],
    vines: [{ x: 420, y: 350 }, { x: 835, y: 315 }, { x: 1280, y: 340 }, { x: 1760, y: 280 }],
    spring: { x: 1510, y: 475 }, keys: [key("racun", "toxic_key", 1070, 595, { toxic: true })],
    enemies: [enemy("mosquito", 670, 420, { flying: true }), enemy("mosquito", 1580, 360, { flying: true })],
    emblems: [{ x: 430, y: 310 }, { x: 1260, y: 300 }, { x: 1770, y: 245 }],
  },
  {
    name: "Grand Yggdrasil Core",
    mechanic: "Empat Elemen",
    tip: "Kumpulkan empat kunci sebelum waktu habis.",
    backdrop: "CORE_BACKDROP", tiles: "CORE_PLATFORM_TILES",
    colors: ["#09091d", "#412b4e", "#4de9dc", "#ff9c50"],
    spawn: { x: 100, y: 610 }, portal: { x: 2110, y: 350 }, required: 4, timeLimit: 95,
    platforms: [p(0, 680, 360, 90), p(500, 560, 250), p(870, 420, 240), p(1230, 640, 250), p(1580, 500, 260), p(1980, 400, 320)],
    climbZones: [{ x: 360, y: 300, w: 95, h: 380 }],
    updrafts: [{ x: 750, y: 210, w: 120, h: 500 }],
    digSpots: [{ id: "api", x: 1360, y: 640 }],
    vines: [{ x: 1510, y: 300 }],
    keys: [key("angin", "wind_key", 980, 350), key("es", "ice_key", 620, 495), key("akar", "root_key", 1710, 435), key("api", "fire_key", 1360, 575, { hidden: true })],
    enemies: [enemy("guardian", 1840, 500)],
    emblems: [{ x: 780, y: 170 }, { x: 1510, y: 260 }, { x: 2240, y: 290 }],
  },
];

// Each area opens into three navigable bands: roots below, the original route,
// and a high canopy route. Generated climb structures connect those bands.
const EXPANSIONS = [
  {
    portal: { x: 3540, y: 280 }, required: 4, climbArt: { key: "CLIMB_TREE_01", x: 2310, y: 120, w: 360, h: 1110 },
    platforms: [p(2180, 730, 300), p(2240, 1180, 430, 70), p(2380, 930, 380), p(2320, 680, 420), p(2450, 430, 360), p(2780, 390, 300), p(3120, 330, 300), p(3400, 330, 350)],
    climbZones: [{ x: 2440, y: 170, w: 92, h: 1030, art: true }],
    keys: [key("akar-rahasia", "tier_key_a", 2460, 1110), key("mahkota-ek", "wind_key", 3240, 260)],
    enemies: [enemy("beetle", 2290, 730), enemy("beetle", 2500, 1180), enemy("woodpecker", 2490, 930), enemy("hawk", 2680, 560, { flying: true }), enemy("beetle", 2910, 390), enemy("hawk", 3300, 230, { flying: true })],
    movingPlatforms: [{ x: 2740, y: 650, w: 135, h: 24, range: 180, speed: 1.15, vertical: true }],
  },
  {
    portal: { x: 3540, y: 220 }, required: 4, climbArt: { key: "CLIMB_TREE_02", x: 2350, y: 90, w: 330, h: 1200 },
    platforms: [p(2180, 620, 260), p(2240, 1240, 390), p(2370, 1010, 340), p(2320, 770, 400), p(2440, 530, 330), p(2510, 300, 300), p(2850, 440, 260), p(3170, 270, 250), p(3410, 270, 360)],
    climbZones: [{ x: 2450, y: 130, w: 82, h: 1130, art: true }, { x: 3090, y: 260, w: 82, h: 650 }],
    keys: [key("resin-bawah", "tier_key_a", 2470, 1170), key("jarum-langit", "tier_key_b", 3290, 200)],
    enemies: [enemy("woodpecker", 2280, 620), enemy("beetle", 2440, 1240), enemy("woodpecker", 2520, 1010), enemy("woodpecker", 2550, 770), enemy("hawk", 2900, 330, { flying: true }), enemy("woodpecker", 3490, 270)],
    movingPlatforms: [{ x: 2800, y: 760, w: 130, h: 24, range: 230, speed: 1.05, vertical: true }],
  },
  {
    portal: { x: 3540, y: 300 }, required: 3, climbArt: { key: "CLIMB_TREE_03", x: 2280, y: 130, w: 410, h: 1080 },
    platforms: [p(2180, 760, 280), p(2260, 1210, 370), p(2380, 940, 330), p(2390, 690, 330), p(2470, 450, 300), p(2820, 390, 250), p(3150, 350, 270), p(3400, 350, 360)],
    climbZones: [{ x: 2440, y: 190, w: 95, h: 1010, art: true }],
    updrafts: [{ x: 2680, y: 300, w: 170, h: 920 }, { x: 3040, y: 190, w: 120, h: 630 }],
    keys: [key("pusaran-bawah", "round_walnut", 2440, 1140), key("bulu-angin", "wind_key", 3260, 280)],
    enemies: [enemy("hawk", 2320, 630, { flying: true }), enemy("beetle", 2440, 1210), enemy("hawk", 2550, 820, { flying: true }), enemy("hawk", 2760, 470, { flying: true }), enemy("hawk", 3050, 280, { flying: true }), enemy("beetle", 3490, 350)],
  },
  {
    portal: { x: 3540, y: 1310 }, required: 4, climbArt: { key: "CLIMB_TREE_04", x: 2330, y: 350, w: 350, h: 1020 },
    platforms: [p(2200, 780, 300), p(2180, 1030, 330), p(2280, 1330, 430), p(2430, 1090, 350), p(2380, 830, 390), p(2510, 580, 300), p(2860, 760, 290), p(3200, 1010, 270), p(3400, 1360, 380)],
    climbZones: [{ x: 2450, y: 400, w: 88, h: 950, art: true }],
    digSpots: [{ id: "fosil-bawah", x: 2460, y: 1330 }, { id: "getah-tua", x: 3310, y: 1010 }],
    keys: [key("fosil-bawah", "triangle_walnut", 2460, 1260, { hidden: true }), key("getah-tua", "root_key", 3310, 940, { hidden: true })],
    enemies: [enemy("mole", 2280, 780), enemy("mole", 2360, 1030), enemy("mole", 2520, 1330), enemy("snail", 2540, 1090), enemy("mole", 2940, 760), enemy("snail", 3470, 1360)],
  },
  {
    portal: { x: 3540, y: 250 }, required: 3, climbArt: { key: "CLIMB_TREE_05", x: 2310, y: 100, w: 350, h: 1180 },
    platforms: [p(2180, 730, 280), p(2220, 1250, 410), p(2380, 1030, 330), p(2320, 790, 390), p(2450, 560, 350), p(2520, 330, 290), p(2870, 470, 250), p(3190, 300, 260), p(3400, 300, 370)],
    climbZones: [{ x: 2430, y: 140, w: 90, h: 1110, art: true }],
    mushrooms: [{ color: "red", sprite: "red_mushroom", x: 2720, y: 1250 }, { color: "blue", sprite: "blue_mushroom", x: 2960, y: 1050 }, { color: "green", sprite: "green_mushroom", x: 3160, y: 790 }],
    keys: [key("spora-dalam", "root_key", 2450, 1180), key("cahaya-puncak", "fire_key", 3300, 230)],
    enemies: [enemy("snail", 2280, 730), enemy("snail", 2450, 1250), enemy("snail", 2490, 1030), enemy("mosquito", 2720, 650, { flying: true }), enemy("snail", 2940, 470), enemy("mosquito", 3300, 210, { flying: true })],
  },
  {
    portal: { x: 3540, y: 360 }, required: 3, climbArt: { key: "CLIMB_TREE_06", x: 2330, y: 120, w: 380, h: 1130 },
    platforms: [p(2180, 720, 270), p(2220, 1210, 390), p(2390, 970, 330), p(2340, 730, 410), p(2470, 500, 340), p(2800, 610, 250), p(3130, 430, 270), p(3400, 410, 370)],
    climbZones: [{ x: 2460, y: 170, w: 90, h: 1050, art: true }],
    movingPlatforms: [{ x: 2730, y: 1020, w: 150, h: 24, range: 230, speed: 1.2, vertical: true }, { x: 3070, y: 700, w: 150, h: 24, range: 200, speed: 1.35, vertical: true }],
    updrafts: [{ x: 2920, y: 350, w: 120, h: 760 }],
    keys: [key("daun-dalam", "triangle_walnut", 2440, 1140), key("embun-tinggi", "ice_key", 3240, 360)],
    enemies: [enemy("frog", 2290, 720), enemy("frog", 2460, 1210), enemy("frog", 2520, 970), enemy("woodpecker", 2570, 730), enemy("frog", 2890, 610), enemy("woodpecker", 3480, 410)],
  },
  {
    portal: { x: 3540, y: 260 }, required: 3, climbArt: { key: "CLIMB_TREE_07", x: 2320, y: 80, w: 370, h: 1190 },
    platforms: [p(2180, 700, 300, 46, "ice"), p(2220, 1240, 400, 46, "ice"), p(2380, 990, 350, 46, "ice"), p(2350, 740, 390, 46, "ice"), p(2460, 500, 330, 46, "ice"), p(2820, 420, 270, 46, "ice"), p(3140, 310, 270, 46, "ice"), p(3400, 310, 370, 60)],
    climbZones: [{ x: 2460, y: 120, w: 88, h: 1110, art: true }],
    windZones: [{ x: 2680, y: 250, w: 430, h: 930, force: -145 }, { x: 3100, y: 170, w: 420, h: 780, force: 160 }],
    keys: [key("bara-salju", "fire_key", 2470, 1170), key("mahkota-es", "ice_key", 3270, 240)],
    enemies: [enemy("owl", 2290, 590, { flying: true }), enemy("owl", 2490, 1100, { flying: true }), enemy("owl", 2580, 850, { flying: true }), enemy("clockbeetle", 2860, 420), enemy("owl", 3200, 210, { flying: true }), enemy("clockbeetle", 3490, 310)],
  },
  {
    portal: { x: 3540, y: 240 }, required: 3, climbArt: { key: "CLIMB_TREE_08", x: 2300, y: 70, w: 390, h: 1210 },
    platforms: [p(2180, 670, 290), p(2210, 1240, 400), p(2390, 990, 340), p(2330, 740, 410), p(2470, 490, 330), p(2840, 560, 250), p(3160, 320, 260), p(3400, 290, 370)],
    climbZones: [{ x: 2450, y: 120, w: 88, h: 1120, art: true }],
    movingPlatforms: [{ x: 2710, y: 1050, w: 130, h: 24, range: 260, speed: 1.65, vertical: true }, { x: 3070, y: 650, w: 130, h: 24, range: 250, speed: 1.9, vertical: true }, { x: 3300, y: 520, w: 120, h: 24, range: 150, speed: 2.1, vertical: true }],
    keys: [key("gear-bawah", "round_walnut", 2460, 1170), key("gear-langit", "wind_key", 3270, 250)],
    enemies: [enemy("clockbeetle", 2280, 670), enemy("clockbeetle", 2460, 1240), enemy("clockbeetle", 2550, 990), enemy("mosquito", 2790, 660, { flying: true }), enemy("clockbeetle", 2910, 560), enemy("clockbeetle", 3480, 290)],
  },
  {
    portal: { x: 3540, y: 300 }, required: 3, climbArt: { key: "CLIMB_TREE_09", x: 2310, y: 100, w: 390, h: 1160 },
    platforms: [p(2180, 690, 270), p(2200, 1260, 380), p(2380, 1010, 330), p(2340, 760, 380), p(2470, 520, 330), p(2830, 430, 250), p(3160, 360, 270), p(3400, 350, 370)],
    climbZones: [{ x: 2450, y: 150, w: 92, h: 1090, art: true }],
    hazards: [{ x: 2580, y: 1280, w: 300, h: 220 }, { x: 3070, y: 1280, w: 360, h: 220 }],
    vines: [{ x: 2750, y: 300 }, { x: 3030, y: 250 }, { x: 3320, y: 210 }],
    keys: [key("mangrove-bawah", "root_key", 2440, 1190), key("embun-suci", "ice_key", 3270, 290)],
    enemies: [enemy("mosquito", 2270, 560, { flying: true }), enemy("mosquito", 2450, 1130, { flying: true }), enemy("snail", 2520, 1010), enemy("mosquito", 2760, 570, { flying: true }), enemy("mosquito", 3090, 310, { flying: true }), enemy("snail", 3480, 350)],
  },
  {
    portal: { x: 3560, y: 210 }, required: 4, timeLimit: 150, climbArt: { key: "CLIMB_TREE_10", x: 2290, y: 60, w: 420, h: 1250 },
    platforms: [p(2180, 660, 300), p(2200, 1270, 410), p(2380, 1010, 350), p(2320, 760, 420), p(2470, 510, 340), p(2820, 430, 260), p(3160, 300, 280), p(3410, 260, 370)],
    climbZones: [{ x: 2450, y: 100, w: 96, h: 1160, art: true }],
    updrafts: [{ x: 2700, y: 270, w: 120, h: 950 }],
    vines: [{ x: 3000, y: 250 }, { x: 3330, y: 160 }],
    movingPlatforms: [{ x: 2870, y: 900, w: 130, h: 24, range: 260, speed: 1.8, vertical: true }],
    enemies: [enemy("guardian", 2470, 1270), enemy("owl", 2550, 900, { flying: true }), enemy("clockbeetle", 2580, 760), enemy("mosquito", 2850, 570, { flying: true }), enemy("hawk", 3200, 210, { flying: true }), enemy("guardian", 3460, 260)],
  },
];

const arrayFields = ["platforms", "climbZones", "keys", "enemies", "movingPlatforms", "updrafts", "windZones", "digSpots", "mushrooms", "hazards", "vines"];
EXPANSIONS.forEach((expansion, index) => {
  const area = AREAS[index];
  for (const field of arrayFields) if (expansion[field]) area[field] = [...(area[field] || []), ...expansion[field]];
  for (const [field, value] of Object.entries(expansion)) if (!arrayFields.includes(field)) area[field] = value;
  area.worldWidth = 3800; area.worldHeight = 1500;
});

// The four final elemental keys now occupy distinct vertical routes.
Object.assign(AREAS[9].keys[0], { x: 2760, y: 360 });
Object.assign(AREAS[9].keys[1], { x: 2440, y: 1200 });
Object.assign(AREAS[9].keys[2], { x: 3260, y: 230 });
Object.assign(AREAS[9].keys[3], { x: 2950, y: 820, hidden: false });

// Extend the original chapter with a final approach after the old portal site.
const oldAreaEnemy = ["beetle", "woodpecker", "hawk", "mole", "snail", "frog", "owl", "clockbeetle", "mosquito", "guardian"];
AREAS.slice(0, 10).forEach((area, index) => {
  const routeY = Math.max(280, Math.min(1420, area.portal.y + 50));
  area.platforms.push(p(3700, routeY + 120, 300), p(3980, routeY + 20, 300), p(4260, routeY - 70, 420));
  area.enemies.push(
    enemy(oldAreaEnemy[index], 3820, routeY + 120, { flying: ["hawk", "owl", "mosquito"].includes(oldAreaEnemy[index]) }),
    enemy(index % 2 ? "hawk" : "clockbeetle", 4140, routeY - 40, { flying: index % 2 === 1 }),
  );
  if (index < 9) {
    area.keys.push(key(`ujian-${index}`, index % 2 ? "fire_key" : "wind_key", 4140, routeY - 50));
    area.required += 1;
  }
  area.portal = { x: 4490, y: routeY - 120 };
  area.worldWidth = 4700; area.worldHeight = 1800;
});

const widePlatforms = (variant = "normal") => [
  p(0, 980, 470, 90, variant), p(560, 900, 320, 50, variant), p(970, 820, 300, 50, variant),
  p(1350, 1040, 330, 60, variant), p(1770, 1320, 430, 70, variant), p(1930, 1040, 410, 55, variant),
  p(1940, 760, 400, 55, variant), p(2030, 500, 330, 50, variant), p(2440, 680, 320, 50, variant),
  p(2820, 820, 340, 55, variant), p(3220, 740, 310, 50, variant), p(3590, 660, 300, 50, variant),
  p(3970, 580, 290, 50, variant), p(4310, 500, 390, 70, variant),
];

const crowd = (types) => [
  enemy(types[0], 380, 980), enemy(types[1], 720, 870, { flying: types[1] === "hawk" || types[1] === "owl" || types[1] === "mosquito" }),
  enemy(types[2], 1120, 720, { flying: types[2] === "hawk" || types[2] === "owl" || types[2] === "mosquito" }),
  enemy(types[0], 1510, 1040), enemy(types[1], 1990, 1320, { flying: types[1] === "hawk" || types[1] === "owl" || types[1] === "mosquito" }),
  enemy(types[2], 2180, 760, { flying: types[2] === "hawk" || types[2] === "owl" || types[2] === "mosquito" }),
  enemy(types[0], 2590, 680), enemy(types[1], 3000, 820, { flying: types[1] === "hawk" || types[1] === "owl" || types[1] === "mosquito" }),
  enemy(types[2], 3410, 570, { flying: types[2] === "hawk" || types[2] === "owl" || types[2] === "mosquito" }), enemy(types[0], 4120, 620),
];

AREAS.push(
  {
    name: "Sunken Redwood", mechanic: "Pasang-Surut Kanopi", tip: "Naiki batang saat rakit daun bergerak mengikuti arus.",
    backdrop: "FOREST_BACKDROP", tiles: "FOREST_PLATFORM_TILES", colors: ["#061929", "#16536b", "#42dfbf", "#ffca6a"],
    spawn: { x: 110, y: 980 }, portal: { x: 4510, y: 350 }, required: 4, worldWidth: 4700, worldHeight: 1800,
    platforms: widePlatforms(), climbArt: { key: "CLIMB_TREE_11", x: 1780, y: 210, w: 470, h: 1150 },
    climbZones: [{ x: 1970, y: 250, w: 90, h: 1090, art: true }],
    movingPlatforms: [{ x: 480, y: 1120, w: 150, h: 24, range: 260, speed: .9, vertical: true }, { x: 2690, y: 1120, w: 160, h: 24, range: 280, speed: 1.1, vertical: true }],
    hazards: [{ x: 470, y: 1450, w: 1220, h: 300 }, { x: 2360, y: 1450, w: 1210, h: 300 }],
    keys: [key("karang", "root_key", 760, 800), key("palung", "ice_key", 2030, 1250), key("pasang", "round_walnut", 3020, 850), key("mahkota", "wind_key", 3720, 400)],
    enemies: crowd(["frog", "mosquito", "snail"]), emblems: [{ x: 610, y: 760 }, { x: 2180, y: 420 }, { x: 4050, y: 520 }],
  },
  {
    name: "Tempest Orchard", mechanic: "Petir & Angin Silang", tip: "Lihat kilatan tanah sebelum petir menyambar.",
    backdrop: "FOREST_BACKDROP", tiles: "FOREST_PLATFORM_TILES", colors: ["#090d2b", "#303b76", "#4eeaff", "#ffe06b"],
    spawn: { x: 110, y: 980 }, portal: { x: 4510, y: 350 }, required: 4, worldWidth: 4700, worldHeight: 1800,
    platforms: widePlatforms(), climbArt: { key: "CLIMB_TREE_12", x: 1780, y: 180, w: 500, h: 1190 },
    climbZones: [{ x: 1980, y: 220, w: 92, h: 1120, art: true }],
    updrafts: [{ x: 880, y: 360, w: 120, h: 900 }, { x: 2760, y: 300, w: 120, h: 1050 }],
    windZones: [{ x: 400, y: 300, w: 1100, h: 1150, force: 145 }, { x: 2500, y: 260, w: 1300, h: 1180, force: -165 }],
    lightningZones: [{ x: 620, w: 190 }, { x: 1450, w: 220 }, { x: 2900, w: 230 }, { x: 3920, w: 210 }],
    keys: [key("buah-badai", "wind_key", 1100, 650), key("akar-petir", "root_key", 2010, 1240), key("kilat", "fire_key", 3370, 600), key("awan", "ice_key", 3700, 400)],
    enemies: crowd(["woodpecker", "hawk", "owl"]), emblems: [{ x: 820, y: 600 }, { x: 2200, y: 430 }, { x: 4200, y: 500 }],
  },
  {
    name: "Crystal Hive", mechanic: "Gravitasi Kristal", tip: "Zona kristal membuat lompatan dan glide lebih ringan.",
    backdrop: "CAVERN_BACKDROP", tiles: "CAVERN_PLATFORM_TILES", colors: ["#0b0824", "#472c69", "#74f0ff", "#f2a44f"],
    spawn: { x: 110, y: 980 }, portal: { x: 4510, y: 350 }, required: 4, worldWidth: 4700, worldHeight: 1800,
    platforms: widePlatforms(), climbArt: { key: "CLIMB_TREE_13", x: 1780, y: 190, w: 460, h: 1170 },
    climbZones: [{ x: 1960, y: 230, w: 90, h: 1110, art: true }],
    lowGravityZones: [{ x: 430, y: 280, w: 680, h: 1100 }, { x: 2390, y: 250, w: 820, h: 1180 }],
    mushrooms: [{ color: "blue", sprite: "blue_mushroom", x: 1280, y: 1040 }, { color: "green", sprite: "green_mushroom", x: 3170, y: 920 }],
    keys: [key("madu", "round_walnut", 760, 800), key("sarang", "root_key", 2010, 1240), key("prisma", "ice_key", 3000, 850), key("ratu", "fire_key", 3720, 400)],
    enemies: crowd(["snail", "mosquito", "clockbeetle"]), emblems: [{ x: 600, y: 620 }, { x: 2220, y: 430 }, { x: 4070, y: 520 }],
  },
  {
    name: "Ashen Crown", mechanic: "Panas & Ventilasi Bara", tip: "Berhenti di batu gelap untuk memulihkan stamina dari panas.",
    backdrop: "CORE_BACKDROP", tiles: "CORE_PLATFORM_TILES", colors: ["#16080c", "#5b2b26", "#ff7a43", "#ffd16a"],
    spawn: { x: 110, y: 980 }, portal: { x: 4510, y: 350 }, required: 4, worldWidth: 4700, worldHeight: 1800,
    platforms: widePlatforms(), climbArt: { key: "CLIMB_TREE_14", x: 1760, y: 180, w: 520, h: 1190 },
    climbZones: [{ x: 1980, y: 220, w: 94, h: 1120, art: true }],
    hotZones: [{ x: 470, y: 520, w: 650, h: 850 }, { x: 2520, y: 400, w: 720, h: 1000 }],
    updrafts: [{ x: 1220, y: 500, w: 130, h: 900 }, { x: 3510, y: 250, w: 130, h: 1100 }],
    keys: [key("abu", "root_key", 760, 800), key("bara", "fire_key", 2020, 1240), key("asap", "wind_key", 3000, 850), key("mahkota-api", "fire_key", 3710, 400)],
    enemies: crowd(["clockbeetle", "hawk", "guardian"]), emblems: [{ x: 620, y: 630 }, { x: 2190, y: 430 }, { x: 4050, y: 520 }],
  },
  {
    name: "Moonlit Grove", mechanic: "Bayangan & Akar Pindah", tip: "AKSI pada pusaran ungu untuk berpindah antarakar.",
    backdrop: "CAVERN_BACKDROP", tiles: "CAVERN_PLATFORM_TILES", colors: ["#07081b", "#292452", "#9a77ff", "#d8e4ff"],
    spawn: { x: 110, y: 980 }, portal: { x: 4510, y: 350 }, required: 4, worldWidth: 4700, worldHeight: 1800,
    platforms: widePlatforms(), climbArt: { key: "CLIMB_TREE_15", x: 1770, y: 170, w: 500, h: 1200 },
    climbZones: [{ x: 1970, y: 210, w: 92, h: 1130, art: true }],
    shadowZones: [{ x: 780, y: 350, w: 620, h: 1050 }, { x: 2680, y: 260, w: 650, h: 1180 }],
    teleporters: [{ id: "bulan-a", x: 1040, y: 650, toX: 2860, toY: 850 }, { id: "bulan-b", x: 2860, y: 850, toX: 1040, toY: 650 }],
    keys: [key("rembulan", "ice_key", 760, 800), key("bayang", "root_key", 2020, 1240), key("bintang", "wind_key", 3000, 850), key("fajar", "fire_key", 3710, 400)],
    enemies: crowd(["mosquito", "owl", "mole"]), emblems: [{ x: 600, y: 620 }, { x: 2190, y: 430 }, { x: 4080, y: 520 }],
  },
  {
    name: "Skyroot Archipelago", mechanic: "Pulau Akar Terapung", tip: "Rangkai updraft; satu glide yang salah menjatuhkanmu ke akar bawah.",
    backdrop: "FOREST_BACKDROP", tiles: "FOREST_PLATFORM_TILES", colors: ["#07162d", "#35628b", "#8cecff", "#fff0a0"],
    spawn: { x: 110, y: 980 }, portal: { x: 4510, y: 350 }, required: 4, worldWidth: 4700, worldHeight: 1800,
    platforms: widePlatforms(), climbArt: { key: "CLIMB_TREE_16", x: 1760, y: 160, w: 520, h: 1210 },
    climbZones: [{ x: 1980, y: 200, w: 94, h: 1140, art: true }],
    updrafts: [{ x: 460, y: 300, w: 120, h: 1120 }, { x: 1260, y: 270, w: 120, h: 1160 }, { x: 2780, y: 250, w: 130, h: 1180 }, { x: 3900, y: 210, w: 120, h: 1200 }],
    lowGravityZones: [{ x: 1500, y: 250, w: 1000, h: 1200 }],
    movingPlatforms: [{ x: 760, y: 1120, w: 140, h: 24, range: 260, speed: 1.4, vertical: true }, { x: 3370, y: 900, w: 140, h: 24, range: 300, speed: 1.55, vertical: true }],
    keys: [key("pulau", "root_key", 760, 800), key("awan", "ice_key", 2020, 1240), key("angin", "wind_key", 3000, 850), key("langit", "fire_key", 3710, 400)],
    enemies: crowd(["hawk", "owl", "mosquito"]), emblems: [{ x: 610, y: 620 }, { x: 2210, y: 430 }, { x: 4070, y: 520 }],
  },
  {
    name: "Amber Fossil Deep", mechanic: "Ekskavasi Fosil", tip: "Semua kunci terkubur; cari retakan yang dijaga musuh.",
    backdrop: "CAVERN_BACKDROP", tiles: "CAVERN_PLATFORM_TILES", colors: ["#120c1c", "#54362a", "#ffbf55", "#81e0c0"],
    spawn: { x: 110, y: 980 }, portal: { x: 4510, y: 350 }, required: 4, worldWidth: 4700, worldHeight: 1800,
    platforms: widePlatforms(), climbArt: { key: "CLIMB_TREE_17", x: 1790, y: 190, w: 450, h: 1170 },
    climbZones: [{ x: 1970, y: 230, w: 90, h: 1110, art: true }],
    digSpots: [{ id: "fosil-1", x: 760, y: 870 }, { id: "fosil-2", x: 2020, y: 1320 }, { id: "fosil-3", x: 3000, y: 920 }, { id: "fosil-4", x: 3710, y: 470 }],
    keys: [key("fosil-1", "triangle_walnut", 760, 800, { hidden: true }), key("fosil-2", "root_key", 2020, 1240, { hidden: true }), key("fosil-3", "round_walnut", 3000, 850, { hidden: true }), key("fosil-4", "fire_key", 3710, 400, { hidden: true })],
    crumblePlatforms: [{ x: 2440, y: 680 }, { x: 3590, y: 470 }],
    enemies: crowd(["mole", "snail", "beetle"]), emblems: [{ x: 610, y: 620 }, { x: 2210, y: 430 }, { x: 4070, y: 520 }],
  },
  {
    name: "Chrono Bark", mechanic: "Platform Waktu", tip: "Gear bergerak cepat dan beberapa dahan runtuh setelah diinjak.",
    backdrop: "CORE_BACKDROP", tiles: "CORE_PLATFORM_TILES", colors: ["#0c0b1f", "#493a35", "#43e2de", "#e6b95d"],
    spawn: { x: 110, y: 980 }, portal: { x: 4510, y: 350 }, required: 4, timeLimit: 140, worldWidth: 4700, worldHeight: 1800,
    platforms: widePlatforms(), climbArt: { key: "CLIMB_TREE_18", x: 1750, y: 160, w: 540, h: 1210 },
    climbZones: [{ x: 1980, y: 200, w: 94, h: 1140, art: true }],
    movingPlatforms: [{ x: 480, y: 1160, w: 130, h: 24, range: 300, speed: 2.1, vertical: true }, { x: 2650, y: 1040, w: 130, h: 24, range: 320, speed: 2.35, vertical: true }, { x: 3820, y: 900, w: 130, h: 24, range: 310, speed: 2.6, vertical: true }],
    crumblePlatforms: [{ x: 970, y: 720 }, { x: 2440, y: 680 }, { x: 3220, y: 680 }],
    keys: [key("detik", "gear_key", 760, 800), key("jam", "root_key", 2020, 1240), key("masa", "wind_key", 3000, 850), key("abadi", "fire_key", 3710, 400)],
    enemies: crowd(["clockbeetle", "mosquito", "guardian"]), emblems: [{ x: 610, y: 620 }, { x: 2210, y: 430 }, { x: 4070, y: 520 }],
  },
  {
    name: "Dreamcap Nexus", mechanic: "Portal Jamur", tip: "Jamur dan pusaran ungu mengubah jalurmu—ingat pasangan portal.",
    backdrop: "CAVERN_BACKDROP", tiles: "CAVERN_PLATFORM_TILES", colors: ["#0d0720", "#4e2469", "#50e7ff", "#ff68bf"],
    spawn: { x: 110, y: 980 }, portal: { x: 4510, y: 350 }, required: 4, worldWidth: 4700, worldHeight: 1800,
    platforms: widePlatforms(), climbArt: { key: "CLIMB_TREE_19", x: 1760, y: 150, w: 520, h: 1220 },
    climbZones: [{ x: 1980, y: 190, w: 94, h: 1150, art: true }],
    mushrooms: [{ color: "red", sprite: "red_mushroom", x: 500, y: 980 }, { color: "blue", sprite: "blue_mushroom", x: 1280, y: 1040 }, { color: "green", sprite: "green_mushroom", x: 3180, y: 920 }],
    teleporters: [{ id: "mimpi-a", x: 1080, y: 650, toX: 3010, toY: 850 }, { id: "mimpi-b", x: 3010, y: 850, toX: 1080, toY: 650 }],
    lowGravityZones: [{ x: 1450, y: 260, w: 1050, h: 1180 }],
    keys: [key("mimpi", "ice_key", 760, 800), key("spora", "root_key", 2020, 1240), key("gema", "wind_key", 3000, 850), key("bangun", "fire_key", 3710, 400)],
    enemies: crowd(["snail", "mosquito", "mole"]), emblems: [{ x: 610, y: 620 }, { x: 2210, y: 430 }, { x: 4070, y: 520 }],
  },
  {
    name: "Celestial Crown", mechanic: "Ujian Langit", tip: "Semua mekanik kembali; pilih skin yang cocok sebelum mendaki.",
    backdrop: "CORE_BACKDROP", tiles: "CORE_PLATFORM_TILES", colors: ["#06071a", "#39275d", "#58f0e4", "#ffd569"],
    spawn: { x: 110, y: 980 }, portal: { x: 4510, y: 300 }, required: 5, timeLimit: 190, worldWidth: 4700, worldHeight: 1800,
    platforms: widePlatforms(), climbArt: { key: "CLIMB_TREE_20", x: 1740, y: 120, w: 560, h: 1250 },
    climbZones: [{ x: 1980, y: 160, w: 98, h: 1180, art: true }],
    updrafts: [{ x: 820, y: 260, w: 130, h: 1170 }, { x: 2760, y: 230, w: 130, h: 1200 }],
    windZones: [{ x: 3000, y: 250, w: 900, h: 1180, force: -180 }],
    lowGravityZones: [{ x: 1350, y: 240, w: 1180, h: 1220 }],
    shadowZones: [{ x: 3550, y: 210, w: 700, h: 1220 }],
    movingPlatforms: [{ x: 600, y: 1180, w: 130, h: 24, range: 300, speed: 2, vertical: true }, { x: 3290, y: 980, w: 130, h: 24, range: 330, speed: 2.25, vertical: true }],
    vines: [{ x: 1180, y: 420 }, { x: 3060, y: 280 }, { x: 4050, y: 220 }],
    keys: [key("angin-final", "wind_key", 760, 800), key("es-final", "ice_key", 2020, 1240), key("akar-final", "root_key", 2600, 610), key("api-final", "fire_key", 3370, 610), key("bintang-final", "round_walnut", 4070, 550)],
    enemies: [...crowd(["guardian", "owl", "mosquito"]), enemy("guardian", 4380, 430)], emblems: [{ x: 610, y: 620 }, { x: 2210, y: 430 }, { x: 4070, y: 520 }],
  },
);

// Snap chapter-two objectives and ground enemies to their actual routes so
// every branch remains reachable after tuning the shared open-world spine.
AREAS.slice(10).forEach((area) => {
  area.portal.y = 420;
  area.keys.forEach((item) => {
    const platform = area.platforms.find((entry) => item.x >= entry.x && item.x <= entry.x + entry.w);
    if (platform) item.y = platform.y - 65;
  });
  area.enemies.forEach((foe) => {
    if (foe.flying) return;
    const platform = area.platforms.find((entry) => foe.x >= entry.x && foe.x <= entry.x + entry.w);
    if (platform) foe.y = platform.y;
  });
});

const chapterThree = [
  ["Verdant Colossus", "Benih Raksasa", "CLIMB_TREE_21", "FOREST_BACKDROP", "FOREST_PLATFORM_TILES", ["#061c1a", "#286044", "#7df079", "#ffd66a"], "sunscarab", "thornwolf", "growth"],
  ["Thunder Nest", "Sarang Petir", "CLIMB_TREE_22", "FOREST_BACKDROP", "FOREST_PLATFORM_TILES", ["#090d2b", "#3f4780", "#50e6ff", "#ffe468"], "voidbat", "eclipseowl", "storm"],
  ["Mirrorwood", "Dunia Pantulan", "CLIMB_TREE_23", "CAVERN_BACKDROP", "CAVERN_PLATFORM_TILES", ["#0b0922", "#4d3a68", "#a9efff", "#e889ff"], "prismlion", "moonwraith", "mirror"],
  ["Lava Sap Foundry", "Pabrik Getah Api", "CLIMB_TREE_24", "CORE_BACKDROP", "CORE_PLATFORM_TILES", ["#18080a", "#63332b", "#ff7148", "#ffd26a"], "lavacrab", "gearspider", "lava"],
  ["Abyssal Roots", "Akar Jurang", "CLIMB_TREE_25", "CAVERN_BACKDROP", "CAVERN_PLATFORM_TILES", ["#050615", "#25234e", "#4de2d9", "#f15bb5"], "voidbat", "bogstalker", "abyss"],
  ["Cloud Temple", "Kuil Langit", "CLIMB_TREE_26", "FOREST_BACKDROP", "FOREST_PLATFORM_TILES", ["#07182e", "#4d78a0", "#d9f3ff", "#f2cf68"], "cloudray", "skyjelly", "cloud"],
  ["Prism Orchard", "Kebun Spektrum", "CLIMB_TREE_27", "FOREST_BACKDROP", "FOREST_PLATFORM_TILES", ["#100d2d", "#503b7a", "#58f0e4", "#ff8bd5"], "prismlion", "crystalmite", "prism"],
  ["Bonewood Catacomb", "Katakombe Fosil", "CLIMB_TREE_28", "CAVERN_BACKDROP", "CAVERN_PLATFORM_TILES", ["#100c18", "#4f4037", "#efdcaa", "#e8a950"], "thornwolf", "riverwyrm", "bone"],
  ["Eclipse Canopy", "Kanopi Gerhana", "CLIMB_TREE_29", "CORE_BACKDROP", "CORE_PLATFORM_TILES", ["#070619", "#452850", "#ffd45d", "#aa72ff"], "eclipseowl", "starwraith", "eclipse"],
  ["Heart of Seasons", "Jantung Empat Musim", "CLIMB_TREE_30", "CORE_BACKDROP", "CORE_PLATFORM_TILES", ["#071424", "#3b5c50", "#7de58a", "#ffd166"], "sunscarab", "guardian", "seasons"],
];

chapterThree.forEach((config, chapterIndex) => {
  const [name, mechanic, tree, backdrop, tiles, colors, groundType, airType, kind] = config;
  const area = {
    name, mechanic, tip: "Gunakan seluruh tinggi dunia dan kalahkan penjaga jalur.", backdrop, tiles, colors,
    spawn: { x: 110, y: 980 }, portal: { x: 4510, y: 420 }, required: chapterIndex === 9 ? 5 : 4,
    worldWidth: 4700, worldHeight: 1900, platforms: widePlatforms(),
    climbArt: { key: tree, x: 1740, y: 120, w: 560, h: 1270 }, climbZones: [{ x: 1980, y: 170, w: 98, h: 1190, art: true }],
    keys: [key(`${kind}-1`, "wind_key", 760, 835), key(`${kind}-2`, "root_key", 2020, 1255), key(`${kind}-3`, "ice_key", 3000, 755), key(`${kind}-4`, "fire_key", 3710, 595)],
    enemies: [...crowd([groundType, airType, chapterIndex % 2 ? "starwraith" : "gearspider"]), enemy(groundType, 4380, 500)],
    emblems: [{ x: 610, y: 650 }, { x: 2200, y: 430 }, { x: 4070, y: 500 }],
  };
  if (chapterIndex === 9) area.keys.push(key("seasons-5", "round_walnut", 4200, 515));
  if (["storm", "eclipse"].includes(kind)) area.lightningZones = [{ x: 620, w: 190 }, { x: 2880, w: 220 }, { x: 3950, w: 210 }];
  if (["mirror", "cloud", "prism"].includes(kind)) area.lowGravityZones = [{ x: 1300, y: 240, w: 1250, h: 1250 }];
  if (kind === "mirror") area.teleporters = [{ id: "mirror-a", x: 1050, y: 760, toX: 3050, toY: 700 }, { id: "mirror-b", x: 3050, y: 700, toX: 1050, toY: 760 }];
  if (kind === "lava") { area.hotZones = [{ x: 500, y: 350, w: 900, h: 1100 }, { x: 2750, y: 300, w: 900, h: 1150 }]; area.updrafts = [{ x: 1500, y: 350, w: 130, h: 1000 }]; }
  if (kind === "abyss") area.shadowZones = [{ x: 700, y: 260, w: 1100, h: 1250 }, { x: 3000, y: 230, w: 900, h: 1280 }];
  if (kind === "cloud") area.updrafts = [{ x: 520, y: 240, w: 130, h: 1200 }, { x: 2800, y: 220, w: 130, h: 1250 }];
  if (kind === "bone") area.crumblePlatforms = [{ x: 970, y: 820 }, { x: 2440, y: 680 }, { x: 3590, y: 660 }];
  if (kind === "seasons") { area.updrafts = [{ x: 900, y: 230, w: 130, h: 1250 }]; area.shadowZones = [{ x: 3300, y: 220, w: 700, h: 1250 }]; area.timeLimit = 220; }
  area.enemies.forEach((foe) => {
    if (foe.flying) return;
    const platform = area.platforms.find((entry) => foe.x >= entry.x && foe.x <= entry.x + entry.w);
    if (platform) foe.y = platform.y;
  });
  AREAS.push(area);
});

const LANDMARKS = [
  ["oak_gust_bell", "gust", "Lonceng angin membuka arus menuju portal."],
  ["pine_resin_lantern", "reveal", "Lentera resin menyingkap jalur tersembunyi."],
  ["canyon_wind_turbine", "gust", "Turbin daun membangkitkan arus kuat."],
  ["root_burrow_switch", "tunnel", "Sakelar akar melontarkan Luma ke jalur atas."],
  ["cavern_color_prism", "prism", "Prisma warna memulihkan tenaga dan hati."],
  ["waterfall_waterwheel", "slow", "Roda air memperlambat semua mesin bergerak."],
  ["frost_heat_brazier", "shield", "Bara kuno memberi pelindung dari bahaya."],
  ["clockwork_time_switch", "time", "Sakelar waktu memberi waktu tambahan."],
  ["swamp_purifier_flower", "shield", "Bunga pemurni memberi pelindung racun."],
  ["core_gravity_totem", "gravity", "Totem membentuk kantong gravitasi ringan."],
  ["redwood_tide_valve", "slow", "Katup pasang memperlambat rakit daun."],
  ["orchard_lightning_rod", "lightning", "Penangkal petir mematikan sambaran."],
  ["hive_honey_prism", "prism", "Prisma madu memulihkan seluruh tenaga."],
  ["ashen_ember_vent", "gust", "Ventilasi bara menciptakan arus panas."],
  ["moon_mirror", "phase", "Cermin bulan memberi perlindungan bayangan."],
  ["skyroot_sky_anchor", "slow", "Jangkar langit menstabilkan pulau bergerak."],
  ["amber_fossil_drill", "reveal", "Bor fosil membuka semua retakan terkubur."],
  ["chrono_master_dial", "time", "Dial utama menambahkan waktu perjalanan."],
  ["dreamcap_dream_mirror", "tunnel", "Cermin mimpi memindahkan Luma ke kanopi."],
  ["celestial_star_seal", "prism", "Segel bintang memulihkan kekuatan terakhir."],
  ["worldseed_loom", "prism", "Alat tenun benih menumbuhkan jalan terakhir.", "landmarks2"],
  ["storm_nest_beacon", "lightning", "Mercusuar sarang menetralkan petir.", "landmarks2"],
  ["mirrorwood_lens", "phase", "Lensa cermin memberi perlindungan pantulan.", "landmarks2"],
  ["lava_sap_forge", "shield", "Tempa getah memberi pelindung panas.", "landmarks2"],
  ["abyss_echo_conch", "tunnel", "Gema jurang melontarkan Luma ke jalur atas.", "landmarks2"],
  ["cloud_temple_bell", "gust", "Lonceng kuil membangkitkan arus langit.", "landmarks2"],
  ["prism_orchard_core", "prism", "Inti prisma memulihkan tenaga.", "landmarks2"],
  ["bonewood_archive", "reveal", "Arsip fosil menyingkap jalur rahasia.", "landmarks2"],
  ["eclipse_orrery", "time", "Orrery gerhana menambah waktu.", "landmarks2"],
  ["seasons_heart", "prism", "Jantung musim memulihkan seluruh kekuatan.", "landmarks2"],
];

const NEW_ENEMY_TYPES = [
  "thornboar", "conewasp", "sapslime", "barkmantis", "windserpent", "crystalmite",
  "embermoth", "moonwraith", "gearspider", "bogstalker", "skyjelly", "starwraith",
];
const NEW_FLYING = new Set(["conewasp", "windserpent", "embermoth", "moonwraith", "skyjelly", "starwraith"]);

// A final landmark gauntlet lengthens every area and gives each biome one more
// concrete mechanic to master before its portal can open.
AREAS.forEach((area, index) => {
  const baseY = Math.max(320, Math.min(1460, area.portal.y + 90));
  const extension = [
    p(4600, baseY + 50, 290), p(4850, baseY - 20, 290), p(5100, baseY - 90, 290),
    p(5350, baseY - 20, 290), p(5580, baseY - 100, 260),
  ];
  area.platforms.push(...extension);
  const [sprite, effect, message, sheet = "landmarks"] = LANDMARKS[index];
  area.mechanicNodes = [{ id: `landmark-${index + 1}`, sprite, effect, message, sheet, x: 5440, y: baseY - 90 }];
  area.nodesRequired = 1;
  const firstType = NEW_ENEMY_TYPES[index % NEW_ENEMY_TYPES.length];
  const secondType = NEW_ENEMY_TYPES[(index + 5) % NEW_ENEMY_TYPES.length];
  const thirdType = NEW_ENEMY_TYPES[(index + 9) % NEW_ENEMY_TYPES.length];
  area.enemies.push(
    enemy(firstType, 4750, baseY + 50, { flying: NEW_FLYING.has(firstType) }),
    enemy(secondType, 5220, baseY - (NEW_FLYING.has(secondType) ? 170 : 90), { flying: NEW_FLYING.has(secondType) }),
    enemy(thirdType, 5650, baseY - (NEW_FLYING.has(thirdType) ? 210 : 100), { flying: NEW_FLYING.has(thirdType) }),
  );
  area.portal = { x: 5750, y: baseY - 180 };
  area.worldWidth = 5900; area.worldHeight = 1900;
});

const CH3_TYPES = ["sunscarab", "voidbat", "thornwolf", "riverwyrm", "lavacrab", "cloudray", "prismlion", "eclipseowl"];
const CH3_FLYING = new Set(["voidbat", "cloudray", "eclipseowl"]);
AREAS.forEach((area, index) => {
  const baseY = Math.max(340, Math.min(1580, area.portal.y + 100));
  area.platforms.push(p(5850, baseY + 60, 300), p(6120, baseY - 10, 300), p(6390, baseY - 80, 300), p(6660, baseY - 10, 300), p(6930, baseY - 90, 350));
  const keepers = [CH3_TYPES[index % 8], CH3_TYPES[(index + 3) % 8], CH3_TYPES[(index + 6) % 8]];
  area.enemies.push(
    enemy(keepers[0], 6020, baseY + 60, { flying: CH3_FLYING.has(keepers[0]), gateKeeper: true }),
    enemy(keepers[1], 6500, baseY - (CH3_FLYING.has(keepers[1]) ? 190 : 80), { flying: CH3_FLYING.has(keepers[1]), gateKeeper: true }),
    enemy(keepers[2], 7040, baseY - (CH3_FLYING.has(keepers[2]) ? 210 : 90), { flying: CH3_FLYING.has(keepers[2]), gateKeeper: true }),
  );
  area.portal = { x: 7180, y: baseY - 170 }; area.worldWidth = 7350; area.worldHeight = 2100;
});

export function makeArea(index) {
  return structuredClone(AREAS[index]);
}

export const ENEMY_SHEET = {
  beetle: "woodland", woodpecker: "woodland", hawk: "woodland", mole: "woodland",
  snail: "elemental", frog: "elemental", owl: "elemental", clockbeetle: "elemental",
  mosquito: "final", guardian: "final",
  thornboar: "newForest", conewasp: "newForest", sapslime: "newForest", barkmantis: "newForest",
  windserpent: "newArcane", crystalmite: "newArcane", embermoth: "newArcane", moonwraith: "newArcane",
  gearspider: "newWeird", bogstalker: "newWeird", skyjelly: "newWeird", starwraith: "newWeird",
  sunscarab: "chapter3A", voidbat: "chapter3A", thornwolf: "chapter3A", riverwyrm: "chapter3A",
  lavacrab: "chapter3B", cloudray: "chapter3B", prismlion: "chapter3B", eclipseowl: "chapter3B",
};

export const AREA_COUNT = AREAS.length;
