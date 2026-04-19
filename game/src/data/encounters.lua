-- Encounter tables
-- Each zone table is a list of possible creatures with spawn level range and weight.
-- Weights are relative (total need not equal 100).
--
-- Naming convention: "region_zone_dark" / "region_zone_lit"
-- MapManager appends the suffix based on RegionState.isLit() at load time.

local encounter_tables = {

  -- Willowfen: dark variants (hostile, anxious Lumins)
  willowfen_grass_dark = {
    { creature_id = "gleamfin",  min_level = 2, max_level = 4, weight = 60 },
    { creature_id = "mossling",  min_level = 2, max_level = 3, weight = 40 },
  },
  willowfen_marsh_dark = {
    { creature_id = "gleamfin",  min_level = 3, max_level = 5, weight = 50 },
    { creature_id = "mossling",  min_level = 3, max_level = 4, weight = 30 },
    { creature_id = "bogsprite", min_level = 4, max_level = 6, weight = 20 },
  },

  -- Willowfen: lit variants (calmer, more variety, rare Lumins possible)
  willowfen_grass_lit = {
    { creature_id = "gleamfin",  min_level = 2, max_level = 5, weight = 50 },
    { creature_id = "mossling",  min_level = 2, max_level = 4, weight = 30 },
    { creature_id = "shimmray",  min_level = 3, max_level = 5, weight = 20 },
  },
  willowfen_marsh_lit = {
    { creature_id = "gleamfin",  min_level = 3, max_level = 6, weight = 40 },
    { creature_id = "mossling",  min_level = 3, max_level = 5, weight = 25 },
    { creature_id = "bogsprite", min_level = 4, max_level = 7, weight = 20 },
    { creature_id = "glimmer",   min_level = 4, max_level = 6, weight = 15 },
  },

  -- Legacy aliases (no suffix) kept for backwards compatibility
  willowfen_grass = {
    { creature_id = "gleamfin",  min_level = 2, max_level = 4, weight = 60 },
    { creature_id = "mossling",  min_level = 2, max_level = 3, weight = 40 },
  },
  willowfen_marsh = {
    { creature_id = "gleamfin",  min_level = 3, max_level = 5, weight = 50 },
    { creature_id = "mossling",  min_level = 3, max_level = 4, weight = 30 },
    { creature_id = "bogsprite", min_level = 4, max_level = 6, weight = 20 },
  },
}

return encounter_tables
