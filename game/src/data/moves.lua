-- Move definitions
-- Pure data. damage_mult is multiplied against the attacker's atk stat.
-- effect drives ability behaviour in the combat system.

return {

  -- -----------------------------------------------------------------------
  -- Basic attacks (no cooldown)
  -- -----------------------------------------------------------------------
  ember_tap = {
    id          = "ember_tap",
    name        = "Ember Tap",
    type        = "flare",
    damage_mult = 1.0,
    cooldown    = 0,
    range       = 40,
    effect      = "melee",
  },

  water_flick = {
    id          = "water_flick",
    name        = "Water Flick",
    type        = "tide",
    damage_mult = 1.0,
    cooldown    = 0,
    range       = 40,
    effect      = "melee",
  },

  leaf_tap = {
    id          = "leaf_tap",
    name        = "Leaf Tap",
    type        = "verdant",
    damage_mult = 1.0,
    cooldown    = 0,
    range       = 40,
    effect      = "melee",
  },

  shadow_tap = {
    id          = "shadow_tap",
    name        = "Shadow Tap",
    type        = "dusk",
    damage_mult = 1.0,
    cooldown    = 0,
    range       = 40,
    effect      = "melee",
  },

  -- -----------------------------------------------------------------------
  -- Ability moves (cooldown > 0)
  -- -----------------------------------------------------------------------
  solar_burst = {
    id          = "solar_burst",
    name        = "Solar Burst",
    type        = "flare",
    damage_mult = 1.5,
    cooldown    = 4.0,
    range       = 80,
    effect      = "nova",
  },

  wing_shield = {
    id          = "wing_shield",
    name        = "Wing Shield",
    type        = "flare",
    damage_mult = 0,
    cooldown    = 6.0,
    range       = 0,
    effect      = "self_shield",
    duration    = 2.0,
  },

  ember_dash = {
    id          = "ember_dash",
    name        = "Ember Dash",
    type        = "flare",
    damage_mult = 1.2,
    cooldown    = 3.0,
    range       = 60,
    effect      = "nova",
  },

  inferno_dash = {
    id          = "inferno_dash",
    name        = "Inferno Dash",
    type        = "flare",
    damage_mult = 2.0,
    cooldown    = 5.0,
    range       = 80,
    effect      = "nova",
  },

  tidal_rush = {
    id          = "tidal_rush",
    name        = "Tidal Rush",
    type        = "tide",
    damage_mult = 1.3,
    cooldown    = 3.5,
    range       = 60,
    effect      = "nova",
  },

  riptide = {
    id          = "riptide",
    name        = "Riptide",
    type        = "tide",
    damage_mult = 1.8,
    cooldown    = 5.0,
    range       = 90,
    effect      = "nova",
  },

  root_bind = {
    id          = "root_bind",
    name        = "Root Bind",
    type        = "verdant",
    damage_mult = 0.8,
    cooldown    = 4.0,
    range       = 50,
    effect      = "nova",
  },

  dusk_pulse = {
    id          = "dusk_pulse",
    name        = "Dusk Pulse",
    type        = "dusk",
    damage_mult = 1.4,
    cooldown    = 3.5,
    range       = 70,
    effect      = "nova",
  },

  void_burst = {
    id          = "void_burst",
    name        = "Void Burst",
    type        = "dusk",
    damage_mult = 2.0,
    cooldown    = 6.0,
    range       = 100,
    effect      = "nova",
  },

  flame_dash = {
    id          = "flame_dash",
    name        = "Flame Dash",
    type        = "flare",
    damage_mult = 1.2,
    cooldown    = 3.0,
    range       = 55,
    effect      = "nova",
  },
}
