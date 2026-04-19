-- Creature definitions
-- Pure data — no logic. All Lumins and enemy creatures are defined here.
--
-- Stat fields used by Lumin instances (src/creatures/lumin.lua):
--   base_hp/atk/def/spd  — stats at level 1
--   hp/atk/def/spd_growth — added per level
--   moves                 — { {level, move_id}, ... }
--   evolves_to, evolves_at, evolves_requires_lit
--   exp_yield, capture_difficulty
--
-- Fields used by Enemy entity (overworld spawning):
--   speed, aggro_range, attack_range, attack_cooldown
--   sprite_png, sprite_json

return {

  -- -----------------------------------------------------------------------
  -- Pip / Flamewing — Luma's Flare-type starter
  -- -----------------------------------------------------------------------
  pip = {
    id   = "pip",
    name = "Pip",
    type = "flare",
    description = "A small ember-moth drawn to warmth and curiosity.",

    base_hp  = 28,  base_atk = 12,  base_def = 8,   base_spd = 16,
    hp_growth = 4,  atk_growth = 2, def_growth = 1, spd_growth = 2,

    moves = {
      { level = 1,  move = "ember_tap"   },
      { level = 5,  move = "wing_shield" },
      { level = 12, move = "solar_burst" },
    },

    evolves_to           = "flamewing",
    evolves_at           = 12,
    evolves_requires_lit = true,

    exp_yield          = 45,
    capture_difficulty = 1,

    sprite_png  = "assets/sprites/pip.png",
    sprite_json = "assets/sprites/pip.json",

    -- Overworld enemy behaviour (if spawned as enemy)
    speed          = 70,
    aggro_range    = 90,
    attack_range   = 30,
    attack_cooldown = 1.5,
  },

  flamewing = {
    id   = "flamewing",
    name = "Flamewing",
    type = "flare",
    description = "Pip's evolved form — wings of living flame.",

    base_hp  = 52,  base_atk = 20,  base_def = 14,  base_spd = 22,
    hp_growth = 6,  atk_growth = 3, def_growth = 2, spd_growth = 3,

    moves = {
      { level = 1,  move = "ember_tap"    },
      { level = 5,  move = "wing_shield"  },
      { level = 12, move = "solar_burst"  },
      { level = 20, move = "inferno_dash" },
    },

    evolves_to           = "solwing",
    evolves_at           = 30,
    evolves_requires_lit = true,

    exp_yield          = 120,
    capture_difficulty = 3,

    sprite_png  = "assets/sprites/npc_generic.png",
    sprite_json = "assets/sprites/npc_generic.json",

    speed          = 85,
    aggro_range    = 100,
    attack_range   = 32,
    attack_cooldown = 1.3,
  },

  -- -----------------------------------------------------------------------
  -- Gleamfin / Shimmray — Tide-type, Willowfen marsh
  -- -----------------------------------------------------------------------
  gleamfin = {
    id   = "gleamfin",
    name = "Gleamfin",
    type = "tide",
    description = "A shimmering fish-sprite that skims shallow water.",

    base_hp  = 35,  base_atk = 10,  base_def = 12,  base_spd = 10,
    hp_growth = 5,  atk_growth = 2, def_growth = 2, spd_growth = 1,

    moves = {
      { level = 1, move = "water_flick" },
      { level = 5, move = "tidal_rush"  },
    },

    evolves_to           = "shimmray",
    evolves_at           = 10,
    evolves_requires_lit = false,

    exp_yield          = 12,
    capture_difficulty = 2,

    sprite_png  = "assets/sprites/npc_generic.png",
    sprite_json = "assets/sprites/npc_generic.json",

    speed          = 60,
    aggro_range    = 110,
    attack_range   = 30,
    attack_cooldown = 1.6,
  },

  shimmray = {
    id   = "shimmray",
    name = "Shimmray",
    type = "tide",
    description = "Gleamfin's evolved form — a graceful ray of living light.",

    base_hp  = 60,  base_atk = 18,  base_def = 20,  base_spd = 14,
    hp_growth = 7,  atk_growth = 3, def_growth = 3, spd_growth = 2,

    moves = {
      { level = 1,  move = "water_flick" },
      { level = 5,  move = "tidal_rush"  },
      { level = 18, move = "riptide"     },
    },

    evolves_to = nil,

    exp_yield          = 95,
    capture_difficulty = 3,

    sprite_png  = "assets/sprites/npc_generic.png",
    sprite_json = "assets/sprites/npc_generic.json",

    speed          = 70,
    aggro_range    = 100,
    attack_range   = 35,
    attack_cooldown = 1.4,
  },

  -- -----------------------------------------------------------------------
  -- Mossling — Verdant-type, Willowfen forest floor
  -- -----------------------------------------------------------------------
  mossling = {
    id   = "mossling",
    name = "Mossling",
    type = "verdant",
    description = "A ball of living moss that rolls around forest paths.",

    base_hp  = 30,  base_atk = 11,  base_def = 10,  base_spd = 12,
    hp_growth = 4,  atk_growth = 2, def_growth = 2, spd_growth = 2,

    moves = {
      { level = 1, move = "leaf_tap"  },
      { level = 5, move = "root_bind" },
    },

    evolves_to = nil,

    exp_yield          = 8,
    capture_difficulty = 1,

    sprite_png  = "assets/sprites/npc_generic.png",
    sprite_json = "assets/sprites/npc_generic.json",

    speed          = 45,
    aggro_range    = 90,
    attack_range   = 28,
    attack_cooldown = 2.0,
  },

  -- -----------------------------------------------------------------------
  -- Glimmer / Lumara — Dusk-type, found everywhere at twilight
  -- -----------------------------------------------------------------------
  glimmer = {
    id   = "glimmer",
    name = "Glimmer",
    type = "dusk",
    description = "A fleeting spark of dusk-light shaped like a moth.",

    base_hp  = 22,  base_atk = 14,  base_def = 6,   base_spd = 20,
    hp_growth = 3,  atk_growth = 2, def_growth = 1, spd_growth = 3,

    moves = {
      { level = 1, move = "shadow_tap" },
      { level = 5, move = "dusk_pulse" },
    },

    evolves_to           = "lumara",
    evolves_at           = 10,
    evolves_requires_lit = false,

    exp_yield          = 10,
    capture_difficulty = 2,

    sprite_png  = "assets/sprites/npc_generic.png",
    sprite_json = "assets/sprites/npc_generic.json",

    speed          = 75,
    aggro_range    = 95,
    attack_range   = 28,
    attack_cooldown = 1.5,
  },

  lumara = {
    id   = "lumara",
    name = "Lumara",
    type = "dusk",
    description = "Glimmer's evolved form — a radiant dusk-spirit.",

    base_hp  = 40,  base_atk = 22,  base_def = 12,  base_spd = 26,
    hp_growth = 5,  atk_growth = 3, def_growth = 2, spd_growth = 4,

    moves = {
      { level = 1,  move = "shadow_tap" },
      { level = 5,  move = "dusk_pulse" },
      { level = 15, move = "void_burst" },
    },

    evolves_to = nil,

    exp_yield          = 90,
    capture_difficulty = 4,

    sprite_png  = "assets/sprites/npc_generic.png",
    sprite_json = "assets/sprites/npc_generic.json",

    speed          = 90,
    aggro_range    = 110,
    attack_range   = 30,
    attack_cooldown = 1.2,
  },

  -- -----------------------------------------------------------------------
  -- Cinderpup — Flare-type, deeper wildlands
  -- -----------------------------------------------------------------------
  cinderpup = {
    id   = "cinderpup",
    name = "Cinderpup",
    type = "flare",
    description = "A fiery pup with coal-dark fur and ember-bright eyes.",

    base_hp  = 32,  base_atk = 13,  base_def = 9,   base_spd = 14,
    hp_growth = 5,  atk_growth = 2, def_growth = 2, spd_growth = 2,

    moves = {
      { level = 1, move = "ember_tap"  },
      { level = 5, move = "flame_dash" },
    },

    evolves_to = nil,

    exp_yield          = 20,
    capture_difficulty = 2,

    sprite_png  = "assets/sprites/npc_generic.png",
    sprite_json = "assets/sprites/npc_generic.json",

    speed          = 65,
    aggro_range    = 100,
    attack_range   = 30,
    attack_cooldown = 1.7,
  },

  -- -----------------------------------------------------------------------
  -- Bogsprite — enemy-only Dusk creature, Willowfen dungeon
  -- -----------------------------------------------------------------------
  bogsprite = {
    id   = "bogsprite",
    name = "Bogsprite",
    type = "dusk",
    description = "A malicious wisp haunting dungeon corridors.",

    base_hp  = 45,  base_atk = 14,  base_def = 15,  base_spd = 8,
    hp_growth = 6,  atk_growth = 2, def_growth = 3, spd_growth = 1,

    moves = { { level = 1, move = "shadow_tap" } },

    evolves_to = nil,

    exp_yield          = 18,
    capture_difficulty = 5,

    sprite_png  = "assets/sprites/npc_generic.png",
    sprite_json = "assets/sprites/npc_generic.json",

    speed          = 38,
    aggro_range    = 80,
    attack_range   = 35,
    attack_cooldown = 2.4,
  },
}
