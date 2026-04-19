-- Encounter tables
-- Each zone table is a list of possible creatures with spawn level range and weight.
-- Weights are relative (total need not equal 100).

local encounter_tables = {
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
