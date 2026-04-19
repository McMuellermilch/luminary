-- AnimationComponent
-- Wraps a set of named anim8 animations and draws the current one.
-- Relies on a Love2D Image and a table of { name → anim8_animation }.
--
-- Usage:
--   local anim = AnimationComponent.new(image, anims)
--   entity:addComponent("animation", anim)
--   anim:setState("walk_down")
--   -- update and draw are called automatically via Entity:update/draw

local AnimationComponent = {}
AnimationComponent.__index = AnimationComponent

function AnimationComponent.new(image, anims)
  local self = setmetatable({}, AnimationComponent)
  self.image        = image
  self.animations   = anims        -- { name = anim8_anim }
  self.current      = nil
  self.current_name = ""
  -- Default to first available animation
  local first_name = next(anims)
  if first_name then self:setState(first_name) end
  return self
end

function AnimationComponent:setState(name)
  if self.current_name == name then return end
  local anim = self.animations[name]
  if not anim then
    -- Graceful fallback: keep current state rather than crashing
    return
  end
  self.current_name = name
  self.current      = anim
  self.current:gotoFrame(1)
end

function AnimationComponent:update(dt)
  if self.current then
    self.current:update(dt)
  end
end

-- Draw at the owner entity's position.
-- ox, oy — optional pixel offset from entity origin (default 0, 0)
function AnimationComponent:draw(ox, oy)
  if not (self.current and self.image) then return end
  local e = self.owner
  self.current:draw(self.image, e.x + (ox or 0), e.y + (oy or 0))
end

return AnimationComponent
