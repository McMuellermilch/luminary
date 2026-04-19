-- Base Entity class
-- All game entities (player, NPCs, enemies) inherit from this.
-- Components are added via addComponent and updated/drawn automatically.
--
-- Component protocol:
--   component.owner is set to the entity when addComponent is called.
--   If a component has update(dt) or draw(), they are called each frame.

local Entity = {}
Entity.__index = Entity

function Entity.new(x, y)
  local self = setmetatable({}, Entity)
  self.x          = x
  self.y          = y
  self.components = {}
  self.active     = true
  return self
end

function Entity:addComponent(name, component)
  self.components[name] = component
  component.owner = self
end

function Entity:getComponent(name)
  return self.components[name]
end

-- Update all components in insertion order (Lua iterates pairs arbitrarily,
-- so components that need ordering should call each other explicitly).
function Entity:update(dt)
  for _, comp in pairs(self.components) do
    if comp.update then comp:update(dt) end
  end
end

-- Draw all components.
function Entity:draw()
  for _, comp in pairs(self.components) do
    if comp.draw then comp:draw() end
  end
end

function Entity:destroy()
  self.active = false
end

return Entity
