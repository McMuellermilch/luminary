-- Lumin
-- A live Lumin instance in the player's party.
-- Distinct from static creature data — holds current HP, EXP, level, etc.

local Events   = require("src.core.events")
local Creatures = require("src.data.creatures")
local Moves    = require("src.data.moves")

local Lumin = {}

-- -------------------------------------------------------------------------
-- Stat helpers
-- -------------------------------------------------------------------------

function Lumin.calcStat(stat, data, level)
  local base   = data["base_" .. stat] or 10
  local growth = data[stat .. "_growth"] or 1
  return base + growth * (level - 1)
end

-- EXP required to reach the next level from `level`.
function Lumin.expToNext(level)
  return math.floor(50 * (level ^ 1.5))
end

-- Returns the list of move IDs this creature knows up to `level` (max 4).
function Lumin.learnedMoves(data, level)
  local result = {}
  for _, entry in ipairs(data.moves or {}) do
    if entry.level <= level and #result < 4 then
      result[#result + 1] = entry.move
    end
  end
  return result
end

-- -------------------------------------------------------------------------
-- Constructor
-- -------------------------------------------------------------------------

function Lumin.new(creature_id, level)
  level = level or 1
  local data = Creatures[creature_id]
  assert(data, "Lumin.new: unknown creature_id '" .. tostring(creature_id) .. "'")

  local max_hp = Lumin.calcStat("hp", data, level)
  return {
    id          = creature_id,
    data        = data,
    nickname    = nil,
    level       = level,
    exp         = 0,
    exp_to_next = Lumin.expToNext(level),
    max_hp      = max_hp,
    hp          = max_hp,
    atk         = Lumin.calcStat("atk", data, level),
    def         = Lumin.calcStat("def", data, level),
    spd         = Lumin.calcStat("spd", data, level),
    moves       = Lumin.learnedMoves(data, level),
    bonded      = false,
  }
end

-- Display name: nickname if set, otherwise species name.
function Lumin.displayName(lumin)
  return lumin.nickname or lumin.data.name
end

-- -------------------------------------------------------------------------
-- EXP & levelling
-- -------------------------------------------------------------------------

function Lumin.addExp(lumin, amount)
  if amount <= 0 then return end
  lumin.exp = lumin.exp + amount
  while lumin.exp >= lumin.exp_to_next do
    lumin.exp = lumin.exp - lumin.exp_to_next
    Lumin._levelUp(lumin)
  end
end

function Lumin._levelUp(lumin)
  lumin.level       = lumin.level + 1
  lumin.exp_to_next = Lumin.expToNext(lumin.level)

  -- Preserve HP ratio across level-up
  local hp_ratio = lumin.hp / lumin.max_hp
  lumin.max_hp   = Lumin.calcStat("hp",  lumin.data, lumin.level)
  lumin.hp       = math.max(1, math.floor(lumin.max_hp * hp_ratio))
  lumin.atk      = Lumin.calcStat("atk", lumin.data, lumin.level)
  lumin.def      = Lumin.calcStat("def", lumin.data, lumin.level)
  lumin.spd      = Lumin.calcStat("spd", lumin.data, lumin.level)

  -- Learn any move taught at this level
  for _, entry in ipairs(lumin.data.moves or {}) do
    if entry.level == lumin.level and #lumin.moves < 4 then
      -- Only add if not already known
      local already = false
      for _, mid in ipairs(lumin.moves) do
        if mid == entry.move then already = true; break end
      end
      if not already and Moves[entry.move] then
        lumin.moves[#lumin.moves + 1] = entry.move
        Events.emit("lumin_learned_move", lumin, entry.move)
      end
    end
  end

  -- Check evolution
  Lumin._checkEvolution(lumin)

  Events.emit("lumin_leveled_up", lumin)
  print(string.format("[Lumin] %s reached level %d!",
    Lumin.displayName(lumin), lumin.level))
end

-- -------------------------------------------------------------------------
-- Evolution
-- -------------------------------------------------------------------------

function Lumin._checkEvolution(lumin)
  local data = lumin.data
  if not data.evolves_to then return end
  if lumin.level < (data.evolves_at or math.huge) then return end

  -- Lit-region requirement deferred to Phase 9 (BeaconSystem).
  -- For now evolve unconditionally when level is reached.

  local evo_id   = data.evolves_to
  local evo_data = Creatures[evo_id]
  if not evo_data then
    print("[Lumin] Warning: evolution target '" .. evo_id .. "' not found.")
    return
  end

  local hp_pct = lumin.hp / lumin.max_hp

  lumin.id   = evo_id
  lumin.data = evo_data

  -- Recalculate with new base stats, retain HP percentage
  lumin.max_hp = Lumin.calcStat("hp",  evo_data, lumin.level)
  lumin.hp     = math.max(1, math.floor(lumin.max_hp * hp_pct))
  lumin.atk    = Lumin.calcStat("atk", evo_data, lumin.level)
  lumin.def    = Lumin.calcStat("def", evo_data, lumin.level)
  lumin.spd    = Lumin.calcStat("spd", evo_data, lumin.level)

  Events.emit("lumin_evolving", lumin)
  print(string.format("[Lumin] %s evolved into %s!",
    data.name, evo_data.name))
end

return Lumin
