-- CaptureSystem
-- Trust calculation, capture validation, and post-capture Lumin initialisation.
-- Called by Overworld when the player throws a Lightglass Lantern.

local Lumin        = require("src.creatures.lumin")
local PartyManager = require("src.creatures.partymanager")
local Events       = require("src.core.events")

local CaptureSystem = {}

-- Per-session species familiarity: { [creature_id] = catch_count }
-- Serialised in Phase 11.
CaptureSystem.familiarity = {}

-- Base trust before bonuses and penalties.
local BASE_TRUST = 40

-- -------------------------------------------------------------------------
-- Validation — call before consuming the item.
-- Returns: ok (bool), message (string) explaining why not (nil on success).
-- -------------------------------------------------------------------------
function CaptureSystem.canCapture(enemy, item)
  if enemy.is_boss then
    return false, "Umbral Guardians cannot be captured."
  end
  local required = item and item.required_type
  if required and enemy.creature_type ~= required then
    return false, "This lantern only works on " .. required .. " Lumins."
  end
  if not required and enemy.creature_type == "void" then
    return false, "Use a Duskglass Lantern for Void Lumins."
  end
  return true, nil
end

-- -------------------------------------------------------------------------
-- Trust roll — returns a number; capture succeeds if >= 80.
-- enemy: Enemy entity (needs .creature_id, .creature_type, health component)
-- item:  item definition table from src/data/items.lua
-- -------------------------------------------------------------------------
function CaptureSystem.calcTrust(enemy, item)
  local hp_comp  = enemy:getComponent("health")
  local hp_frac  = hp_comp.hp / hp_comp.max_hp
  local hp_bonus = (1 - hp_frac) * 60   -- 0 at full HP, up to 60 at 1 HP

  local fam_bonus  = (CaptureSystem.familiarity[enemy.creature_id] or 0) * 5
  local item_bonus = (item and item.trust_bonus) or 0
  local penalty    = (enemy.capture_difficulty or 1) * 10

  return BASE_TRUST + hp_bonus + fam_bonus + item_bonus - penalty
end

-- -------------------------------------------------------------------------
-- Finalise a successful capture.
-- Creates a Lumin instance, records familiarity, adds to party/storage.
-- Returns the new Lumin.
-- -------------------------------------------------------------------------
function CaptureSystem.finalize(enemy)
  local level = enemy.capture_level or 1
  local lumin = Lumin.new(enemy.creature_id, level)
  lumin.bonded = true
  -- Captured while weakened: start at ~25% HP
  lumin.hp = math.max(1, math.floor(lumin.max_hp * 0.25))

  -- Track familiarity for future capture bonuses
  CaptureSystem.familiarity[enemy.creature_id] =
    (CaptureSystem.familiarity[enemy.creature_id] or 0) + 1

  PartyManager.add(lumin)
  Events.emit("lumin_captured", lumin)
  print(string.format("[Capture] %s (Lv%d) joined the party!", lumin.data.name, lumin.level))
  return lumin
end

return CaptureSystem
