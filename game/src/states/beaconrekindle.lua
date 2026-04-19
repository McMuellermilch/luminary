-- BeaconRekindleState
-- Cutscene state pushed on top of OverworldState when the player uses a
-- Beacon Shard at a Beacon Tower. Animates the darkness shader from dark
-- to lit while an expanding light circle erupts from the tower position.
--
-- params:
--   overworld  — reference to the live OverworldState (for camera + player)
--   region_id  — e.g. "willowfen"
--   tower_x    — world-space X of the tower tile top-left
--   tower_y    — world-space Y of the tower tile top-left

local RegionState = require("src.world.regionstate")

local BeaconRekindleState = {}
BeaconRekindleState.__index = BeaconRekindleState

local DURATION    = 3.5    -- total cutscene length in seconds
local REKINDLE_AT = 1.5    -- call RegionState.rekindle() at this time
local MAX_RADIUS  = 1000   -- max expansion radius in window pixels

-- -------------------------------------------------------------------------
function BeaconRekindleState:enter(params)
  self.overworld  = params.overworld
  self.region_id  = params.region_id or RegionState.getActiveRegion()
  self.tower_x    = params.tower_x   or 0
  self.tower_y    = params.tower_y   or 0
  self.timer      = 0
  self.rekindled  = false

  -- Snapshot starting shader params so we can interpolate smoothly
  local p = RegionState.shader_params
  self._from_desat  = p.desaturate
  self._from_bright = p.brightness

  -- Initial camera shake to signal something big is happening
  self.overworld.camera:shake(3, 0.7)
end

function BeaconRekindleState:exit() end

-- -------------------------------------------------------------------------
function BeaconRekindleState:update(dt)
  self.timer = self.timer + dt
  local t    = math.min(self.timer / DURATION, 1.0)

  -- Smoothstep interpolation for shader params (dark → lit)
  local ease = t * t * (3.0 - 2.0 * t)
  RegionState.shader_params.desaturate = self._from_desat  * (1.0 - ease)
  RegionState.shader_params.brightness = self._from_bright + (1.0 - self._from_bright) * ease

  -- Trigger rekindle at the midpoint (flags set, event emitted)
  if not self.rekindled and self.timer >= REKINDLE_AT then
    self.rekindled = true
    RegionState.rekindle(self.region_id)
    self.overworld.camera:shake(7, 0.5)
  end

  -- Keep camera tracking the player
  local cx, cy = self.overworld.player:center()
  self.overworld.camera:follow(cx, cy)
  self.overworld.camera:update(dt)

  -- End cutscene
  if t >= 1.0 then
    local StateManager = require("src.states.statemanager")
    StateManager.pop()
  end
end

-- -------------------------------------------------------------------------
function BeaconRekindleState:draw()
  local t      = math.min(self.timer / DURATION, 1.0)
  -- Radius eases in quickly then slows (quadratic ease-out)
  local radius = MAX_RADIUS * (1.0 - (1.0 - t) * (1.0 - t))
  local alpha  = math.max(0.0, (1.0 - t) * 0.75)

  -- Convert tower centre from world space to window pixels
  local sx, sy = self.overworld.camera:toScreen(
    self.tower_x + 16, self.tower_y + 16)

  love.graphics.setBlendMode("add")

  -- Outer warm glow ring
  love.graphics.setColor(1.0, 0.80, 0.20, alpha * 0.5)
  love.graphics.circle("fill", sx, sy, radius)

  -- Inner bright core
  love.graphics.setColor(1.0, 0.96, 0.75, math.min(1.0, alpha * 1.8))
  love.graphics.circle("fill", sx, sy, radius * 0.20)

  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(1, 1, 1, 1)
end

function BeaconRekindleState:keypressed(key) end

return BeaconRekindleState
