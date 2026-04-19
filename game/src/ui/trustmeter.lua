-- TrustMeter
-- Animated trust bar displayed in screen space above a capture target.
-- Rendered AFTER camera:detach() so coordinates are window pixels.
--
-- Usage:
--   local meter = TrustMeter.new(trust_value, enemy, camera)
--   meter:update(dt)   -- in overworld update (during capture freeze)
--   meter:draw()       -- in overworld draw, after camera:detach()
--   if meter.done then ... end

local TrustMeter = {}
TrustMeter.__index = TrustMeter

local FILL_DURATION  = 1.5   -- seconds to animate the bar to target fill
local RESULT_HOLD    = 0.6   -- seconds to hold the result before marking done

-- trust_value: raw trust number (0–100+, clamped at 100 for display)
-- enemy:       the target Enemy entity (used for screen position)
-- camera:      the Camera object (provides :toScreen())
function TrustMeter.new(trust_value, enemy, camera)
  local clamped = math.min(trust_value, 100)
  return setmetatable({
    success      = trust_value >= 80,
    target_frac  = clamped / 100,
    fill_frac    = 0,
    enemy        = enemy,
    camera       = camera,
    fill_timer   = 0,        -- time spent filling
    result_timer = 0,        -- time held after fill completes
    done         = false,
  }, TrustMeter)
end

function TrustMeter:update(dt)
  if self.done then return end

  if self.fill_timer < FILL_DURATION then
    self.fill_timer = self.fill_timer + dt
    local t = math.min(self.fill_timer / FILL_DURATION, 1)
    -- Ease-out: slow down as it approaches target
    self.fill_frac = (1 - (1 - t) ^ 2) * self.target_frac
  else
    self.fill_frac = self.target_frac
    self.result_timer = self.result_timer + dt
    if self.result_timer >= RESULT_HOLD then
      self.done = true
    end
  end
end

-- Draw the trust meter. Call in screen space (after camera:detach()).
function TrustMeter:draw()
  if not self.enemy or not self.enemy.active then return end

  -- Convert enemy centre-top to window pixel coordinates
  local wx = self.enemy.x + self.enemy.w / 2
  local wy = self.enemy.y
  local sx, sy = self.camera:toScreen(wx, wy)

  local bw, bh = 60, 8
  local bx = math.floor(sx - bw / 2)
  local by = math.floor(sy - 22)   -- above enemy sprite

  -- Background track
  love.graphics.setColor(0.1, 0.1, 0.1, 0.88)
  love.graphics.rectangle("fill", bx, by, bw, bh, 2, 2)

  -- Fill colour: amber while filling, gold on success, red on failure
  local filling = self.fill_timer < FILL_DURATION
  if filling then
    love.graphics.setColor(1.0, 0.72, 0.15, 0.95)
  elseif self.success then
    local pulse = 0.5 + 0.5 * math.sin(self.result_timer * 12)
    love.graphics.setColor(1.0, 0.82 + pulse * 0.12, 0.0, 0.95)
  else
    love.graphics.setColor(0.88, 0.12, 0.12, 0.9)
  end
  love.graphics.rectangle("fill", bx, by, math.floor(bw * self.fill_frac), bh, 2, 2)

  -- Border
  love.graphics.setColor(1, 1, 1, 0.45)
  love.graphics.rectangle("line", bx, by, bw, bh, 2, 2)

  -- Label: lantern icon text (no percentage, per spec)
  love.graphics.setColor(1, 1, 1, 0.75)
  love.graphics.print("~", bx + bw + 4, by - 1)

  love.graphics.setColor(1, 1, 1, 1)
end

return TrustMeter
