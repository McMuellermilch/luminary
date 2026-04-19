-- Move definitions
-- Used by AbilityComponent. Lumins reference moves by key.
-- damage_mult is applied to the caster's base charge-attack damage.

return {
  solar_burst = {
    name        = "Solar Burst",
    damage_mult = 1.5,
    cooldown    = 4.0,
    range       = 80,
    effect      = "nova",   -- 4-directional hitbox burst
  },
  ember_dash = {
    name        = "Ember Dash",
    damage_mult = 1.2,
    cooldown    = 3.0,
    range       = 60,
    effect      = "nova",
  },
}
