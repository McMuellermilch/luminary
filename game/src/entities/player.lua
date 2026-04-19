-- Player entity
-- Inherits from Entity. Uses Physics, Animation, Facing, and Health components.
-- Phase 5 will wire Health into the combat system.

local Entity    = require("src.entities.entity")
local Physics   = require("src.entities.components.physics")
local AnimComp  = require("src.entities.components.animation")
local Facing    = require("src.entities.components.facing")
local Health    = require("src.entities.components.health")
local Aseprite  = require("src.core.aseprite")
local Input     = require("src.core.input")
local MapManager = require("src.world.mapmanager")

local Player = setmetatable({}, { __index = Entity })
Player.__index = Player

local SPEED  = 120   -- pixels per second
local W      = 20    -- hitbox width
local H      = 26    -- hitbox height
local TILE   = 32

-- Collision filter: slide against walls and NPCs; cross everything else
local function collision_filter(item, other)
  if other.type == "wall" or other.type == "npc" then
    return "slide"
  end
  return "cross"
end

function Player.new(x, y)
  local self = Entity.new(x, y)
  setmetatable(self, Player)

  -- Hitbox size (needed by EntityManager depth sort and WarpSystem)
  self.w    = W
  self.h    = H
  self.type = "player"

  -- Physics — manages bump registration and movement
  local phys = Physics.new(MapManager.world, W, H)
  self:addComponent("physics", phys)
  phys:register()

  -- Animation — loaded from Aseprite JSON
  local sprite = Aseprite.load("assets/sprites/luma.png", "assets/sprites/luma.json")
  local anim   = AnimComp.new(sprite.image, sprite.anims)
  self:addComponent("animation", anim)

  -- Facing — syncs animation state automatically
  local facing = Facing.new("down")
  self:addComponent("facing", facing)

  -- Health — Luma's HP (used in Phase 5 combat)
  self:addComponent("health", Health.new(10))

  return self
end

function Player:update(dt)
  local dx, dy = 0, 0
  local dir    = nil

  if     Input.isDown("move_up")    then dy = -1; dir = "up"
  elseif Input.isDown("move_down")  then dy =  1; dir = "down"
  elseif Input.isDown("move_left")  then dx = -1; dir = "left"
  elseif Input.isDown("move_right") then dx =  1; dir = "right"
  end

  local moving = (dx ~= 0 or dy ~= 0)

  -- Update facing + animation before moving so the frame is correct this frame
  self:getComponent("facing"):set(dir, moving)

  if moving then
    self:getComponent("physics"):move(dx * SPEED * dt, dy * SPEED * dt, collision_filter)
  end

  -- Update animation clock
  self:getComponent("animation"):update(dt)

  -- Interaction
  if Input.wasPressed("confirm") then
    self:_interact()
  end
end

function Player:draw()
  self:getComponent("animation"):draw()
end

-- Returns the world-space centre of the player (used by camera and WarpSystem).
function Player:center()
  return self:getComponent("physics"):center()
end

-- Returns the facing direction string (used by debug HUD).
function Player:getFacing()
  return self:getComponent("facing").direction
end

-- World-space rectangle of the tile directly in front of the player.
function Player:_interactionRect()
  local facing = self:getComponent("facing").direction
  local ix, iy = self.x, self.y
  if     facing == "up"    then iy = iy - TILE
  elseif facing == "down"  then iy = iy + self.h
  elseif facing == "left"  then ix = ix - TILE
  elseif facing == "right" then ix = ix + self.w
  end
  return ix, iy, TILE, TILE
end

function Player:_interact()
  local ix, iy, iw, ih = self:_interactionRect()
  local items = MapManager.world:queryRect(ix, iy, iw, ih)
  for _, item in ipairs(items) do
    if item.type == "npc" and item.onInteract then
      item:onInteract(self)
      return
    end
  end
end

-- Remove from bump world (call before map unload).
function Player:destroy()
  self:getComponent("physics"):unregister()
  Entity.destroy(self)
end

return Player
