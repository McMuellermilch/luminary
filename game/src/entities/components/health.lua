-- HealthComponent
-- Tracks HP and max HP for an entity.
-- Emits events so other systems (HUD, combat) can react.
--
-- Usage:
--   local health = HealthComponent.new(10)
--   entity:addComponent("health", health)
--   health:damage(3)
--   health:isDead()  → bool

local Events = require("src.core.events")

local HealthComponent = {}
HealthComponent.__index = HealthComponent

function HealthComponent.new(max_hp)
  local self = setmetatable({}, HealthComponent)
  self.max_hp = max_hp
  self.hp     = max_hp
  return self
end

function HealthComponent:damage(amount)
  self.hp = math.max(0, self.hp - amount)
  Events.emit("entity_damaged", self.owner, amount)
  if self:isDead() then
    Events.emit("entity_died", self.owner)
  end
end

function HealthComponent:heal(amount)
  self.hp = math.min(self.max_hp, self.hp + amount)
end

function HealthComponent:isDead()
  return self.hp <= 0
end

return HealthComponent
