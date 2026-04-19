-- FacingComponent
-- Tracks the entity's facing direction and automatically updates
-- the AnimationComponent state when direction or movement changes.
--
-- Usage:
--   local facing = FacingComponent.new("down")
--   entity:addComponent("facing", facing)
--   facing:set("left", true)   -- direction, is_moving

local FacingComponent = {}
FacingComponent.__index = FacingComponent

local VALID = { up = true, down = true, left = true, right = true }

function FacingComponent.new(initial_dir)
  local self = setmetatable({}, FacingComponent)
  self.direction = initial_dir or "down"
  self.moving    = false
  return self
end

-- Set facing direction and movement state, then sync the animation.
-- direction — "up" | "down" | "left" | "right" (nil to keep current)
-- moving    — boolean
function FacingComponent:set(direction, moving)
  local changed = false
  if direction and VALID[direction] and direction ~= self.direction then
    self.direction = direction
    changed = true
  end
  if moving ~= self.moving then
    self.moving = moving
    changed = true
  end
  if changed then self:_syncAnim() end
end

-- Force direction and animation state regardless of previous value.
-- Used by NPC:onInteract() so the turn always visually registers.
function FacingComponent:forceDirection(direction)
  if direction and VALID[direction] then
    self.direction = direction
    self:_syncAnim()
  end
end

function FacingComponent:_syncAnim()
  local anim = self.owner:getComponent("animation")
  if not anim then return end
  local prefix = self.moving and "walk_" or "idle_"
  anim:setState(prefix .. self.direction)
end

return FacingComponent
