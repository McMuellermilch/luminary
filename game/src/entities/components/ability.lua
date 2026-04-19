-- AbilityComponent
-- Holds two ability slots with cooldown tracking.
-- move1, move2 — entries from src/data/moves.lua (or nil for empty slot)

local Ability = {}
Ability.__index = Ability

function Ability.new(move1, move2)
  local self = setmetatable({}, Ability)
  self.slots = {
    { move = move1, cooldown = 0 },
    { move = move2, cooldown = 0 },
  }
  return self
end

function Ability:update(dt)
  for _, slot in ipairs(self.slots) do
    if slot.cooldown > 0 then
      slot.cooldown = math.max(0, slot.cooldown - dt)
    end
  end
end

-- Fire ability in slot slot_index (1 or 2).
-- Returns the move data table if the ability was fired, nil if on cooldown or empty.
function Ability:use(slot_index)
  local slot = self.slots[slot_index]
  if not slot or not slot.move then return nil end
  if slot.cooldown > 0 then return nil end
  slot.cooldown = slot.move.cooldown
  return slot.move
end

-- Returns 0.0 (ready) to 1.0 (fully on cooldown) for HUD display.
function Ability:getCooldownFraction(slot_index)
  local slot = self.slots[slot_index]
  if not slot or not slot.move or slot.move.cooldown <= 0 then return 0 end
  return slot.cooldown / slot.move.cooldown
end

return Ability
