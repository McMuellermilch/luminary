-- PhysicsComponent
-- Manages bump.lua registration and movement for an entity.
-- The bump world item IS the entity itself (owner), not the component.
--
-- Usage:
--   local phys = Physics.new(world, w, h)
--   entity:addComponent("physics", phys)
--   phys:register()          -- add entity to bump world
--   phys:move(dx, dy, filter)

local Physics = {}
Physics.__index = Physics

function Physics.new(world, w, h)
  local self = setmetatable({}, Physics)
  self.world = world
  self.w     = w
  self.h     = h
  -- self.owner is set by Entity:addComponent
  return self
end

-- Register the owner entity in the bump world.
-- Call this once after addComponent, before the entity's first update.
function Physics:register()
  local e = self.owner
  self.world:add(e, e.x, e.y, self.w, self.h)
end

-- Move the owner entity through the bump world.
-- dx, dy   — pixel displacement this frame
-- filter   — bump collision filter function
function Physics:move(dx, dy, filter)
  local e  = self.owner
  local nx = e.x + dx
  local ny = e.y + dy
  local ax, ay = self.world:move(e, nx, ny, filter)
  e.x = ax
  e.y = ay
end

-- Remove the owner entity from the bump world (call on entity destruction).
function Physics:unregister()
  if self.world then
    pcall(function() self.world:remove(self.owner) end)
  end
end

-- Convenience: centre point of the physics rectangle.
function Physics:center()
  local e = self.owner
  return e.x + self.w / 2, e.y + self.h / 2
end

return Physics
