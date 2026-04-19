-- Item definitions
-- Pure data — no logic. All usable items are defined here.
--
-- Capture items:
--   type          = "capture"
--   trust_bonus   — flat bonus added to the trust roll
--   required_type — if set, only works on Lumins of this creature type
--
-- Healing items:
--   type = "heal",      heal_amount = <hp restored>
--   type = "heal_full"  — restores all HP
--
-- Key items:
--   type = "key" — no quantity; used by quest system; cannot be sold

return {

  -- -----------------------------------------------------------------------
  -- Healing items
  -- -----------------------------------------------------------------------
  potion = {
    id          = "potion",
    name        = "Glow Potion",
    description = "A small vial of Beacon light. Restores 30 HP.",
    type        = "heal",
    heal_amount = 30,
    sprite      = "potion_glow",
  },

  super_potion = {
    id          = "super_potion",
    name        = "Radiance Potion",
    description = "A larger draught of concentrated Beacon light. Restores 80 HP.",
    type        = "heal",
    heal_amount = 80,
    sprite      = "potion_radiance",
  },

  full_restore = {
    id          = "full_restore",
    name        = "Beacon Drop",
    description = "A single drop of pure Beacon essence. Fully restores one Lumin.",
    type        = "heal_full",
    sprite      = "beacon_drop",
  },

  -- -----------------------------------------------------------------------
  -- Key items
  -- -----------------------------------------------------------------------
  beacon_shard_willowfen = {
    id          = "beacon_shard_willowfen",
    name        = "Willowfen Shard",
    description = "A fragment of the Willowfen Beacon Tower. Thrums with faint light.",
    type        = "key",
    sprite      = "beacon_shard",
  },

  lightweaver_map = {
    id          = "lightweaver_map",
    name        = "Vesper's Map",
    description = "An old map marked by the Lightweaver Vesper. Shows hidden Beacon sites.",
    type        = "key",
    sprite      = "map_vesper",
  },

  -- -----------------------------------------------------------------------
  -- Lightglass Lanterns — capture items
  -- -----------------------------------------------------------------------
  lightglass_lantern = {
    id          = "lightglass_lantern",
    name        = "Lightglass Lantern",
    description = "A glass lantern filled with Beacon light. Lumins are drawn to it.",
    type        = "capture",
    trust_bonus = 0,
    sprite      = "lantern_light",
  },

  warmglass_lantern = {
    id          = "warmglass_lantern",
    name        = "Warmglass Lantern",
    description = "A warmer lantern. Lumins feel safer and more willing to enter.",
    type        = "capture",
    trust_bonus = 20,
    sprite      = "lantern_warm",
  },

  duskglass_lantern = {
    id            = "duskglass_lantern",
    name          = "Duskglass Lantern",
    description   = "Contains shadow-light. Required for Void Lumins.",
    type          = "capture",
    trust_bonus   = 0,
    required_type = "void",
    sprite        = "lantern_dusk",
  },

}
