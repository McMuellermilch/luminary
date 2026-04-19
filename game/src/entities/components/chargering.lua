-- ChargeRingComponent
-- Tracks the player's attack charge state and renders the ring in world space.
-- Drawn manually by CombatState (not via Entity:draw) so it stays inside the
-- arena coordinate transform.

local ChargeRing = {}
ChargeRing.__index = ChargeRing

local CHARGE_TIME = 1.5   -- seconds from 0 to full charge

function ChargeRing.new()
  local self = setmetatable({}, ChargeRing)
  self.charge    = 0       -- 0.0 – 1.0
  self.charging  = false
  self.hold_time = 0
  return self
end

function ChargeRing:startCharge()
  self.charging  = true
  self.hold_time = 0
end

function ChargeRing:update(dt)
  if self.charging then
    self.hold_time = self.hold_time + dt
    self.charge    = math.min(self.hold_time / CHARGE_TIME, 1.0)
  end
end

-- Returns current charge fraction (0–1) and resets the ring.
function ChargeRing:release()
  local level    = self.charge
  self.charge    = 0
  self.charging  = false
  self.hold_time = 0
  return level
end

function ChargeRing:reset()
  self.charge    = 0
  self.charging  = false
  self.hold_time = 0
end

-- Draw the charge ring in arena/world space around the owner entity.
-- Call this inside the arena love.graphics.translate transform.
function ChargeRing:draw()
  if self.charge == 0 and not self.charging then return end
  local e  = self.owner
  local cx = e.x + (e.w or 16) / 2
  local cy = e.y + (e.h or 16) / 2
  local r  = 18   -- ring radius in pixels

  -- Dim background ring
  love.graphics.setColor(0.3, 0.3, 0.3, 0.45)
  love.graphics.circle("line", cx, cy, r)

  if self.charge > 0 then
    -- Colour shifts: pale yellow → gold → near-white
    local t = self.charge
    local cr, cg, cb
    if t < 0.3 then
      cr, cg, cb = 0.8, 0.8, 0.2
    elseif t < 0.7 then
      cr, cg, cb = 1.0, 0.75, 0.0
    else
      cr, cg, cb = 1.0, 1.0, 0.55
    end
    love.graphics.setColor(cr, cg, cb, 0.9)

    -- Filled arc from the top, clockwise
    local steps      = math.max(3, math.floor(self.charge * 32))
    local start_ang  = -math.pi / 2
    local end_ang    = start_ang + self.charge * 2 * math.pi
    local verts      = { cx, cy }
    for i = 0, steps do
      local a = start_ang + (end_ang - start_ang) * i / steps
      verts[#verts + 1] = cx + math.cos(a) * r
      verts[#verts + 1] = cy + math.sin(a) * r
    end
    if #verts >= 6 then
      love.graphics.polygon("fill", verts)
    end

    -- Bright outline
    love.graphics.setColor(1, 1, 1, 0.55)
    love.graphics.circle("line", cx, cy, r)
  end

  love.graphics.setColor(1, 1, 1, 1)
end

return ChargeRing
