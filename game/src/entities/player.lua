-- Player entity (Phase 2 stub)
-- Coloured rectangle with 4-directional movement and bump.lua collision.
-- Phase 4 will replace this with the full Entity + component system.

local Input      = require("src.core.input")
local MapManager = require("src.world.mapmanager")

local Player = {}
Player.__index = Player

local SPEED     = 120   -- pixels per second
local WIDTH     = 20    -- hitbox width (slightly smaller than tile)
local HEIGHT    = 26    -- hitbox height
local TILE      = 32    -- tile size

-- Colours per facing direction (placeholder art)
local COLORS = {
  down  = {0.95, 0.75, 0.35},
  up    = {0.85, 0.65, 0.25},
  left  = {0.90, 0.70, 0.30},
  right = {0.90, 0.70, 0.30},
}

-- bump.lua collision filter:
--   "slide"  — stop and slide along walls
--   "cross"  — pass through but register the collision (triggers)
local function collisionFilter(item, other)
  if other.type == "wall" then
    return "slide"
  end
  return "cross"
end

function Player.new(x, y)
  local self = setmetatable({}, Player)
  self.x       = x
  self.y       = y
  self.w       = WIDTH
  self.h       = HEIGHT
  self.facing  = "down"
  self.moving  = false

  -- Register with bump world
  MapManager.world:add(self, self.x, self.y, self.w, self.h)

  return self
end

function Player:update(dt)
  local dx, dy = 0, 0

  -- Only one axis at a time (4-directional, no diagonal)
  if Input.isDown("move_up") then
    dy = -1; self.facing = "up"
  elseif Input.isDown("move_down") then
    dy =  1; self.facing = "down"
  elseif Input.isDown("move_left") then
    dx = -1; self.facing = "left"
  elseif Input.isDown("move_right") then
    dx =  1; self.facing = "right"
  end

  self.moving = (dx ~= 0 or dy ~= 0)

  if self.moving then
    local nx = self.x + dx * SPEED * dt
    local ny = self.y + dy * SPEED * dt

    local actualX, actualY = MapManager.world:move(self, nx, ny, collisionFilter)
    self.x = actualX
    self.y = actualY
  end

  -- Interaction check: press confirm to interact with what's ahead
  if Input.wasPressed("confirm") then
    self:_interact()
  end
end

-- Returns the world-space rectangle of the tile directly in front of the player.
function Player:_interactionRect()
  local ix, iy = self.x, self.y
  if     self.facing == "up"    then iy = iy - TILE
  elseif self.facing == "down"  then iy = iy + self.h
  elseif self.facing == "left"  then ix = ix - TILE
  elseif self.facing == "right" then ix = ix + self.w
  end
  return ix, iy, TILE, TILE
end

function Player:_interact()
  local ix, iy, iw, ih = self:_interactionRect()
  -- Query bump for anything in the interaction rectangle
  local items = MapManager.world:queryRect(ix, iy, iw, ih)
  for _, item in ipairs(items) do
    if item.type == "npc" and item.onInteract then
      item:onInteract(self)
      return
    end
  end
end

function Player:draw()
  -- Placeholder: draw a coloured rectangle with a direction indicator
  local c = COLORS[self.facing]
  love.graphics.setColor(c[1], c[2], c[3], 1)
  love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 3, 3)

  -- Direction dot
  love.graphics.setColor(0.2, 0.15, 0.05, 1)
  local dot_size = 5
  local cx, cy = self.x + self.w/2, self.y + self.h/2
  local dot_offsets = {
    up    = {0, -7},
    down  = {0,  7},
    left  = {-7, 0},
    right = { 7, 0},
  }
  local off = dot_offsets[self.facing]
  love.graphics.circle("fill", cx + off[1], cy + off[2], dot_size/2)

  love.graphics.setColor(1, 1, 1, 1)
end

-- Centre of the player sprite (used by camera follow).
function Player:center()
  return self.x + self.w / 2, self.y + self.h / 2
end

return Player
