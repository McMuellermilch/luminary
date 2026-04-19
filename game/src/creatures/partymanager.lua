-- PartyManager
-- Manages the player's active party (up to 3 Lumins) and PC storage.
-- Also handles EXP distribution when enemies are defeated.

local Events = require("src.core.events")
local Lumin  = require("src.creatures.lumin")

local PartyManager = {}

PartyManager.party   = {}   -- active party, max 3 Lumin instances
PartyManager.storage = {}   -- PC storage (unlimited; serialised in Phase 11)

-- -------------------------------------------------------------------------
-- Initialisation — call once at game start if party is empty.
-- -------------------------------------------------------------------------
function PartyManager.initIfEmpty()
  if #PartyManager.party == 0 then
    PartyManager.add(Lumin.new("pip", 1))
  end
end

-- -------------------------------------------------------------------------
-- Party management
-- -------------------------------------------------------------------------

function PartyManager.add(lumin)
  if #PartyManager.party < 3 then
    PartyManager.party[#PartyManager.party + 1] = lumin
  else
    PartyManager.storage[#PartyManager.storage + 1] = lumin
  end
end

function PartyManager.remove(slot)
  table.remove(PartyManager.party, slot)
end

function PartyManager.swap(a, b)
  PartyManager.party[a], PartyManager.party[b] =
    PartyManager.party[b], PartyManager.party[a]
end

function PartyManager.getActive()
  return PartyManager.party[1]
end

function PartyManager.getCompanion()
  return PartyManager.party[2]
end

function PartyManager.isAlive(lumin)
  return lumin ~= nil and lumin.hp > 0
end

-- Restore all party HP (used at Lighthouse / save points in Phase 9).
function PartyManager.healAll()
  for _, lumin in ipairs(PartyManager.party) do
    lumin.hp = lumin.max_hp
  end
end

-- -------------------------------------------------------------------------
-- EXP distribution
-- Award EXP to all living party members when an enemy is defeated.
-- -------------------------------------------------------------------------
Events.on("enemy_defeated", function(data)
  local exp = data.exp_yield or 0
  if exp <= 0 then return end
  for _, lumin in ipairs(PartyManager.party) do
    if PartyManager.isAlive(lumin) then
      Lumin.addExp(lumin, exp)
    end
  end
end)

return PartyManager
