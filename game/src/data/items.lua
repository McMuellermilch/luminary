-- Item definitions
-- Pure data — no logic. All usable items are defined here.
--
-- Capture items:
--   type          = "capture"
--   trust_bonus   — flat bonus added to the trust roll
--   required_type — if set, only works on Lumins of this creature type
--
-- Healing items (Phase 8):
--   type = "heal", restore = <hp amount>

return {

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
