-- Creature definitions
-- Used by combat system to instantiate enemy entities.
-- creature_id keys match the ids used in encounter tables.

return {
  gleamfin = {
    name          = "Gleamfin",
    max_hp        = 10,
    speed         = 60,
    aggro_range   = 110,
    attack_range  = 30,
    base_damage   = 2,
    attack_cooldown = 1.6,
    exp           = 12,
    sprite_png    = "assets/sprites/npc_generic.png",
    sprite_json   = "assets/sprites/npc_generic.json",
  },
  mossling = {
    name          = "Mossling",
    max_hp        = 8,
    speed         = 45,
    aggro_range   = 90,
    attack_range  = 28,
    base_damage   = 2,
    attack_cooldown = 2.0,
    exp           = 8,
    sprite_png    = "assets/sprites/npc_generic.png",
    sprite_json   = "assets/sprites/npc_generic.json",
  },
  bogsprite = {
    name          = "Bogsprite",
    max_hp        = 14,
    speed         = 38,
    aggro_range   = 80,
    attack_range  = 35,
    base_damage   = 3,
    attack_cooldown = 2.4,
    exp           = 18,
    sprite_png    = "assets/sprites/npc_generic.png",
    sprite_json   = "assets/sprites/npc_generic.json",
  },
}
